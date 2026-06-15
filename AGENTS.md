# AGENTS.md — Apex Grid EA

## Must read first
- **`CONTEXT.md`** is the authoritative spec. Read it before any code change.
- The team is Indonesian. Docs are in Indonesian, but code comments are in English.

## Project facts
- **MQL4 Expert Advisor** for MetaTrader 4. Single file: `src/experts/ApexGrid.mq4` (v1.03, 735 lines).
- Targets broker JDR Securities, pair GBPUSD, timeframe M1.
- Strategy: Grid + Martingale with MA crossover entries and basket close exits.
- MIT licensed. Repo: `github.com/codecat92/apex-grid-ea`.

## Key constraints
- **Cannot compile or test locally.** No build system exists. Compilation and backtesting happen only inside the MT4 Strategy Tester. Do not try to compile or run the `.mq4` file.
- **No lint/typecheck commands exist.** Skip linting steps — there is nothing to run.
- **Single source file** — no `#include`, no imports, no multi-file architecture. The entire EA lives in one file organized into 29 labeled code blocks.
- **Conventional commits** required: `feat:`, `fix:`, `docs:`, `test:`.

## Architecture (5 layers, all implemented)
1. **Entry Signal** — MA5/MA40 SMA crossover on Close. Golden Cross = BUY, Death Cross = SELL. Both grids can run simultaneously.
2. **Grid Manager** — Market orders at level 0, pending stop orders at higher levels. Lot = `StartLot × Multiplier^Level`. Gap-fill and error-130 fallback.
3. **Exit Manager** — Basket close via profit-peak trailing (no per-position SL/TP). 5-minute cooldown after close.
4. **Time Filter** — Active 01:00–22:00, Friday stop at 14:00. Extra window at 01:06–01:07 with tighter grid step.
5. **Risk Shutdown** — Monitors drawdown, margin level, daily/weekly profit targets.

## Parameter defaults (do not change without explicit request)
- MagicNumber: 1888, StartLot: 0.10, Multiplier: 1.5, GridStep: 250, GeneralTP: 200
- MA: Fast=5, Slow=40, SMA, Close
- Trailing: FixedDistance=50, TriggerDistance=160
- Risk: DailyProfit=20%, WeeklyProfit=20%, DrawdownCloseAll=90%, MarginCloseAll=20%

## Conventions
- MQL4 uses `extern` (not `input` like MQL5).
- Order comments use format: `"Apex Grid BUY"`, `"Apex Grid SELL 1"`, etc.
- Lot sizes must be normalized via `NormalizeLot()`.
- Git branch is `main`. No develop/staging branches exist.
- `.gitignore` excludes `mql4-lsp-server` and `.DS_Store`.
