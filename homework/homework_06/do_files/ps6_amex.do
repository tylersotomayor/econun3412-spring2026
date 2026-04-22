* ============================================================
* ps6_amex.do
* ECON UN3412 -- Homework 6, Problem 1 (graded)
* AMERICAN EXPRESS CREDIT-CARD APPLICANTS  (AmEx.dta)
*
* Scope:
*   Solves parts (a)--(n).  Produces six regression specifications
*   (LPM, probit, logit)  x  (reduced, full-with-drg controls),
*   marginal-effect tables at the median (part c) and the 20/80
*   income percentiles (part d), log-odds summaries (part e),
*   fitted-value histograms (parts k--l), and out-of-support
*   diagnostics for the LPM (part l).
*
* Outputs:
*   tables  ->  ../output/tables/prob1_amex_*.tex
*   figures ->  ../output/figures/prob1_amex_*.pdf
*   log     ->  ps6_amex.log
*
* Conventions:
*   - Dependent variable: cardhldr (1 = approved).
*   - "inc" is income/1000 (so coefficients are per $1,000).
*   - Reduced model: inc age selfempl ownrent acadmos
*   - Full model:    reduced + majordrg + minordrg
*   - All variance estimates are Huber--White (vce(robust)).
* ============================================================

clear all
set more off
capture log close
log using "ps6_amex.log", replace text

set scheme s2mono
graph set window fontface "Times New Roman"


* ==========================================================
*  Load data and apply preprocessing from Part (a)
* ==========================================================

use "../data/AmEx.dta", clear

keep cardhldr income age selfempl ownrent acadmos majordrg minordrg

* Rescale income (per $1,000) so coefficients are interpretable
replace income = income/1000
rename income inc
label var inc       "Income (\\\$1,000s)"
label var age       "Age (years)"
label var selfempl  "Self-employed = 1"
label var ownrent   "Own residence = 1"
label var acadmos   "Months at current address"
label var majordrg  "Major derogatory events (12 mo)"
label var minordrg  "Minor derogatory events (12 mo)"
label var cardhldr  "Approved cardholder = 1"


* ==========================================================
*  PART (a)  --  Fraction of cardholders
* ==========================================================

display as text _newline "=== Part (a): tabulate cardhldr ==="
tabulate cardhldr

summarize cardhldr, meanonly
scalar phat_a = r(mean)
scalar n_a    = r(N)
display as text "Fraction of sample approved: " %6.4f phat_a  "  (n = " %9.0fc n_a ")"


* ==========================================================
*  PART (b)  --  Reduced-form LPM / Logit / Probit
* ==========================================================

display as text _newline "=== Part (b): LPM / logit / probit (reduced) ==="

reg    cardhldr inc age selfempl ownrent acadmos, robust
estimates store lpm_red

logit  cardhldr inc age selfempl ownrent acadmos, vce(robust)
estimates store log_red

probit cardhldr inc age selfempl ownrent acadmos, vce(robust)
estimates store prob_red


* ==========================================================
*  Pre-compute the median and quantile values we will need
*  downstream for parts (c)--(e).
* ==========================================================

foreach v in inc age acadmos {
    quietly summarize `v', detail
    scalar med_`v' = r(p50)
}
display as text "Medians used:  inc=" %5.2f med_inc ///
                "  age=" %5.2f med_age ///
                "  acadmos=" %5.2f med_acadmos

centile inc, centile(20 50 80)
scalar inc_p20 = r(c_1)
scalar inc_p50 = r(c_2)
scalar inc_p80 = r(c_3)
display as text "Income percentiles (\$1,000s):  p20=" %6.2f inc_p20 ///
                "  p50=" %6.2f inc_p50 "  p80=" %6.2f inc_p80


* ==========================================================
*  Helper: compute predicted probabilities at two scenarios
*  (dummy d = 0 and d = 1) holding other vars fixed, and
*  return the four scalars P0, P1, Delta, %Delta by assigning
*  to global macros of the user's choice.
* ==========================================================

