* ============================================================
* ps6_problem1.do
* ECON UN3412 -- Homework 6
* Stock & Watson Empirical Exercise 11.1
*
* Dependent variables:
*   employed   = 1 if respondent was employed in April 2009
*                (conditional on being employed full-time in
*                 April 2008).  Used in parts (a)--(f).
*   unemployed = 1 if respondent was unemployed in April 2009
*                (out-of-labor-force respondents are not in
*                 either indicator).  Used in part (g).
*
* Principal regressors:
*   age, age^2, female, race dummies (nonwhite), married,
*   union, region (ne_states, so_states, ce_states, we_states),
*   earnings in April 2008 (earnwke),
*   education dummies (educ_lths, educ_hs, educ_somecol,
*     educ_aa, educ_bac, educ_adv).
*
* Three probability models used throughout:
*   - LPM     :   reg      (OLS with robust SEs)
*   - Probit  :   probit   (MLE; latent normal shock)
*   - Logit   :   logit    (MLE; latent logistic shock)
*
* Outputs:
*   tables  ->  ../output/tables/prob1_*.tex
*   figures ->  ../output/figures/prob1_*.pdf
*   log     ->  ps6_problem1.log
* ============================================================

clear all
set more off
capture log close
log using "ps6_problem1.log", replace text

* ----------------------------------------------------------
*  HELPER: define a consistent academic graph style for all
*  plots produced in this file.  The "s2mono" scheme yields
*  a clean, journal-style monochrome palette; we override a
*  few parameters so that reference markers (20, 40, 60 yrs)
*  remain visible against the background.
* ----------------------------------------------------------
set scheme s2mono
graph set window fontface "Times New Roman"


