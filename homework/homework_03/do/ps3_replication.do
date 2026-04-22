* ==============================================================================
* ECON UN3412 — Homework 3 (Spring 2026)
* Replication .do file (Stata) — Option A (manual cd to project root)
* Author: Tyler Sotomayor
* ==============================================================================

version 18.0
clear all
set more off
set linesize 255

* ==============================================================================
* 0. Paths (relative to project root)
* ==============================================================================

global DATA   "data"
global OUT    "output"
global TABS   "$OUT/tables"
global FIGS   "$OUT/figures"
global LOGS   "$OUT/logs"

capture mkdir "$OUT"
capture mkdir "$TABS"
capture mkdir "$FIGS"
capture mkdir "$LOGS"

capture log close
log using "$LOGS/ps3_replication.log", replace text

display as text "============================================================"
display as text "Running from: `c(pwd)'"
display as text "============================================================"

* ==============================================================================
* 1. Packages
* ==============================================================================

capture which esttab
if _rc {
    ssc install estout, replace
}

* ==============================================================================
* 2. House style for LaTeX regression tables
*    NOTE: line continuation uses " ///" with a leading space (required). 
* ==============================================================================

global ESTSTYLE ///
    "booktabs se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) se(%9.3f) alignment(D{.}{.}{-1})"

* ==============================================================================
* PROBLEM 1(a) — GPA4.dta (Table 2)
* ==============================================================================

use "$DATA/GPA4.dta", clear

describe
summarize colGPA hsGPA skipped PC bgfriend campus

eststo clear

reg colGPA hsGPA skipped, vce(robust)
eststo col1

reg colGPA hsGPA skipped PC, vce(robust)
eststo col2

reg colGPA hsGPA skipped PC bgfriend campus, vce(robust)
eststo col3

esttab col1 col2 col3 using "$TABS/prob1_table2.tex", replace ///
    $ESTSTYLE ///
    nomtitles ///
    collabels("(1)" "(2)" "(3)", none) ///
    keep(hsGPA skipped PC bgfriend campus _cons) ///
    order(hsGPA skipped PC bgfriend campus _cons) ///
    coeflabels(_cons "Intercept") ///
    stats(N r2 rmse, fmt(%9.0fc %9.3f %9.3f) labels("n" "R-squared" "Regression RMSE")) ///
    addnotes("Robust standard errors in parentheses.")

display as text "Wrote: $TABS/prob1_table2.tex"

* ==============================================================================
* PROBLEM 2 — Nursing Home Utilization
* Part 2.1 (Year 2000 data)
* ==============================================================================

display as text "============================================================"
display as text "PROBLEM 2 — Year 2000 Analysis"
display as text "============================================================"

use "$DATA/WiscoNursingHome.dta", clear

* Keep only cost-report year 2000
keep if cryear == 2000

* Create log(TPY)
gen logtpy = log(tpy)

* Basic checks
summarize tpy logtpy numbed sqrfoot

display as text "---- Correlation: TPY and log(TPY) ----"
corr tpy logtpy

display as text "---- Correlation Matrix: TPY, NUMBED, SQRFOOT ----"
corr tpy numbed sqrfoot

* ------------------------------------------------------------------------------
* 2.1(b) Scatter plots
* ------------------------------------------------------------------------------

display as text "---- Generating Scatter Plots ----"

* Scatter: TPY vs NUMBED
twoway ///
    (scatter tpy numbed, msize(small) mcolor(navy)) ///
    (lfit tpy numbed, lcolor(maroon)), ///
    title("TPY vs NUMBED (Year 2000)") ///
    ytitle("TPY") ///
    xtitle("NUMBED") ///
    legend(off)

graph export "$FIGS/prob2_tpy_numbed.pdf", replace

* Scatter: TPY vs SQRFOOT
twoway ///
    (scatter tpy sqrfoot, msize(small) mcolor(navy)) ///
    (lfit tpy sqrfoot, lcolor(maroon)), ///
    title("TPY vs SQRFOOT (Year 2000)") ///
    ytitle("TPY") ///
    xtitle("SQRFOOT") ///
    legend(off)

graph export "$FIGS/prob2_tpy_sqrfoot.pdf", replace

* ------------------------------------------------------------------------------
* 2.1(c)(i) TPY on NUMBED
* ------------------------------------------------------------------------------

display as text "---- Regression: TPY on NUMBED ----"

reg tpy numbed

display as text "R-squared = " %6.4f e(r2)
display as text "t-stat(NUMBED) = " %6.4f (_b[numbed]/_se[numbed])

* ------------------------------------------------------------------------------
* 2.1(c)(ii) TPY on SQRFOOT
* ------------------------------------------------------------------------------

* ------------------------------------------------------------------------------
* 2.1(c)(iii) LOGTPY on LOG(NUMBED)
* ------------------------------------------------------------------------------

gen lognumbed = log(numbed)

display as text "---- Regression: LOGTPY on LOG(NUMBED) ----"

reg logtpy lognumbed

