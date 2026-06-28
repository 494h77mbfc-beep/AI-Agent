---
name: stata-did
description: "Comprehensive Difference-in-Differences (DID) analysis in Stata. Covers classical 2x2, staggered DID (csdid, csdid2, did_imputation, eventstudyinteract, sdid, sdid_event, did_multiplegt, did_multiplegt_dyn, did2s, jwdid, wooldid, lpdid, fect, fdid, stackedev, staggered_stata, hdidregress, drdid), event studies (eventdd, xtevent, event_plot), parallel trends, bacondecomp, honestdid, pretrends, twowayfeweights, yatchew_test, robustate, flexpaneldid, and multe."
---

# Stata Difference-in-Differences (DID) Skill

This skill provides comprehensive instructions and code examples for implementing modern Difference-in-Differences (DID) estimators in Stata.

## 0. Package Dependencies and Installation

Each estimator has dependencies beyond the base command. Install ALL of the following before running analyses:

### One-Time Installation Checklist

```stata
* Core infrastructure
ssc install reghdfe, replace
ssc install ftools, replace
ssc install avar, replace          // REQUIRED by eventstudyinteract (hidden dependency!)

* Staggered DID estimators
ssc install csdid, replace
ssc install drdid, replace         // csdid dependency
ssc install did_imputation, replace
ssc install eventstudyinteract, replace
ssc install wooldid, replace
ssc install jwdid, replace
ssc install sdid, replace
ssc install did_multiplegt, replace
ssc install did_multiplegt_dyn, replace
ssc install did2s, replace
ssc install lpdid, replace
ssc install stackedev, replace

* Diagnostics and visualization
ssc install bacondecomp, replace
ssc install event_plot, replace
ssc install coefplot, replace
ssc install honestdid, replace
ssc install pretrends, replace
ssc install twowayfeweights, replace
ssc install eventdd, replace
ssc install xtevent, replace
```

| Package | Hidden Dependencies | Install Command |
|---------|-------------------|-----------------|
| `eventstudyinteract` | **`avar`** (NOT auto-installed) | `ssc install avar, replace` |
| `csdid` | `drdid` | `ssc install drdid, replace` |
| `did_imputation` | none beyond base | `ssc install did_imputation, replace` |
| `wooldid` | none but needs `set maxvar` (see §0.1) | `ssc install wooldid, replace` |

### 0.1 `maxvar` and Capacity Constraints

Certain estimators create many internal interaction terms that exceed Stata's default `maxvar=5000`. **`set maxvar` must be called BEFORE loading any data** (Stata requires no unsaved changes in memory).

| Estimator | Typical Requirement | Notes |
|-----------|-------------------|-------|
| `wooldid` | `set maxvar 20000` to `50000` | For N>10K with staggered treatment. Also set `set emptycells drop` and `set matsize 11000`. Single estimation may take >10 minutes for 30K+ obs. |
| `eventstudyinteract` | Default 5000 usually sufficient | Only with very many cohort×time bins |
| `csdid` | Default 5000 usually sufficient | — |
| `did_imputation` | Default 5000 usually sufficient | — |

**Correct pattern for wooldid with large datasets:**

```stata
* Step 1: Set maxvar BEFORE loading data
set maxvar 50000
set emptycells drop
set matsize 11000

* Step 2: Load data
use "mydata.dta", clear
xtset id year
```

### 0.2 Data Encoding Compatibility

Different estimators expect different encodings for never-treated units:

| Estimator | Never-Treated Encoding | Treated Encoding |
|-----------|----------------------|-----------------|
| `csdid` | `first_treat = 0` | `first_treat = treatment_year` |
| `did_imputation` | `first_treat = 0` or `.` | `first_treat = treatment_year` |
| `eventstudyinteract` | `first_treat = .` (missing) | `first_treat = treatment_year`; need `never_treated` dummy: `gen never_treated = missing(first_treat)` |
| `wooldid` | **`first_treat = .` (missing)** | `first_treat = treatment_year` |
| `jwdid` | `first_treat = 0` | `first_treat = treatment_year` |

**Recommendation**: Create BOTH encodings and use the appropriate one per estimator:

```stata
gen first_treat_year = first_treat  // 0 for never-treated (csdid, did_imputation, jwdid)
gen first_treat_miss = first_treat  // . for never-treated (eventstudyinteract, wooldid)
replace first_treat_miss = . if first_treat == 0
gen never_treated = missing(first_treat_miss)  // for eventstudyinteract
```

## 1. Data Preparation and Setup

