/*===========================================================================
  07_weighted_prediction.do
  Out-of-Sample Prediction: Time-Weighted WLS vs Unweighted OLS
  Models: WA4, WB4, WC4, WD4 (weighted, [aw=t])
  Compared against: MA4, MB4, MC4, MD4 (unweighted OLS benchmarks)
===========================================================================*/

clear all
set more off
capture log close sublog07
cd "/home/aragorn/Working/chepai_data"
use "data/cleaned_data.dta", clear
capture mkdir "results"
capture mkdir "log"
log using "log/07_weighted_prediction.log", name(sublog07) replace text

di "=== 07_weighted_prediction.do: WLS vs OLS out-of-sample prediction ==="
di "=== Weighting: analytic weight = t (linear time weight) ==="

* ── display test set ────────────────────────────────────────────────────────
di "=== Test set observations ==="
list year month min_price avg_price warning_price supply bidders if test==1

* Collect test period t values
qui levelsof t if test==1, local(test_ts)
di "Test t values: `test_ts'"

*===========================================================================
* SECTION 1 – Weighted WLS Models (analytic weight = t)
*===========================================================================

*---------------------------------------------------------------------------
* WA4: Level min_price  [aw=t]
*---------------------------------------------------------------------------
capture drop p0 e0

qui reg min_price supply bidders warning_price t i.month L1_min [aw=t] if train==1 & anomaly==0
qui predict p0
qui gen e0 = min_price - p0

scalar mae_WA4  = 0
scalar sse_WA4  = 0
scalar mape_WA4 = 0
scalar cnt_WA4  = 0

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    local p = r(mean)
    qui sum min_price if t==`tv'
    local a = r(mean)
    local e = `a' - `p'
    local ae = abs(`e')
    local pe = abs(`e'/`a')*100
    scalar mae_WA4  = mae_WA4  + `ae'
    scalar sse_WA4  = sse_WA4  + (`e')^2
    scalar mape_WA4 = mape_WA4 + `pe'
    scalar cnt_WA4  = cnt_WA4  + 1
}
scalar mae_WA4  = mae_WA4  / cnt_WA4
scalar rmse_WA4 = sqrt(sse_WA4 / cnt_WA4)
scalar mape_WA4 = mape_WA4 / cnt_WA4
di "WA4: MAE=" mae_WA4 "  RMSE=" rmse_WA4 "  MAPE=" mape_WA4

* Save per-period predictions
foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    scalar pred_WA4_`tv' = r(mean)
    qui sum min_price if t==`tv'
    scalar act_min_`tv' = r(mean)
    qui sum year if t==`tv'
    scalar yr_`tv' = r(mean)
    qui sum month if t==`tv'
    scalar mo_`tv' = r(mean)
}

drop p0 e0

*---------------------------------------------------------------------------
* WB4: Log min_price  [aw=t] — Duan smearing adjustment
*---------------------------------------------------------------------------
capture drop plog p0 e0

qui reg ln_min_price ln_supply ln_bidders ln_warning t i.month L1_ln_min [aw=t] if train==1 & anomaly==0
local sigma2_WB4 = e(rmse)^2
qui predict plog
qui gen p0 = exp(plog + `sigma2_WB4'/2)
qui gen e0 = min_price - p0

scalar mae_WB4  = 0
scalar sse_WB4  = 0
scalar mape_WB4 = 0
scalar cnt_WB4  = 0

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    local p = r(mean)
    qui sum min_price if t==`tv'
    local a = r(mean)
    local e = `a' - `p'
    local ae = abs(`e')
    local pe = abs(`e'/`a')*100
    scalar mae_WB4  = mae_WB4  + `ae'
    scalar sse_WB4  = sse_WB4  + (`e')^2
    scalar mape_WB4 = mape_WB4 + `pe'
    scalar cnt_WB4  = cnt_WB4  + 1
}
scalar mae_WB4  = mae_WB4  / cnt_WB4
scalar rmse_WB4 = sqrt(sse_WB4 / cnt_WB4)
scalar mape_WB4 = mape_WB4 / cnt_WB4
di "WB4: MAE=" mae_WB4 "  RMSE=" rmse_WB4 "  MAPE=" mape_WB4

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    scalar pred_WB4_`tv' = r(mean)
}

drop plog p0 e0

*---------------------------------------------------------------------------
* WC4: Level avg_price  [aw=t]
*---------------------------------------------------------------------------
capture drop p0 e0

qui reg avg_price supply bidders warning_price t i.month L1_avg [aw=t] if train==1 & anomaly==0
qui predict p0
qui gen e0 = avg_price - p0

