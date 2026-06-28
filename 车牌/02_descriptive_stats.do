/*===========================================================================
  02_descriptive_stats.do
  Shanghai Car License Plate Auction Data - Descriptive Statistics
  Data: 2010m1 - 2026m2 (194 observations)
  Author: Sisyphus
  Date: 2026-03-26
===========================================================================*/

clear all
set more off
capture log close sublog02

* Set working directory
cd "/home/aragorn/Working/chepai_data"

* Load data
use "data/cleaned_data.dta", clear

* Create output directories
capture mkdir "results"
capture mkdir "results/figures"

* Open log
log using "log/02_descriptive_stats.log", name(sublog02) replace text

* Set graph scheme
set scheme s2color

*---------------------------------------------------------------------------
* 1. DESCRIPTIVE STATISTICS TABLE (Full Sample)
*---------------------------------------------------------------------------
di _n "=== Descriptive Statistics - Full Sample ==="
sum min_price avg_price supply bidders warning_price bid_ratio price_spread if !anomaly

* Check if estout package is available
capture which estpost
if _rc == 0 {
    * estout is available
    estpost summarize min_price avg_price supply bidders warning_price bid_ratio price_spread if !anomaly
    esttab using "results/desc_stats.txt", replace ///
        cells("mean(fmt(%10.1f)) sd(fmt(%10.1f)) min(fmt(%10.0f)) max(fmt(%10.0f)) count(fmt(%3.0f))") ///
        title("Descriptive Statistics - Full Sample") label noobs
    di "Descriptive stats written via esttab."
}
else {
    * Fallback: use file write
    file open fh using "results/desc_stats.txt", write replace
    file write fh "Descriptive Statistics - Full Sample" _n
    file write fh "=====================================================================" _n
    file write fh "Variable            Mean          SD           Min          Max         N" _n
    file write fh "---------------------------------------------------------------------" _n
    foreach v in min_price avg_price supply bidders warning_price bid_ratio price_spread {
        quietly sum `v' if !anomaly
        file write fh %-20s ("`v'") %12.1f (r(mean)) %12.1f (r(sd)) %12.0f (r(min)) %12.0f (r(max)) %8.0f (r(N)) _n
    }
    file write fh "=====================================================================" _n
    file close fh
    di "Descriptive stats written via file write (estout not available)."
}

*---------------------------------------------------------------------------
* 2. TRAIN vs TEST SPLIT SUMMARY
*---------------------------------------------------------------------------
di _n "=== Train/Test Split Summary ==="
tab train
di "Training observations: " %3.0f sum(train)
di "Test observations:      " %3.0f sum(test)

*---------------------------------------------------------------------------
* 3. MISSING VALUES CHECK
*---------------------------------------------------------------------------
di _n "=== Missing Value Check ==="
misstable summarize min_price avg_price supply bidders year month

* Check lagged variables (expect 1 missing at start)
misstable summarize L1_min L2_min L1_avg L1_warning L1_bidders

*---------------------------------------------------------------------------
* 4. DUPLICATE MONTHS CHECK
*---------------------------------------------------------------------------
di _n "=== Duplicate Year-Month Check ==="
duplicates report year month

*---------------------------------------------------------------------------
* 5. RANGE ASSERTIONS
*---------------------------------------------------------------------------
di _n "=== Assertion Checks ==="
assert min_price > 0 if !missing(min_price)
assert supply > 0 if !missing(supply)
assert bidders > 0 if !missing(bidders)
di "All assertions passed."

* Show anomaly observation
di _n "=== Anomaly Observation ==="
list year month min_price avg_price if anomaly == 1

* Show potential anomalies: unusually low prices
di _n "=== Low Price Observations (< 20000 yuan) ==="
list year month min_price avg_price if (min_price < 20000 | avg_price < 20000) & !missing(min_price)

*---------------------------------------------------------------------------
* 6. CORRELATION MATRIX (Training sample, no anomaly)
*---------------------------------------------------------------------------
di _n "=== Correlation Matrix (Train sample, no anomaly) ==="
pwcorr min_price avg_price supply bidders warning_price bid_ratio L1_min if train & !anomaly, star(0.05) sig

