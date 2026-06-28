/*===========================================================================
  06_weighted_models.do
  Weighted Least Squares Models - Time-Weighted Regression
  Compares WLS (analytic weight = t) vs OLS for 4 key models (MA4/MB4/MC4/MD4)
===========================================================================*/

clear all
set more off
capture log close sublog06
cd "/home/aragorn/Working/chepai_data"
use "data/cleaned_data.dta", clear
capture mkdir "results"
capture mkdir "log"
log using "log/06_weighted_models.log", name(sublog06) replace text

* Install outreg2 if needed
capture which outreg2
if _rc != 0 {
    ssc install outreg2, replace
}

di _n "=== 06_weighted_models.do: WLS vs OLS comparison ==="
di "Weighting scheme: analytic weight = t (linear time weight, newer obs get higher weight)"
di "Models: MA4, WA4, MB4, WB4, MC4, WC4, MD4, WD4"

*===========================================================================
* GROUP A: Minimum Price (Level) - MA4 Unweighted vs WA4 Weighted
*===========================================================================

* MA4 Unweighted (benchmark)
reg min_price supply bidders warning_price t i.month L1_min if train==1 & anomaly==0
outreg2 using "results/reg_weighted_comparison.txt", replace ctitle(MA4-Unweighted) ///
    title("Weighted vs Unweighted OLS: Key Models (MA4/MB4/MC4/MD4)") ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N)) ///
    label dec(4)
est store ma4_u
local ma4_u_r2  = e(r2)
local ma4_u_r2a = e(r2_a)
local ma4_u_n   = e(N)
estat ic
matrix ic = r(S)
local ma4_u_aic = ic[1,5]
local ma4_u_bic = ic[1,6]

* WA4 Weighted (analytic weight = t)
reg min_price supply bidders warning_price t i.month L1_min [aw=t] if train==1 & anomaly==0
outreg2 using "results/reg_weighted_comparison.txt", append ctitle(WA4-Weighted) ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N)) ///
    label dec(4)
est store ma4_w
local ma4_w_r2  = e(r2)
local ma4_w_r2a = e(r2_a)
local ma4_w_n   = e(N)
estat ic
matrix ic = r(S)
local ma4_w_aic = ic[1,5]
local ma4_w_bic = ic[1,6]

di "=== Group A (min_price level) complete ==="

*===========================================================================
* GROUP B: Log Minimum Price - MB4 Unweighted vs WB4 Weighted
*===========================================================================

* MB4 Unweighted (benchmark)
reg ln_min_price ln_supply ln_bidders ln_warning t i.month L1_ln_min if train==1 & anomaly==0
outreg2 using "results/reg_weighted_comparison.txt", append ctitle(MB4-Unweighted) ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N)) ///
    label dec(4)
est store mb4_u
local mb4_u_r2  = e(r2)
local mb4_u_r2a = e(r2_a)
local mb4_u_n   = e(N)
estat ic
matrix ic = r(S)
local mb4_u_aic = ic[1,5]
local mb4_u_bic = ic[1,6]

* WB4 Weighted (analytic weight = t)
reg ln_min_price ln_supply ln_bidders ln_warning t i.month L1_ln_min [aw=t] if train==1 & anomaly==0
outreg2 using "results/reg_weighted_comparison.txt", append ctitle(WB4-Weighted) ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N)) ///
    label dec(4)
est store mb4_w
local mb4_w_r2  = e(r2)
local mb4_w_r2a = e(r2_a)
local mb4_w_n   = e(N)
estat ic
matrix ic = r(S)
local mb4_w_aic = ic[1,5]
local mb4_w_bic = ic[1,6]

di "=== Group B (ln_min_price log) complete ==="

*===========================================================================
* GROUP C: Average Price (Level) - MC4 Unweighted vs WC4 Weighted
*===========================================================================

* MC4 Unweighted (benchmark)
reg avg_price supply bidders warning_price t i.month L1_avg if train==1 & anomaly==0
outreg2 using "results/reg_weighted_comparison.txt", append ctitle(MC4-Unweighted) ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N)) ///
    label dec(4)