display as text "R-squared = " %6.4f e(r2)
display as text "t-stat(LOGNUMBED) = " %6.4f (_b[lognumbed]/_se[lognumbed])

display as text "---- Regression: TPY on SQRFOOT ----"

reg tpy sqrfoot

display as text "R-squared = " %6.4f e(r2)
display as text "t-stat(SQRFOOT) = " %6.4f (_b[sqrfoot]/_se[sqrfoot])

* ------------------------------------------------------------------------------
* 2.1(c)(iv) LOGTPY on LOG(SQRFOOT)
* ------------------------------------------------------------------------------

gen logsqrfoot = log(sqrfoot)

display as text "---- Regression: LOGTPY on LOG(SQRFOOT) ----"

reg logtpy logsqrfoot

display as text "R-squared = " %6.4f e(r2)
display as text "t-stat(LOGSQRFOOT) = " %6.4f (_b[logsqrfoot]/_se[logsqrfoot])

* ==============================================================================
* PROBLEM 2.2 — Year 2001 Analysis
* Same regression as 2.1(c)(i): TPY on NUMBED
* ==============================================================================

display as text "============================================================"
display as text "PROBLEM 2.2 — Year 2001 Analysis"
display as text "============================================================"

use "$DATA/WiscoNursingHome.dta", clear

* Keep only cost-report year 2001
keep if cryear == 2001

display as text "---- Regression: TPY on NUMBED (Year 2001) ----"

reg tpy numbed

display as text "R-squared (2001) = " %6.4f e(r2)
display as text "t-stat(NUMBED, 2001) = " %6.4f (_b[numbed]/_se[numbed])

* ==============================================================================
* PROBLEM 3(a)(ii) — Wage on Female
* ==============================================================================

display as text "============================================================"
display as text "PROBLEM 3(a)(ii) — wage on female"
display as text "============================================================"

use "$DATA/WAGE.dta", clear

reg wage female

display as text "Mean wage (female=0): " %6.4f _b[_cons]
display as text "Mean wage difference (female=1 - female=0): " %6.4f _b[female]
display as text "R-squared = " %6.4f e(r2)

* ==============================================================================
* PROBLEM 3(c) — Perfect multicollinearity (female and male dummy)
* ==============================================================================

display as text "============================================================"
display as text "PROBLEM 3(a)(iii) — Female and Male Dummy Together"
display as text "============================================================"

use "$DATA/WAGE.dta", clear

* Generate male dummy
gen male = 1 - female

* Verify construction
tab female male

* Run regression with both dummies
reg wage educ female male

* ==============================================================================
* PROBLEM 3(a)(iv) — OVB: wage on educ, then wage on educ + exper
* ==============================================================================

display as text "============================================================"
display as text "PROBLEM 3(d) — wage on educ; then wage on educ + exper"
display as text "============================================================"

use "$DATA/WAGE.dta", clear

* (1) Simple regression: wage on educ
reg wage educ
display as text "beta1 (educ) in simple model = " %9.6f _b[educ]

* (2) Multiple regression: wage on educ and exper
reg wage educ exper
display as text "beta1 (educ) controlling for exper = " %9.6f _b[educ]
display as text "beta2 (exper) controlling for educ = " %9.6f _b[exper]

* ==============================================================================
* PROBLEM 3 — Full model (classical vs robust SEs)
* ==============================================================================

use "$DATA/WAGE.dta", clear

eststo clear

* Classical SEs
reg wage educ exper tenure female nonwhite
eststo classical

* Robust SEs
reg wage educ exper tenure female nonwhite, vce(robust)
eststo robust

esttab classical robust using "$TABS/prob3_fullmodel.tex", replace ///
    $ESTSTYLE ///
    nomtitles ///
    collabels("(1) Classical SEs" "(2) Robust SEs", none) ///
    keep(educ exper tenure female nonwhite _cons) ///
    order(educ exper tenure female nonwhite _cons) ///
    coeflabels(_cons "Intercept") ///
    stats(N r2 rmse, fmt(%9.0fc %9.3f %9.3f) ///
          labels("n" "R-squared" "Regression RMSE")) ///
    nonotes ///
    addnotes("Column (2) reports heteroskedasticity-robust standard errors.")
	
* ==============================================================================
* PROBLEM 3(f) — Hypothesis tests using ROBUST regression
* ==============================================================================

display as text "============================================================"
display as text "PROBLEM 3(f) — Hypothesis tests (robust VCE)"
display as text "============================================================"

* Individual (two-sided) tests H0: beta_i = 0 for i=1,...,5
* (The t-stats and p-values are in the regression output, but we can also display them cleanly.)
foreach v in educ exper tenure female nonwhite {
    display as text "---- H0: beta_`v' = 0 (robust) ----"
    test `v' = 0
}

* Joint test H0: beta1=beta2=beta3=beta4=beta5=0
display as text "---- Joint test: educ exper tenure female nonwhite all zero (robust) ----"
test educ exper tenure female nonwhite


log close
display as text "Done."
