* ============================================================
* explore_data.do
* ECON UN3412 -- Homework 6
* Purpose: describe the three .dta files used in the SW 11.1
*   and SW 11.2 recitation exercises so that we know variable
*   names, types, sample sizes, missingness, and label values
*   before writing the substantive analysis files.
* ============================================================

clear all
set more off
capture log close
log using "explore_data.log", replace text

* ----------------------------------------------------------
* 1. employment_08_09.dta  (used for SW 11.1 parts a-g)
* ----------------------------------------------------------
use "../data/employment_08_09.dta", clear
describe
summarize
codebook, compact
tab employed, missing
tab unemployed, missing

* ----------------------------------------------------------
* 2. employment_06_07.dta  (used for SW 11.1 part h)
* ----------------------------------------------------------
use "../data/employment_06_07.dta", clear
describe
summarize
codebook, compact
tab employed, missing

* ----------------------------------------------------------
* 3. Smoking.dta  (used for SW 11.2 all parts)
* ----------------------------------------------------------
use "../data/Smoking.dta", clear
describe
summarize
codebook, compact
tab smoker, missing
tab smkban, missing

log close