scalar mae_WC4  = 0
scalar sse_WC4  = 0
scalar mape_WC4 = 0
scalar cnt_WC4  = 0

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    local p = r(mean)
    qui sum avg_price if t==`tv'
    local a = r(mean)
    local e = `a' - `p'
    local ae = abs(`e')
    local pe = abs(`e'/`a')*100
    scalar mae_WC4  = mae_WC4  + `ae'
    scalar sse_WC4  = sse_WC4  + (`e')^2
    scalar mape_WC4 = mape_WC4 + `pe'
    scalar cnt_WC4  = cnt_WC4  + 1
}
scalar mae_WC4  = mae_WC4  / cnt_WC4
scalar rmse_WC4 = sqrt(sse_WC4 / cnt_WC4)
scalar mape_WC4 = mape_WC4 / cnt_WC4
di "WC4: MAE=" mae_WC4 "  RMSE=" rmse_WC4 "  MAPE=" mape_WC4

* Save per-period predictions
foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    scalar pred_WC4_`tv' = r(mean)
    qui sum avg_price if t==`tv'
    scalar act_avg_`tv' = r(mean)
}

drop p0 e0

*---------------------------------------------------------------------------
* WD4: Log avg_price  [aw=t] — Duan smearing adjustment
*---------------------------------------------------------------------------
capture drop plog p0 e0

qui reg ln_avg_price ln_supply ln_bidders ln_warning t i.month L1_ln_avg [aw=t] if train==1 & anomaly==0
local sigma2_WD4 = e(rmse)^2
qui predict plog
qui gen p0 = exp(plog + `sigma2_WD4'/2)
qui gen e0 = avg_price - p0

scalar mae_WD4  = 0
scalar sse_WD4  = 0
scalar mape_WD4 = 0
scalar cnt_WD4  = 0

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    local p = r(mean)
    qui sum avg_price if t==`tv'
    local a = r(mean)
    local e = `a' - `p'
    local ae = abs(`e')
    local pe = abs(`e'/`a')*100
    scalar mae_WD4  = mae_WD4  + `ae'
    scalar sse_WD4  = sse_WD4  + (`e')^2
    scalar mape_WD4 = mape_WD4 + `pe'
    scalar cnt_WD4  = cnt_WD4  + 1
}
scalar mae_WD4  = mae_WD4  / cnt_WD4
scalar rmse_WD4 = sqrt(sse_WD4 / cnt_WD4)
scalar mape_WD4 = mape_WD4 / cnt_WD4
di "WD4: MAE=" mae_WD4 "  RMSE=" rmse_WD4 "  MAPE=" mape_WD4

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    scalar pred_WD4_`tv' = r(mean)
}

drop plog p0 e0

*===========================================================================
* SECTION 2 – Unweighted OLS Benchmarks (re-run for per-period predictions)
*===========================================================================

*---------------------------------------------------------------------------
* MA4: Level min_price (unweighted OLS)
*---------------------------------------------------------------------------
capture drop p0 e0

qui reg min_price supply bidders warning_price t i.month L1_min if train==1 & anomaly==0
qui predict p0
qui gen e0 = min_price - p0

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    scalar pred_MA4_`tv' = r(mean)
}

drop p0 e0

*---------------------------------------------------------------------------
* MB4: Log min_price (unweighted OLS) — Duan smearing
*---------------------------------------------------------------------------
capture drop plog p0 e0

qui reg ln_min_price ln_supply ln_bidders ln_warning t i.month L1_ln_min if train==1 & anomaly==0
local sigma2_MB4 = e(rmse)^2
qui predict plog
qui gen p0 = exp(plog + `sigma2_MB4'/2)
qui gen e0 = min_price - p0

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    scalar pred_MB4_`tv' = r(mean)
}

drop plog p0 e0

*---------------------------------------------------------------------------
* MC4: Level avg_price (unweighted OLS)
*---------------------------------------------------------------------------
capture drop p0 e0

qui reg avg_price supply bidders warning_price t i.month L1_avg if train==1 & anomaly==0
qui predict p0
qui gen e0 = avg_price - p0

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    scalar pred_MC4_`tv' = r(mean)
}

drop p0 e0

*---------------------------------------------------------------------------
* MD4: Log avg_price (unweighted OLS) — Duan smearing
*---------------------------------------------------------------------------
capture drop plog p0 e0

