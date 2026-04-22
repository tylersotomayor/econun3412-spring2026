********************************************************************************
* download_yahoo_data.do
* ECON UN3412 — Problem Set 5, Problem 3(d)
*
* PURPOSE:
*   Downloads daily adjusted close prices from Yahoo Finance for 10 U.S.
*   firms and the S&P 500 index, computes log returns, arranges as panel
*   data, and saves to ../data/stock_panel.dta.
*
* DATA SOURCE:
*   Yahoo Finance (https://finance.yahoo.com)
*   Retrieved via the yfinance Python package (Aroussi, 2024).
*
* REQUIREMENTS:
*   - Stata 16+ with Python integration enabled
*   - Python 3.x with 'yfinance' and 'pandas' packages installed
*     (install via: pip install yfinance pandas)
*
* SAMPLE:
*   January 1, 2021 – January 1, 2026 (trading days only)
*
* FIRMS (10 large-cap U.S. companies, diverse sectors):
*   1. AAPL  — Apple Inc.             (Technology)
*   2. MSFT  — Microsoft Corp.        (Technology)
*   3. JPM   — JPMorgan Chase & Co.   (Financials)
*   4. JNJ   — Johnson & Johnson      (Healthcare)
*   5. XOM   — ExxonMobil Corp.       (Energy)
*   6. PG    — Procter & Gamble Co.   (Consumer Staples)
*   7. DIS   — Walt Disney Co.        (Communication Services)
*   8. HD    — Home Depot Inc.        (Consumer Discretionary)
*   9. CAT   — Caterpillar Inc.       (Industrials)
*  10. NEE   — NextEra Energy Inc.    (Utilities)
*
* MARKET INDEX:
*   ^GSPC — S&P 500
*
* OUTPUT:
*   ../data/stock_panel.dta   (balanced panel: 10 firms × T trading days)
*   ../data/firm_list.csv     (firm ID–ticker–sector mapping)
*
* LOG RETURNS:
*   r_{it} = 100 × [ln(P_{it}) − ln(P_{i,t-1})]
*   This is the standard econometric measure of percentage change
*   (Stock & Watson, 2020, Ch. 14). Log returns are additive over time
*   and approximately equal to simple percentage returns for small
*   daily changes.
********************************************************************************


clear all
set more off


********************************************************************************
* STEP 1: DOWNLOAD DATA VIA PYTHON AND SAVE AS TEMPORARY CSV
*
*   We use Stata's 'python:' block to run yfinance, then save the
*   panel to a CSV file. Stata then imports the CSV natively — this
*   is vastly faster than pushing data row-by-row via sfi.Data.
********************************************************************************

python:

import yfinance as yf
import pandas as pd
import numpy as np
import os
from datetime import datetime

# ── Parameters ─────────────────────────────────────────────────────────────
tickers = ['AAPL', 'MSFT', 'JPM', 'JNJ', 'XOM',
           'PG',   'DIS',  'HD',  'CAT', 'NEE']

sectors = ['Technology', 'Technology', 'Financials', 'Healthcare', 'Energy',
           'Consumer Staples', 'Communication Services',
           'Consumer Discretionary', 'Industrials', 'Utilities']

market_ticker = '^GSPC'
start_date    = '2021-01-01'
end_date      = '2026-01-01'

print("=" * 60)
print("DOWNLOADING YAHOO FINANCE DATA")
print("=" * 60)
print(f"Firms:       {tickers}")
print(f"Market:      {market_ticker}")
print(f"Period:      {start_date} to {end_date}")
print(f"Timestamp:   {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 60)

# ── Download adjusted close prices ─────────────────────────────────────────
#
# auto_adjust=True means the 'Close' column already reflects
# splits and dividends (i.e., it IS the adjusted close).

all_tickers = tickers + [market_ticker]
data = yf.download(all_tickers, start=start_date, end=end_date,
                   auto_adjust=True)
prices = data['Close'].rename(columns={'^GSPC': 'SP500'}).dropna()

print(f"\nPrices: {prices.shape[0]} trading days, "
      f"{prices.shape[1]} series")
print(f"Date range: {prices.index.min().date()} to "
      f"{prices.index.max().date()}")

# ── Compute log returns: 100 × Δln(P) ─────────────────────────────────────
#
# r_t = 100 × [ln(P_t) − ln(P_{t-1})]
#
# The log-difference is the standard econometric measure of
# percentage change. For small daily changes it approximates the
# simple percentage return, and it has the desirable property
# of being additive over time.

log_ret = (np.log(prices).diff() * 100).dropna()
market_ret = log_ret['SP500']

# ── Reshape to panel (long) format ─────────────────────────────────────────
#
# Each row = (firm_id, date, log_ret_firm, log_ret_market).
# This is the stacked panel format required by xtset / xtreg.

panels = []
for i, ticker in enumerate(tickers, start=1):
    df = pd.DataFrame({
        'firm_id':        i,
        'ticker':         ticker,
        'sector':         sectors[i - 1],
        'date':           log_ret.index.strftime('%Y-%m-%d'),
        'log_ret_firm':   log_ret[ticker].values,
        'log_ret_market': market_ret.values,
        'stata_date':     (log_ret.index - pd.Timestamp('1960-01-01')).days
    })
    panels.append(df)

panel = pd.concat(panels, ignore_index=True)
panel = panel.sort_values(['firm_id', 'date']).reset_index(drop=True)

n_firms = panel['firm_id'].nunique()
n_days  = panel.groupby('firm_id').size().iloc[0]

print(f"\nPanel: {n_firms} firms x {n_days} days = {len(panel)} obs")
print(panel[['log_ret_firm', 'log_ret_market']].describe().round(4))

# ── Save to CSV (Stata will import this) ───────────────────────────────────
csv_path = '../data/_temp_stock_panel.csv'
panel.to_csv(csv_path, index=False)
print(f"\nTemp CSV saved to {csv_path}")

# ── Save firm list ─────────────────────────────────────────────────────────
firm_list = pd.DataFrame({
    'firm_id': range(1, 11),
    'ticker':  tickers,
    'sector':  sectors
})
firm_list.to_csv('../data/firm_list.csv', index=False)

print("\n" + "=" * 60)
print("DOWNLOAD COMPLETE — HANDING OFF TO STATA")
print("=" * 60)

end


********************************************************************************
* STEP 2: IMPORT THE CSV INTO STATA
*
*   Stata's native 'import delimited' reads CSVs very quickly.
*   It automatically detects column types (numeric vs. string).
********************************************************************************

import delimited "../data/_temp_stock_panel.csv", clear


********************************************************************************
* STEP 3: LABEL VARIABLES AND FORMAT
*
*   Add informative variable labels and format the date variable
*   so that Stata output is self-documenting.
********************************************************************************

label var firm_id        "Firm identifier (1-10)"
label var ticker         "Ticker symbol"
label var sector         "GICS sector"
label var log_ret_firm   "Log return of firm stock (x100)"
label var log_ret_market "Log return of S&P 500 (x100)"
label var stata_date     "Trading date (days since 1960-01-01)"

* Format stata_date as a calendar date for display
format stata_date %td

* Drop the string date column (stata_date serves this purpose)
capture drop date


********************************************************************************
* STEP 4: VERIFY THE DATA
*
*   Sanity checks before saving:
*     - Correct number of observations (should be n × T)
*     - Balanced panel (same T for each firm)
*     - Means near zero (expected for daily log returns)
*     - No missing values
********************************************************************************

di ""
di "=========================================="
di " DATA VERIFICATION"
di "=========================================="

describe

summarize log_ret_firm log_ret_market

* Check balance: every firm should have the same count
tab firm_id

* Check for missing values
count if missing(log_ret_firm)
count if missing(log_ret_market)


********************************************************************************
* STEP 5: SAVE THE PANEL DATASET AND CLEAN UP
*
*   Save as .dta, then delete the temporary CSV.
*   The .dta file is loaded by ps5_problem3d.do for FE regressions.
********************************************************************************

save "../data/stock_panel.dta", replace

* Clean up temporary CSV
erase "../data/_temp_stock_panel.csv"

di ""
di "=========================================="
di " SAVED: ../data/stock_panel.dta"
di "=========================================="
di " Ready for panel regressions."
di " Next step: do ps5_problem3d.do"
di "=========================================="