Before running DID models, ensure your data is set up correctly as a panel.

### 1.0 Clustering Level: Critical Principle

**Always cluster standard errors at the level of treatment assignment, NOT at the observation level.**

| Treatment Assignment Level | Cluster By | Example |
|---------------------------|------------|---------|
| City/County policy | City/County ID | "Broadband China" pilot cities → `vce(cluster citycode)` |
| State/Province law | State/Province ID | US state-level minimum wage → `vce(cluster statefips)` |
| Firm-level adoption | Firm ID (only if treatment IS at firm level) | Firm voluntary program → `vce(cluster firmid)` |

**Why**: Treatment is assigned at a higher level than individual observations. Errors are correlated within the treatment unit. Clustering at the observation (e.g., firm) level when treatment is at city level produces artificially small standard errors and inflated significance.

**Implementation**:
```stata
* WRONG: firm-level clustering when treatment is at city level
reghdfe y did controls, absorb(firm year) vce(cluster firmid)

* CORRECT: cluster at treatment-assignment level
reghdfe y did controls, absorb(firm year) vce(cluster citycode)
```

### 1.1 Setting up Treatment Variables
For staggered DID, you need a variable indicating the time when a unit was first treated.

```stata
* Setup panel
xtset id year

* Create treatment timing variable (first_treat)
* If treat is 1 for all periods after treatment:
bysort id: egen first_treat = min(cond(treat == 1, year, .))

* For units never treated, first_treat should be 0 or . depending on the command
gen never_treated = missing(first_treat)
```

## 2. Classical 2x2 DID

Use `reghdfe` for high-dimensional fixed effects and clustered standard errors.

```stata
* Basic 2x2 DID
reghdfe y i.treat##i.post, absorb(id year) vce(cluster id)

* Fixed effects version (equivalent)
gen treat_post = treat * post
reghdfe y treat_post, absorb(id year) vce(cluster id)
```

## 3. Staggered DID Estimators

Standard TWFE can be biased with staggered treatment and heterogeneous effects. Use these modern estimators.

### 3.1 Callaway and Sant'Anna (2020) - `csdid` / `csdid2`
Best for general staggered DID with various control group options. `csdid2` is an updated version with improved syntax.

```stata
* Install csdid
ssc install csdid, replace
ssc install drdid, replace    // dependency

* Basic usage (note: time() not tvar(); cluster at treatment-assignment level)
csdid y controls, ivar(id) time(year) gvar(first_treat) method(dripw) vce(cluster cluster_id)

* Post-estimation: Event Study
estat event

* Post-estimation: Group-time ATT
estat group

* csdid2 (updated version) - install from GitHub
* net install csdid2, from("https://raw.githubusercontent.com/friosavila/stpackages/main/csdid2/")
```

### 3.2 Borusyak, Jaravel, and Spiess (2024) - `did_imputation`
Efficient imputation-based estimator.

```stata
* Install
ssc install did_imputation, replace

* Basic usage
did_imputation y id year first_treat, autosample horizon(0/5) pretrend(5)

* NOTE: did_imputation does NOT accept controls() or vce(); use bare cluster()
* It internally uses untreated observations as controls (imputation-based)
did_imputation y id year first_treat, autosample horizon(0/5) pretrend(5) ///
    cluster(cluster_id)
```

### 3.3 Sun and Abraham (2021) - `eventstudyinteract`
Interaction-weighted estimator for event studies.

```stata
* Install (CRITICAL: avar is a HIDDEN dependency)
ssc install avar, replace
ssc install eventstudyinteract, replace

* Step 1: Generate relative time dummies (ALL periods, including -1)
gen rel_time = year - first_treat
replace rel_time = -5 if rel_time <= -5 & !missing(rel_time)
replace rel_time = 5  if rel_time >= 5  & !missing(rel_time)

forvalues t = -5/5 {
    if `t' < 0 {
        local tn = abs(`t')
        gen D_m`tn' = (rel_time == `t' & !missing(rel_time))
    }
    else {
        gen D_`t' = (rel_time == `t' & !missing(rel_time))
    }
}

* Step 2: Estimate (period -1 is NOT automatically omitted as reference)
* First-treat must be . for never-treated; need never_treated dummy
replace first_treat = . if first_treat == 0
gen never_treated = missing(first_treat)
eventstudyinteract y D_*, cohort(first_treat) control_cohort(never_treated) ///
    absorb(id year) vce(cluster cluster_id)

