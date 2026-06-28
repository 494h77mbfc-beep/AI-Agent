/*===========================================================================
  05_model_selection.do
  Model Selection and Future Prediction
  Summarizes all models, selects best model, predicts 2026m3
===========================================================================*/

clear all
set more off
capture log close sublog05
cd "/home/aragorn/Working/chepai_data"
use "data/cleaned_data.dta", clear
capture mkdir "results"
capture mkdir "log"
log using "log/05_model_selection.log", name(sublog05) replace text

di "=== 05_model_selection.do started ==="
di "Dataset loaded: `c(N)' observations, `c(k)' variables"

*===========================================================================
* SECTION 1: RE-ESTIMATE ALL 8 KEY MODELS AND COLLECT FIT STATISTICS
* Training set: train==1 & anomaly==0
* Models with warning_price: 2014+ subset (~144 obs)
*===========================================================================

di ""
di "=== SECTION 1: IN-SAMPLE MODEL FIT STATISTICS ==="

*---------------------------------------------------------------------------
* GROUP A: Level models, min_price, with warning_price
*---------------------------------------------------------------------------

* MA1: Basic (no time trend, no lags)
qui reg min_price supply bidders warning_price if train==1 & anomaly==0
scalar r2_MA1   = e(r2)
scalar r2a_MA1  = e(r2_a)
scalar N_MA1    = e(N)
estat ic
matrix ic = r(S)
scalar aic_MA1  = ic[1,5]
scalar bic_MA1  = ic[1,6]
di "MA1: N=" N_MA1 " R2=" r2_MA1 " AdjR2=" r2a_MA1 " AIC=" aic_MA1 " BIC=" bic_MA1

* MA2: Add linear time trend
qui reg min_price supply bidders warning_price t if train==1 & anomaly==0
scalar r2_MA2   = e(r2)
scalar r2a_MA2  = e(r2_a)
scalar N_MA2    = e(N)
estat ic
matrix ic = r(S)
scalar aic_MA2  = ic[1,5]
scalar bic_MA2  = ic[1,6]
di "MA2: N=" N_MA2 " R2=" r2_MA2 " AdjR2=" r2a_MA2 " AIC=" aic_MA2 " BIC=" bic_MA2

* MA3: Add month fixed effects
qui reg min_price supply bidders warning_price t i.month if train==1 & anomaly==0
scalar r2_MA3   = e(r2)
scalar r2a_MA3  = e(r2_a)
scalar N_MA3    = e(N)
estat ic
matrix ic = r(S)
scalar aic_MA3  = ic[1,5]
scalar bic_MA3  = ic[1,6]
di "MA3: N=" N_MA3 " R2=" r2_MA3 " AdjR2=" r2a_MA3 " AIC=" aic_MA3 " BIC=" bic_MA3

* MA4: Add L1 lag (key model)
qui reg min_price supply bidders warning_price t i.month L1_min if train==1 & anomaly==0
scalar r2_MA4   = e(r2)
scalar r2a_MA4  = e(r2_a)
scalar N_MA4    = e(N)
estat ic
matrix ic = r(S)
scalar aic_MA4  = ic[1,5]
scalar bic_MA4  = ic[1,6]
di "MA4: N=" N_MA4 " R2=" r2_MA4 " AdjR2=" r2a_MA4 " AIC=" aic_MA4 " BIC=" bic_MA4

*---------------------------------------------------------------------------
* GROUP B: Log models, ln_min_price, with warning_price
*---------------------------------------------------------------------------

* MB1: Basic log model
qui reg ln_min_price ln_supply ln_bidders ln_warning if train==1 & anomaly==0
scalar r2_MB1   = e(r2)
scalar r2a_MB1  = e(r2_a)
scalar N_MB1    = e(N)
estat ic
matrix ic = r(S)
scalar aic_MB1  = ic[1,5]
scalar bic_MB1  = ic[1,6]
di "MB1: N=" N_MB1 " R2=" r2_MB1 " AdjR2=" r2a_MB1 " AIC=" aic_MB1 " BIC=" bic_MB1

* MB2: Add time trend
qui reg ln_min_price ln_supply ln_bidders ln_warning t if train==1 & anomaly==0
scalar r2_MB2   = e(r2)
scalar r2a_MB2  = e(r2_a)
scalar N_MB2    = e(N)
estat ic
matrix ic = r(S)
scalar aic_MB2  = ic[1,5]
scalar bic_MB2  = ic[1,6]
di "MB2: N=" N_MB2 " R2=" r2_MB2 " AdjR2=" r2a_MB2 " AIC=" aic_MB2 " BIC=" bic_MB2

