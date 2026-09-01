# Apex Grid EA — Parameter Reference (v1.12)

> Parameter dikelompokkan per sisi BUY/SELL. Semua nilai default sama untuk kedua sisi
> agar perilaku default identik dengan versi sebelumnya. Parameter dengan suffix `Buy`/`Sell`
> mengontrol sisi masing-masing secara terpisah.

## Shared

| Parameter       | Default | Type   | Description                                  |
|----------------|---------|--------|----------------------------------------------|
| MagicNumber    | 1888    | int    | Unique ID to distinguish bot orders          |
| UseTrailingStop| true    | bool   | Enable trailing stop (global on/off)         |

## BUY Grid

| Parameter              | Default | Type   | Description                                     |
|------------------------|---------|--------|-------------------------------------------------|
| EnableBuyGrid          | true    | bool   | Enable BUY baskets entirely                     |
| StartLotBuy            | 0.01    | double | Lot size for first BUY grid level               |
| MultiplierBuy          | 1.5     | double | Lot multiplier per BUY level                    |
| GridStepBuy            | 250     | int    | Distance between BUY grid levels (pips)         |
| GeneralTPBuy           | 25      | int    | Overall take profit for BUY basket (pips)       |
| OrdersPerStepBuy       | 2       | int    | Orders per BUY grid level                       |
| MaxGridLevelBuy        | 20      | int    | Max BUY grid levels                             |
| StopLossPipsBuy        | 375     | int    | Stop loss distance per BUY order (pips)         |
| FixedDistanceBuy       | 10      | int    | BUY trailing distance (pips)                    |
| TriggerDistanceBuy     | 15      | int    | Min BUY distance before trailing activates      |
| MinGapPipsBuy          | 3.0     | double | Min MA gap to open a BUY basket (pips)          |
| EntryCooldownSecBuy    | 30      | int    | Cooldown between BUY entries (sec)              |
| MaxBasketsPerSideBuy   | 5       | int    | Max concurrent BUY baskets                      |

## SELL Grid

| Parameter              | Default | Type   | Description                                     |
|------------------------|---------|--------|-------------------------------------------------|
| EnableSellGrid         | true    | bool   | Enable SELL baskets entirely                    |
| StartLotSell           | 0.01    | double | Lot size for first SELL grid level              |
| MultiplierSell         | 1.5     | double | Lot multiplier per SELL level                   |
| GridStepSell           | 250     | int    | Distance between SELL grid levels (pips)        |
| GeneralTPSell          | 25      | int    | Overall take profit for SELL basket (pips)      |
| OrdersPerStepSell      | 2       | int    | Orders per SELL grid level                      |
| MaxGridLevelSell       | 20      | int    | Max SELL grid levels                            |
| StopLossPipsSell       | 375     | int    | Stop loss distance per SELL order (pips)        |
| FixedDistanceSell      | 10      | int    | SELL trailing distance (pips)                   |
| TriggerDistanceSell    | 15      | int    | Min SELL distance before trailing activates     |
| MinGapPipsSell         | 3.0     | double | Min MA gap to open a SELL basket (pips)         |
| EntryCooldownSecSell   | 30      | int    | Cooldown between SELL entries (sec)             |
| MaxBasketsPerSideSell  | 5       | int    | Max concurrent SELL baskets                     |

## MA Entry Signal (shared — single crossover)

| Parameter     | Default | Type | Description                     |
|---------------|---------|------|---------------------------------|
| MAFastPeriod  | 5       | int  | Fast MA period (sensitive)      |
| MASlowPeriod  | 20      | int  | Slow MA period (trend)          |
| MAMethod      | 0 (SMA) | int  | 0=SMA, 1=EMA, 2=SMMA, 3=LWMA   |
| MAPrice       | 0 (Close)| int  | 0=Close, 1=Open, 2=High, 3=Low, 4=Median, 5=Typical, 6=Weighted |
| BBPeriod      | 20      | int  | Bollinger Bands period (unused) |
| BBDeviation   | 2.0     | double | Bollinger Bands deviation (unused) |

## Time Filter

| Parameter          | Default | Type   | Description                     |
|-------------------|---------|--------|---------------------------------|
| StartTime         | 00:00   | string | Trading start time              |
| EndTime           | 23:59   | string | Trading end time                |
| FridayTrade       | true    | bool   | Enable Friday trading           |
| FridayStop        | 14:00   | string | Friday stop time                |
| UseExtraTime      | true    | bool   | Enable extra trading window     |
| ExtraStart        | 01:06   | string | Extra window start              |
| ExtraEnd          | 01:07   | string | Extra window end                |
| AdditionalGridStep| 100     | int    | Grid step during extra window (shared) |

## Risk Management

| Parameter        | Default | Type   | Description                              |
|-----------------|---------|--------|------------------------------------------|
| DailyProfitPct  | 20.0    | double | Stop trading if daily profit reached     |
| WeeklyProfitPct | 20.0    | double | Stop trading if weekly profit reached    |
| DrawdownCloseAll| 90.0    | double | Close all if drawdown exceeds %          |
| MarginCloseAll  | 20.0    | double | Close all if margin level below %        |
| AutoStopTrading | true    | bool   | Enable auto stop on max drawdown         |
| MaxDrawdown     | 15.0    | double | Max drawdown before bot stops            |
| MinMarginLevel  | 1000.0  | double | Minimum margin level %                   |

## News Filter

| Parameter          | Default  | Type   | Description                                  |
|-------------------|----------|--------|----------------------------------------------|
| NewsFilter        | false    | bool   | Enable news filter                           |
| NewsMinutesBefore | 30       | int    | Minutes before news (no entry)               |
| NewsMinutesAfter  | 60       | int    | Minutes after news (no entry)                |
| NewsRefreshMin    | 15       | int    | News data refresh interval (minutes)         |
| NewsCurrencies    | GBP,USD  | string | Currencies to monitor (comma separated)      |
| NewsTimezoneOffset| 0        | int    | Timezone offset broker from UTC (e.g. 2, -5) |

## Nota (v1.12)

- `.set` presets lama **tidak kompatibel 1:1** — nama parameter berubah
  (mis. `StartLot` → `StartLotBuy`/`StartLotSell`).
- Magic number per basket: BUY = `Magic*100 + id`, SELL = `Magic*100 + MaxBasketsPerSideBuy + id`.