qui reg ln_avg_price ln_supply ln_bidders ln_warning t i.month L1_ln_avg if train==1 & anomaly==0
local sigma2_MD4 = e(rmse)^2
qui predict plog
qui gen p0 = exp(plog + `sigma2_MD4'/2)
qui gen e0 = avg_price - p0

foreach tv of local test_ts {
    qui sum p0 if t==`tv'
    scalar pred_MD4_`tv' = r(mean)
}

drop plog p0 e0

*===========================================================================
* SECTION 3 – Summary to log
*===========================================================================

di _n "=== PREDICTION COMPARISON: WLS vs OLS ==="
di "Model | MAE       | RMSE      | MAPE(%)"
di "------|-----------|-----------|--------"
di "WA4   | " mae_WA4 " | " rmse_WA4 " | " mape_WA4
di "WB4   | " mae_WB4 " | " rmse_WB4 " | " mape_WB4
di "WC4   | " mae_WC4 " | " rmse_WC4 " | " mape_WC4
di "WD4   | " mae_WD4 " | " rmse_WD4 " | " mape_WD4
di _n "Hardcoded OLS benchmarks (from 04_prediction.do):"
di "MA4: MAE=638  RMSE=687  MAPE=0.68%"
di "MB4: MAE=641  RMSE=684  MAPE=0.68%"
di "MC4: MAE=683  RMSE=734  MAPE=0.73%"
di "MD4: MAE=683  RMSE=732  MAPE=0.73%"

*===========================================================================
* SECTION 4 – Write Markdown report
*===========================================================================

file open mout using "results/weighted_prediction_results.md", write replace

file write mout "# 加权模型样本外预测结果" _n _n
file write mout "## 测试集：2025年10月 — 2026年2月（N=5）" _n _n
file write mout "> 加权方式：分析权重 = t（线性时间权重，越近的观测权重越大）" _n
file write mout "> 对数模型使用Duan smearing调整：pred = exp(pred_log + σ²/2)" _n _n

*--- Section: Minimum Price comparison ---
file write mout "### 最低成交价预测对比" _n _n
file write mout "| 模型 | 类型 | 权重 | MAE（元）| RMSE（元）| MAPE（%）|" _n
file write mout "|------|------|------|---------|---------|---------|" _n
file write mout "| MA4 | 水平值 | 等权（OLS） | 638 | 687 | 0.68 |" _n
file write mout "| WA4 | 水平值 | 时间加权（WLS） | " ///
    %8.0f (mae_WA4) " | " %8.0f (rmse_WA4) " | " %5.2f (mape_WA4) " |" _n
file write mout "| MB4 | 对数 | 等权（OLS） | 641 | 684 | 0.68 |" _n
file write mout "| WB4 | 对数 | 时间加权（WLS） | " ///
    %8.0f (mae_WB4) " | " %8.0f (rmse_WB4) " | " %5.2f (mape_WB4) " |" _n
file write mout _n

*--- Section: Average Price comparison ---
file write mout "### 平均成交价预测对比" _n _n
file write mout "| 模型 | 类型 | 权重 | MAE（元）| RMSE（元）| MAPE（%）|" _n
file write mout "|------|------|------|---------|---------|---------|" _n
file write mout "| MC4 | 水平值 | 等权（OLS） | 683 | 734 | 0.73 |" _n
file write mout "| WC4 | 水平值 | 时间加权（WLS） | " ///
    %8.0f (mae_WC4) " | " %8.0f (rmse_WC4) " | " %5.2f (mape_WC4) " |" _n
file write mout "| MD4 | 对数 | 等权（OLS） | 683 | 732 | 0.73 |" _n
file write mout "| WD4 | 对数 | 时间加权（WLS） | " ///
    %8.0f (mae_WD4) " | " %8.0f (rmse_WD4) " | " %5.2f (mape_WD4) " |" _n
file write mout _n

*--- Section: Per-period detail — min_price ---
file write mout "### 逐期预测明细" _n _n
file write mout "#### 最低成交价" _n _n
file write mout "| 期间 | 实际值 | WA4预测 | WA4误差 | WB4预测 | WB4误差 | MA4预测 | MA4误差 | MB4预测 | MB4误差 |" _n
file write mout "|------|--------|---------|---------|---------|---------|---------|---------|---------|---------|" _n

foreach tv of local test_ts {
    local yr_v   = scalar(yr_`tv')
    local mo_v   = scalar(mo_`tv')
    local a_min  = scalar(act_min_`tv')
    local pWA4   = scalar(pred_WA4_`tv')
    local pWB4   = scalar(pred_WB4_`tv')
    local pMA4   = scalar(pred_MA4_`tv')
    local pMB4   = scalar(pred_MB4_`tv')
    local eWA4   = `a_min' - `pWA4'
    local eWB4   = `a_min' - `pWB4'
    local eMA4   = `a_min' - `pMA4'
    local eMB4   = `a_min' - `pMB4'
    file write mout "| " %4.0f (`yr_v') "m" %02.0f (`mo_v') " | " ///
        %8.0f (`a_min') " | " %8.1f (`pWA4') " | " %8.1f (`eWA4') " | " ///
        %8.1f (`pWB4') " | " %8.1f (`eWB4') " | " ///
        %8.1f (`pMA4') " | " %8.1f (`eMA4') " | " ///
        %8.1f (`pMB4') " | " %8.1f (`eMB4') " |" _n
}

file write mout _n

*--- Section: Per-period detail — avg_price ---
file write mout "#### 平均成交价" _n _n
file write mout "| 期间 | 实际值 | WC4预测 | WC4误差 | WD4预测 | WD4误差 | MC4预测 | MC4误差 | MD4预测 | MD4误差 |" _n
file write mout "|------|--------|---------|---------|---------|---------|---------|---------|---------|---------|" _n

foreach tv of local test_ts {
    local yr_v   = scalar(yr_`tv')
    local mo_v   = scalar(mo_`tv')
    local a_avg  = scalar(act_avg_`tv')
    local pWC4   = scalar(pred_WC4_`tv')
    local pWD4   = scalar(pred_WD4_`tv')
    local pMC4   = scalar(pred_MC4_`tv')
    local pMD4   = scalar(pred_MD4_`tv')
    local eWC4   = `a_avg' - `pWC4'
    local eWD4   = `a_avg' - `pWD4'
    local eMC4   = `a_avg' - `pMC4'
    local eMD4   = `a_avg' - `pMD4'
    file write mout "| " %4.0f (`yr_v') "m" %02.0f (`mo_v') " | " ///
        %8.0f (`a_avg') " | " %8.1f (`pWC4') " | " %8.1f (`eWC4') " | " ///
        %8.1f (`pWD4') " | " %8.1f (`eWD4') " | " ///
        %8.1f (`pMC4') " | " %8.1f (`eMC4') " | " ///
        %8.1f (`pMD4') " | " %8.1f (`eMD4') " |" _n
}

file write mout _n

*--- Section: Key findings (dynamic) ---
file write mout "### 关键发现" _n _n

* Min price: compare WA4/MA4 and WB4/MB4 by RMSE
local rmse_WA4_v = scalar(rmse_WA4)
local rmse_WB4_v = scalar(rmse_WB4)
local rmse_WC4_v = scalar(rmse_WC4)
local rmse_WD4_v = scalar(rmse_WD4)

* OLS benchmarks (from 04_prediction.do results)
local rmse_MA4_hc = 687
local rmse_MB4_hc = 684
local rmse_MC4_hc = 734
local rmse_MD4_hc = 732

* WA4 vs MA4
if `rmse_WA4_v' < `rmse_MA4_hc' {
    file write mout "- **WA4 优于 MA4**（最低价水平值）：WLS RMSE=" %8.0f (`rmse_WA4_v') " < OLS RMSE=687（时间加权改善预测）" _n
}
else {
    file write mout "- **WA4 未优于 MA4**（最低价水平值）：WLS RMSE=" %8.0f (`rmse_WA4_v') " ≥ OLS RMSE=687（时间加权未改善预测）" _n
}

* WB4 vs MB4
if `rmse_WB4_v' < `rmse_MB4_hc' {
    file write mout "- **WB4 优于 MB4**（最低价对数）：WLS RMSE=" %8.0f (`rmse_WB4_v') " < OLS RMSE=684（时间加权改善预测）" _n
}
else {
    file write mout "- **WB4 未优于 MB4**（最低价对数）：WLS RMSE=" %8.0f (`rmse_WB4_v') " ≥ OLS RMSE=684（时间加权未改善预测）" _n
}

* WC4 vs MC4
if `rmse_WC4_v' < `rmse_MC4_hc' {
    file write mout "- **WC4 优于 MC4**（平均价水平值）：WLS RMSE=" %8.0f (`rmse_WC4_v') " < OLS RMSE=734（时间加权改善预测）" _n
}
else {
    file write mout "- **WC4 未优于 MC4**（平均价水平值）：WLS RMSE=" %8.0f (`rmse_WC4_v') " ≥ OLS RMSE=734（时间加权未改善预测）" _n
}

* WD4 vs MD4
if `rmse_WD4_v' < `rmse_MD4_hc' {
    file write mout "- **WD4 优于 MD4**（平均价对数）：WLS RMSE=" %8.0f (`rmse_WD4_v') " < OLS RMSE=732（时间加权改善预测）" _n
}
else {
    file write mout "- **WD4 未优于 MD4**（平均价对数）：WLS RMSE=" %8.0f (`rmse_WD4_v') " ≥ OLS RMSE=732（时间加权未改善预测）" _n
}

file write mout _n
file write mout "---" _n
file write mout "_Generated by 07_weighted_prediction.do_" _n

file close mout

di "=== Markdown written to results/weighted_prediction_results.md ==="
di "=== 07_weighted_prediction.do completed ==="

log close sublog07
