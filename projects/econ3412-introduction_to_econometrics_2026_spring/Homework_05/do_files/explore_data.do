* ============================================================
* explore_data.do
* Quick exploration of handguns.dta
* ============================================================

clear all
set more off

use "../handguns.dta", clear

describe

summarize vio rob mur shall incarc_rate density avginc pop pb1064 pw1064 pm1029 stateid year
