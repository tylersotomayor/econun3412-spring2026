* ============================================================
* ps5_problems1and2.do
* ECON UN3412 — Problem Set 5
* Concealed-carry ("shall-issue") laws and crime
*
* This .do file produces all regressions needed for:
*   Problem 1: Parts (i), (ii), (a)–(c)
*   Problem 2: Tables 1–3  (ln(vio), ln(rob), ln(mur))
*
* Each table has 5 columns:
*   (1) OLS of ln(Y) on shall only, robust SEs
*   (2) OLS of ln(Y) on shall + controls, robust SEs
*   (3) + state FE (via dummies), robust SEs
*   (4) + state FE + year FE (via dummies), robust SEs
*   (5) same as (4) but with clustered SEs at the state level
*
* Outputs:
*   ../output/tables/table1_vio.tex
*   ../output/tables/table2_rob.tex
*   ../output/tables/table3_mur.tex
*   ../output/tables/prob1_reg_i.tex
*   ../output/tables/prob1_reg_ii.tex
* ============================================================

clear all
set more off

* ----------------------------------------------------------
* 1. LOAD DATA
* ----------------------------------------------------------
* Load the balanced panel: 51 "states" × 23 years = 1,173 obs
use "../handguns.dta", clear

* ----------------------------------------------------------
* 2. GENERATE KEY VARIABLES
* ----------------------------------------------------------

* Generate the log-transformed dependent variables.
* These are log crime rates per 100,000 population.
gen ln_vio = ln(vio)
    label var ln_vio "ln(Violent Crime Rate)"

gen ln_rob = ln(rob)
    label var ln_rob "ln(Robbery Rate)"

gen ln_mur = ln(mur)
    label var ln_mur "ln(Murder Rate)"

* ----------------------------------------------------------
* 3. GENERATE STATE AND YEAR DUMMY VARIABLES
* ----------------------------------------------------------

* Create a full set of state indicator (dummy) variables.
* 'stateid' runs from 1–56 (with some gaps); tabulate creates
* one dummy per observed category: st1, st2, ..., st56.
* These will be used to include state fixed effects manually
* so we can also run F-tests on them.
tabulate stateid, generate(st)

* Create a full set of year indicator (dummy) variables.
* 'year' runs from 77–99 (i.e., 1977–1999); tabulate creates
* yr1, yr2, ..., yr23.
tabulate year, generate(yr)

* ----------------------------------------------------------
* 4. DEFINE LOCAL MACROS FOR CONTROLS AND FIXED EFFECTS
* ----------------------------------------------------------

* State characteristic control variables (listed in the problem set):
local controls "incarc_rate density avginc pop pb1064 pw1064 pm1029"

* State fixed effect dummies (drop one for identification):
*   st1–st51; we drop st1 (the reference state) to avoid
*   perfect multicollinearity with the intercept.
local state_fe "st2-st51"

* Year fixed effect dummies (drop one for identification):
*   yr1–yr23; we drop yr1 (the reference year = 1977).
local year_fe "yr2-yr23"


* ============================================================
*  PROBLEM 1 — REGRESSIONS (i) AND (ii)
* ============================================================

* ----------------------------------------------------------
* Regression (i): ln(vio) on shall only, robust SEs
* ----------------------------------------------------------
* This is a simple bivariate OLS regression of the log violent
* crime rate on the shall-issue indicator. Heteroskedasticity-
* robust (HC1 / "Eicker–Huber–White") standard errors are used.
reg ln_vio shall, robust
estimates store p1_reg_i

* Export Regression (i) table via esttab
esttab p1_reg_i using "../output/tables/prob1_reg_i.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label title("Problem 1 Regression (i): ln(vio) on shall") ///
    stats(N r2 r2_a, labels("Observations" "\$R^2\$" "Adjusted \$R^2\$") fmt(%9.0fc %9.4f %9.4f)) ///
    booktabs alignment(D{.}{.}{-1}) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses.")

