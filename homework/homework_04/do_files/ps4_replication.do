* ==============================================================================
* ECON UN3412 — Homework 4 (Spring 2026)
* Replication .do file (Stata) — Option A (manual cd to project root)
* Author: Tyler Sotomayor
* ==============================================================================

version 18.0
clear all
set more off
set linesize 255

* ==============================================================================
* 0. Paths (relative to project root)
* ==============================================================================

global DATA   "data"
global OUT    "output"
global TABS   "$OUT/tables"
global FIGS   "$OUT/figures"
global LOGS   "$OUT/logs"

capture mkdir "$OUT"
capture mkdir "$TABS"
capture mkdir "$FIGS"
capture mkdir "$LOGS"

capture log close
log using "$LOGS/ps4_replication.log", replace text

display as text "============================================================"
display as text "Running from: `c(pwd)'"
display as text "============================================================"

* ==============================================================================
* 1. Packages
* ==============================================================================

capture which esttab
if _rc {
    ssc install estout, replace
}

* ==============================================================================
* 2. House style for LaTeX regression tables
*    NOTE: line continuation uses " ///" with a leading space (required). 
* ==============================================================================

global ESTSTYLE ///
    "booktabs se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) se(%9.3f) alignment(D{.}{.}{-1})"