* MB3: Add month fixed effects
qui reg ln_min_price ln_supply ln_bidders ln_warning t i.month if train==1 & anomaly==0
scalar r2_MB3   = e(r2)
scalar r2a_MB3  = e(r2_a)
scalar N_MB3    = e(N)
estat ic
matrix ic = r(S)
scalar aic_MB3  = ic[1,5]
scalar bic_MB3  = ic[1,6]
di "MB3: N=" N_MB3 " R2=" r2_MB3 " AdjR2=" r2a_MB3 " AIC=" aic_MB3 " BIC=" bic_MB3

* MB4: Add log lag (key model)
qui reg ln_min_price ln_supply ln_bidders ln_warning t i.month L1_ln_min if train==1 & anomaly==0
scalar r2_MB4   = e(r2)
scalar r2a_MB4  = e(r2_a)
scalar N_MB4    = e(N)
estat ic
matrix ic = r(S)
scalar aic_MB4  = ic[1,5]
scalar bic_MB4  = ic[1,6]
di "MB4: N=" N_MB4 " R2=" r2_MB4 " AdjR2=" r2a_MB4 " AIC=" aic_MB4 " BIC=" bic_MB4

*===========================================================================
* SECTION 2: WRITE MODEL COMPARISON TABLE
*===========================================================================

di ""
di "=== SECTION 2: WRITING MODEL COMPARISON TABLE ==="

* Hardcoded out-of-sample test results from prediction_results.md
* MA4: MAE=638, RMSE=687, MAPE=0.68%
* MB4: MAE=641, RMSE=684, MAPE=0.68%
* (other models not in this focused comparison)

file open fsel using "results/model_selection.txt", write replace

file write fsel "======================================================================" _n
file write fsel "MODEL SELECTION COMPARISON TABLE" _n
file write fsel "Shanghai Car Plate Auction Price - Min Price Models" _n
file write fsel "Training: train==1 & anomaly==0 (2014m1-2025m9 for warning_price models)" _n
file write fsel "======================================================================" _n _n

file write fsel "In-Sample Fit Statistics:" _n
file write fsel "------------------------------------------------------------------------" _n
file write fsel "Model  |   N   |   R2   | Adj-R2 |    AIC     |    BIC     | Spec" _n
file write fsel "-------|-------|--------|--------|------------|------------|------" _n

* Group A: Level models
file write fsel "MA1    | " %5.0f (N_MA1) " | " %6.4f (r2_MA1) " | " %6.4f (r2a_MA1) ///
    " | " %10.1f (aic_MA1) " | " %10.1f (bic_MA1) " | level, supply bidders warning" _n
file write fsel "MA2    | " %5.0f (N_MA2) " | " %6.4f (r2_MA2) " | " %6.4f (r2a_MA2) ///
    " | " %10.1f (aic_MA2) " | " %10.1f (bic_MA2) " | +t" _n
file write fsel "MA3    | " %5.0f (N_MA3) " | " %6.4f (r2_MA3) " | " %6.4f (r2a_MA3) ///
    " | " %10.1f (aic_MA3) " | " %10.1f (bic_MA3) " | +t +i.month" _n
file write fsel "MA4    | " %5.0f (N_MA4) " | " %6.4f (r2_MA4) " | " %6.4f (r2a_MA4) ///
    " | " %10.1f (aic_MA4) " | " %10.1f (bic_MA4) " | +t +i.month +L1_min  [KEY]" _n
file write fsel "-------|-------|--------|--------|------------|------------|------" _n

* Group B: Log models
file write fsel "MB1    | " %5.0f (N_MB1) " | " %6.4f (r2_MB1) " | " %6.4f (r2a_MB1) ///
    " | " %10.1f (aic_MB1) " | " %10.1f (bic_MB1) " | log, ln_supply ln_bidders ln_warning" _n
file write fsel "MB2    | " %5.0f (N_MB2) " | " %6.4f (r2_MB2) " | " %6.4f (r2a_MB2) ///
    " | " %10.1f (aic_MB2) " | " %10.1f (bic_MB2) " | +t" _n
file write fsel "MB3    | " %5.0f (N_MB3) " | " %6.4f (r2_MB3) " | " %6.4f (r2a_MB3) ///
    " | " %10.1f (aic_MB3) " | " %10.1f (bic_MB3) " | +t +i.month" _n
