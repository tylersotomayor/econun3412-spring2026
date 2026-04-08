* ============================================================
* ps5_problem3d.do
* ECON UN3412 — Problem Set 5, Problem 3(d)
*
* Panel data regression of firm stock returns on S&P 500 returns
* using cross-section (firm) fixed effects.
*
* Data: Daily adjusted close prices for 10 U.S. firms and the
* S&P 500 index from Yahoo Finance, Jan 1, 2021 – Jan 1, 2026.
* Returns are computed as daily percentage changes.
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
* pct_ret_firm   = daily percentage return of the firm's stock
* pct_ret_market = daily percentage return of S&P 500
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
* Display summary statistics for the return variables to verify
* the data is sensible (means near zero, reasonable SD).
summarize pct_ret_firm pct_ret_market

* ----------------------------------------------------------
* 4. CROSS-SECTION FIXED EFFECTS REGRESSION
* ----------------------------------------------------------
* We estimate the following model:
*
*   pct_ret_firm_{it} = alpha_i + beta * pct_ret_market_t + u_{it}
*
* where alpha_i are firm-specific fixed effects (intercepts)
* that capture each firm's average idiosyncratic return
* (i.e., the firm's "alpha" in CAPM terminology), and beta
* measures the sensitivity of firm returns to market returns
* (the firm's "beta" in CAPM language).
*
* We use xtreg with the fe (fixed effects / within) estimator.
* The option vce(robust) produces heteroskedasticity-robust
* standard errors.
*
* The within estimator demeans each variable by its firm-
* specific mean, then runs OLS on the demeaned data. This
* is numerically equivalent to including a full set of firm
* dummy variables (the LSDV estimator), but is computationally
* more efficient.

xtreg pct_ret_firm pct_ret_market, fe vce(robust)
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
    label title("Firm-Level Stock Returns on S\&P 500 Market Returns: Fixed Effects Panel Regression") ///
    stats(N r2_w r2_b r2_o N_g, ///
          labels("Observations" "Within \$R^2\$" "Between \$R^2\$" "Overall \$R^2\$" "Number of firms") ///
          fmt(%9.0fc %9.4f %9.4f %9.4f %9.0f)) ///
    booktabs alignment(D{.}{.}{-1}) ///
    addnotes("Dependent variable: daily percentage return of firm stock." ///
             "Firm (cross-section) fixed effects estimated via within transformation." ///
             "Heteroskedasticity-robust standard errors in parentheses." ///
             "Data: Yahoo Finance, Jan 2021 -- Dec 2025, 10 U.S. firms.")

* ----------------------------------------------------------
* 7. ALSO RUN WITH FIRM DUMMIES (LSDV) FOR COMPARISON
* ----------------------------------------------------------
* This is algebraically identical to xtreg, fe but shows the
* dummy coefficients explicitly. Useful for confirming results.
tabulate firm_id, generate(firm_d)
reg pct_ret_firm pct_ret_market firm_d2-firm_d10, robust

di ""
di "============================================="
di " PROBLEM 3(d) REGRESSIONS COMPLETE "
di "============================================="
