* ------------------------------------------------------------
* amex_explore.do -- structural inspection of AmEx.dta
* ------------------------------------------------------------
clear all
set more off
capture log close
log using "amex_explore.log", replace text

use "../data/AmEx.dta", clear
describe
summarize
codebook, compact

* Tab the binary outcome
tab cardhldr, missing

log close
