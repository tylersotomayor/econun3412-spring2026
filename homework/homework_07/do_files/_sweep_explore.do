clear all
set more off
cd "/Users/tylersotomayor/columbia_university/2025-2026/spring_2026/econ_3412_spring_2026/homework/homework_07"

di _dup(60) "=" _n "FERTILITY" _n _dup(60) "="
use "data/fertility.dta", clear
describe
sum
di _dup(60) "=" _n "MOVIES" _n _dup(60) "="
use "data/movies.dta", clear
describe
sum attend* pr_attend* assaults holiday* | head
di _dup(60) "=" _n "NAMES" _n _dup(60) "="
use "data/names.dta", clear
describe
sum
