* Quick APE check: average partial effect of majordrg in probit and logit
clear all
set more off
use "../data/AmEx.dta", clear
keep cardhldr income age selfempl ownrent acadmos majordrg minordrg
replace income = income/1000
rename income inc

* LPM coefficient for comparison
reg cardhldr inc age selfempl ownrent acadmos majordrg minordrg, robust
scalar b_lpm = _b[majordrg]

probit cardhldr inc age selfempl ownrent acadmos majordrg minordrg, vce(robust)
margins, dydx(majordrg)
matrix M = r(table)
scalar ape_prob = M[1,1]

logit cardhldr inc age selfempl ownrent acadmos majordrg minordrg, vce(robust)
margins, dydx(majordrg)
matrix M = r(table)
scalar ape_log = M[1,1]

display as text _newline "=== APE comparison ==="
display as text "LPM beta      = " %7.4f b_lpm
display as text "Probit APE    = " %7.4f ape_prob
display as text "Logit  APE    = " %7.4f ape_log
