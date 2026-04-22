* ============================================================
* ps6_problem2.do
* ECON UN3412 -- Homework 6
* Stock & Watson Empirical Exercise 11.2
*
* Dataset: Smoking.dta
*   10,000 U.S. indoor workers surveyed between 1991 and 1993
*
* Binary dependent variable:
*   smoker   = 1 if the worker is a current smoker
*
* Key regressor of interest:
*   smkban   = 1 if the worker's workplace has a smoking ban
*
* Additional controls used in parts (c)--(f):
*   female, age, age^2, hsdrop, hsgrad, colsome, colgrad,
*   black, hispanic.
*
* Outputs:
*   tables   ->  ../output/tables/prob2_*.tex
*   figures  ->  ../output/figures/prob2_*.pdf
*   log      ->  ps6_problem2.log
* ============================================================

clear all
set more off
capture log close
log using "ps6_problem2.log", replace text

set scheme s2mono
graph set window fontface "Times New Roman"

use "../data/Smoking.dta", clear

* Generate age squared (used starting in part c)
gen age2 = age^2
    label var age2 "age squared"


* ==========================================================
*  PART (a)  --  P(smoker) FOR:
*    (i)   all workers
*    (ii)  workers subject to a ban
*    (iii) workers not subject to a ban
* ==========================================================
*
*  The sample analogue of these probabilities is just the
*  sample mean of `smoker', overall and within each value
*  of `smkban'.  95% CIs (which we also record for the
*  write-up) use the Bernoulli formula
*      phat +/- 1.96 * sqrt(phat*(1-phat)/n_cell).

summarize smoker, meanonly
scalar pall   = r(mean)
scalar nall   = _N
scalar se_all = sqrt(pall*(1-pall)/nall)

summarize smoker if smkban==1, meanonly
scalar pban   = r(mean)
scalar nban   = r(N)
scalar se_ban = sqrt(pban*(1-pban)/nban)

summarize smoker if smkban==0, meanonly
scalar pnob   = r(mean)
scalar nnob   = r(N)
scalar se_nob = sqrt(pnob*(1-pnob)/nnob)

display as text _newline "=== Part (a) ==="
display as text "All workers          : P = " %6.4f pall  "  (SE " %6.4f se_all ", n = " %9.0fc nall ")"
display as text "With workplace ban   : P = " %6.4f pban  "  (SE " %6.4f se_ban ", n = " %9.0fc nban ")"
display as text "Without workplace ban: P = " %6.4f pnob  "  (SE " %6.4f se_nob ", n = " %9.0fc nnob ")"

file open f_parta using "../output/tables/prob2_parta.tex", write replace
file write f_parta "\newcommand{\pallmean}{" %6.4f (pall)   "}" _n
file write f_parta "\newcommand{\pallse}{"   %6.4f (se_all) "}" _n
file write f_parta "\newcommand{\pallN}{"    %9.0fc (nall)  "}" _n
file write f_parta "\newcommand{\pbanmean}{" %6.4f (pban)   "}" _n
file write f_parta "\newcommand{\pbanse}{"   %6.4f (se_ban) "}" _n
file write f_parta "\newcommand{\pbanN}{"    %9.0fc (nban)  "}" _n
file write f_parta "\newcommand{\pnobmean}{" %6.4f (pnob)   "}" _n
file write f_parta "\newcommand{\pnobse}{"   %6.4f (se_nob) "}" _n
file write f_parta "\newcommand{\pnobN}{"    %9.0fc (nnob)  "}" _n
file close f_parta


* ==========================================================
*  PART (b)  --  LPM:  smoker ON smkban ONLY
*    Tests whether the difference P(smoker|smkban=1) -
*    P(smoker|smkban=0) is statistically significant.
*    Because smkban is the only regressor, the OLS
*    coefficient equals exactly that difference in means.
* ==========================================================

reg smoker smkban, robust
estimates store lpm_simple

scalar beta_b = _b[smkban]
scalar se_b   = _se[smkban]
scalar t_b    = beta_b / se_b

display as text _newline "=== Part (b) -- LPM without controls ==="
display as text "beta_smkban (= difference in means) = " %8.4f beta_b
display as text "Robust SE                            = " %8.4f se_b
display as text "t-statistic                          = " %8.4f t_b


