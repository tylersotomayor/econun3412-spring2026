*==============================================================
* ps7_ajr.do
* Replication of Acemoglu, Johnson, and Robinson (2001) Table 4
* ECON UN3412 -- Problem Set 7 -- Problem 1 (a)--(g)
*
* Re-runs all nine columns of AJR (2001) Table 4 with
* vce(robust), stores every coefficient and SE, and writes
* LaTeX-ready tables plus \newcommand macros to
*   output/tables/
*==============================================================

clear all
set more off
capture log close
cd "/Users/tylersotomayor/columbia_university/2025-2026/spring_2026/econ_3412_spring_2026/homework/homework_07"
log using "do_files/ps7_ajr.log", replace text

use "data/maketable4.dta", clear

*--------------------------------------------------------------
* Part (a): preliminary step -- restrict to base sample
*--------------------------------------------------------------
keep if baseco == 1
count  // should equal 64

* Build the "other continent" indicator for (d).
gen byte othercont = 0
replace othercont = 1 if inlist(shortnam, "AUS", "NZL", "MLT")
label var othercont "1 if AUS, NZL, or MLT (other continent)"

*--------------------------------------------------------------
* PROGRAM: save_tsls -- capture 1st-stage and 2nd-stage
* coefficients and robust SEs for one ivregress 2sls call.
* Arguments: #1 = column tag (e.g., "c1"); remaining = model spec.
*--------------------------------------------------------------
capture program drop save_tsls
program define save_tsls
    args tag yvar xvar zvar wvars ifclause
    if "`ifclause'" == "" {
        ivregress 2sls `yvar' `wvars' (`xvar' = `zvar'), vce(robust) first
    }
    else {
        ivregress 2sls `yvar' `wvars' (`xvar' = `zvar') `ifclause', vce(robust) first
    }
    * second-stage coefficients
    scalar b2_`tag' = _b[`xvar']
    scalar se2_`tag' = _se[`xvar']
    scalar N_`tag'   = e(N)
    foreach w of local wvars {
        scalar bw_`tag'_`w' = _b[`w']
        scalar sew_`tag'_`w' = _se[`w']
    }
    * first-stage coefficient on instrument(s)
    estat firststage, forcenonrobust
    mat FS = r(singleresults)
    * Instead, rerun the first stage OLS manually w/ robust SEs to grab coefficients on z and w's
    if "`ifclause'" == "" {
        reg `xvar' `zvar' `wvars', vce(robust)
    }
    else {
        reg `xvar' `zvar' `wvars' `ifclause', vce(robust)
    }
    scalar b1_`tag' = _b[`zvar']
    scalar se1_`tag' = _se[`zvar']
    scalar r2_`tag'  = e(r2)
    foreach w of local wvars {
        scalar b1w_`tag'_`w' = _b[`w']
        scalar se1w_`tag'_`w' = _se[`w']
    }
end

*==============================================================
* Column 1: base sample, no controls
*==============================================================
display _newline _dup(60) "="
display "COLUMN 1: Base sample, no controls"
display _dup(60) "="
ivregress 2sls logpgp95 (avexpr = logem4), vce(robust) first
scalar b2_ca  = _b[avexpr]
scalar se2_ca = _se[avexpr]
scalar N_ca   = e(N)
reg avexpr logem4, vce(robust)
scalar b1_ca  = _b[logem4]
scalar se1_ca = _se[logem4]
scalar r2_ca  = e(r2)

*==============================================================
* Column 2: base sample, + lat_abst
*==============================================================
display _newline _dup(60) "="
display "COLUMN 2: Base sample, + lat_abst"
display _dup(60) "="
ivregress 2sls logpgp95 lat_abst (avexpr = logem4), vce(robust) first
scalar b2_cb     = _b[avexpr]
scalar se2_cb    = _se[avexpr]
scalar bw_cb_lat = _b[lat_abst]
scalar sew_cb_lat = _se[lat_abst]
scalar N_cb      = e(N)
reg avexpr logem4 lat_abst, vce(robust)
scalar b1_cb       = _b[logem4]
scalar se1_cb      = _se[logem4]
scalar b1w_cb_lat  = _b[lat_abst]
scalar se1w_cb_lat = _se[lat_abst]
scalar r2_cb       = e(r2)

*==============================================================
* Column 3: base sample without Neo-Europes (rich4), no controls
*==============================================================
display _newline _dup(60) "="
display "COLUMN 3: Base sample without Neo-Europes, no controls"
display _dup(60) "="
ivregress 2sls logpgp95 (avexpr = logem4) if rich4 != 1, vce(robust) first
scalar b2_cc  = _b[avexpr]
scalar se2_cc = _se[avexpr]
scalar N_cc   = e(N)
reg avexpr logem4 if rich4 != 1, vce(robust)
scalar b1_cc  = _b[logem4]
scalar se1_cc = _se[logem4]
scalar r2_cc  = e(r2)

*==============================================================
* Column 4: base without Neo-Europes, + lat_abst
*==============================================================
display _newline _dup(60) "="
display "COLUMN 4: Base sample without Neo-Europes, + lat_abst"
display _dup(60) "="
ivregress 2sls logpgp95 lat_abst (avexpr = logem4) if rich4 != 1, vce(robust) first
scalar b2_cd     = _b[avexpr]
scalar se2_cd    = _se[avexpr]
scalar bw_cd_lat = _b[lat_abst]
scalar sew_cd_lat = _se[lat_abst]
scalar N_cd      = e(N)
reg avexpr logem4 lat_abst if rich4 != 1, vce(robust)
scalar b1_cd       = _b[logem4]
scalar se1_cd      = _se[logem4]
scalar b1w_cd_lat  = _b[lat_abst]
scalar se1w_cd_lat = _se[lat_abst]
scalar r2_cd       = e(r2)

*==============================================================
* Column 5: base without Africa, no controls
*==============================================================
display _newline _dup(60) "="
display "COLUMN 5: Base sample without Africa, no controls"
display _dup(60) "="
ivregress 2sls logpgp95 (avexpr = logem4) if africa != 1, vce(robust) first
scalar b2_ce  = _b[avexpr]
scalar se2_ce = _se[avexpr]
scalar N_ce   = e(N)
reg avexpr logem4 if africa != 1, vce(robust)
scalar b1_ce  = _b[logem4]
scalar se1_ce = _se[logem4]
scalar r2_ce  = e(r2)

*==============================================================
* Column 6: base without Africa, + lat_abst
*==============================================================
display _newline _dup(60) "="
display "COLUMN 6: Base sample without Africa, + lat_abst"
display _dup(60) "="
ivregress 2sls logpgp95 lat_abst (avexpr = logem4) if africa != 1, vce(robust) first
scalar b2_cf     = _b[avexpr]
scalar se2_cf    = _se[avexpr]
scalar bw_cf_lat = _b[lat_abst]
scalar sew_cf_lat = _se[lat_abst]
scalar N_cf      = e(N)
reg avexpr logem4 lat_abst if africa != 1, vce(robust)
scalar b1_cf       = _b[logem4]
scalar se1_cf      = _se[logem4]
scalar b1w_cf_lat  = _b[lat_abst]
scalar se1w_cf_lat = _se[lat_abst]
scalar r2_cf       = e(r2)

*==============================================================
* Column 7: base with continent dummies (asia, africa, other)
*==============================================================
display _newline _dup(60) "="
display "COLUMN 7: Base sample with continent dummies"
display _dup(60) "="
ivregress 2sls logpgp95 asia africa othercont (avexpr = logem4), vce(robust) first
scalar b2_cg       = _b[avexpr]
scalar se2_cg      = _se[avexpr]
scalar bw_cg_asia  = _b[asia]
scalar sew_cg_asia = _se[asia]
scalar bw_cg_afr   = _b[africa]
scalar sew_cg_afr  = _se[africa]
scalar bw_cg_oth   = _b[othercont]
scalar sew_cg_oth  = _se[othercont]
scalar N_cg        = e(N)
reg avexpr logem4 asia africa othercont, vce(robust)
scalar b1_cg         = _b[logem4]
scalar se1_cg        = _se[logem4]
scalar b1w_cg_asia   = _b[asia]
scalar se1w_cg_asia  = _se[asia]
scalar b1w_cg_afr    = _b[africa]
scalar se1w_cg_afr   = _se[africa]
scalar b1w_cg_oth    = _b[othercont]
scalar se1w_cg_oth   = _se[othercont]
scalar r2_cg         = e(r2)

*==============================================================
* Column 8: base with continent dummies + lat_abst
*==============================================================
display _newline _dup(60) "="
display "COLUMN 8: Base sample with continent dummies + lat_abst"
display _dup(60) "="
ivregress 2sls logpgp95 asia africa othercont lat_abst (avexpr = logem4), vce(robust) first
scalar b2_ch        = _b[avexpr]
scalar se2_ch       = _se[avexpr]
scalar bw_ch_asia   = _b[asia]
scalar sew_ch_asia  = _se[asia]
scalar bw_ch_afr    = _b[africa]
scalar sew_ch_afr   = _se[africa]
scalar bw_ch_oth    = _b[othercont]
scalar sew_ch_oth   = _se[othercont]
scalar bw_ch_lat    = _b[lat_abst]
scalar sew_ch_lat   = _se[lat_abst]
scalar N_ch         = e(N)
reg avexpr logem4 asia africa othercont lat_abst, vce(robust)
scalar b1_ch         = _b[logem4]
scalar se1_ch        = _se[logem4]
scalar b1w_ch_asia   = _b[asia]
scalar se1w_ch_asia  = _se[asia]
scalar b1w_ch_afr    = _b[africa]
scalar se1w_ch_afr   = _se[africa]
scalar b1w_ch_oth    = _b[othercont]
scalar se1w_ch_oth   = _se[othercont]
scalar b1w_ch_lat    = _b[lat_abst]
scalar se1w_ch_lat   = _se[lat_abst]
scalar r2_ch         = e(r2)

*==============================================================
* Column 9: base sample, dep var = loghjypl, no controls
*==============================================================
display _newline _dup(60) "="
display "COLUMN 9: Base sample, dep var = loghjypl"
display _dup(60) "="
ivregress 2sls loghjypl (avexpr = logem4), vce(robust) first
scalar b2_ci  = _b[avexpr]
scalar se2_ci = _se[avexpr]
scalar N_ci   = e(N)
reg avexpr logem4 if !missing(loghjypl), vce(robust)
scalar b1_ci  = _b[logem4]
scalar se1_ci = _se[logem4]
scalar r2_ci  = e(r2)

*==============================================================
* Part (b): Three methods of TSLS
* Use column 1 spec: Y = logpgp95, X = avexpr, Z = logem4, no W.
*==============================================================
display _newline _dup(60) "="
display "PART (b): Three methods of TSLS equivalence"
display _dup(60) "="

* (b.1) TSLS slope from ivregress
scalar tsls_b = b2_ca

* (b.2) Covariance-ratio formula: s_zy / s_zx
qui sum logpgp95 if !missing(avexpr, logem4)
scalar my = r(mean)
qui sum avexpr if !missing(avexpr, logem4)
scalar mx = r(mean)
qui sum logem4 if !missing(avexpr, logem4)
scalar mz = r(mean)
gen zy_dev = (logem4 - mz)*(logpgp95 - my)
gen zx_dev = (logem4 - mz)*(avexpr - mx)
qui sum zy_dev if !missing(avexpr, logem4)
scalar s_zy = r(mean) * (r(N)/(r(N)-1))
qui sum zx_dev if !missing(avexpr, logem4)
scalar s_zx = r(mean) * (r(N)/(r(N)-1))
scalar cov_b = s_zy / s_zx
drop zy_dev zx_dev

* (b.3) Reduced-form approach:
* beta_TSLS = (coef from reg Y on Z) / (coef from reg X on Z)
reg logpgp95 logem4 if !missing(avexpr)
scalar pi_Y = _b[logem4]
reg avexpr logem4 if !missing(logpgp95)
scalar pi_X = _b[logem4]
scalar rf_b = pi_Y / pi_X

display "TSLS (ivregress):           " %9.6f tsls_b
display "Covariance-ratio formula:   " %9.6f cov_b
display "Reduced-form ratio:         " %9.6f rf_b

*==============================================================
* Part (f): Alternative estimators on column 2 spec
*==============================================================
display _newline _dup(60) "="
display "PART (f): 2SLS vs GMM vs LIML (column 2 spec)"
display _dup(60) "="

* 2SLS (reuse)
ivregress 2sls logpgp95 lat_abst (avexpr = logem4), vce(robust)
scalar f_2sls_b  = _b[avexpr]
scalar f_2sls_se = _se[avexpr]

ivregress gmm logpgp95 lat_abst (avexpr = logem4), vce(robust)
scalar f_gmm_b  = _b[avexpr]
scalar f_gmm_se = _se[avexpr]

ivregress liml logpgp95 lat_abst (avexpr = logem4), vce(robust)
scalar f_liml_b  = _b[avexpr]
scalar f_liml_se = _se[avexpr]

display "2SLS beta = " %7.4f f_2sls_b " (" %6.4f f_2sls_se ")"
display "GMM  beta = " %7.4f f_gmm_b  " (" %6.4f f_gmm_se ")"
display "LIML beta = " %7.4f f_liml_b " (" %6.4f f_liml_se ")"

*==============================================================
* WRITE LATEX MACROS --- output/tables/prob1_macros.tex
*==============================================================
file open mac using "output/tables/prob1_macros.tex", write replace
file write mac "% Auto-generated by ps7_ajr.do; do not edit by hand." _n

* Helper: write a \newcommand with a 3-decimal formatted number.
local cols "ca cb cc cd ce cf cg ch ci"
foreach c of local cols {
    file write mac "\newcommand{\ajr" "`c'" "bsecond}{" %5.3f (b2_`c') "}" _n
    file write mac "\newcommand{\ajr" "`c'" "sesecond}{" %5.3f (se2_`c') "}" _n
    file write mac "\newcommand{\ajr" "`c'" "bfirst}{"   %5.3f (b1_`c') "}" _n
    file write mac "\newcommand{\ajr" "`c'" "sefirst}{"  %5.3f (se1_`c') "}" _n
    file write mac "\newcommand{\ajr" "`c'" "Rsq}{"      %5.3f (r2_`c') "}" _n
    file write mac "\newcommand{\ajr" "`c'" "N}{"        %4.0f (N_`c')  "}" _n
}
* lat_abst coefficients where applicable
foreach c in cb cd cf ch {
    file write mac "\newcommand{\ajr" "`c'" "bsecondlat}{"  %5.3f (bw_`c'_lat) "}" _n
    file write mac "\newcommand{\ajr" "`c'" "sesecondlat}{" %5.3f (sew_`c'_lat) "}" _n
    file write mac "\newcommand{\ajr" "`c'" "bfirstlat}{"   %5.3f (b1w_`c'_lat) "}" _n
    file write mac "\newcommand{\ajr" "`c'" "sefirstlat}{"  %5.3f (se1w_`c'_lat) "}" _n
}
* continent dummies (columns 7 and 8)
foreach c in cg ch {
    foreach w in asia afr oth {
        file write mac "\newcommand{\ajr" "`c'" "bsecond`w'}{"  %5.3f (bw_`c'_`w') "}" _n
        file write mac "\newcommand{\ajr" "`c'" "sesecond`w'}{" %5.3f (sew_`c'_`w') "}" _n
        file write mac "\newcommand{\ajr" "`c'" "bfirst`w'}{"   %5.3f (b1w_`c'_`w') "}" _n
        file write mac "\newcommand{\ajr" "`c'" "sefirst`w'}{"  %5.3f (se1w_`c'_`w') "}" _n
    }
}
* Part (b) equivalence
file write mac "\newcommand{\ajrTSLSb}{"  %7.4f (tsls_b) "}" _n
file write mac "\newcommand{\ajrCOVb}{"   %7.4f (cov_b)  "}" _n
file write mac "\newcommand{\ajrRFb}{"    %7.4f (rf_b)   "}" _n

* Part (f)
file write mac "\newcommand{\ajrTSLSfb}{"  %6.3f (f_2sls_b)  "}" _n
file write mac "\newcommand{\ajrTSLSfse}{" %6.3f (f_2sls_se) "}" _n
file write mac "\newcommand{\ajrGMMfb}{"   %6.3f (f_gmm_b)   "}" _n
file write mac "\newcommand{\ajrGMMfse}{"  %6.3f (f_gmm_se)  "}" _n
file write mac "\newcommand{\ajrLIMLfb}{"  %6.3f (f_liml_b)  "}" _n
file write mac "\newcommand{\ajrLIMLfse}{" %6.3f (f_liml_se) "}" _n

file close mac

*==============================================================
* Second-stage SE comparison macros: published vs our robust
* Published SEs (AJR Table 4 second stage, avexpr coeff):
*   c1: 0.16  c2: 0.22  c3: 0.36  c4: 0.35
*   c5: 0.10  c6: 0.12  c7: 0.30  c8: 0.46  c9: 0.17
*==============================================================
matrix pub_se2 = (0.16 \ 0.22 \ 0.36 \ 0.35 \ 0.10 \ 0.12 \ 0.30 \ 0.46 \ 0.17)
matrix pub_se1 = (0.13 \ 0.14 \ 0.13 \ 0.14 \ 0.22 \ 0.24 \ 0.17 \ 0.18 \ 0.13)
display _newline "SE comparison (our robust vs. paper non-robust):"
display "Col   Y=avexpr-2nd   |diff|   |   1st stage (logem4)   |diff|"
local i = 0
local cols2 "ca cb cc cd ce cf cg ch ci"
foreach c of local cols2 {
    local ++i
    display "  `c'    " %6.3f (se2_`c') "   (" %5.2f pub_se2[`i',1] ")  " ///
        %5.2f abs(se2_`c' - pub_se2[`i',1]) "  |  " ///
        %6.3f (se1_`c') "   (" %5.2f pub_se1[`i',1] ")  " ///
        %5.2f abs(se1_`c' - pub_se1[`i',1])
}

log close
