# Apex Grid EA — Parameter Reference

## Core Trading

| Parameter       | Default | Type   | Description                             |
|----------------|---------|--------|-----------------------------------------|
| MagicNumber    | 1888    | int    | Unique ID to distinguish bot orders     |
| StartLot       | 0.10    | double | Lot size for first grid level           |
| Multiplier     | 1.5     | double | Lot multiplier per level                |
| GridStep       | 250     | int    | Distance between grid levels (pips)     |
| GeneralTP      | 200     | int    | Overall take profit (pips, reserved)    |
| OrdersPerStep  | 2       | int    | Number of orders per grid level         |

## MA Entry Signal

| Parameter     | Default | Type | Description                     |
|---------------|---------|------|---------------------------------|
| MAFastPeriod  | 5       | int  | Fast MA period (sensitive)      |
| MASlowPeriod  | 40      | int  | Slow MA period (trend)          |
| MAMethod      | 0 (SMA) | int  | 0=SMA, 1=EMA, 2=SMMA, 3=LWMA   |
| MAPrice       | 0 (Close)| int  | 0=Close, 1=Open, 2=High, 3=Low, 4=Median, 5=Typical, 6=Weighted |

## Trailing Exit

| Parameter        | Default | Type | Description                              |
|------------------|---------|------|------------------------------------------|
| UseTrailingStop  | true    | bool | Enable trailing stop                     |
| FixedDistance    | 50      | int  | Trailing distance (pips)                 |
| TriggerDistance  | 160     | int  | Min distance before trailing activates   |

## Time Filter

| Parameter          | Default | Type   | Description                     |
|-------------------|---------|--------|---------------------------------|
| StartTime         | 01:00   | string | Trading start time              |
| EndTime           | 22:00   | string | Trading end time                |
| FridayTrade       | true    | bool   | Enable Friday trading           |
| FridayStop        | 14:00   | string | Friday stop time                |
| UseExtraTime      | true    | bool   | Enable extra trading window     |
| ExtraStart        | 01:06   | string | Extra window start              |
| ExtraEnd          | 01:07   | string | Extra window end                |
| AdditionalGridStep| 100     | int    | Grid step during extra window   |

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