* ==========================================================
*  PART (c)  --  LPM WITH FULL CONTROL SET
* ==========================================================
*
*  Omitted education category:  college graduate (workers
*  with more than 16 years of schooling would be absorbed
*  by colgrad=1; `no high school' = hsdrop = 1 is the
*  lowest category).  To match SW's textbook table we drop
*  the omitted category implicitly by NOT including "some
*  high school / grad school" -- Stata picks the reference
*  automatically when there is collinearity.
*
*  Here we include hsdrop, hsgrad, colsome, colgrad.  The
*  omitted group is "master's or higher" (roughly 10% of
*  the sample; those not in any of the four dummies).

reg smoker smkban female age age2 hsdrop hsgrad colsome colgrad ///
    black hispanic, robust
estimates store lpm_full

scalar beta_c = _b[smkban]
scalar se_c   = _se[smkban]

display as text _newline "=== Part (c) -- LPM with full controls ==="
display as text "beta_smkban = " %8.4f beta_c "   SE = " %8.4f se_c


* ==========================================================
*  PART (d)  --  TEST H0: coef on smkban = 0 IN MODEL (c)
* ==========================================================

test smkban
scalar F_smk  = r(F)
scalar p_smk  = r(p)

display as text _newline "=== Part (d) -- Hypothesis test on smkban ==="
display as text "F(1, N-k-1) = " %8.4f F_smk "  p-value = " %6.4f p_smk


* ==========================================================
*  PART (e)  --  TEST JOINT SIGNIFICANCE OF EDUCATION DUMMIES
* ==========================================================
*
*  H0: beta_hsdrop = beta_hsgrad = beta_colsome = beta_colgrad = 0
*  i.e. P(smoker) does not depend on the level of education.
*
*  If we cannot reject, education has no explanatory power.
*  If we reject, the pattern of coefficients tells us how
*  P(smoker) varies with the education ladder.

test hsdrop hsgrad colsome colgrad
scalar F_educ_lpm = r(F)
scalar p_educ_lpm = r(p)

display as text _newline "=== Part (e) -- Joint F-test on education ==="
display as text "F(4, .) = " %8.4f F_educ_lpm "  p-value = " %6.4f p_educ_lpm


* ==========================================================
*  Consolidated LPM table for parts (b)--(e)
* ==========================================================

esttab lpm_simple lpm_full ///
    using "../output/tables/prob2_lpm.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    mtitles("LPM simple" "LPM full controls") ///
    title("Linear Probability Model of Smoking, Smoking.dta (n=10{,}000)\label{tab:prob2-lpm}") ///
    stats(N r2 r2_a, ///
        labels("Observations" "\$R^2\$" "Adjusted \$R^2\$") ///
        fmt(%9.0fc %9.4f %9.4f)) ///
    order(smkban female age age2 hsdrop hsgrad colsome colgrad ///
          black hispanic _cons) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses." ///
             "Omitted education category: advanced degree.")


* ==========================================================
*  PART (f)  --  REPEAT (c)--(e) WITH PROBIT
* ==========================================================

probit smoker smkban female age age2 hsdrop hsgrad colsome colgrad ///
    black hispanic, vce(robust)
estimates store probit_full

* Store pseudo-R2 and log-likelihood
scalar ll_prob = e(ll)
scalar r2p_prob = e(r2_p)

* (f, part c-analogue)  Average marginal effect of smkban
margins, dydx(smkban) post
scalar ame_smk_prob   = _b[smkban]
scalar ame_se_smk_prob = _se[smkban]

display as text _newline "=== Part (f) -- Probit ==="
display as text "AME of smkban (probit) = " %8.4f ame_smk_prob "  SE = " %8.4f ame_se_smk_prob

* Re-estimate probit for hypothesis tests
quietly probit smoker smkban female age age2 hsdrop hsgrad colsome colgrad ///
    black hispanic, vce(robust)

* (f, part d-analogue)  Test H0: coef on smkban = 0
* After -probit-, -test- returns the Wald chi2 statistic in
* r(chi2); r(F) is missing in that case.
test smkban
scalar chi2_smk_prob = r(chi2)
scalar p_smk_prob    = r(p)
display as text "Probit smkban test: chi2(1) = " %8.4f chi2_smk_prob ///
               "  p = " %6.4f p_smk_prob

* (f, part e-analogue)  Joint test on education dummies
test hsdrop hsgrad colsome colgrad
scalar chi2_educ_prob = r(chi2)
scalar p_educ_prob    = r(p)
display as text "Probit joint education test: chi2(4) = " %8.4f chi2_educ_prob ///
               "  p = " %6.4f p_educ_prob

* Export probit table alongside LPM (c) for side-by-side comparison
esttab lpm_full probit_full ///
    using "../output/tables/prob2_lpm_vs_probit.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    mtitles("LPM" "Probit") ///
    title("LPM vs Probit: Determinants of Smoking\label{tab:prob2-vs}") ///
    stats(N r2 r2_p ll, ///
        labels("Observations" "\$R^2\$" "Pseudo \$R^2\$" "Log-likelihood") ///
        fmt(%9.0fc %9.4f %9.4f %9.2f)) ///
    order(smkban female age age2 hsdrop hsgrad colsome colgrad ///
          black hispanic _cons) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses." ///
             "Probit coefficients are index coefficients, NOT marginal effects.")


* ==========================================================
*  FIGURE:  Predicted P(smoker) by education category
*           Compares LPM and probit to visualize how they
*           differ when the probability is in the interior.
* ==========================================================

* Create a synthetic "representative" worker at the sample
* means of continuous vars (age, age2, female, black, hispanic)
* and evaluate P(smoker) by swapping the education dummy.
preserve
    * Build dataset with one row per education level
    clear
    set obs 5
    gen educlvl_num = _n
    * 1 = master's (omitted, all edu dummies = 0)
    * 2 = college grad
    * 3 = some college
    * 4 = high school grad
    * 5 = high school dropout
    gen str10 educlvl = ""
    replace educlvl = "Master+"  if educlvl_num == 1
    replace educlvl = "BA"       if educlvl_num == 2
    replace educlvl = "SomeColl" if educlvl_num == 3
    replace educlvl = "HSgrad"   if educlvl_num == 4
    replace educlvl = "HSdrop"   if educlvl_num == 5
    gen hsdrop  = (educlvl_num == 5)
    gen hsgrad  = (educlvl_num == 4)
    gen colsome = (educlvl_num == 3)
    gen colgrad = (educlvl_num == 2)

    * Sample means pulled from full dataset (hard-coded from
    * summarize output above to avoid re-loading)
    gen smkban   = 0.6098
    gen female   = 0.5637
    gen age      = 38.6932
    gen age2     = 38.6932^2
    gen black    = 0.0769
    gen hispanic = 0.1134

    * Predicted P from LPM
    estimates restore lpm_full
    predict phat_lpm, xb

    * Predicted P from probit
    estimates restore probit_full
    predict phat_prob, pr

    list educlvl phat_lpm phat_prob, sepby(educlvl_num)

    * Plot:  simple side-by-side bar chart
    graph bar phat_lpm phat_prob, ///
        over(educlvl, sort(educlvl_num) label(labsize(small))) ///
        bar(1, color(navy)) bar(2, color(maroon)) ///
        ylabel(0(0.05)0.40, angle(horizontal) nogrid format(%4.2f)) ///
        ytitle("Predicted P(smoker)", size(medsmall)) ///
        title("Predicted Probability of Smoking by Education", size(medium)) ///
        subtitle("Evaluated at sample means of age, female, race, smkban", size(small)) ///
        legend(order(1 "LPM" 2 "Probit") rows(1) region(lcolor(none)) size(small)) ///
        graphregion(color(white)) plotregion(color(white)) ///
        xsize(7) ysize(4.5)
    graph export "../output/figures/prob2_predprob_educ.pdf", replace as(pdf)
restore


* ==========================================================
*  HOUSEKEEPING
* ==========================================================

* Write out a small LaTeX fragment with the hypothesis-test
* numbers from (d) and (e) for clean inclusion in the write-up.
file open f_tests using "../output/tables/prob2_tests.tex", write replace
file write f_tests "\newcommand{\smkbanbeta}{"   %7.4f (beta_c) "}"      _n
file write f_tests "\newcommand{\smkbanse}{"     %7.4f (se_c)   "}"      _n
file write f_tests "\newcommand{\smkbanF}{"      %7.3f (F_smk)  "}"      _n
file write f_tests "\newcommand{\smkbanp}{"      %6.4f (p_smk)  "}"      _n
file write f_tests "\newcommand{\educF}{"        %7.3f (F_educ_lpm) "}"  _n
file write f_tests "\newcommand{\educp}{"        %6.4f (p_educ_lpm) "}"  _n
file write f_tests "\newcommand{\educFprob}{"    %7.3f (chi2_educ_prob) "}" _n
file write f_tests "\newcommand{\educpprob}{"    %6.4f (p_educ_prob) "}" _n
file write f_tests "\newcommand{\smkchisqprob}{" %7.3f (chi2_smk_prob) "}" _n
file write f_tests "\newcommand{\smkpprob}{"     %6.4f (p_smk_prob) "}"   _n
file write f_tests "\newcommand{\amesmkprob}{"   %7.4f (ame_smk_prob) "}" _n
file write f_tests "\newcommand{\amesmksprob}{"  %7.4f (ame_se_smk_prob) "}" _n
file close f_tests

display as text _newline "=== All Problem 2 outputs written ==="
log close
