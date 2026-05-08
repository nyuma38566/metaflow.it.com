# MetaFlow Trade Kit

MetaFlow Trade Kit is a compact trading resource repository focused on three practical areas:

- reference Expert Advisors for MetaTrader 4 and MetaTrader 5
- broker evaluation notes for FX and CFD deployment
- binary distribution through GitHub Releases instead of source control

## Repository layout

- `index.html`: project landing page
- `styles.css`: presentation layer for the landing page
- `strategies/EMA_Cross_ATR_Filter.mq5`: MT5 trend-following sample
- `strategies/RSI_Session_Reversion.mq4`: MT4 mean-reversion sample
- `strategies/London_Breakout_ATR_Manager.mq5`: MT5 session breakout sample

## Distribution model

Client binaries such as `metatrade.exe` are intended to be published under GitHub Releases.
This keeps the repository smaller and makes versioned downloads easier to manage.

- Release channel: `https://github.com/nyuma38566/metaflow.it.com/releases`
- Current checksum reference: `ebff20de90a5483980415df177832b151e89f40a87e3b186adac6b2edaf7a379`

## Included strategy samples

### EMA Cross ATR Filter

An MT5 trend model built around EMA crossover confirmation with ATR-based stop and target placement.
The script includes new-bar detection, spread control, and single-position handling.

### RSI Session Reversion

An MT4 reversal model that waits for RSI to move back inside normal bounds during a configured session.
It is structured for simple intraday testing and parameter tuning.

### London Breakout ATR Manager

An MT5 breakout system that records the early London session range and trades directional breaks once
the market moves outside the recorded high or low. Volatility is used to scale both protection and target levels.

## Broker due diligence checklist

Before deploying any strategy, review the following with the target broker:

- average and event-driven spread behavior
- commission schedule and swap policy
- order fill quality and rejection rate
- stop level restrictions and margin requirements
- symbol trading hours and contract specifications

## Usage guidance

1. Open `index.html` locally or host it with GitHub Pages for a simple project landing page.
2. Import the scripts under `strategies/` into MetaEditor and compile them inside the target platform version.
3. Run backtests and forward tests before any production use.

## Disclaimer

The code in this repository is provided as a technical example only.
It is not investment advice, performance guidance, or a guarantee of execution quality across brokers.