capture program drop _me
program define _me
    syntax, MODel(string) DUMmy(string) OTHer(string) ///
            INC(real) AGE(real) ACADmos(real) TAG(string)
    * Other dummy held at 0 in both scenarios; dummy varies 0->1.
    quietly estimates restore `model'
    quietly margins, at(inc=`inc' age=`age' acadmos=`acadmos' ///
                        `other'=0 `dummy'=(0 1)) post
    matrix B_ = e(b)
    scalar `tag'_P0    = B_[1,1]
    scalar `tag'_P1    = B_[1,2]
    scalar `tag'_D     = B_[1,2] - B_[1,1]
    scalar `tag'_PCT   = (B_[1,2] - B_[1,1]) / B_[1,1]
    display as text "  `model'  (`dummy' 0->1):  P0=" %6.4f `tag'_P0 ///
                    "  P1=" %6.4f `tag'_P1 ///
                    "  D=" %7.4f `tag'_D ///
                    "  %D=" %7.4f `tag'_PCT
end


* ==========================================================
*  PART (c)  --  MEs at median X
* ==========================================================

display as text _newline "=== Part (c): MEs at median X ==="

* (income, age, acadmos) at medians.  "dummy" varies 0->1;
* "otherdummy" held at 0 in both scenarios.
foreach mod in lpm_red prob_red log_red {
    _me, model(`mod') dummy(selfempl) other(ownrent) ///
         inc(`=med_inc') age(`=med_age') acadmos(`=med_acadmos') tag(c50s_`mod')
    _me, model(`mod') dummy(ownrent) other(selfempl) ///
         inc(`=med_inc') age(`=med_age') acadmos(`=med_acadmos') tag(c50o_`mod')
}


* ==========================================================
*  PART (d)  --  MEs at income p20 and p80 (age, acadmos
*                still at medians).
* ==========================================================

display as text _newline "=== Part (d): MEs at income p20 and p80 ==="

foreach mod in lpm_red prob_red log_red {
    _me, model(`mod') dummy(selfempl) other(ownrent) ///
         inc(`=inc_p20') age(`=med_age') acadmos(`=med_acadmos') tag(c20s_`mod')
    _me, model(`mod') dummy(ownrent) other(selfempl) ///
         inc(`=inc_p20') age(`=med_age') acadmos(`=med_acadmos') tag(c20o_`mod')
    _me, model(`mod') dummy(selfempl) other(ownrent) ///
         inc(`=inc_p80') age(`=med_age') acadmos(`=med_acadmos') tag(c80s_`mod')
    _me, model(`mod') dummy(ownrent) other(selfempl) ///
         inc(`=inc_p80') age(`=med_age') acadmos(`=med_acadmos') tag(c80o_`mod')
}


* ==========================================================
*  Export combined (c)+(d) LaTeX table
* ==========================================================

file open fme using "../output/tables/prob1_amex_me.tex", write replace
file write fme "\begin{table}[H]" _n
file write fme "\centering" _n
file write fme "\caption{Marginal Effects on $\Pr(\text{cardhldr}=1)$ of \texttt{selfempl} and \texttt{ownrent}, by Income Level (reduced model)\label{tab:prob1-me}}" _n
file write fme "\begin{tabular}{l ccc ccc}" _n
file write fme "\toprule" _n
file write fme " & \multicolumn{3}{c}{Absolute change $\Delta\hat{P}$} & \multicolumn{3}{c}{Percent change $\%\Delta\hat{P}$} \\" _n
file write fme "\cmidrule(lr){2-4}\cmidrule(lr){5-7}" _n
file write fme "Income level & LPM & Probit & Logit & LPM & Probit & Logit \\" _n
file write fme "\midrule" _n
file write fme "\multicolumn{7}{l}{\emph{$\Delta$\texttt{selfempl} (switch from 0 to 1; \texttt{ownrent}=0, rest at medians)}} \\" _n
file write fme "20\% income (\\$"  %5.2f (inc_p20) "k) " ///
    " & " %7.4f (c20s_lpm_red_D)  " & " %7.4f (c20s_prob_red_D) " & " %7.4f (c20s_log_red_D)  ///
    " & " %7.4f (c20s_lpm_red_PCT)  " & " %7.4f (c20s_prob_red_PCT) " & " %7.4f (c20s_log_red_PCT) " \\" _n
file write fme "50\% income (\\$"  %5.2f (med_inc) "k) " ///
    " & " %7.4f (c50s_lpm_red_D)  " & " %7.4f (c50s_prob_red_D) " & " %7.4f (c50s_log_red_D)   ///
    " & " %7.4f (c50s_lpm_red_PCT)  " & " %7.4f (c50s_prob_red_PCT) " & " %7.4f (c50s_log_red_PCT)  " \\" _n
file write fme "80\% income (\\$"  %5.2f (inc_p80) "k) " ///
    " & " %7.4f (c80s_lpm_red_D)  " & " %7.4f (c80s_prob_red_D) " & " %7.4f (c80s_log_red_D)  ///
    " & " %7.4f (c80s_lpm_red_PCT)  " & " %7.4f (c80s_prob_red_PCT) " & " %7.4f (c80s_log_red_PCT) " \\" _n
file write fme "\midrule" _n
file write fme "\multicolumn{7}{l}{\emph{$\Delta$\texttt{ownrent} (switch from 0 to 1; \texttt{selfempl}=0, rest at medians)}} \\" _n
file write fme "20\% income (\\$"  %5.2f (inc_p20) "k) " ///
    " & " %7.4f (c20o_lpm_red_D)  " & " %7.4f (c20o_prob_red_D) " & " %7.4f (c20o_log_red_D)  ///
    " & " %7.4f (c20o_lpm_red_PCT)  " & " %7.4f (c20o_prob_red_PCT) " & " %7.4f (c20o_log_red_PCT) " \\" _n
file write fme "50\% income (\\$"  %5.2f (med_inc) "k) " ///
    " & " %7.4f (c50o_lpm_red_D)  " & " %7.4f (c50o_prob_red_D) " & " %7.4f (c50o_log_red_D)   ///
    " & " %7.4f (c50o_lpm_red_PCT)  " & " %7.4f (c50o_prob_red_PCT) " & " %7.4f (c50o_log_red_PCT)  " \\" _n
file write fme "80\% income (\\$"  %5.2f (inc_p80) "k) " ///
    " & " %7.4f (c80o_lpm_red_D)  " & " %7.4f (c80o_prob_red_D) " & " %7.4f (c80o_log_red_D)  ///
    " & " %7.4f (c80o_lpm_red_PCT)  " & " %7.4f (c80o_prob_red_PCT) " & " %7.4f (c80o_log_red_PCT) " \\" _n
file write fme "\bottomrule" _n
file write fme "\end{tabular}" _n
file write fme `"\parbox{0.95\textwidth}{\footnotesize \emph{Notes.}"' _n
file write fme `" Other continuous covariates (\texttt{age}, \texttt{acadmos}) are held at their sample medians."' _n
file write fme `" Marginal effects are discrete differences in predicted probability from switching the indicator from 0 to 1."' _n
file write fme `" Percent changes are $\Delta\hat{P}/\hat{P}_{0}$."' _n
file write fme `"}"' _n
file write fme "\end{table}" _n
file close fme


* ==========================================================
*  PART (e)  --  Log-odds summary
*  Delta_logodds  =  logit(P1) - logit(P0)
*  For the logit model this quantity equals the dummy's
*  coefficient regardless of other X's, which is the
*  definition of the odds-ratio interpretation of logit.
* ==========================================================

display as text _newline "=== Part (e): change in log-odds ==="

* compute logit(P1) - logit(P0)  for each (income level, dummy, model)
* using the scalars saved in parts (c) and (d).

file open flo using "../output/tables/prob1_amex_logodds.tex", write replace
file write flo "\begin{table}[H]" _n
file write flo "\centering" _n
file write flo "\caption{Change in Log-Odds of Approval, $\Delta\log[P/(1-P)]$, Across Income Levels\label{tab:prob1-logodds}}" _n
file write flo "\begin{tabular}{l l ccc}" _n
file write flo "\toprule" _n
file write flo "Change & Income level & LPM & Probit & Logit \\" _n
file write flo "\midrule" _n

foreach dcode in s o {
    local dname = cond("`dcode'"=="s", "selfempl", "ownrent")
    file write flo "\multicolumn{5}{l}{\emph{$\Delta\log\frac{P}{1-P}$ for switching \texttt{`dname'} from 0 to 1}} \\" _n
    foreach q in 20 50 80 {
        local qkey = cond("`q'"=="50", "c50", "c`q'")
        local qlabel = cond("`q'"=="50", "median", "`q'\%")
        foreach m in lpm_red prob_red log_red {
            * avoid log(0) or log(1); both endpoints of fitted probs
            * are safely inside (0,1) in practice.
            scalar _p0 = `qkey'`dcode'_`m'_P0
            scalar _p1 = `qkey'`dcode'_`m'_P1
            scalar _dlo_`m' = ln(_p1/(1-_p1)) - ln(_p0/(1-_p0))
        }
        file write flo " & `qlabel' " ///
            " & " %7.4f (_dlo_lpm_red) ///
            " & " %7.4f (_dlo_prob_red) ///
            " & " %7.4f (_dlo_log_red) " \\" _n
    }
    file write flo "\midrule" _n
}
file write flo "\bottomrule" _n
file write flo "\end{tabular}" _n
file write flo `"\parbox{0.9\textwidth}{\footnotesize \emph{Notes.} For the logit model these values should equal the dummy's regression coefficient (invariant to income); small departures reflect rounding.}"' _n
file write flo "\end{table}" _n
file close flo


* ==========================================================
*  PART (f)  --  Add majordrg and minordrg to the spec.
* ==========================================================

display as text _newline "=== Part (f): LPM/logit/probit with derogatory events ==="

reg    cardhldr inc age selfempl ownrent acadmos majordrg minordrg, robust
estimates store lpm_full

logit  cardhldr inc age selfempl ownrent acadmos majordrg minordrg, vce(robust)
estimates store log_full

probit cardhldr inc age selfempl ownrent acadmos majordrg minordrg, vce(robust)
estimates store prob_full


* ==========================================================
*  PART (g)  --  Full 6-column table
* ==========================================================

esttab lpm_red prob_red log_red lpm_full prob_full log_full ///
    using "../output/tables/prob1_amex_six.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    mtitles("LPM"    "Probit"  "Logit"   ///
            "LPM+drg" "Probit+drg" "Logit+drg") ///
    title("Determinants of Being an AmEx Cardholder (Problem~1 Table)\label{tab:prob1-six}") ///
    stats(N r2 r2_a r2_p ll, ///
        labels("Observations" "\$R^2\$" "Adjusted \$R^2\$" "Pseudo \$R^2\$" "Log-likelihood") ///
        fmt(%9.0fc %9.4f %9.4f %9.4f %9.2f)) ///
    order(inc age selfempl ownrent acadmos majordrg minordrg _cons) ///
    addnotes("Heteroskedasticity-robust standard errors in parentheses." ///
             "Stars: *p<0.10, **p<0.05, ***p<0.01." ///
             "Dependent variable: cardhldr = 1 if applicant approved as cardholder.")


* ==========================================================
*  PART (i)  --  95% CI for LPM coefficient on majordrg
* ==========================================================

estimates restore lpm_full
matrix Bf = e(b)
matrix Vf = e(V)
scalar b_major   = Bf[1,"majordrg"]
scalar se_major  = sqrt(Vf["majordrg","majordrg"])
scalar ci_lo_maj = b_major - 1.96*se_major
scalar ci_hi_maj = b_major + 1.96*se_major

display as text _newline "=== Part (i): 95% CI for LPM majordrg ==="
display as text "beta = " %7.4f b_major "  SE = " %7.4f se_major ///
                "  95% CI = [" %7.4f ci_lo_maj ", " %7.4f ci_hi_maj "]"


* ==========================================================
*  PART (j)  --  Probit / logit marginal effect of majordrg
*                at median covariates
* ==========================================================

display as text _newline "=== Part (j): ME of majordrg at medians (probit, logit) ==="

quietly summarize majordrg, detail
scalar med_major = r(p50)
quietly summarize minordrg, detail
scalar med_minor = r(p50)

* probit
estimates restore prob_full
margins, dydx(majordrg) ///
         at(inc=`=med_inc' age=`=med_age' selfempl=0 ownrent=0 ///
            acadmos=`=med_acadmos' majordrg=`=med_major' minordrg=`=med_minor')
matrix M = r(table)
scalar dy_prob  = M[1, 1]
scalar se_prob  = M[2, 1]
scalar lo_prob  = M[5, 1]
scalar hi_prob  = M[6, 1]
display as text "Probit dy/dmajordrg = " %7.4f dy_prob ///
                "  SE = " %7.4f se_prob ///
                "  95% CI = [" %7.4f lo_prob ", " %7.4f hi_prob "]"

* logit
estimates restore log_full
margins, dydx(majordrg) ///
         at(inc=`=med_inc' age=`=med_age' selfempl=0 ownrent=0 ///
            acadmos=`=med_acadmos' majordrg=`=med_major' minordrg=`=med_minor')
matrix M = r(table)
scalar dy_log  = M[1, 1]
scalar se_log  = M[2, 1]
scalar lo_log  = M[5, 1]
scalar hi_log  = M[6, 1]
display as text "Logit  dy/dmajordrg = " %7.4f dy_log ///
                "  SE = " %7.4f se_log ///
                "  95% CI = [" %7.4f lo_log ", " %7.4f hi_log "]"


file open fci using "../output/tables/prob1_amex_cis.tex", write replace
file write fci "% auto-generated CI macros (parts i and j)" _n
file write fci "\newcommand{\amexLPMbetamaj}{"  %7.4f (b_major)   "}" _n
file write fci "\newcommand{\amexLPMsemaj}{"    %7.4f (se_major)  "}" _n
file write fci "\newcommand{\amexLPMcilomaj}{"  %7.4f (ci_lo_maj) "}" _n
file write fci "\newcommand{\amexLPMcihimaj}{"  %7.4f (ci_hi_maj) "}" _n
file write fci "\newcommand{\amexPROBmedmaj}{"  %7.4f (dy_prob)   "}" _n
file write fci "\newcommand{\amexPROBsemaj}{"   %7.4f (se_prob)   "}" _n
file write fci "\newcommand{\amexPROBcilo}{"    %7.4f (lo_prob)   "}" _n
file write fci "\newcommand{\amexPROBcihi}{"    %7.4f (hi_prob)   "}" _n
file write fci "\newcommand{\amexLOGmedmaj}{"   %7.4f (dy_log)    "}" _n
file write fci "\newcommand{\amexLOGsemaj}{"    %7.4f (se_log)    "}" _n
file write fci "\newcommand{\amexLOGcilo}{"     %7.4f (lo_log)    "}" _n
file write fci "\newcommand{\amexLOGcihi}{"     %7.4f (hi_log)    "}" _n
file close fci


* ==========================================================
*  PART (k)  --  Histograms of fitted Y-values
*  PART (l)  --  Out-of-range diagnostics for LPM
* ==========================================================

display as text _newline "=== Part (k): fitted-value histograms ==="

preserve
    quietly reg    cardhldr inc age selfempl ownrent acadmos majordrg minordrg, robust
    predict yhat_lpm, xb
    quietly probit cardhldr inc age selfempl ownrent acadmos majordrg minordrg, vce(robust)
    predict yhat_prob, pr
    quietly logit  cardhldr inc age selfempl ownrent acadmos majordrg minordrg, vce(robust)
    predict yhat_log, pr

    twoway (histogram yhat_lpm, width(0.02) fcolor(gs12) lcolor(black)), ///
        xtitle("Fitted P(cardhldr=1)", size(medsmall)) ///
        ytitle("Density", size(medsmall)) ///
        title("LPM", size(medium)) ///
        xlabel(-0.25(0.25)1.25, nogrid) ///
        xline(0, lcolor(gs8) lpattern(dash)) ///
        xline(1, lcolor(gs8) lpattern(dash)) ///
        graphregion(color(white)) plotregion(color(white)) name(h_lpm, replace) nodraw

    twoway (histogram yhat_prob, width(0.02) fcolor(gs12) lcolor(black)), ///
        xtitle("Fitted P(cardhldr=1)", size(medsmall)) ///
        ytitle("", size(medsmall)) ///
        title("Probit", size(medium)) ///
        xlabel(0(0.25)1, nogrid) ///
        graphregion(color(white)) plotregion(color(white)) name(h_prob, replace) nodraw

    twoway (histogram yhat_log, width(0.02) fcolor(gs12) lcolor(black)), ///
        xtitle("Fitted P(cardhldr=1)", size(medsmall)) ///
        ytitle("", size(medsmall)) ///
        title("Logit", size(medium)) ///
        xlabel(0(0.25)1, nogrid) ///
        graphregion(color(white)) plotregion(color(white)) name(h_log, replace) nodraw

    graph combine h_lpm h_prob h_log, rows(1) ///
        graphregion(color(white)) ///
        title("Fitted-Value Histograms Across Models", size(medium)) ///
        note("Dashed lines at 0 and 1 bound the legitimate probability domain for the LPM.", size(vsmall))
    graph export "../output/figures/prob1_amex_fitted_hist.pdf", replace as(pdf)

    * ---- Part (l): LPM out-of-range diagnostics
    gen out_lo  = (yhat_lpm < 0)
    gen out_hi  = (yhat_lpm > 1)
    gen out_any = out_lo | out_hi

    summarize out_lo,  meanonly
    scalar lpm_below = r(mean)
    summarize out_hi,  meanonly
    scalar lpm_above = r(mean)
    summarize out_any, meanonly
    scalar lpm_outside = r(mean)
    quietly summarize yhat_lpm
    scalar lpm_min = r(min)
    scalar lpm_max = r(max)

    display as text "=== Part (l): LPM support diagnostics ==="
    display as text "  fitted-value min/max:        [" %6.4f lpm_min ", " %6.4f lpm_max "]"
    display as text "  fraction below 0           = " %6.4f lpm_below
    display as text "  fraction above 1           = " %6.4f lpm_above
    display as text "  fraction outside [0,1]     = " %6.4f lpm_outside
restore

file open fll using "../output/tables/prob1_amex_lpm_oor.tex", write replace
file write fll "% LPM out-of-range diagnostics (part l)" _n
file write fll "\newcommand{\amexLPMmin}{"       %6.4f (lpm_min)     "}" _n
file write fll "\newcommand{\amexLPMmax}{"       %6.4f (lpm_max)     "}" _n
file write fll "\newcommand{\amexLPMpctbelow}{"  %6.4f (lpm_below)   "}" _n
file write fll "\newcommand{\amexLPMpctabove}{"  %6.4f (lpm_above)   "}" _n
file write fll "\newcommand{\amexLPMpctout}{"    %6.4f (lpm_outside) "}" _n
file close fll


* ==========================================================
*  Average partial effects (APE) of majordrg, probit & logit.
*  These are referenced in the reflection for part (j) and in
*  the comparison prose in part (m).  The LPM coefficient is
*  already stored above in b_major (scalar).
* ==========================================================

display as text _newline "=== APE of majordrg (probit, logit) ==="

estimates restore prob_full
margins, dydx(majordrg)
matrix M = r(table)
scalar ape_prob_maj = M[1, 1]
scalar ape_prob_se  = M[2, 1]

estimates restore log_full
margins, dydx(majordrg)
matrix M = r(table)
scalar ape_log_maj = M[1, 1]
scalar ape_log_se  = M[2, 1]

display as text "LPM beta        = " %7.4f b_major
display as text "Probit APE      = " %7.4f ape_prob_maj " (SE " %6.4f ape_prob_se ")"
display as text "Logit  APE      = " %7.4f ape_log_maj  " (SE " %6.4f ape_log_se  ")"

file open fap using "../output/tables/prob1_amex_apes.tex", write replace
file write fap "% APEs for majordrg (reflection after part j, prose in part m)" _n
file write fap "\newcommand{\amexAPEprob}{"    %7.4f (ape_prob_maj) "}" _n
file write fap "\newcommand{\amexAPEprobSE}{"  %7.4f (ape_prob_se)  "}" _n
file write fap "\newcommand{\amexAPElog}{"     %7.4f (ape_log_maj)  "}" _n
file write fap "\newcommand{\amexAPElogSE}{"   %7.4f (ape_log_se)   "}" _n
file close fap


* ==========================================================
*  PART (n)  --  Amemiya rule of thumb for majordrg
*  beta_LPM   ~=  0.4 * beta_probit
*  beta_LPM   ~=  0.25 * beta_logit
* ==========================================================

display as text _newline "=== Part (n): Amemiya rule for majordrg ==="

estimates restore lpm_full
scalar b_lpm_maj  = _b[majordrg]
estimates restore prob_full
scalar b_prob_maj = _b[majordrg]
estimates restore log_full
scalar b_log_maj  = _b[majordrg]

scalar approx_prob = 0.4  * b_prob_maj
scalar approx_log  = 0.25 * b_log_maj
scalar ratio_prob  = b_lpm_maj / b_prob_maj
scalar ratio_log   = b_lpm_maj / b_log_maj

display as text "beta_LPM(majordrg)      = " %7.4f b_lpm_maj
display as text "beta_probit(majordrg)   = " %7.4f b_prob_maj
display as text "beta_logit(majordrg)    = " %7.4f b_log_maj
display as text "0.4 * beta_probit       = " %7.4f approx_prob
display as text "0.25 * beta_logit       = " %7.4f approx_log
display as text "beta_LPM / beta_probit  = " %7.4f ratio_prob  "   (rule-of-thumb 0.40)"
display as text "beta_LPM / beta_logit   = " %7.4f ratio_log   "   (rule-of-thumb 0.25)"

file open fam using "../output/tables/prob1_amex_amemiya.tex", write replace
file write fam "% Amemiya rule check (part n)" _n
file write fam "\newcommand{\amexBLPMmaj}{"     %7.4f (b_lpm_maj)   "}" _n
file write fam "\newcommand{\amexBPROBmaj}{"    %7.4f (b_prob_maj)  "}" _n
file write fam "\newcommand{\amexBLOGmaj}{"     %7.4f (b_log_maj)   "}" _n
file write fam "\newcommand{\amexApproxPROB}{"  %7.4f (approx_prob) "}" _n
file write fam "\newcommand{\amexApproxLOG}{"   %7.4f (approx_log)  "}" _n
file write fam "\newcommand{\amexRatioPROB}{"   %7.4f (ratio_prob)  "}" _n
file write fam "\newcommand{\amexRatioLOG}{"    %7.4f (ratio_log)   "}" _n
file close fam


* ==========================================================
*  Macros we also need for the main text (part a and (b))
* ==========================================================

file open fa using "../output/tables/prob1_amex_parta.tex", write replace
file write fa "% auto-generated macros for part (a)" _n
file write fa "\newcommand{\amexPhat}{" %6.4f (phat_a) "}" _n
file write fa "\newcommand{\amexN}{"    %9.0fc (n_a)    "}" _n
file write fa "\newcommand{\amexIncMed}{"   %5.2f (med_inc)     "}" _n
file write fa "\newcommand{\amexIncP}{"     %5.2f (inc_p20)     "}" _n
file write fa "\newcommand{\amexIncQ}{"     %5.2f (inc_p80)     "}" _n
file write fa "\newcommand{\amexAgeMed}{"   %5.2f (med_age)     "}" _n
file write fa "\newcommand{\amexAcadMed}{"  %5.2f (med_acadmos) "}" _n
file close fa


* ==========================================================
*  Housekeeping
* ==========================================================
display as text _newline "=== All AMEX outputs written ==="
log close