file write fsel "MB4    | " %5.0f (N_MB4) " | " %6.4f (r2_MB4) " | " %6.4f (r2a_MB4) ///
    " | " %10.1f (aic_MB4) " | " %10.1f (bic_MB4) " | +t +i.month +L1_ln_min  [KEY]" _n

file write fsel _n
file write fsel "Out-of-Sample Test Performance (2025m10 - 2026m2, N=5):" _n
file write fsel "-------------------------------------------------------" _n
file write fsel "Model  | MAE (Yuan) | RMSE (Yuan) | MAPE (%)  | Notes" _n
file write fsel "-------|------------|-------------|-----------|------" _n
file write fsel "MA4    |        638 |         687 |    0.68%  | Level, with warning_price" _n
file write fsel "MB4    |        641 |         684 |    0.68%  | Log-to-level, with warning_price" _n
file write fsel "MC4    |        683 |         734 |    0.73%  | Level avg_price" _n
file write fsel "MD4    |        683 |         732 |    0.73%  | Log-to-level avg_price" _n
file write fsel "FA4    |       1070 |        1196 |    1.14%  | Level min_price, no warning" _n
file write fsel "FB4    |       2513 |        3114 |    2.67%  | Log min_price, no warning" _n
file write fsel _n
file write fsel "Note: AIC/BIC not comparable between A and B groups (different dep var scales)" _n

file close fsel

di "Model comparison table written to results/model_selection.txt"

*===========================================================================
* SECTION 3: MODEL SELECTION RATIONALE
*===========================================================================

di ""
di "=== MODEL SELECTION ==="
di "Best predictive model: MA4 (Level, min_price, with warning_price)"
di "Reasons:"
di "  1. Nearly identical MAPE on test set (0.68%) as MB4"
di "  2. MA4 RMSE=687 vs MB4 RMSE=684 — virtually no difference"
di "  3. Level model is directly interpretable (yuan, no transformation)"
di "  4. No need for Duan smearing retransformation (simpler pipeline)"
di "  5. Strong in-sample Adj-R2 fit"
di "  Note: MB4 is nearly identical in test accuracy (RMSE=684 vs 687)"
di "  For practical use, either MA4 or MB4 is acceptable"

*===========================================================================
* SECTION 4: FUTURE PREDICTION FOR 2026m3 USING MA4 AND MB4
*===========================================================================

di ""
di "=== SECTION 4: FUTURE PREDICTION FOR 2026m3 ==="
di "Assumptions:"
di "  t=195 (2026m3), month=3"
di "  supply, bidders, warning_price: last known values from t=194 (2026m2)"
di "  L1_min = 94100 (actual 2026m2 min_price)"
di "  L1_ln_min = ln(94100)"

* ── get last known covariate values from t=194 (2026m2) ──────────────────
qui sum supply if t==194
local supply_2026m3 = r(mean)
qui sum bidders if t==194
local bidders_2026m3 = r(mean)
qui sum warning_price if t==194
local warning_2026m3 = r(mean)
qui sum ln_supply if t==194
local ln_supply_2026m3 = r(mean)
qui sum ln_bidders if t==194
local ln_bidders_2026m3 = r(mean)
qui sum ln_warning if t==194
local ln_warning_2026m3 = r(mean)

local L1_min_2026m3    = 94100
local L1_ln_min_2026m3 = ln(94100)
local t_2026m3         = 195
local month_2026m3     = 3

di "Covariates for 2026m3:"
di "  supply       = `supply_2026m3'"
di "  bidders      = `bidders_2026m3'"
di "  warning_price= `warning_2026m3'"
di "  ln_supply    = `ln_supply_2026m3'"
di "  ln_bidders   = `ln_bidders_2026m3'"
di "  ln_warning   = `ln_warning_2026m3'"
di "  L1_min       = `L1_min_2026m3'"
di "  L1_ln_min    = `L1_ln_min_2026m3'"
di "  t            = `t_2026m3'"
di "  month        = `month_2026m3'"

