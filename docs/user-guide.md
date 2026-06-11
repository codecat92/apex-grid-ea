# Apex Grid EA — User Guide

## Installation

1. Copy `ApexGrid.mq4` to `MQL4/Experts/` directory
2. Restart MetaTrader 4 or refresh Navigator
3. Drag Apex Grid EA onto GBPUSD M1 chart
4. Configure parameters in the Inputs tab
5. Enable **Allow Live Trading** and **Allow DLL Imports** (if needed)
6. Click OK

## Recommended Setup

| Setting          | Value     |
|-----------------|-----------|
| Symbol          | GBPUSD    |
| Timeframe       | M1        |
| Broker          | JDR Securities |
| Account Type    | Standard  |
| Leverage        | 1:500     |

## Parameter Configuration

### Quick Start (Default)
All default parameters are optimized for GBPUSD M1. No changes needed.

### Customization Notes

**Lot Size:**
- Start with small lot (0.01) for demo testing
- Increase gradually (0.10 for live on standard account)

**Risk Settings:**
- Default risk params are conservative
- MaxDrawdown 15% will stop the bot before significant loss
- MinMarginLevel 1000 ensures sufficient margin

**Time Settings:**
- Default 01:00-22:00 covers major trading sessions
- Friday stop at 14:00 avoids weekend gap risk
- Extra window 01:06-01:07 is for specific strategy timing

## Safety Features

1. **Auto Stop Trading** — Bot stops when drawdown exceeds MaxDrawdown
2. **Daily/Weekly Profit Target** — Stops trading after reaching profit goal
3. **Drawdown Protection** — Closes all positions at critical drawdown
4. **Margin Monitoring** — Closes positions if margin level drops too low
5. **Time Filter** — Only trades during configured hours
6. **Friday Stop** — Prevents weekend gap exposure

## Monitoring

Check these values regularly:

- **Drawdown:** Monitor equity vs balance
- **Margin Level:** Should stay above 1000%
- **Grid Level:** Deep grids (level 5+) increase risk significantly
- **Profit Target:** Bot stops automatically at 20% daily/weekly profit

## Troubleshooting

| Issue                | Solution                              |
|----------------------|---------------------------------------|
| No trades opening    | Check time filter, MA crossover signal|
| Bot not trading      | Check G_Stopped flag in Experts tab   |
| Orders not closing   | Check trailing parameters             |
| Too many grid levels | Reduce GridStep or increase multiplier|

## Disclaimer

Trading forex involves substantial risk. This EA uses martingale strategy which can lead to rapid losses during strong trends. Always test on demo account first.
