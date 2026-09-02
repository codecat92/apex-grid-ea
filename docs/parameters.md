# Apex Grid EA — Parameter Reference (v1.15)

> Parameter dikelompokkan per sisi BUY/SELL. Default telah diselaraskan dengan
> behaviour Yetti Classic (rounding lot, grid step berbasis POINT, single-basket,
> GeneralTP 200, opsi SL ala Yetti). Nilai tetap dapat diubah user via tab Inputs.

## Shared

| Parameter       | Default | Type   | Description                                  |
|----------------|---------|--------|----------------------------------------------|
| MagicNumber    | 1888    | int    | Unique ID to distinguish bot orders          |
| UseTrailingStop| true    | bool   | Enable trailing stop (global on/off)         |

## BUY Grid

| Parameter              | Default | Type   | Description                                     |
|------------------------|---------|--------|-------------------------------------------------|
| EnableBuyGrid          | true    | bool   | Enable BUY baskets entirely                     |
| StartLotBuy            | 0.13    | double | Lot for first BUY level (Yetti-aligned)         |
| MultiplierBuy          | 1.5     | double | Lot multiplier per BUY level                    |
| GridStepBuy            | 250     | int    | BUY grid distance in POINTS (250 = 25 pips 5-digit) |
| GeneralTPBuy           | 200     | int    | Overall take profit for BUY basket (pips, Yetti-aligned) |
| OrdersPerStepBuy       | 2       | int    | Orders per BUY grid level                       |
| MaxGridLevelBuy        | 20      | int    | Max BUY grid levels                             |
| StopLossPipsBuy        | 375     | int    | Stop loss distance per BUY order (pips)         |
| UseStopLossBuy         | true    | bool   | Enable per-order SL for BUY (false = SL 0 ala Yetti) |
| FixedDistanceBuy       | 10      | int    | BUY trailing distance (pips)                    |
| TriggerDistanceBuy     | 15      | int    | Min BUY distance before trailing activates      |
| MinGapPipsBuy          | 3.0     | double | Min MA gap to open a BUY basket (pips)          |
| EntryCooldownSecBuy    | 30      | int    | Cooldown between BUY entries (sec)              |
| MaxBasketsPerSideBuy   | 1       | int    | Max concurrent BUY baskets (1 = Yetti single-basket) |

## SELL Grid

| Parameter              | Default | Type   | Description                                     |
|------------------------|---------|--------|-------------------------------------------------|
| EnableSellGrid         | true    | bool   | Enable SELL baskets entirely                    |
| StartLotSell           | 0.13    | double | Lot for first SELL level (Yetti-aligned)        |
| MultiplierSell         | 1.5     | double | Lot multiplier per SELL level                   |
| GridStepSell           | 250     | int    | SELL grid distance in POINTS (250 = 25 pips 5-digit) |
| GeneralTPSell          | 200     | int    | Overall take profit for SELL basket (pips, Yetti-aligned) |
| OrdersPerStepSell      | 2       | int    | Orders per SELL grid level                      |
| MaxGridLevelSell       | 20      | int    | Max SELL grid levels                            |
| StopLossPipsSell       | 375     | int    | Stop loss distance per SELL order (pips)        |
| UseStopLossSell        | true    | bool   | Enable per-order SL for SELL (false = SL 0 ala Yetti) |
| FixedDistanceSell      | 10      | int    | SELL trailing distance (pips)                   |
| TriggerDistanceSell    | 15      | int    | Min SELL distance before trailing activates     |
| MinGapPipsSell         | 3.0     | double | Min MA gap to open a SELL basket (pips)         |
| EntryCooldownSecSell   | 30      | int    | Cooldown between SELL entries (sec)             |
| MaxBasketsPerSideSell  | 1       | int    | Max concurrent SELL baskets (1 = Yetti single-basket) |

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
| AdditionalGridStep| 100     | int    | Grid step during extra window (points) |

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

## Perubahan v1.15 (transparansi log)

Setiap kejadian yang menghentikan atau memblokir trading kini dicetak di log dalam
kalimat lengkap (English) agar investigasi mudah:

- **STOPPED** — bot berhenti trading. Penyebab verbatim + nilai terukur:
  - Drawdown melebihi `MaxDrawdown`
  - Drawdown kritis `DrawdownCloseAll` (semua posisi ditutup)
  - Margin kritis `MarginCloseAll` (semua posisi ditutup)
  - Margin di bawah `MinMarginLevel`
  - Daily / Weekly profit target tercapai
- **Trading resumed** — bot mulai lagi setelah reset harian/mingguan, mencantumkan
  penyebab stop sebelumnya.
- **Trading blocked** — entry diblokir sementara (dithrottle ~5 menit): weekend,
  di luar jam aktif, Friday-stop, atau news filter.
- **OnInit** mencetak ringkasan konfigurasi aktif untuk verifikasi parameter.

Log hanya dicetak saat terjadi **transisi state** (tidak membanjiri log).

## Perubahan v1.14 (exit ala Yetti)

- **`GeneralTPBuy/Sell` = 200 pips** — menyamai parameter UI Yetti (terbaca 200).
  Mengurangi penutupan prematur; biarkan profit-peak trailing menahan basket seperti Yetti.
- **`UseStopLossBuy/Sell` (default true)** — toggle SL per order. Saat `false`,
  semua `OrderSend` memakai SL = 0 (persis Yetti `sl: 0.00000`), termasuk fallback error-130.
- Exit basket dalam tetap via profit-peak trailing (`CheckTrailing` + `BasketClose`) — sudah sesuai pola Yetti.

## Perubahan v1.13 (align ke Yetti)

- **Rounding lot**: `NormalizeLot()` kini memakai `MathRound` (bukan `MathFloor`).
  Deret 0.13 → 0.20 → 0.29 → 0.44 → 0.66 → 0.99 → 1.48 → 2.22 (persis log Yetti 26 Ags).
- **GridStep berbasis POINT**: jarak grid = `GridStep × Point`.
  250 points = 25 pips (GBPUSD 5-digit), sama dengan grid Yetti.
- **Single-basket**: `MaxBasketsPerSideBuy/Sell = 1` — satu basket dalam per sisi seperti Yetti.
- **StartLot = 0.13** untuk kedua sisi.

## Catatan Risiko

- `MaxGridLevel = 20` dengan grid step 25 pips = kedalaman 500 pips.
- Lot level 20 ≈ **432 lot** per order (×2 order = ~864/level) — jauh di atas yang
  pernah tercapai Yetti (level 10, ~7.5 lot). Untuk uji komposisi kecil, turunkan
  `MaxGridLevel` atau `StartLot`.
- SL 375 pips per order tetap dipasang sebagai proteksi (Yetti tidak memakai SL);
  matikan via `UseStopLossBuy/Sell=false` hanya jika ingin murni ala Yetti.

## Nota (v1.12)

- `.set` presets lama **tidak kompatibel 1:1** — nama parameter berubah
  (mis. `StartLot` → `StartLotBuy`/`StartLotSell`).
- Magic number per basket: BUY = `Magic*100 + id`, SELL = `Magic*100 + MaxBasketsPerSideBuy + id`.