* ── Expand dataset by 1 observation for 2026m3 ───────────────────────────
* Save current N
local Nobs = _N
set obs `=`Nobs'+1'
local newrow = `Nobs' + 1

replace t             = `t_2026m3'         in `newrow'
replace year          = 2026               in `newrow'
replace month         = `month_2026m3'     in `newrow'
replace supply        = `supply_2026m3'    in `newrow'
replace bidders       = `bidders_2026m3'   in `newrow'
replace warning_price = `warning_2026m3'   in `newrow'
replace ln_supply     = `ln_supply_2026m3' in `newrow'
replace ln_bidders    = `ln_bidders_2026m3' in `newrow'
replace ln_warning    = `ln_warning_2026m3' in `newrow'
replace L1_min        = `L1_min_2026m3'   in `newrow'
replace L1_ln_min     = `L1_ln_min_2026m3' in `newrow'

* ── MA4 prediction for 2026m3 ────────────────────────────────────────────
capture drop pred_MA4_future
qui reg min_price supply bidders warning_price t i.month L1_min ///
    if train==1 & anomaly==0
predict pred_MA4_future if t==`t_2026m3'

qui sum pred_MA4_future if t==`t_2026m3'
local ma4_pred = r(mean)
di ""
di "MA4 predicted min_price for 2026m3 (t=195): " %10.2f (`ma4_pred') " yuan"

* ── MB4 prediction for 2026m3 (with Duan smearing) ──────────────────────
capture drop pred_MB4_log_future pred_MB4_future

qui reg ln_min_price ln_supply ln_bidders ln_warning t i.month L1_ln_min ///
    if train==1 & anomaly==0
local sigma2_MB4 = e(rmse)^2
di "MB4 sigma2 (for Duan smearing) = `sigma2_MB4'"

predict pred_MB4_log_future if t==`t_2026m3'

* Duan smearing: level prediction = exp(log_prediction + sigma2/2)
gen pred_MB4_future = exp(pred_MB4_log_future + `sigma2_MB4'/2) ///
    if t==`t_2026m3'

qui sum pred_MB4_future if t==`t_2026m3'
local mb4_pred = r(mean)
di "MB4 predicted min_price for 2026m3 (t=195): " %10.2f (`mb4_pred') " yuan"

* ── Summary ──────────────────────────────────────────────────────────────
di ""
di "=== FUTURE PREDICTION SUMMARY ==="
di "Period: 2026m3 (March 2026)"
di "  MA4 (level model) prediction: " %10.2f (`ma4_pred') " yuan"
di "  MB4 (log model, Duan-adjusted): " %10.2f (`mb4_pred') " yuan"
di "  Average of MA4 and MB4: " %10.2f ((`ma4_pred'+`mb4_pred')/2) " yuan"
di ""
di "  Reference: 2026m2 actual min_price = 94100 yuan"
local ma4_chg = `ma4_pred' - 94100
local mb4_chg = `mb4_pred' - 94100
local ma4_pct = (`ma4_pred' - 94100) / 94100 * 100
local mb4_pct = (`mb4_pred' - 94100) / 94100 * 100
di "  MA4 predicted change: " %8.1f (`ma4_chg') " yuan (" %6.2f (`ma4_pct') "%)"
di "  MB4 predicted change: " %8.1f (`mb4_chg') " yuan (" %6.2f (`mb4_pct') "%)"

* ── Append future predictions to model_selection.txt ─────────────────────
file open fsel using "results/model_selection.txt", write append
file write fsel _n
file write fsel "======================================================================" _n
file write fsel "FUTURE PREDICTION: March 2026 (2026m3)" _n
file write fsel "======================================================================" _n
file write fsel "Assumptions:" _n
file write fsel "  t = 195, month = 3, year = 2026" _n
file write fsel "  supply, bidders, warning_price: last known (2026m2, t=194)" _n
file write fsel "  L1_min = 94100 (actual 2026m2 min_price)" _n
file write fsel "  L1_ln_min = ln(94100)" _n _n
file write fsel "Model   | Predicted min_price (Yuan) | Method" _n
file write fsel "--------|---------------------------|--------" _n
file write fsel "MA4     | " %25.2f (`ma4_pred') " | level OLS" _n
file write fsel "MB4     | " %25.2f (`mb4_pred') " | log OLS + Duan smearing" _n
file write fsel "Average | " %25.2f ((`ma4_pred'+`mb4_pred')/2) " | ensemble" _n _n
file write fsel "Reference: 2026m2 actual min_price = 94100 yuan" _n
file write fsel "---" _n
file write fsel "_Generated by 05_model_selection.do_" _n
file close fsel

di ""
di "=== 05_model_selection.do completed ==="
di "Output written to: results/model_selection.txt"

log close sublog05