est store mc4_u
local mc4_u_r2  = e(r2)
local mc4_u_r2a = e(r2_a)
local mc4_u_n   = e(N)
estat ic
matrix ic = r(S)
local mc4_u_aic = ic[1,5]
local mc4_u_bic = ic[1,6]

* WC4 Weighted (analytic weight = t)
reg avg_price supply bidders warning_price t i.month L1_avg [aw=t] if train==1 & anomaly==0
outreg2 using "results/reg_weighted_comparison.txt", append ctitle(WC4-Weighted) ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N)) ///
    label dec(4)
est store mc4_w
local mc4_w_r2  = e(r2)
local mc4_w_r2a = e(r2_a)
local mc4_w_n   = e(N)
estat ic
matrix ic = r(S)
local mc4_w_aic = ic[1,5]
local mc4_w_bic = ic[1,6]

di "=== Group C (avg_price level) complete ==="

*===========================================================================
* GROUP D: Log Average Price - MD4 Unweighted vs WD4 Weighted
*===========================================================================

* MD4 Unweighted (benchmark)
reg ln_avg_price ln_supply ln_bidders ln_warning t i.month L1_ln_avg if train==1 & anomaly==0
outreg2 using "results/reg_weighted_comparison.txt", append ctitle(MD4-Unweighted) ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N)) ///
    label dec(4)
est store md4_u
local md4_u_r2  = e(r2)
local md4_u_r2a = e(r2_a)
local md4_u_n   = e(N)
estat ic
matrix ic = r(S)
local md4_u_aic = ic[1,5]
local md4_u_bic = ic[1,6]

* WD4 Weighted (analytic weight = t)
reg ln_avg_price ln_supply ln_bidders ln_warning t i.month L1_ln_avg [aw=t] if train==1 & anomaly==0
outreg2 using "results/reg_weighted_comparison.txt", append ctitle(WD4-Weighted) ///
    addstat("R-squared", e(r2), "Adj R-sq", e(r2_a), "N", e(N)) ///
    label dec(4)
est store md4_w
local md4_w_r2  = e(r2)
local md4_w_r2a = e(r2_a)
local md4_w_n   = e(N)
estat ic
matrix ic = r(S)
local md4_w_aic = ic[1,5]
local md4_w_bic = ic[1,6]

di "=== Group D (ln_avg_price log) complete ==="

*===========================================================================
* COEFFICIENT COMPARISON TABLE (console summary)
*===========================================================================
di _n "=== COEFFICIENT COMPARISON: Unweighted vs Weighted ==="
est table ma4_u ma4_w mb4_u mb4_w mc4_u mc4_w md4_u md4_w, ///
    stat(N r2 r2_a) b(%9.4f) star

*===========================================================================
* FIT COMPARISON - Write to results/weighted_fit_comparison.txt
*===========================================================================