* Step 3: IW estimator gives coefficients for ALL periods including -1.
* If plotting with other estimators, normalize to period -1 by subtracting
* the period -1 coefficient from all periods. See §4.4 for details.
```

### 3.4 Arkhangelsky et al. (2021) - `sdid` / `sdid_event`
Synthetic Difference-in-Differences. `sdid_event` extends SDID for event studies.

```stata
* Install sdid
ssc install sdid, replace

* Basic SDID
sdid y id year treat, vce(bootstrap) seed(123) graph

* SDID event study (install from GitHub)
* net install sdid_event, from("https://raw.githubusercontent.com/DiegoCiccia/sdid/main/sdid_event/")
```

### 3.5 de Chaisemartin and D'Haultfœuille (2020, 2024) - `did_multiplegt` / `did_multiplegt_dyn`
Handles heterogeneous effects and switching treatments. `did_multiplegt_dyn` is the dynamic version.

```stata
* Install
ssc install did_multiplegt, replace
ssc install did_multiplegt_dyn, replace

* did_multiplegt (older version)
did_multiplegt y id year treat, robust_dynamic dynamic(5) placebo(3)

* did_multiplegt_dyn (recommended)
did_multiplegt_dyn y id year treat, effects(5) placebo(3)
```

### 3.6 Gardner (2022) - `did2s`
Two-stage DID estimator.

```stata
* Install
ssc install did2s, replace

* Basic usage
did2s y, first_stage(id year) second_stage(treat) treatment(treat) cluster(id)
```

### 3.7 Rios-Avila, Sant'Anna, Yotov (2024) - `jwdid`
Wooldridge-style DID estimator (extension of Wooldridge 2021).

```stata
* Install
ssc install jwdid, replace

* Basic usage
jwdid y, ivar(id) tvar(year) gvar(first_treat)

* Post-estimation for event study
estat event
```

### 3.8 Wooldridge (2021) - `wooldid`
Wooldridge's approach to DID with multiple time periods.

```stata
* Install
ssc install wooldid, replace

* NOTE: wooldid does NOT accept covariates(). For large datasets, set maxvar BEFORE
* loading data (see §0.1). Never-treated must have first_treat = . (missing) not 0.
* Basic usage (no controls):
wooldid y id year first_treat
* With controls: include them directly as additional covariates in the model
* (wooldid constructs cohort-specific polynomials automatically)
```

### 3.9 Dube, Girardi, Jordà, Taylor (2023) - `lpdid`
Local Projections DID.

```stata
* Install
ssc install lpdid, replace

* Basic usage
lpdid y, ivar(id) tvar(year) gvar(first_treat) horizon(5)
```

### 3.10 Liu, Wang, Xu (2022) - `fect`
Fixed Effects Counterfactual estimator.

```stata
* Install from GitHub
* net install fect, from("https://raw.githubusercontent.com/xuyiqing/fect_stata/main/")

* Basic usage
fect y id year treat, method("ife") cv("ok")
```

### 3.11 Greathouse - `fdid`
Forward Difference-in-Differences.

```stata
* Install from GitHub
* net install fdid, from("https://raw.githubusercontent.com/jgreathouse9/FDIDTutorial/main/")

* See GitHub repository for usage examples
```

### 3.12 Bleiberg - `stackedev`
Stacked Event Study.

```stata
* Install
ssc install stackedev, replace

* Basic usage
stackedev y, cohort(first_treat) time(year) unit(id) never_treat(never_treated)
```

### 3.13 Roth and Sant'Anna (2023) - `staggered_stata`
Efficient estimator for staggered DID.

```stata
* Install from GitHub
* net install staggered, from("https://raw.githubusercontent.com/jonathandroth/staggered/main/stata/")

* Basic usage
staggered y, i(id) t(year) g(first_treat) estimand("simple")
```

### 3.14 Stata 18 built-in - `hdidregress`
Heterogeneous DID regression (Stata 18+ only).

```stata
* No installation needed (Stata 18)
hdidregress ra y controls, group(id) time(year) treatment(treat)

* With IPW
hdidregress ipw y controls, group(id) time(year) treatment(treat)

* With AIPW
hdidregress aipw y controls, group(id) time(year) treatment(treat)
```

### 3.15 Sant'Anna and Zhao (2020) - `drdid`
Doubly Robust DID.

```stata
* Install
ssc install drdid, replace