* ----------------------------------------------------------
* Regression (ii): ln(vio) on shall + controls, robust SEs
* ----------------------------------------------------------
* This is the multiple regression with all state-characteristic
* control variables: incarceration rate, population density,
* average income, population, and demographic shares.
reg ln_vio shall `controls', robust
estimates store p1_reg_ii

* Export Regression (ii) table via esttab
esttab p1_reg_ii using "../output/tables/prob1_reg_ii.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label title("Problem 1 Regression (ii): ln(vio) on shall + controls") ///
    stats(N r2 r2_a, labels("Observations" "\$R^2\$" "Adjusted \$R^2\$") fmt(%9.0fc %9.4f %9.4f)) ///
    booktabs alignment(D{.}{.}{-1}) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses." ///
             "Controls: incarc\_rate, density, avginc, pop, pb1064, pw1064, pm1029.")


* ============================================================
*  PROBLEM 2 — TABLES 1, 2, AND 3
*  Loop over three dependent variables: ln_vio, ln_rob, ln_mur
* ============================================================

* We loop over the three crime outcomes. For each outcome we
* estimate five specifications of increasing richness.

foreach depvar in ln_vio ln_rob ln_mur {

    * Determine short name and table number for labeling
    if "`depvar'" == "ln_vio" {
        local shortname "vio"
        local tablenum  "1"
        local tablecap  "The Effect of Concealed Handgun Laws on Violent Crime"
    }
    if "`depvar'" == "ln_rob" {
        local shortname "rob"
        local tablenum  "2"
        local tablecap  "The Effect of Concealed Handgun Laws on Robberies"
    }
    if "`depvar'" == "ln_mur" {
        local shortname "mur"
        local tablenum  "3"
        local tablecap  "The Effect of Concealed Handgun Laws on Murders"
    }

    * ----------------------------------------------------------
    * Column (1): OLS, shall only, robust SEs
    * ----------------------------------------------------------
    * Baseline regression: no controls, no fixed effects.
    * Captures the raw correlation between shall-issue laws
    * and log crime rates across all state-years.
    reg `depvar' shall, robust
    estimates store `shortname'_1

    * ----------------------------------------------------------
    * Column (2): OLS, shall + controls, robust SEs
    * ----------------------------------------------------------
    * Add the seven state-characteristic control variables.
    * This controls for observable confounders that differ
    * across states and time: incarceration, demographics, etc.
    reg `depvar' shall `controls', robust
    estimates store `shortname'_2

    * ----------------------------------------------------------
    * Column (3): State FE + controls, robust SEs
    * ----------------------------------------------------------
    * Add state fixed effects (50 state dummies, with st1 as
    * the omitted reference category). State FE absorb all
    * time-invariant unobserved heterogeneity across states
    * (e.g., geography, culture, historical gun ownership).
    * Identification now comes from within-state variation
    * over time: states that changed their shall-issue law
    * status during the sample period.
    reg `depvar' shall `controls' `state_fe', robust
    estimates store `shortname'_3

    * F-test: are the state fixed effects jointly zero?
    * Under H0: all state dummy coefficients = 0 (i.e., no
    * state-level heterogeneity). A large F rejects H0.
    testparm `state_fe'
    local F_state_3 = r(F)
    local p_state_3 = r(p)
    estadd scalar F_state = `F_state_3' : `shortname'_3
    estadd scalar p_state = `p_state_3' : `shortname'_3

    * ----------------------------------------------------------
    * Column (4): State FE + Year FE + controls, robust SEs
    * ----------------------------------------------------------
    * Add year fixed effects (22 year dummies, with yr1 as
    * the reference year = 1977). Year FE absorb aggregate
    * time trends that affect all states equally (e.g., national
    * crime trends, federal legislation, economic cycles).
    * This is essentially a two-way fixed effects (TWFE) model.
    reg `depvar' shall `controls' `state_fe' `year_fe', robust
    estimates store `shortname'_4

    * F-test: are the state fixed effects jointly zero?
    testparm `state_fe'
    local F_state_4 = r(F)
    local p_state_4 = r(p)
    estadd scalar F_state = `F_state_4' : `shortname'_4
    estadd scalar p_state = `p_state_4' : `shortname'_4

    * F-test: are the year fixed effects jointly zero?
    testparm `year_fe'
    local F_year_4 = r(F)
    local p_year_4 = r(p)
    estadd scalar F_year = `F_year_4' : `shortname'_4
    estadd scalar p_year = `p_year_4' : `shortname'_4

    * ----------------------------------------------------------
    * Column (5): State FE + Year FE + controls, clustered SEs
    * ----------------------------------------------------------
    * Same specification as (4), but standard errors are now
    * clustered at the state level. Clustering allows for
    * arbitrary serial correlation (autocorrelation) in the
    * error term within each state over time, as well as
    * heteroskedasticity. This is the "HAC" (heteroskedasticity-
    * and autocorrelation-consistent) approach for panel data
    * recommended by Arellano (1987) and implemented via the
    * vce(cluster stateid) option.
    reg `depvar' shall `controls' `state_fe' `year_fe', vce(cluster stateid)
    estimates store `shortname'_5

    * F-test: are the year fixed effects jointly zero?
    * (State FE F-test is not reported for column 5 per table notes)
    testparm `year_fe'
    local F_year_5 = r(F)
    local p_year_5 = r(p)
    estadd scalar F_year = `F_year_5' : `shortname'_5
    estadd scalar p_year = `p_year_5' : `shortname'_5

    * ----------------------------------------------------------
    * Display key results to log for verification
    * ----------------------------------------------------------
    di ""
    di "============================================="
    di "TABLE `tablenum': `tablecap'"
    di "============================================="
    di ""

    * Print coefficients on 'shall' across all 5 columns
    foreach col in 1 2 3 4 5 {
        estimates restore `shortname'_`col'
        di "Column (`col'): shall = " _b[shall] "  SE = " _se[shall]
    }

    * Print F-statistics
    di ""
    di "F-stat state FE (col 3): " `F_state_3' "  p = " `p_state_3'
    di "F-stat state FE (col 4): " `F_state_4' "  p = " `p_state_4'
    di "F-stat year FE  (col 4): " `F_year_4'  "  p = " `p_year_4'
    di "F-stat year FE  (col 5): " `F_year_5'  "  p = " `p_year_5'
    di ""

    * ----------------------------------------------------------
    * Export Table as LaTeX via esttab
    * ----------------------------------------------------------
    * We export a combined table with columns (1)–(5), keeping
    * only the coefficient on 'shall' visible (dropping the 50+
    * state and year dummies from the display).
    esttab `shortname'_1 `shortname'_2 `shortname'_3 `shortname'_4 `shortname'_5 ///
        using "../output/tables/table`tablenum'_`shortname'.tex", replace ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        keep(shall) ///
        label title("`tablecap'") ///
        mtitles("(1)" "(2)" "(3)" "(4)" "(5)") ///
        stats(N r2, labels("Observations" "\$R^2\$") fmt(%9.0fc %9.4f)) ///
        booktabs alignment(D{.}{.}{-1}) ///
        addnotes("Dependent variable: ln(`shortname')." ///
                 "Heteroskedasticity-robust SEs in columns (1)--(4); clustered at state level in column (5)." ///
                 "State characteristic controls: incarc\_rate, density, avginc, pop, pb1064, pw1064, pm1029.")
}

* ----------------------------------------------------------
* DISPLAY NUMBER OF OBSERVATIONS (should be 1173 for all)
* ----------------------------------------------------------
di ""
di "Total observations in dataset: " _N
di ""
di "============================================="
di " ALL REGRESSIONS COMPLETE "
di "============================================="
