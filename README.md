# Apex Grid EA

Grid + Martingale trading bot untuk MetaTrader 4, terinspirasi dari Yetti Classic v3.03_fix.

## Overview

Apex Grid EA membuka posisi berlapis (grid) dengan lot progresif (martingale) dan menutup semua posisi sekaligus (basket close) ketika trailing stop atau general TP terpicu.

- **Platform:** MetaTrader 4 (MT4)
- **Pair:** GBPUSD
- **Timeframe:** M1
- **Broker Target:** JDR Securities

## Quick Start

1. Copy `src/experts/ApexGrid.mq4` ke `MQL4/Experts/`
2. Restart MT4
3. Drag EA ke chart GBPUSD M1
4. Enable Allow Live Trading

## Strategy (5 Layers)

| Layer | Function | Description |
|-------|----------|-------------|
| 1 | MA Crossover | Golden Cross → BUY, Death Cross → SELL |
| 2 | Grid Manager | Open new level every GridStep pips against trend |
| 3 | Exit Manager | Trailing stop + General TP basket close |
| 4 | Time Filter | Trade only during configured hours |
| 5 | Risk Shutdown | Auto-stop on drawdown, margin, or profit target |

## Default Parameters

- **StartLot:** 0.10, **Multiplier:** 1.5, **GridStep:** 250 pips
- **MA:** SMA(5) vs SMA(40) on Close
- **Trailing:** 50 pip distance, 160 pip trigger
- **Risk:** MaxDrawdown 15%, MinMarginLevel 1000%, Daily/Weekly Profit 20%

## Documentation

- [Strategy](docs/strategy.md)
- [Parameters](docs/parameters.md)
- [User Guide](docs/user-guide.md)
- [Context](CONTEXT.md)

## Disclaimer

Trading forex involves substantial risk. This EA uses martingale strategy which can lead to rapid losses. Always test on demo first.