*---------------------------------------------------------------------------
* 7. ANNUAL MEANS TABLE
*---------------------------------------------------------------------------
di _n "=== Annual Mean Values ==="
preserve
collapse (mean) min_price avg_price supply bidders bid_ratio ///
         (count) n_obs=min_price, by(year)
label var min_price "Mean Min Price"
label var avg_price "Mean Avg Price"
label var supply    "Mean Supply"
label var bidders   "Mean Bidders"
label var bid_ratio "Mean Bid Ratio"
label var n_obs     "Observations"
list year min_price avg_price supply bidders bid_ratio n_obs, sep(0) noobs
restore

*---------------------------------------------------------------------------
* 8. DEFINE TIME AXIS LABELS
*---------------------------------------------------------------------------
* t is numeric 1-194; map January of each year to a label
label define tlab ///
    1   "2010" ///
    13  "2011" ///
    25  "2012" ///
    37  "2013" ///
    49  "2014" ///
    61  "2015" ///
    73  "2016" ///
    85  "2017" ///
    97  "2018" ///
    109 "2019" ///
    121 "2020" ///
    133 "2021" ///
    145 "2022" ///
    157 "2023" ///
    169 "2024" ///
    181 "2025" ///
    194 "2026m2"
label values t tlab

* Train/test boundary: last train obs is 2025m9 = t=189 (1+(2025-2010)*12+9-1=188... let's calc)
* t = (year-2010)*12 + month  → 2025m9: (2025-2010)*12 + 9 = 180+9 = 189
* first test obs: 2025m10 → t = 190
local split_t = 189

*---------------------------------------------------------------------------
* 9. FIGURE: Price Trend Over Time
*---------------------------------------------------------------------------
twoway ///
    (line min_price t if !anomaly, lcolor(navy) lwidth(medthin) lpattern(solid)) ///
    (line avg_price t if !anomaly, lcolor(cranberry) lwidth(medthin) lpattern(dash)), ///
    title("Shanghai Car License Plate Auction Prices", size(medium)) ///
    subtitle("Monthly 2010m1 – 2026m2 (anomaly 2010m12 excluded)", size(small)) ///
    ytitle("Price (Yuan)", size(small)) xtitle("") ///
    xlabel(1 13 25 37 49 61 73 85 97 109 121 133 145 157 169 181 194, ///
           angle(45) valuelabel labsize(vsmall)) ///
    xline(`split_t', lcolor(green) lpattern(shortdash) lwidth(thin)) ///
    legend(label(1 "Minimum Price") label(2 "Average Price") ///
           ring(0) position(11) size(small)) ///
    note("Green dashed line = train/test split (2025m9/2025m10)", size(vsmall))
graph export "results/figures/price_trend.png", replace width(1200)
di "Saved: results/figures/price_trend.png"

*---------------------------------------------------------------------------
* 10. FIGURE: Plates Supply Over Time
*---------------------------------------------------------------------------
twoway (line supply t if !anomaly, lcolor(dknavy) lwidth(medthin)), ///
    title("Plates Supplied Over Time", size(medium)) ///
    subtitle("Monthly 2010m1 – 2026m2", size(small)) ///
    ytitle("Quantity", size(small)) xtitle("") ///
    xlabel(1 13 25 37 49 61 73 85 97 109 121 133 145 157 169 181 194, ///
           angle(45) valuelabel labsize(vsmall)) ///
    xline(`split_t', lcolor(green) lpattern(shortdash) lwidth(thin))
graph export "results/figures/supply_trend.png", replace width(1200)
di "Saved: results/figures/supply_trend.png"

*---------------------------------------------------------------------------
* 11. FIGURE: Number of Bidders Over Time
*---------------------------------------------------------------------------
twoway (line bidders t if !anomaly, lcolor(dkgreen) lwidth(medthin)), ///
    title("Number of Bidders Over Time", size(medium)) ///
    subtitle("Monthly 2010m1 – 2026m2", size(small)) ///
    ytitle("Bidders", size(small)) xtitle("") ///
    xlabel(1 13 25 37 49 61 73 85 97 109 121 133 145 157 169 181 194, ///
           angle(45) valuelabel labsize(vsmall)) ///
    xline(`split_t', lcolor(green) lpattern(shortdash) lwidth(thin))
graph export "results/figures/bidders_trend.png", replace width(1200)
di "Saved: results/figures/bidders_trend.png"

*---------------------------------------------------------------------------
* 12. FIGURE: Bid-to-Supply Ratio Over Time
*---------------------------------------------------------------------------
twoway (line bid_ratio t if !anomaly, lcolor(orange) lwidth(medthin)), ///
    title("Bid-to-Supply Ratio Over Time", size(medium)) ///
    subtitle("Monthly 2010m1 – 2026m2", size(small)) ///
    ytitle("Ratio (Bidders/Supply)", size(small)) xtitle("") ///
    xlabel(1 13 25 37 49 61 73 85 97 109 121 133 145 157 169 181 194, ///
           angle(45) valuelabel labsize(vsmall)) ///
    xline(`split_t', lcolor(green) lpattern(shortdash) lwidth(thin))
graph export "results/figures/bidratio_trend.png", replace width(1200)
di "Saved: results/figures/bidratio_trend.png"

*---------------------------------------------------------------------------
* 13. FIGURE: Warning Price vs Transaction Prices (2014 onward, t >= 49)
*---------------------------------------------------------------------------
twoway ///
    (line min_price t if t >= 49 & !anomaly, lcolor(navy) lwidth(medthin) lpattern(solid)) ///
    (line avg_price t if t >= 49 & !anomaly, lcolor(cranberry) lwidth(medthin) lpattern(dash)) ///
    (line warning_price t if t >= 49 & !missing(warning_price), lcolor(dkgreen) lwidth(medthin) lpattern(dot)), ///
    title("Prices vs Warning Price (2014 onward)", size(medium)) ///
    ytitle("Price (Yuan)", size(small)) xtitle("") ///
    xlabel(49 61 73 85 97 109 121 133 145 157 169 181 194, ///
           angle(45) valuelabel labsize(vsmall)) ///
    xline(`split_t', lcolor(green) lpattern(shortdash) lwidth(thin)) ///
    legend(label(1 "Min Price") label(2 "Avg Price") label(3 "Warning Price") ///
           ring(0) position(11) size(small))
graph export "results/figures/warning_price_comparison.png", replace width(1200)
di "Saved: results/figures/warning_price_comparison.png"

*---------------------------------------------------------------------------
* 14. FIGURE: Log Prices Trend (for regression context)
*---------------------------------------------------------------------------
twoway ///
    (line ln_min_price t if !anomaly, lcolor(navy) lwidth(medthin) lpattern(solid)) ///
    (line ln_avg_price t if !anomaly, lcolor(cranberry) lwidth(medthin) lpattern(dash)), ///
    title("Log Prices Over Time", size(medium)) ///
    ytitle("Log Price", size(small)) xtitle("") ///
    xlabel(1 13 25 37 49 61 73 85 97 109 121 133 145 157 169 181 194, ///
           angle(45) valuelabel labsize(vsmall)) ///
    xline(`split_t', lcolor(green) lpattern(shortdash) lwidth(thin)) ///
    legend(label(1 "Log Min Price") label(2 "Log Avg Price") ///
           ring(0) position(11) size(small))
graph export "results/figures/log_prices_trend.png", replace width(1200)
di "Saved: results/figures/log_prices_trend.png"

*---------------------------------------------------------------------------
* 15. FIGURE: Price Spread Over Time
*---------------------------------------------------------------------------
twoway (line price_spread t if !anomaly, lcolor(purple) lwidth(medthin)), ///
    title("Price Spread (Avg - Min) Over Time", size(medium)) ///
    ytitle("Spread (Yuan)", size(small)) xtitle("") ///
    xlabel(1 13 25 37 49 61 73 85 97 109 121 133 145 157 169 181 194, ///
           angle(45) valuelabel labsize(vsmall)) ///
    xline(`split_t', lcolor(green) lpattern(shortdash) lwidth(thin))
graph export "results/figures/price_spread_trend.png", replace width(1200)
di "Saved: results/figures/price_spread_trend.png"

*---------------------------------------------------------------------------
* 16. FINAL SUMMARY
*---------------------------------------------------------------------------
di _n "=== File list in results/figures/ ==="
local figures : dir "results/figures" files "*.png"
foreach f of local figures {
    di "  " "`f'"
}

di _n "=== 02_descriptive_stats.do completed successfully ==="
di "Output: results/desc_stats.txt"
di "Figures: results/figures/*.png"

log close sublog02
