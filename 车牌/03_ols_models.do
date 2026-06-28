/*===========================================================================
  03_ols_models.do
  OLS Regression Models for Shanghai Car Plate Auction Price Prediction
  Groups A-D: level and log models for min_price and avg_price
  Full-sample models (no warning_price) also included
===========================================================================*/

clear all
set more off
capture log close sublog03
cd "/home/aragorn/Working/chepai_data"
use "data/cleaned_data.dta", clear
capture mkdir "results"
capture mkdir "log"
log using "log/03_ols_models.log", name(sublog03) replace text

* Install outreg2 if not available
capture which outreg2
if _rc != 0 {
    ssc install outreg2, replace
}

* Define sample: training set excluding anomaly
* Note: models WITH warning_price will have fewer obs (2014 onward) due to missing warning_price

*===========================================================================
* GROUP A: Level models - min_price as dependent variable
*===========================================================================

* MA1: Basic (no time trend, no lags)
reg min_price supply bidders warning_price if train==1 & anomaly==0
outreg2 using "results/reg_minprice_level.txt", replace ctitle(MA1) ///
    title("OLS Models: Minimum Transaction Price (Level)") ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N))

* MA2: Add linear time trend
reg min_price supply bidders warning_price t if train==1 & anomaly==0
outreg2 using "results/reg_minprice_level.txt", append ctitle(MA2)

* MA3: Add month FE
reg min_price supply bidders warning_price t i.month if train==1 & anomaly==0
outreg2 using "results/reg_minprice_level.txt", append ctitle(MA3)

* MA4: Add L1 lag
reg min_price supply bidders warning_price t i.month L1_min if train==1 & anomaly==0
outreg2 using "results/reg_minprice_level.txt", append ctitle(MA4)

* MA5: Add L2 lag
reg min_price supply bidders warning_price t i.month L1_min L2_min if train==1 & anomaly==0
outreg2 using "results/reg_minprice_level.txt", append ctitle(MA5)

* MA6: Add bid_ratio
reg min_price supply bidders warning_price t i.month L1_min bid_ratio if train==1 & anomaly==0
outreg2 using "results/reg_minprice_level.txt", append ctitle(MA6)

* MA7: Add polynomial terms
reg min_price supply bidders warning_price t t2 i.month L1_min bidders2 if train==1 & anomaly==0
outreg2 using "results/reg_minprice_level.txt", append ctitle(MA7)

* MA8: Add interaction term
reg min_price supply bidders warning_price t i.month L1_min supply_bidders if train==1 & anomaly==0
outreg2 using "results/reg_minprice_level.txt", append ctitle(MA8)

di "=== Group A complete ==="

*===========================================================================
* GROUP B: Log models - ln_min_price as dependent variable
*===========================================================================

* MB1: Log basics
reg ln_min_price ln_supply ln_bidders ln_warning if train==1 & anomaly==0
outreg2 using "results/reg_minprice_log.txt", replace ctitle(MB1) ///
    title("OLS Models: Log Minimum Transaction Price")

* MB2: Add time trend
reg ln_min_price ln_supply ln_bidders ln_warning t if train==1 & anomaly==0
outreg2 using "results/reg_minprice_log.txt", append ctitle(MB2)

* MB3: Add month FE
reg ln_min_price ln_supply ln_bidders ln_warning t i.month if train==1 & anomaly==0
outreg2 using "results/reg_minprice_log.txt", append ctitle(MB3)

* MB4: Add log lag
reg ln_min_price ln_supply ln_bidders ln_warning t i.month L1_ln_min if train==1 & anomaly==0
outreg2 using "results/reg_minprice_log.txt", append ctitle(MB4)

* MB5: Add polynomial
reg ln_min_price ln_supply ln_bidders ln_warning t i.month L1_ln_min bidders2 if train==1 & anomaly==0
outreg2 using "results/reg_minprice_log.txt", append ctitle(MB5)

di "=== Group B complete ==="

*===========================================================================
* GROUP C: Level models - avg_price as dependent variable
*===========================================================================

* MC1: Basic
reg avg_price supply bidders warning_price if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_level.txt", replace ctitle(MC1) ///
    title("OLS Models: Average Transaction Price (Level)")

* MC2: Add time trend
reg avg_price supply bidders warning_price t if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_level.txt", append ctitle(MC2)

* MC3: Add month FE
reg avg_price supply bidders warning_price t i.month if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_level.txt", append ctitle(MC3)

* MC4: Add L1 lag
reg avg_price supply bidders warning_price t i.month L1_avg if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_level.txt", append ctitle(MC4)

* MC5: Add L2 lag of min_price (parallel to MA5 using L2_min)
reg avg_price supply bidders warning_price t i.month L1_avg L2_min if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_level.txt", append ctitle(MC5)

* MC6: Add bid_ratio
reg avg_price supply bidders warning_price t i.month L1_avg bid_ratio if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_level.txt", append ctitle(MC6)

* MC7: Add polynomial terms
reg avg_price supply bidders warning_price t t2 i.month L1_avg bidders2 if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_level.txt", append ctitle(MC7)

* MC8: Add interaction term
reg avg_price supply bidders warning_price t i.month L1_avg supply_bidders if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_level.txt", append ctitle(MC8)

di "=== Group C complete ==="

*===========================================================================
* GROUP D: Log models - ln_avg_price as dependent variable
*===========================================================================

* MD1: Log basics
reg ln_avg_price ln_supply ln_bidders ln_warning if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_log.txt", replace ctitle(MD1) ///
    title("OLS Models: Log Average Transaction Price")

* MD2: Add time trend
reg ln_avg_price ln_supply ln_bidders ln_warning t if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_log.txt", append ctitle(MD2)

* MD3: Add month FE
reg ln_avg_price ln_supply ln_bidders ln_warning t i.month if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_log.txt", append ctitle(MD3)

* MD4: Add log lag
reg ln_avg_price ln_supply ln_bidders ln_warning t i.month L1_ln_avg if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_log.txt", append ctitle(MD4)

* MD5: Add polynomial
reg ln_avg_price ln_supply ln_bidders ln_warning t i.month L1_ln_avg bidders2 if train==1 & anomaly==0
outreg2 using "results/reg_avgprice_log.txt", append ctitle(MD5)

di "=== Group D complete ==="

*===========================================================================
* FULL-SAMPLE MODELS: No warning_price (all training data 2010-2025m9)
* These use the complete training sample instead of the 2014+ subset
*===========================================================================

* FA4: Level min_price, full sample with lag
reg min_price supply bidders t i.month L1_min if train==1 & anomaly==0
outreg2 using "results/reg_fullsample.txt", replace ctitle(FA4) ///
    title("OLS Models: Full Sample (No Warning Price)")

* FB4: Log min_price, full sample with lag
reg ln_min_price ln_supply ln_bidders t i.month L1_ln_min if train==1 & anomaly==0
outreg2 using "results/reg_fullsample.txt", append ctitle(FB4)

* FC4: Level avg_price, full sample with lag
reg avg_price supply bidders t i.month L1_avg if train==1 & anomaly==0
outreg2 using "results/reg_fullsample.txt", append ctitle(FC4)

* FD4: Log avg_price, full sample with lag
reg ln_avg_price ln_supply ln_bidders t i.month L1_ln_avg if train==1 & anomaly==0
outreg2 using "results/reg_fullsample.txt", append ctitle(FD4)

di "=== Full-sample models complete ==="
di "=== 03_ols_models.do completed ==="

log close sublog03
