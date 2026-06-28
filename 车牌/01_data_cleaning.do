/*===========================================================================
  01_data_cleaning.do
  Shanghai Car License Plate Auction Data - Cleaning & Variable Construction
  Data: 2010m1 - 2026m2 (194 observations)
  Author: Sisyphus
  Date: 2026-03-26
===========================================================================*/

clear all
set more off
capture log close sublog01

* Set working directory
cd "/home/aragorn/Working/chepai_data"

* Create log
log using "log/01_data_cleaning.log", name(sublog01) replace text

*---------------------------------------------------------------------------
* 1. IMPORT DATA
*---------------------------------------------------------------------------
import delimited "shanghai_car_license_auction_2010_2026.csv", ///
    encoding(UTF-8) varnames(1) clear

* Check import
describe
list in 1/3

* Rename variables to English names
* (Stata imports Chinese column headers as Chinese variable names)
rename 拍卖时间        time_str
rename 投放数量        supply
rename 最低成交价      min_price
rename 平均成交价      avg_price
rename 最低成交价截止时间 cutoff_time
rename 投标人数        bidders
rename 警示价          warning_price

* Confirm rename
describe

*---------------------------------------------------------------------------
* 2. PARSE CHINESE DATE STRINGS
*---------------------------------------------------------------------------
* Extract year and month from strings like "2010年1月"
gen year  = .
gen month = .

* Use regexm to match pattern: digits + 年 + digits + 月
* Note: Stata's regexm uses POSIX ERE; Chinese chars are fine as literals
forvalues i = 1/`=_N' {
    local s = time_str[`i']
    if regexm("`s'", "([0-9]+)年([0-9]+)月") {
        replace year  = real(regexs(1)) in `i'
        replace month = real(regexs(2)) in `i'
    }
}

* Verify extraction
assert !missing(year)
assert !missing(month)
assert year  >= 2010 & year  <= 2026
assert month >= 1    & month <= 12

* Generate time-series index: t=1 → January 2010
gen t = (year - 2010) * 12 + month
label var t "Time index (1 = Jan 2010)"

* Declare as monthly time series
tsset t

* Confirm no gaps (should be 194 obs, t from 1 to 194)
sum t

*---------------------------------------------------------------------------
* 3. HANDLE ANOMALOUS OBSERVATION
*---------------------------------------------------------------------------
* 2010m12: min_price = 10,400 yuan — clearly anomalous (all other months ~37,000+)
* Flagged with dummy; excluded from regressions via if !anomaly
gen byte anomaly = (year == 2010 & month == 12)
label var anomaly "Anomaly flag: 2010m12 min_price=10400 (system anomaly)"

* Show the anomalous observation
di _n "=== Anomalous observation ==="
list year month min_price avg_price if anomaly == 1

*---------------------------------------------------------------------------
* 4. DERIVED VARIABLES
*---------------------------------------------------------------------------
* Bid intensity ratio
gen bid_ratio = bidders / supply
label var bid_ratio "Bid-to-supply ratio (bidders/supply)"

* Price spread
gen price_spread = avg_price - min_price
label var price_spread "Price spread: avg - min (Yuan)"

* Log transformations
gen ln_min_price = ln(min_price)
label var ln_min_price "Log minimum transaction price"

gen ln_avg_price = ln(avg_price)
label var ln_avg_price "Log average transaction price"

gen ln_bidders = ln(bidders)
label var ln_bidders "Log number of bidders"

gen ln_supply = ln(supply)
label var ln_supply "Log number of plates supplied"

* Log warning price (only defined from ~2014 onward; missing before)
gen ln_warning = ln(warning_price) if !missing(warning_price) & warning_price > 0
label var ln_warning "Log warning price (reference floor price)"

*---------------------------------------------------------------------------
* 5. LAGGED VARIABLES (requires tsset)
*---------------------------------------------------------------------------
gen L1_min      = L.min_price
gen L2_min      = L2.min_price
gen L1_avg      = L.avg_price
gen L1_bidders  = L.bidders
gen L1_supply   = L.supply
gen L1_ln_min   = L.ln_min_price
gen L1_ln_avg   = L.ln_avg_price
gen L1_ln_bidders = L.ln_bidders
gen L1_warning  = L.warning_price
gen L1_ln_warning = L.ln_warning

label var L1_min       "Lag 1: minimum price"
label var L2_min       "Lag 2: minimum price"
label var L1_avg       "Lag 1: average price"
label var L1_bidders   "Lag 1: number of bidders"
label var L1_supply    "Lag 1: supply"
label var L1_ln_min    "Lag 1: log minimum price"
label var L1_ln_avg    "Lag 1: log average price"
label var L1_ln_bidders "Lag 1: log bidders"
label var L1_warning   "Lag 1: warning price"
label var L1_ln_warning "Lag 1: log warning price"

*---------------------------------------------------------------------------
* 6. POLYNOMIAL AND INTERACTION TERMS
*---------------------------------------------------------------------------
gen t2 = t^2
label var t2 "Time trend squared"

* Scale to avoid numerical issues in regression
gen bidders2 = bidders^2 / 1e8
label var bidders2 "Bidders squared / 1e8 (scaled)"

gen supply_bidders = supply * bidders / 1e6
label var supply_bidders "Supply x bidders / 1e6 (scaled interaction)"

*---------------------------------------------------------------------------
* 7. TRAIN / TEST SPLIT
*---------------------------------------------------------------------------
* Training set: up to and including 2025m9
* Test set: 2025m10 onward (last 5 observations)
gen byte train = (year < 2025 | (year == 2025 & month <= 9))
gen byte test  = 1 - train

label var train "Train set indicator (up to 2025m9 inclusive)"
label var test  "Test set indicator (2025m10 onward)"

di _n "=== Train/Test split ==="
tab train
di "Train obs: " %3.0f sum(train)
di "Test  obs: " %3.0f sum(test)

* Confirm test set is exactly 2025m10 - 2026m2
list year month if test == 1

*---------------------------------------------------------------------------
* 8. VARIABLE LABELS (remaining)
*---------------------------------------------------------------------------
label var time_str    "Date string (Chinese format)"
label var supply      "Number of plates supplied"
label var min_price   "Minimum transaction price (Yuan)"
label var avg_price   "Average transaction price (Yuan)"
label var cutoff_time "Cutoff time string for minimum price"
label var bidders     "Number of bidders"
label var warning_price "Warning/reference floor price (Yuan)"
label var year        "Year"
label var month       "Month"

*---------------------------------------------------------------------------
* 9. FINAL CHECKS & SUMMARY STATISTICS
*---------------------------------------------------------------------------
describe

di _n "=== Summary statistics ==="
sum min_price avg_price supply bidders warning_price bid_ratio price_spread ///
    ln_min_price ln_avg_price

di _n "=== Missing values check ==="
sum L1_min L2_min L1_avg L1_warning

di _n "=== Anomalous observation detail ==="
list year month min_price avg_price bidders supply if anomaly == 1

*---------------------------------------------------------------------------
* 10. SAVE DATA
*---------------------------------------------------------------------------
* Ensure output directory exists
capture mkdir "data"

save "data/cleaned_data.dta", replace
export delimited "data/cleaned_data.csv", replace

di _n "=== Data saved successfully ==="
di "DTA: data/cleaned_data.dta"
di "CSV: data/cleaned_data.csv"
di "Total observations: " _N

log close sublog01