* Write fit comparison table using a post-file approach
tempname fh
file open `fh' using "results/weighted_fit_comparison.txt", write replace

file write `fh' "=========================================================================" _n
file write `fh' "  WEIGHTED vs UNWEIGHTED OLS: Fit Statistics Comparison" _n
file write `fh' "  Weighting: analytic weight = t (1..194), newer obs get higher weight" _n
file write `fh' "  Sample: train==1 & anomaly==0 (training set, excl. 2010m12 anomaly)" _n
file write `fh' "=========================================================================" _n
file write `fh' _n
file write `fh' "Model           | N   |   R2     | Adj-R2   |   AIC     |   BIC    " _n
file write `fh' "----------------|-----|----------|----------|-----------|----------" _n

* Format and write each row
local fmt "%8.4f"

* MA4 Unweighted
local line = "MA4-Unweighted  | " + string(`ma4_u_n', "%3.0f") + " | " ///
    + string(`ma4_u_r2', "`fmt'") + " | " ///
    + string(`ma4_u_r2a', "`fmt'") + " | " ///
    + string(`ma4_u_aic', "%9.2f") + " | " ///
    + string(`ma4_u_bic', "%9.2f")
file write `fh' "`line'" _n

* WA4 Weighted
local line = "WA4-Weighted    | " + string(`ma4_w_n', "%3.0f") + " | " ///
    + string(`ma4_w_r2', "`fmt'") + " | " ///
    + string(`ma4_w_r2a', "`fmt'") + " | " ///
    + string(`ma4_w_aic', "%9.2f") + " | " ///
    + string(`ma4_w_bic', "%9.2f")
file write `fh' "`line'" _n

file write `fh' "----------------|-----|----------|----------|-----------|----------" _n

* MB4 Unweighted
local line = "MB4-Unweighted  | " + string(`mb4_u_n', "%3.0f") + " | " ///
    + string(`mb4_u_r2', "`fmt'") + " | " ///
    + string(`mb4_u_r2a', "`fmt'") + " | " ///
    + string(`mb4_u_aic', "%9.2f") + " | " ///
    + string(`mb4_u_bic', "%9.2f")
file write `fh' "`line'" _n

* WB4 Weighted
local line = "WB4-Weighted    | " + string(`mb4_w_n', "%3.0f") + " | " ///
    + string(`mb4_w_r2', "`fmt'") + " | " ///
    + string(`mb4_w_r2a', "`fmt'") + " | " ///
    + string(`mb4_w_aic', "%9.2f") + " | " ///
    + string(`mb4_w_bic', "%9.2f")
file write `fh' "`line'" _n

file write `fh' "----------------|-----|----------|----------|-----------|----------" _n

* MC4 Unweighted
local line = "MC4-Unweighted  | " + string(`mc4_u_n', "%3.0f") + " | " ///
    + string(`mc4_u_r2', "`fmt'") + " | " ///
    + string(`mc4_u_r2a', "`fmt'") + " | " ///
    + string(`mc4_u_aic', "%9.2f") + " | " ///
    + string(`mc4_u_bic', "%9.2f")
file write `fh' "`line'" _n

* WC4 Weighted
local line = "WC4-Weighted    | " + string(`mc4_w_n', "%3.0f") + " | " ///
    + string(`mc4_w_r2', "`fmt'") + " | " ///
    + string(`mc4_w_r2a', "`fmt'") + " | " ///
    + string(`mc4_w_aic', "%9.2f") + " | " ///
    + string(`mc4_w_bic', "%9.2f")
file write `fh' "`line'" _n

file write `fh' "----------------|-----|----------|----------|-----------|----------" _n

* MD4 Unweighted
local line = "MD4-Unweighted  | " + string(`md4_u_n', "%3.0f") + " | " ///
    + string(`md4_u_r2', "`fmt'") + " | " ///
    + string(`md4_u_r2a', "`fmt'") + " | " ///
    + string(`md4_u_aic', "%9.2f") + " | " ///
    + string(`md4_u_bic', "%9.2f")
file write `fh' "`line'" _n

* WD4 Weighted
local line = "WD4-Weighted    | " + string(`md4_w_n', "%3.0f") + " | " ///
    + string(`md4_w_r2', "`fmt'") + " | " ///
    + string(`md4_w_r2a', "`fmt'") + " | " ///
    + string(`md4_w_aic', "%9.2f") + " | " ///
    + string(`md4_w_bic', "%9.2f")
file write `fh' "`line'" _n

file write `fh' "=========================================================================" _n
file write `fh' _n
file write `fh' "Notes:" _n
file write `fh' "  - Analytic weights [aw=t] scale the objective function so recent obs count more" _n
file write `fh' "  - R2/Adj-R2 for WLS: computed on weighted residuals (comparable within model)" _n
file write `fh' "  - AIC/BIC: Stata's 'estat ic' after regression" _n
file write `fh' "  - A-models: dep=min_price, regressors: supply bidders warning_price t month L1_min" _n
file write `fh' "  - B-models: dep=ln_min_price, regressors: ln_supply ln_bidders ln_warning t month L1_ln_min" _n
file write `fh' "  - C-models: dep=avg_price, regressors: supply bidders warning_price t month L1_avg" _n
file write `fh' "  - D-models: dep=ln_avg_price, regressors: ln_supply ln_bidders ln_warning t month L1_ln_avg" _n

file close `fh'

di _n "=== Fit comparison written to results/weighted_fit_comparison.txt ==="
di "=== Regression table written to results/reg_weighted_comparison.txt ==="
di "=== 06_weighted_models.do completed successfully ==="

log close sublog06
