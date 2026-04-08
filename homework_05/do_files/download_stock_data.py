"""
download_stock_data.py
ECON UN3412 — Problem Set 5, Problem 3(d)

Downloads daily adjusted close prices for 10 U.S. companies and the S&P 500
from Yahoo Finance for Jan 1, 2021 – Jan 1, 2026. Computes log returns
(percentage changes via log differences), arranges as panel data, and exports
to Stata .dta format.

Log returns: r_{it} = 100 * [ln(P_{it}) - ln(P_{i,t-1})]

Companies chosen (large-cap, diverse sectors):
  1. AAPL  — Apple (Technology)
  2. MSFT  — Microsoft (Technology)
  3. JPM   — JPMorgan Chase (Financials)
  4. JNJ   — Johnson & Johnson (Healthcare)
  5. XOM   — ExxonMobil (Energy)
  6. PG    — Procter & Gamble (Consumer Staples)
  7. DIS   — Walt Disney (Communication Services)
  8. HD    — Home Depot (Consumer Discretionary)
  9. CAT   — Caterpillar (Industrials)
  10. NEE  — NextEra Energy (Utilities)

Market index: ^GSPC (S&P 500)
"""

import yfinance as yf
import pandas as pd
import numpy as np
import os

# ============================================================
# 1. Define tickers and sample period
# ============================================================
tickers = ['AAPL', 'MSFT', 'JPM', 'JNJ', 'XOM', 'PG', 'DIS', 'HD', 'CAT', 'NEE']
market_ticker = '^GSPC'
start_date = '2021-01-01'
end_date = '2026-01-01'

# ============================================================
# 2. Download adjusted close prices
# ============================================================
all_tickers = tickers + [market_ticker]
print("Downloading data for:", all_tickers)

data = yf.download(all_tickers, start=start_date, end=end_date, auto_adjust=True)

# Extract the 'Close' prices (with auto_adjust=True, Close = Adjusted Close)
prices = data['Close']

# Rename ^GSPC to SP500 for cleaner naming
prices = prices.rename(columns={'^GSPC': 'SP500'})

print(f"\nPrice data shape: {prices.shape}")
print(f"Date range: {prices.index.min()} to {prices.index.max()}")
print(f"Missing values per column:\n{prices.isna().sum()}")

# Drop any rows with missing values (e.g., holidays differ)
prices = prices.dropna()

# ============================================================
# 3. Compute LOG RETURNS (x100 for percentage interpretation)
# ============================================================
# Log return: r_t = 100 * [ln(P_t) - ln(P_{t-1})]
# This is the standard econometric measure of percentage change
# (Stock & Watson, 2020). For small daily changes, log returns
# are approximately equal to simple percentage returns, but they
# have the desirable property of being additive over time and
# symmetric in gains/losses.
log_returns = np.log(prices).diff() * 100
log_returns = log_returns.dropna()  # drop first row (NaN from differencing)

# Extract market log returns
market_ret = log_returns['SP500']

# ============================================================
# 4. Reshape to panel (long) format
# ============================================================
# Each row = (firm_id, date, log_ret_firm, log_ret_market)
panels = []
for i, ticker in enumerate(tickers, start=1):
    firm_data = pd.DataFrame({
        'firm_id': i,
        'ticker': ticker,
        'date': log_returns.index,
        'log_ret_firm': log_returns[ticker].values,
        'log_ret_market': market_ret.values
    })
    panels.append(firm_data)

panel_df = pd.concat(panels, ignore_index=True)

# Sort by firm_id and date (standard panel ordering)
panel_df = panel_df.sort_values(['firm_id', 'date']).reset_index(drop=True)

# Create a numeric date variable for Stata (days since Jan 1, 1960)
panel_df['stata_date'] = (panel_df['date'] - pd.Timestamp('1960-01-01')).dt.days

print(f"\nPanel data shape: {panel_df.shape}")
print(f"Number of firms: {panel_df['firm_id'].nunique()}")
print(f"Number of trading days per firm: {panel_df.groupby('firm_id').size().unique()}")
print(f"\nSample:")
print(panel_df.head(10))
print(panel_df.describe())

# ============================================================
# 5. Export to Stata .dta format
# ============================================================
output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'stock_panel.dta')
panel_df.to_stata(output_path, write_index=False,
                  variable_labels={
                      'firm_id': 'Firm identifier (1-10)',
                      'ticker': 'Ticker symbol',
                      'log_ret_firm': 'Log return of firm stock (x100)',
                      'log_ret_market': 'Log return of S&P 500 (x100)',
                      'stata_date': 'Trading date (days since 1960-01-01)'
                  })

print(f"\nPanel data saved to: {output_path}")

# Also save a summary CSV for reference
summary_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'firm_list.csv')
firm_list = pd.DataFrame({
    'firm_id': range(1, 11),
    'ticker': tickers,
    'sector': ['Technology', 'Technology', 'Financials', 'Healthcare', 'Energy',
                'Consumer Staples', 'Communication Services', 'Consumer Discretionary',
                'Industrials', 'Utilities']
})
firm_list.to_csv(summary_path, index=False)
print(f"Firm list saved to: {summary_path}")