* Basic usage (requires did_multiplegt or did setup)
drdid y, ivar(id) time(year) treatment(treat) drtype(dripw)
```

### 3.16 Multi-Estimator Robustness Plot

When implementing staggered DID, it is **standard practice** to compare results across multiple estimators on a single plot to assess stability. This was prominently demonstrated in Braghieri, Levy, and Makarin (2022, AER), where Figure 2 compared five different staggered DID estimators.

**Workflow**: Run each estimator → Extract coefficients and variance-covariance matrices → Plot together using `event_plot` with the `together` option.

**Step 1: Run TWFE OLS (Baseline)**
```stata
* Create relative time dummies (omit -1 as reference)
gen rel_time = year - first_treat
reghdfe y ib(-1).rel_time controls, absorb(id year) vce(cluster id)

* Store coefficients and variances in matrices
matrix define mat1_ols = e(b)
matrix define mat2_ols = e(V)
```

**Step 2: Run Borusyak et al. (2021) Imputation Estimator**
```stata
* NOTE: did_imputation uses cluster(id) not vce(cluster id)
* NOTE: does NOT accept controls(); estimates against untreated obs internally
did_imputation y id year first_treat, autosample horizon(0/5) pretrend(5) cluster(id)

* IMPORTANT: did_imputation gives coefficients for ALL periods including pre1 (t=-1).
* For comparability with TWFE (which omits -1), normalize:
*   b_normalized[t] = b[t] - _b[pre1]
* See §4.6 for complete normalization code.
matrix define mat1_bor = e(b)
matrix define mat2_bor = e(V)
```

**Step 3: Run Callaway and Sant'Anna (2021)**
```stata
csdid y, time(year) gvar(first_treat) agg(event) method(dripw) vce(cluster id)
estat all
matrix define mat1_cs = e(b)
matrix define mat2_cs = e(V)
```

**Step 4: Run de Chaisemartin and D'Haultfœuille (2020)**
```stata
did_multiplegt y id year treat, robust_dynamic dynamic(5) placebo(3) cluster(id)

* Extract estimates and variances from returned matrices
matrix define mat1_dcdh = e(estimates)'
matrix define mat2_dcdh = e(variances)'
```

**Step 5: Run Sun and Abraham (2021)**
```stata
* CRITICAL: install hidden dependency avar first
* ssc install avar, replace

* Generate cohort-time dummies (ALL periods including -1 needed for normalization)
gen time_to_treat = year - first_treat
replace time_to_treat = -5 if time_to_treat <= -5
replace time_to_treat = 5  if time_to_treat >= 5

forvalues t = -5/5 {
    if `t' < 0 {
        local tname = abs(`t')
        gen g_m`tname' = time_to_treat == `t'
    }
    else if `t' >= 0 {
        gen g_`t' = time_to_treat == `t'
    }
}

* Need never_treated dummy; first_treat must be . (missing) for never-treated
replace first_treat = . if first_treat == 0
gen never_treated = missing(first_treat)

eventstudyinteract y g_*, cohort(first_treat) control_cohort(never_treat) ///
    absorb(id year) vce(cluster id)

* IMPORTANT: IW estimator returns coefficients for ALL periods including period -1.
* For comparability, normalize by subtracting period -1 coefficient:
*   b_normalized[t] = e(b_iw)[period_t] - e(b_iw)[period_m1]
* See §4.6 for complete normalization code.

