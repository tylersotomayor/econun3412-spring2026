* Quick exploratory run to understand maketable4.dta
clear all
set more off
cd "/Users/tylersotomayor/columbia_university/2025-2026/spring_2026/econ_3412_spring_2026/homework/homework_07"
use "data/maketable4.dta", clear
describe
sum
tab baseco, m
tab rich4, m
tab africa, m
tab asia, m
list shortnam if baseco==1 & asia==0 & africa==0 & rich4==0 & !missing(logpgp95)
