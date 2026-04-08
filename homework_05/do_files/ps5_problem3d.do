* ============================================================
* ps5_problem3d.do
* ECON UN3412 — Problem Set 5, Problem 3(d)
*
* Panel data regression of firm stock log returns on S&P 500
* log returns using cross-section (firm) fixed effects.
*
* Log returns are computed as:
*   r_{it} = 100 * [ln(P_{it}) - ln(P_{i,t-1})]
*
* This is the standard econometric measure of percentage change
* (Stock & Watson, 2020). For small daily changes, log returns
* approximate simple percentage returns but are additive over
* time and symmetric in gains and losses.
*
* Data: Daily adjusted close prices for 10 U.S. firms and the
* S&P 500 index from Yahoo Finance, Jan 1, 2021 – Jan 1, 2026.
*
* Firms:
*   1. AAPL (Apple)           6. PG  (Procter & Gamble)
*   2. MSFT (Microsoft)       7. DIS (Walt Disney)
*   3. JPM  (JPMorgan Chase)  8. HD  (Home Depot)
*   4. JNJ  (Johnson & Johnson) 9. CAT (Caterpillar)
*   5. XOM  (ExxonMobil)     10. NEE (NextEra Energy)
*
* Market index: S&P 500 (^GSPC)
*
* Output:
*   ../output/tables/prob3d_fe_regression.tex
* ============================================================

clear all
set more off

* ----------------------------------------------------------
* 1. LOAD PANEL DATA
* ----------------------------------------------------------
* The panel was constructed in Python (download_stock_data.py).
* Each observation is a (firm, trading day) pair.
* log_ret_firm   = 100 * [ln(P_it) - ln(P_{i,t-1})]
* log_ret_market = 100 * [ln(P_mt) - ln(P_{m,t-1})]
* firm_id        = numeric firm identifier (1–10)
use "../data/stock_panel.dta", clear

* ----------------------------------------------------------
* 2. DECLARE PANEL STRUCTURE
* ----------------------------------------------------------
* Tell Stata that this is panel data: firm_id is the cross-
* sectional (entity) dimension and stata_date is the time
* dimension. This enables the use of xtreg and xtset-aware
* commands.
xtset firm_id stata_date

* ----------------------------------------------------------
* 3. SUMMARY STATISTICS
* ----------------------------------------------------------
* Display summary statistics for the log return variables to
* verify the data is sensible (means near zero, reasonable SD).
summarize log_ret_firm log_ret_market

* ----------------------------------------------------------
* 4. CROSS-SECTION FIXED EFFECTS REGRESSION
* ----------------------------------------------------------
* We estimate the following model:
*
*   Delta ln(P_{it}) = alpha_i + beta * Delta ln(P_{mt}) + u_{it}
*
* where Delta ln(P_{it}) = ln(P_{it}) - ln(P_{i,t-1}) is the
* log return (x100) of firm i on day t, and similarly for the
* market. alpha_i are firm-specific fixed effects capturing
* each firm's average idiosyncratic log return (Jensen's alpha),
* and beta measures the sensitivity of firm returns to market
* returns (the firm's "market beta" in CAPM terminology).
*
* We use xtreg with the fe (fixed effects / within) estimator.
* The option vce(robust) produces heteroskedasticity-robust SEs.
*
* The within estimator demeans each variable by its firm-
* specific mean, then runs OLS on the demeaned data. This
* is numerically equivalent to including a full set of firm
* dummy variables (the LSDV estimator), but is computationally
* more efficient.

xtreg log_ret_firm log_ret_market, fe vce(robust)
estimates store fe_model

* ----------------------------------------------------------
* 5. DISPLAY FIRM FIXED EFFECTS (alpha_i)
* ----------------------------------------------------------
* After xtreg, fe, the fixed effects are stored. We can
* predict them using predict with the u option.
predict alpha_i, u
label var alpha_i "Estimated firm fixed effect (alpha_i)"

* Show firm-level averages of the fixed effects
tabulate firm_id, summarize(alpha_i)

* ----------------------------------------------------------
* 6. EXPORT TABLE VIA ESTTAB
* ----------------------------------------------------------
esttab fe_model using "../output/tables/prob3d_fe_regression.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label title("Firm-Level Log Returns on S\&P 500 Log Returns: Fixed Effects Panel Regression") ///
    stats(N r2_w r2_b r2_o N_g, ///
          labels("Observations" "Within \$R^2\$" "Between \$R^2\$" "Overall \$R^2\$" "Number of firms") ///
          fmt(%9.0fc %9.4f %9.4f %9.4f %9.0f)) ///
    booktabs alignment(D{.}{.}{-1}) ///
    addnotes("Dependent variable: daily log return of firm stock (x100)." ///
             "Log returns: $100 \times [\ln(P_{it}) - \ln(P_{i,t-1})]$." ///
             "Firm (cross-section) fixed effects via within transformation." ///
             "Heteroskedasticity-robust standard errors in parentheses." ///
             "Data: Yahoo Finance, Jan 2021 -- Dec 2025, 10 U.S. firms.")

* ----------------------------------------------------------
* 7. ALSO RUN WITH FIRM DUMMIES (LSDV) FOR COMPARISON
* ----------------------------------------------------------
* This is algebraically identical to xtreg, fe but shows the
* dummy coefficients explicitly. Useful for confirming results.
tabulate firm_id, generate(firm_d)
reg log_ret_firm log_ret_market firm_d2-firm_d10, robust

di ""
di "============================================="
di " PROBLEM 3(d) REGRESSIONS COMPLETE "
di "============================================="