* Extract coefficients
matrix define mat1_sa = e(b_iw)
matrix define mat2_sa = e(V_iw)
```

**Step 6: Combine All Estimators in One Figure**
```stata
event_plot mat1_bor#mat2_bor mat1_dcdh#mat2_dcdh mat1_cs#mat2_cs mat1_sa#mat2_sa mat1_ols#mat2_ols, ///
    stub_lag(T+# T+# T+# g_# T+#) ///
    stub_lead(T-# T-# T-# g_m# T-#) ///
    plottype(scatter) ciplottype(rcap) ///
    together trimlag(5) noautolegend ///
    graph_opt( ///
        title("Event Study: Multiple Estimators", size(medlarge)) ///
        xtitle("Periods since treatment") ///
        ytitle("Average effect") ///
        xline(-0.5, lcolor(gs8) lpattern(dash)) ///
        yline(0, lcolor(gs8)) ///
        graphregion(color(white)) bgcolor(white) ///
        legend(order(1 "Borusyak et al." 3 "D'Haultfœuille" 5 "Callaway-Sant'Anna" ///
                     7 "Sun-Abraham" 9 "TWFE OLS") rows(2) region(style(none))) ///
    ) ///
    lag_opt1(msymbol(O) color(dkorange)) lag_ci_opt1(color(dkorange)) ///
    lag_opt2(msymbol(+) color(cranberry)) lag_ci_opt2(color(cranberry)) ///
    lag_opt3(msymbol(Dh) color(navy)) lag_ci_opt3(color(navy)) ///
    lag_opt4(msymbol(Th) color(forest_green)) lag_ci_opt4(color(forest_green)) ///
    lag_opt5(msymbol(Sh) color(black)) lag_ci_opt5(color(black)) ///
    perturb(-0.2(0.1)0.2)  // Slightly offset points to avoid overlap
```

**Key Options Explained**:

| Option | Description |
|--------|-------------|
| `together` | Plot all estimators on the same axes |
| `trimlag(#)` | Limit displayed lags to # periods |
| `stub_lag()` / `stub_lead()` | Name patterns for lag/lead coefficients. Must match the order of estimators provided |
| `lag_opt#()` / `lag_ci_opt#()` | Customize symbol and color for estimator # |
| `perturb()` | Horizontally offset points to prevent overlapping |
| `noautolegend` | Use custom legend via `graph_opt(legend(...))` |

**Best Practices**:
- Always include TWFE OLS as a baseline for comparison.
- Include at least 3-4 modern estimators to demonstrate robustness.
- **CRITICAL**: Normalize all estimators to the same reference period (conventionally period -1) before plotting. `did_imputation` and `eventstudyinteract` do NOT automatically omit period -1 as reference. Subtract the period -1 coefficient from all period estimates for these two estimators (see §4.6).
- Ensure pre-treatment coefficients cluster around zero for all estimators.
- If one estimator shows dramatically different post-treatment patterns, investigate potential violations of its identifying assumptions.
- **Clustering**: Use the treatment assignment level (e.g., city code for city-level policy), not the observation level (e.g., firm ID).
- **Never-treated encoding**: `wooldid` and `eventstudyinteract` require `first_treat = .` (missing) for never-treated units. `csdid` and `did_imputation` accept `first_treat = 0`.

### 3.17 Stata Official Commands (Stata 17+)

Stata 17 and later include built-in DID commands that do not require external packages. These commands are particularly useful for standard DID designs and include built-in Bacon decomposition diagnostics.

#### `didregress` — Standard DID Regression

```stata
* Basic syntax
didregress (y x controls) (treat), group(id) time(year)

* With cluster-robust standard errors
didregress (y x controls) (treat), group(id) time(year) vce(cluster id)

* Heteroskedasticity-robust standard errors
didregress (y x controls) (treat), group(id) time(year) vce(robust)

* With multiple treatment groups
didregress (y x controls) (treat), group(id) time(year) aggregate(group)
```

**Key Options**:

| Option | Description |
|--------|-------------|
| `group(varname)` | Group identifier (e.g., firm, state) |
| `time(varname)` | Time variable |
| `aggregate(group|time|att)` | Aggregation level for ATT |
| `vce(vcetype)` | Variance estimator (robust, cluster, bootstrap) |

**Post-estimation**:
```stata
* Display average treatment effect on the treated (ATT)
estat att

* Bacon decomposition (decomposes TWFE into 2x2 comparisons)
estat bdecomp, graph

* Event study (dynamic effects)
estat ptrends   // Test parallel trends
```

#### `xtdidregress` — Panel Data DID Regression

For panel data with `xtset` already declared:

```stata
* Declare panel structure first
xtset id year

* Basic usage
xtdidregress (y x controls) (treat), group(id) time(year)

* With fixed effects and clustering
xtdidregress (y x controls) (treat), group(id) time(year) vce(cluster id)
```

**Key Features**:
- Automatically handles panel structure.
- Supports time-varying covariates.
- Built-in parallel trends tests via `estat ptrends`.

#### `xthdidregress` — Heterogeneous DID Regression (Stata 18+)

For heterogeneous treatment effects with staggered adoption (Stata 18+):

```stata
* Basic syntax
xthdidregress ra (y x controls) (treat), group(id) time(year)

* With regression adjustment (RA)
xthdidregress ra (y x controls) (treat), group(id) time(year) vce(cluster id)

* With inverse probability weighting (IPW)
xthdidregress ipw (y x controls) (treat), group(id) time(year)

* With augmented IPW (AIPW) — doubly robust
xthdidregress aipw (y x controls) (treat), group(id) time(year)
```

**Key Options**:

| Option | Description |
|--------|-------------|
| `ra` | Regression adjustment |
| `ipw` | Inverse probability weighting |
| `aipw` | Augmented IPW (doubly robust) |
| `group(varname)` | Group identifier |
| `time(varname)` | Time variable |
| `vce(vcetype)` | Variance estimator |

**Post-estimation**:
```stata
* Average treatment effect on the treated
estat att

* Group-time ATTs
estat gratt

* Event study (dynamic effects)
estat event, window(-5 5)

* Bacon decomposition
estat bdecomp, graph
```

#### Bacon Decomposition with Official Commands

The built-in `estat bdecomp` provides a Bacon decomposition without installing external packages:

```stata
* After didregress or xthdidregress
didregress (y controls) (treat), group(id) time(year)

* Decomposition with graph
estat bdecomp, graph

* Detailed output
estat bdecomp, detail

* Save decomposition results
estat bdecomp, save("bacon_results.dta")
```

**Interpretation**:
- The decomposition shows the weights and 2x2 estimates from "good" (treated vs. never-treated) and "bad" (treated vs. already-treated) comparisons.
- If "bad" comparisons have large weights and different signs, TWFE may be biased.
- Modern estimators (csdid, did_imputation, etc.) should be preferred when Bacon decomposition reveals problematic weights.

## 4. Event Study Visualization

### 4.1 Classical Event Study (TWFE)
```stata
* Create relative time dummies (omit -1)
gen rel_time = year - first_treat
char rel_time[omit] -1
xi i.rel_time, prefix(D)

reghdfe y Drel_time_*, absorb(id year) vce(cluster id)
```

### 4.2 Creating Figures with `coefplot`
```stata
* Install
ssc install coefplot, replace

* After event study regression
reghdfe y Drel_time_*, absorb(id year) vce(cluster id)
coefplot, keep(Drel_time_*) vertical yline(0) xline(0) ///
    rename(Drel_time_m5="-5" Drel_time_0="0" ...) ///
    title("Event Study")
```

### 4.3 Comparing Multiple Estimators with `event_plot`
Highly recommended for comparing results from several estimators.

```stata
* Install
ssc install event_plot, replace

* Example workflow:
* 1. Run multiple estimators
* 2. Store results
* 3. Plot together
event_plot est1 est2 est3, ///
    stub_lag(L#) stub_lead(F#) ///
    together graph_opt(title("Comparing Estimators"))
```

See the [five_estimators_example.do](https://github.com/borusyak/did_imputation/blob/main/five_estimators_example.do) for a complete example.

### 4.4 Clarke and Tapia-Schythe (2022) - `eventdd`
Event study with distributed dynamics.

```stata
* Install
ssc install eventdd, replace

* Basic usage
eventdd y controls, timevar(rel_time) method(hdfe) absorb(id year) vce(cluster id)
```

### 4.5 Freyaldenhoven, Hansen, Shapiro (2019) - `xtevent`
Event study with extended functionality.

```stata
* Install
ssc install xtevent, replace

* Basic usage
xtevent y controls, panelvar(id) timevar(year) policyvar(treat) window(5)

* With overlay plot
xtevent y controls, panelvar(id) timevar(year) policyvar(treat) window(5) overlay
```

### 4.6 Reference Period Normalization (CRITICAL for Multi-Estimator Plots)

When comparing multiple estimators on a single event study plot, all estimators MUST use the same reference period (conventionally period -1, the last pre-treatment period). However, not all estimators automatically omit period -1. Failing to normalize produces visually misleading comparisons.

**Which estimators omit period -1 automatically?**

| Estimator | Period -1 = 0? | Normalization Needed |
|-----------|---------------|---------------------|
| TWFE with `ib(-1).rel_time` | ✅ Yes (explicitly omitted) | None |
| `csdid` with `agg(event)` | ✅ Yes (Tm1 omitted) | None |
| `did_imputation` (Borusyak) | ❌ No — `pre1` has a non-zero coefficient | **Subtract `_b[pre1]` from all periods** |
| `eventstudyinteract` (Sun-Abraham) | ❌ No — IW estimator gives coefficients for ALL periods | **Subtract period -1 coefficient from all periods** |

**Normalization code for `did_imputation`:**

```stata
did_imputation y id year first_treat, autosample horizon(0/5) pretrend(5) cluster(cluster_id)

* Get reference coefficient (pre1 = period -1)
local b_ref = _b[pre1]

* Normalize all periods: b_normalized[t] = b[t] - b[-1]
forvalues t = -5/5 {
    if `t' < 0 {
        local tn = abs(`t')
        local b`t' = _b[pre`tn'] - `b_ref'
    }
    else {
        local b`t' = _b[tau`t'] - `b_ref'
    }
}
* Now period -1 IS exactly zero and can be plotted as baseline
```

**Normalization code for `eventstudyinteract`:**

```stata
eventstudyinteract y D_*, cohort(first_treat) control_cohort(never_treated) ...
matrix b_sa = e(b_iw)

* Get period -1 coefficient from the IW result matrix
local col_m1 = colnumb(b_sa, "D_m1")  // or whatever naming convention used
local b_ref = b_sa[1, `col_m1']

* Subtract from all periods for direct comparability with TWFE/csdid
* (For plotting, set period -1 row to b=0, se=0 after normalization)
```

**Placebo test histogram**: For 500+ simulation runs, use `bin(20)` instead of `width()`:

```stata
histogram b_placebo, bin(20) xtitle("Placebo Coefficients") ...
```

## 5. Diagnostics and Robustness

### 5.1 Goodman-Bacon Decomposition - `bacondecomp`
Decomposes the TWFE estimate into weighted averages of 2x2 DID comparisons.

```stata
* Install
ssc install bacondecomp, replace

* Basic usage
bacondecomp y treat, ddetail

* With controls
bacondecomp y treat controls, ddetail
```

### 5.2 Parallel Trends Testing
Standard test: Joint significance of pre-treatment dummies in an event study.
```stata
testparm Drel_time_m5 Drel_time_m4 Drel_time_m3 Drel_time_m2
```

### 5.3 Sensitivity Analysis - `honestdid`
Sensitivity analysis for violations of parallel trends (Rambachan and Roth, 2023).

```stata
* Install
ssc install honestdid, replace

* Use after csdid or eventstudyinteract
honestdid, l_vec(0.5)

* For relative magnitude restrictions
honestdid, pre(1/5) post(6/10) mvec(0.5(0.5)2)
```

### 5.4 Pre-trends Testing - `pretrends`
Formal pre-trends testing.

```stata
* Install
ssc install pretrends, replace

* Basic usage (requires coefficient vector and variance-covariance matrix)
pretrends, pre(1/5) post(6/10)
```

### 5.5 TWFE Weights Decomposition - `twowayfeweights`
Decomposes TWFE weights to check for negative weights.

```stata
* Install
ssc install twowayfeweights, replace

* Basic usage
twowayfeweights y id year treat, type(feTR) summary

* For dynamic effects
twowayfeweights y id year treat, type(feS) summary
```

### 5.6 Yatchew Test - `yatchew_test`
Test for parallel trends using non-parametric methods.

```stata
* Install
ssc install yatchew_test, replace

* Basic usage
yatchew_test y time, treat(treat)
```

### 5.7 Robust Estimation - `robustate`
Robust estimation for DID with large trimming bias correction.

```stata
* Install (note: typo in original command name)
* ssc install robustate, replace

* See help file for usage after installation
```

## 6. Other Estimators

### 6.1 `flexpaneldid`
Flexible panel DID for continuous treatments.

```stata
* Install
ssc install flexpaneldid, replace

* Basic usage (see help file for detailed syntax)
flexpaneldid y, treatment(treat) id(id) time(year)
```

### 6.2 `multe`
Multiple Treatment Effects estimation.

```stata
* Install from GitHub
* net install multe, from("https://raw.githubusercontent.com/gphk-metrics/stata-multe/main/")

* See GitHub repository for usage examples
```

## 7. Robustness Checks

- **Placebo Tests**: Re-run the model with a fake treatment date before the actual treatment.
- **Alternative Estimators**: Compare results across `csdid`, `did_imputation`, and `sdid`.
- **Leave-one-out**: Drop one unit or cohort at a time to check if results are driven by outliers.
- **Sensitivity Analysis**: Use `honestdid` and `pretrends` to assess robustness to parallel trends violations.
- **Weight Analysis**: Use `twowayfeweights` to check for problematic weights in TWFE.

## 8. Exporting Results

Use `esttab` or `outreg2` for publication-quality tables.

```stata
* Using esttab
eststo clear
eststo model1: reghdfe y treat_post, absorb(id year) vce(cluster id)
eststo model2: csdid y, ivar(id) time(year) gvar(first_treat)
esttab model1 model2 using "results.rtf", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalar(N r2) label
```

## 9. Common Pitfalls and Troubleshooting

### Error: "command avar is unrecognized"

**Symptom**: `eventstudyinteract` fails with `r(199)` and "command avar is unrecognized".

**Cause**: `avar` is a hidden dependency of `eventstudyinteract` that is NOT auto-installed.

**Fix**: `ssc install avar, replace`

### Error: "maxvar too small" (wooldid)

**Symptom**: `wooldid` fails with "maxvar too small...currently 5000".

**Cause**: Wooldridge estimator creates cohort-year interaction terms that explode in dimensionality.

**Fix**: 
```stata
* MUST be done BEFORE loading data
set maxvar 50000
set emptycells drop
set matsize 11000
use "mydata.dta", clear
xtset id year
wooldid y id year first_treat
```
**Note**: For 30K+ observations, single estimation may take >10 minutes.

### Error: "no; dataset in memory has changed since last saved" when setting maxvar

**Symptom**: `set maxvar` fails even after loading fresh data.

**Cause**: Stata requires absolutely no unsaved changes before `set maxvar`. Even `xtset` modifies sort order which counts as "changed".

**Fix**: Set maxvar in a do-file BEFORE the first `use` command:
```stata
set maxvar 50000
set emptycells drop
set matsize 11000
use "mydata.dta", clear   // only NOW load data
```

### Error: "option covariates() not allowed" (wooldid)

**Symptom**: `wooldid ... covariates(varlist)` fails with `r(198)`.

**Cause**: `wooldid` does NOT accept a `covariates()` option.

**Fix**: Omit `covariates()`. wooldid constructs cohort-specific polynomials internally. If you need additional controls, include them as manual interactions or use a different estimator (e.g., `csdid`).

### Error: "option controls() not allowed" (did_imputation)

**Symptom**: `did_imputation ... controls(varlist)` fails.

**Cause**: `did_imputation` does NOT accept `controls()`. The imputation estimator uses untreated observations internally as the control group.

**Fix**: Remove `controls()`. The estimator is designed to work without explicit controls.

### Error: did_imputation fails with vce(cluster ...)

**Symptom**: `did_imputation ... vce(cluster id)` produces an error.

**Cause**: `did_imputation` uses bare `cluster(id)` syntax, not `vce(cluster id)`.

**Fix**: Replace `vce(cluster id)` with `cluster(id)`.

### Error: "you have no never-treated control group" (wooldid)

**Symptom**: `wooldid` fails with "you have no never-treated control group".

**Cause**: For `wooldid`, never-treated units must have `first_treat = .` (missing), NOT `first_treat = 0`.

**Fix**:
```stata
replace first_treat = . if treat == 0
```

### Issue: Period -1 shows non-zero coefficient in event study plot

**Symptom**: On a multi-estimator event study plot, Borusyak or Sun-Abraham estimators show a non-zero coefficient at period -1 (which should be the reference).

**Cause**: `did_imputation` and `eventstudyinteract` do NOT automatically omit period -1 as the reference. The IW/imputation estimators compute coefficients for ALL periods, and the normalization is relative to the average pre-treatment effect, not a single period.

**Fix**: See §4.6 "Reference Period Normalization" for complete normalization code. Manually subtract the period -1 coefficient from all period estimates, then set period -1 to 0.

### Issue: csdid fails with tvar() option

**Symptom**: `csdid ... tvar(year)` produces an error or unexpected behavior.

**Cause**: The correct option name is `time()`, not `tvar()`. `tvar` was used in early versions but is now deprecated.

**Fix**: Replace `tvar(year)` with `time(year)`.

### Issue: csdid clustering not working

**Symptom**: `csdid ... cluster(id)` ignores the clustering.

**Cause**: `csdid` requires `vce(cluster id)`, not bare `cluster(id)`.

**Fix**: Use `vce(cluster cluster_id)` instead of `cluster(cluster_id)`.

### Issue: Standard errors too small / over-rejection

**Symptom**: Results appear statistically significant but likely shouldn't be.

**Cause**: Standard errors are clustered at the observation level (e.g., firm) when treatment is assigned at a higher level (e.g., city). This produces artificially small SEs.

**Fix**: Always cluster at the treatment assignment level (see §1.0). If policy is at city level, use `vce(cluster citycode)` throughout ALL regressions (including production function estimation and all robustness checks).

### Placebo test histogram has too few bars

**Symptom**: Placebo test histogram with 500 simulations shows only 3-5 bars.

**Cause**: Using `width(#)` with a value that's too large for the data range.

**Fix**: For 500+ simulation runs, use `bin(20)`:
```stata
histogram b_placebo, bin(20) ...  // NOT width(0.003)
```

---

**Note**: Many packages are actively developed. For the latest syntax and options, always check the help files (`help commandname`) or the GitHub repositories linked in the package documentation. Different packages have different assumptions—use them carefully and cite appropriately.