* ==========================================================
*  PART (a)  --  FRACTION EMPLOYED IN APRIL 2009 AND 95% CI
*                FOR THE PROBABILITY OF EMPLOYMENT
* ==========================================================
*
*  Because the sample consists only of workers who were
*  employed full-time in April 2008, the sample mean of
*  `employed' is precisely the sample analogue of
*  P(employed_2009 = 1 | employed_2008 = 1).  A 95%
*  large-sample CI for a proportion is the usual
*      phat +/- 1.96 * sqrt( phat*(1-phat)/n ).

use "../data/employment_08_09.dta", clear

* Save the sample size for later reference
scalar n_obs = _N

* Unconditional sample mean (= P(Y=1))
summarize employed, meanonly
scalar phat = r(mean)

* Standard error of a proportion (Bernoulli):   sqrt(p(1-p)/n)
scalar se_p = sqrt(phat*(1-phat)/n_obs)
scalar ci_lo = phat - 1.96*se_p
scalar ci_hi = phat + 1.96*se_p

display as text _newline "=== Part (a) ==="
display as text "Sample size (n)                     = " %9.0fc n_obs
display as text "P(employed_2009 | employed_2008)    = " %6.4f phat
display as text "Standard error (Bernoulli formula)  = " %6.4f se_p
display as text "95% CI: [" %6.4f ci_lo ", " %6.4f ci_hi "]"

* Store result for later export
file open f_parta using "../output/tables/prob1_parta.tex", write replace
file write f_parta "% Part (a) numbers, produced by ps6_problem1.do" _n
file write f_parta "\newcommand{\partaphat}{" %6.4f (phat) "}" _n
file write f_parta "\newcommand{\partase}{"   %6.4f (se_p) "}" _n
file write f_parta "\newcommand{\partacilo}{" %6.4f (ci_lo) "}" _n
file write f_parta "\newcommand{\partacihi}{" %6.4f (ci_hi) "}" _n
file write f_parta "\newcommand{\partaN}{"    %9.0fc (n_obs) "}" _n
file close f_parta


* ==========================================================
*  PART (b)  --  LPM REGRESSION ON AGE AND AGE^2
*    (b.i)  Significance of age / nonlinearity
*    (b.ii) Discussed narratively in the write-up
*    (b.iii) Predicted P at ages 20, 40, 60
* ==========================================================

* Generate age-squared
gen age2 = age^2
    label var age2 "age squared"

* LPM  =  OLS on the binary Y with robust (HC1) SEs
reg employed age age2, robust
estimates store lpm_age

* Joint test that both age coefficients are zero (tests
* whether age matters at all for the probability of
* employment in 2009, conditional on 2008 employment).
test age age2
scalar F_age_lpm  = r(F)
scalar p_age_lpm  = r(p)

* (b.iii) Predicted probability at ages 20, 40, 60
*   We use `margins' because it conveniently reports SEs
*   and it treats the quadratic piece correctly.
*   (factor-variable notation lets `margins' differentiate
*    through the quadratic without our having to recompute.)
quietly reg employed c.age##c.age, robust
estimates store lpm_age_fv
margins, at(age=(20 40 60)) post
estimates store lpm_marg

* Keep these predictions for comparison with probit/logit
matrix lpm_pred = e(b)

* Now re-fit the stored LPM in the non-factor form so that
* later replay with `estimates restore' still produces the
* simple specification.
quietly reg employed age age2, robust


* ==========================================================
*  PART (c)  --  PROBIT
* ==========================================================
*
*  Probit model:  Pr(Y=1 | X) = Phi(X' beta), Phi = standard
*  normal CDF.  Coefficients are not marginal effects and
*  require transformation (or `margins') to be interpretable
*  on the probability scale.

probit employed age age2, vce(robust)
estimates store prob_age

* Test joint significance of age and age^2
test age age2
scalar F_age_prob = r(F)
scalar p_age_prob = r(p)

* Factor-variable form for `margins'
quietly probit employed c.age##c.age, vce(robust)
margins, at(age=(20 40 60)) post
estimates store prob_marg
matrix prob_pred = e(b)

* Restore non-FV specification for export
quietly probit employed age age2, vce(robust)


* ==========================================================
*  PART (d)  --  LOGIT
* ==========================================================

logit employed age age2, vce(robust)
estimates store logit_age

test age age2
scalar F_age_logit = r(F)
scalar p_age_logit = r(p)

quietly logit employed c.age##c.age, vce(robust)
margins, at(age=(20 40 60)) post
estimates store logit_marg
matrix logit_pred = e(b)

quietly logit employed age age2, vce(robust)


* ==========================================================
*  Consolidated table for parts (b)--(d):  regression output
* ==========================================================

esttab lpm_age prob_age logit_age ///
    using "../output/tables/prob1_bcd_models.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    mtitles("LPM" "Probit" "Logit") ///
    title("Effect of Age on the Probability of Employment in April 2009\label{tab:prob1-bcd}") ///
    stats(N r2 r2_p ll, ///
        labels("Observations" "\$R^2\$" "Pseudo \$R^2\$" "Log-likelihood") ///
        fmt(%9.0fc %9.4f %9.4f %9.2f)) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses." ///
             "Dependent variable = 1 if employed in April 2009, conditional on employment in April 2008.")


* ==========================================================
*  Consolidated table of predicted probabilities at age
*  20 / 40 / 60 across the three models (part b.iii, c, d)
* ==========================================================

* Display to screen for easy copy into the write-up
display as text _newline "=== Predicted P(employed) at ages 20 / 40 / 60 ==="
display as text "              20yr     40yr     60yr"
display as text "LPM    :  " %6.4f lpm_pred[1,1]   "  " %6.4f lpm_pred[1,2]   "  " %6.4f lpm_pred[1,3]
display as text "Probit :  " %6.4f prob_pred[1,1]  "  " %6.4f prob_pred[1,2]  "  " %6.4f prob_pred[1,3]
display as text "Logit  :  " %6.4f logit_pred[1,1] "  " %6.4f logit_pred[1,2] "  " %6.4f logit_pred[1,3]

* Also write to a LaTeX fragment for inclusion
file open f_pred using "../output/tables/prob1_predprob.tex", write replace
file write f_pred "\begin{tabular}{lccc}" _n
file write f_pred "\toprule" _n
file write f_pred "Model & Age 20 & Age 40 & Age 60 \\\\ \midrule" _n
file write f_pred "LPM    & " %6.4f (lpm_pred[1,1])   " & " %6.4f (lpm_pred[1,2])   " & " %6.4f (lpm_pred[1,3])   " \\\\" _n
file write f_pred "Probit & " %6.4f (prob_pred[1,1])  " & " %6.4f (prob_pred[1,2])  " & " %6.4f (prob_pred[1,3])  " \\\\" _n
file write f_pred "Logit  & " %6.4f (logit_pred[1,1]) " & " %6.4f (logit_pred[1,2]) " & " %6.4f (logit_pred[1,3]) " \\\\" _n
file write f_pred "\bottomrule" _n
file write f_pred "\end{tabular}" _n
file close f_pred


* ==========================================================
*  FIGURE:  Predicted P(employed) vs age for the three models
*           over the support of age in the sample.
* ==========================================================

* Predicted probability curves over the integer age grid
preserve
    * Re-estimate cleanly on the full sample so we can
    * use -predict- with `xb' / `pr' over a grid of ages.
    quietly reg employed c.age##c.age, robust
    predict yhat_lpm_full, xb
    quietly probit employed c.age##c.age, vce(robust)
    predict yhat_prob_full, pr
    quietly logit employed c.age##c.age, vce(robust)
    predict yhat_logit_full, pr

    * Collapse to one observation per age so the plot is
    * smooth and does not overlap thousands of points.
    collapse (mean) yhat_lpm_full yhat_prob_full yhat_logit_full, by(age)

    twoway ///
        (line yhat_lpm_full   age, lwidth(medthick) lcolor(black)    lpattern(solid)) ///
        (line yhat_prob_full  age, lwidth(medthick) lcolor(navy)     lpattern(dash)) ///
        (line yhat_logit_full age, lwidth(medthick) lcolor(maroon)   lpattern(shortdash)), ///
        xlabel(20(10)60, nogrid) ///
        ylabel(0.70(0.05)0.95, nogrid format(%4.2f) angle(horizontal)) ///
        xtitle("Age (years)", size(medsmall)) ///
        ytitle("Predicted P(employed in April 2009)", size(medsmall)) ///
        title("Predicted Probability of Employment by Age", size(medium)) ///
        subtitle("Great Recession Sample, April 2008 {&rarr} April 2009", size(small)) ///
        legend(order(1 "LPM" 2 "Probit" 3 "Logit") rows(1) region(lcolor(none)) size(small)) ///
        graphregion(color(white)) plotregion(color(white) margin(medium)) ///
        xsize(7) ysize(4.5)
    graph export "../output/figures/prob1_predprob_age.pdf", replace as(pdf)
restore


* ==========================================================
*  PART (f)  --  FULL TABLE LIKE SW TABLE 11.2
*    Includes education, sex, race, marital status, region,
*    and April-2008 weekly earnings as additional controls.
* ==========================================================
*
*  Construction notes:
*   1. "Nonwhite" combines race categories 2 and 3 (Black,
*      Other) so that `white' (race==1) is the omitted group.
*   2. "West" region is the omitted reference for the four
*      regional dummies.
*   3. "educ_adv" (advanced degree) is the omitted reference
*      for the five education dummies in the regression to
*      avoid the dummy-variable trap.  The coefficient on
*      each remaining education dummy therefore measures the
*      shift in P(employed) relative to an advanced-degree
*      worker, holding all other covariates fixed.
*   4. Earnings are divided by 100 so the coefficient is
*      expressed per \$100 of April-2008 weekly earnings.

gen nonwhite = (race != 1)
    label var nonwhite "=1 if race != white"

gen earnwk_100 = earnwke / 100
    label var earnwk_100 "Weekly earnings, Apr. 2008 (per 100 USD)"

* LPM with full controls  (corresponds to column 1)
reg employed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, robust
estimates store lpm_full

* Probit with full controls (column 2)
probit employed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, vce(robust)
estimates store prob_full

* Logit with full controls (column 3)
logit employed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, vce(robust)
estimates store logit_full

* Export the three-column "Table 11.2"-style table
esttab lpm_full prob_full logit_full ///
    using "../output/tables/prob1_fullmodel.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    mtitles("LPM" "Probit" "Logit") ///
    title("Determinants of Employment Retention, April 2008 to April 2009\label{tab:prob1-full}") ///
    stats(N r2 r2_p ll, ///
        labels("Observations" "\$R^2\$" "Pseudo \$R^2\$" "Log-likelihood") ///
        fmt(%9.0fc %9.4f %9.4f %9.2f)) ///
    order(age age2 female nonwhite married union ///
          ne_states so_states ce_states ///
          educ_lths educ_hs educ_somecol educ_aa educ_bac ///
          earnwk_100 _cons) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses." ///
             "Omitted reference groups: white, western region, advanced degree.")


* ==========================================================
*  PART (g)  --  REPEAT USING Unemployed AS DEPENDENT VAR
* ==========================================================

reg unemployed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, robust
estimates store lpm_unemp

probit unemployed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, vce(robust)
estimates store prob_unemp

logit unemployed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, vce(robust)
estimates store logit_unemp

esttab lpm_unemp prob_unemp logit_unemp ///
    using "../output/tables/prob1_unemployed.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    mtitles("LPM" "Probit" "Logit") ///
    title("Determinants of Becoming Unemployed by April 2009\label{tab:prob1-unemp}") ///
    stats(N r2 r2_p ll, ///
        labels("Observations" "\$R^2\$" "Pseudo \$R^2\$" "Log-likelihood") ///
        fmt(%9.0fc %9.4f %9.4f %9.2f)) ///
    order(age age2 female nonwhite married union ///
          ne_states so_states ce_states ///
          educ_lths educ_hs educ_somecol educ_aa educ_bac ///
          earnwk_100 _cons) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses." ///
             "Dependent variable = 1 if unemployed in April 2009; =0 otherwise (including out-of-labor-force).")


* ==========================================================
*  PART (h)  --  NORMAL-TIMES COMPARISON WITH 2006-2007 DATA
* ==========================================================

use "../data/employment_06_07.dta", clear
gen age2       = age^2
    label var age2 "age squared"
gen nonwhite   = (race != 1)
    label var nonwhite "=1 if race != white"
gen earnwk_100 = earnwke/100
    label var earnwk_100 "Weekly earnings, Apr. 2006 (per 100 USD)"

* Sample proportion of workers still employed one year later
summarize employed, meanonly
scalar phat_06 = r(mean)
scalar se_06   = sqrt(phat_06*(1-phat_06)/_N)
scalar ci_lo06 = phat_06 - 1.96*se_06
scalar ci_hi06 = phat_06 + 1.96*se_06

display as text _newline "=== Part (h) -- 2006/2007 sample ==="
display as text "P(employed_07 | employed_06)  = " %6.4f phat_06
display as text "95% CI                         = [" %6.4f ci_lo06 ", " %6.4f ci_hi06 "]"

file open f_parth using "../output/tables/prob1_parth.tex", write replace
file write f_parth "\newcommand{\parthphat}{" %6.4f (phat_06) "}" _n
file write f_parth "\newcommand{\parthse}{"   %6.4f (se_06)   "}" _n
file write f_parth "\newcommand{\parthcilo}{" %6.4f (ci_lo06) "}" _n
file write f_parth "\newcommand{\parthcihi}{" %6.4f (ci_hi06) "}" _n
file write f_parth "\newcommand{\parthN}{"    %9.0fc (_N)      "}" _n
file close f_parth

* Full-controls specification on the normal-times sample
reg employed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, robust
estimates store lpm_06

probit employed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, vce(robust)
estimates store prob_06

logit employed age age2 female nonwhite married union ///
    ne_states so_states ce_states ///
    educ_lths educ_hs educ_somecol educ_aa educ_bac ///
    earnwk_100, vce(robust)
estimates store logit_06

esttab lpm_06 prob_06 logit_06 ///
    using "../output/tables/prob1_parth_models.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    mtitles("LPM" "Probit" "Logit") ///
    title("Determinants of Employment Retention, April 2006 to April 2007 (Normal Times)\label{tab:prob1-parth}") ///
    stats(N r2 r2_p ll, ///
        labels("Observations" "\$R^2\$" "Pseudo \$R^2\$" "Log-likelihood") ///
        fmt(%9.0fc %9.4f %9.4f %9.2f)) ///
    order(age age2 female nonwhite married union ///
          ne_states so_states ce_states ///
          educ_lths educ_hs educ_somecol educ_aa educ_bac ///
          earnwk_100 _cons) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses." ///
             "Sample: workers employed full-time in April 2006.")

* Comparative age-profile figure:  predicted P(employed) by
* age for the three models, overlaid for recession (2008/09)
* vs normal times (2006/07).  We re-fit each model in the
* simple age / age^2 form for a cleaner visualization.
preserve
    quietly reg employed c.age##c.age, robust
    predict yh_lpm_06, xb
    quietly probit employed c.age##c.age, vce(robust)
    predict yh_prob_06, pr
    quietly logit employed c.age##c.age, vce(robust)
    predict yh_logit_06, pr
    collapse (mean) yh_lpm_06 yh_prob_06 yh_logit_06, by(age)
    tempfile pred06
    save    `pred06'
restore

use "../data/employment_08_09.dta", clear
gen age2 = age^2
quietly reg employed c.age##c.age, robust
predict yh_lpm_08, xb
quietly probit employed c.age##c.age, vce(robust)
predict yh_prob_08, pr
quietly logit employed c.age##c.age, vce(robust)
predict yh_logit_08, pr
collapse (mean) yh_lpm_08 yh_prob_08 yh_logit_08, by(age)
merge 1:1 age using `pred06'
drop _merge

twoway ///
    (line yh_prob_06 age, lwidth(medthick) lcolor(navy) lpattern(solid)) ///
    (line yh_prob_08 age, lwidth(medthick) lcolor(maroon) lpattern(dash)), ///
    xlabel(20(10)60, nogrid) ///
    ylabel(0.70(0.05)0.95, nogrid format(%4.2f) angle(horizontal)) ///
    xtitle("Age (years)", size(medsmall)) ///
    ytitle("Predicted P(employed one year later)", size(medsmall)) ///
    title("Age Profile of Employment Retention: Recession vs Normal Times", size(medium)) ///
    subtitle("Probit estimates from the two CPS linked cross-sections", size(small)) ///
    legend(order(1 "April 2006 {&rarr} April 2007 (normal)" ///
                 2 "April 2008 {&rarr} April 2009 (recession)") ///
           rows(2) region(lcolor(none)) size(small)) ///
    graphregion(color(white)) plotregion(color(white) margin(medium)) ///
    xsize(7) ysize(4.5)
graph export "../output/figures/prob1_recession_vs_normal.pdf", replace as(pdf)


* ==========================================================
*  HOUSEKEEPING
* ==========================================================

display as text _newline "=== All Problem 1 outputs written ==="
log close
