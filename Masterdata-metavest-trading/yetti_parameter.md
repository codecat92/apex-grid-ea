# Yetti Classic v3.03_fix — Parameter Reference

> **Sumber:** Akun live JDR Securities (15023)
> **Dicatat pada:** *Senin, 15 Juni 2026 pukul 11:42 WIB*
> ⚠️ **PENTING:** Data ini adalah *snapshot* pada waktu di atas. Jika parameter di server berubah, dokumen ini tidak lagi akurat. Selalu verifikasi sebelum menggunakan sebagai acuan.
> **Platform:** MetaTrader 4, Chart: GBPUSD M1
> **Template:** "Yetti Gold Template"

---

## 1. Core Trading Parameters

| Parameter | Value | Tipe |
|---|---|---|
| Activation Code | ---------- | string |
| The name of the setting | Yetti Gold Template | string |
| Caption color | DeepSkyBlue | color |
| Working time frame | current | enum |
| Magic number | 1888 | int |
| Start lot | 0.1 | double |
| Multiplier | 1.5 | double |
| Grid step | 250 | int |
| General take profit | 200 | int |

---

## 2. Drying Mode (AutoDryer — DISABLED)

| Parameter | Value | Tipe |
|---|---|---|
| Percentage of profit in drying mode | 0.5 | double |
| Use "Take equity function" | false | bool |
| Percentage of profit taking | 2.12 | double |
| Profit percentage per day (%) | 20 | double |
| Profit percentage per week (%) | 20 | double |
| Drawdown percentage - all orders are closed | 90 | double |
| Margin level - all orders are closed | 20 | double |
| Use AutoDryer | **false** | bool |
| (hours) Auto dryer start interval | 4 | int |
| (minutes) Power on interval AutoDryer | 0 | int |
| (hours) AutoDryer Run Time | 1 | int |
| (in minutes) AutoDryer Run Time | 0 | int |

---

## 3. Time Filter

| Parameter | Value | Tipe |
|---|---|---|
| Start time of main trade | 01:00 | string |
| Time of end of main trade | 22:00 | string |
| Friday trade | true | bool |
| Time to end trading on Friday | 14:00 | string |
| Use extra time | true | bool |
| Re-trade the grid before the change of main trading time | **true** | bool |
| Time to start additional trading | 01:06 | string |
| Time to end additional trading | 01:07 | string |
| Step of the additional grid order | 100 | int |

---

## 4. Dynamic Pitch (DISABLED)

| Parameter | Value | Tipe |
|---|---|---|
| Use dynamic pitch | **false** | bool |
| Dynamic step size | 10 | int |

---

## 5. Grid Configuration

| Parameter | Value | Tipe |
|---|---|---|
| Number of orders in one step | **2** | int |

---

## 6. Trailing Exit

| Parameter | Value | Tipe |
|---|---|---|
| Include trailing stop | true | bool |
| Fixed distance from the price | 50 | int |
| Trailing Stop triggering distance | 160 | int |

---

## 7. Risk Shutdown

| Parameter | Value | Tipe |
|---|---|---|
| On / Off Auto Stop Trading | true | bool |
| Maximum drawdown level | 15.0 | double |
| Minimum margin level | 1000.0 | double |

---

## 8. Locking System (FIRST & SECOND — BOTH DISABLED)

| Parameter | Value | Tipe |
|---|---|---|
| Use first lock on account | **false** | bool |
| Margin level, at which lock occurs | 5000.0 | double |
| Drawdown at which the lock occurs | 50.0 | double |
| Size of the first lock - percentage of the lot | 50 | int |
| Use the second locking of the account | **false** | bool |
| Margin level, at which lock occurs | 1000.0 | double |
| Drawdown, at which the lock occurs | 70.0 | double |
| Size of the second lock - percentage of the lot | 50 | int |

---

## 9. News Filter (ENABLED)

| Parameter | Value | Tipe |
|---|---|---|
| News filter | **true** | bool |
| Minutes triggering before news | 30 | int |
| Minutes triggering after news | 60 | int |
| Show important news | true | bool |
| Show average news | false | bool |
| Show weak news | false | bool |
| Currencies to be shown in the news (comma-separated) | USD,EUR,GBP,CHF,CAD,AUD,NZD,JPY | string |

---

## 10. Display

| Parameter | Value | Tipe |
|---|---|---|
| Draw lines on the chart | true | bool |
| Font size | 8 | int |

---

## 11. Perbandingan dengan Apex Grid EA

### Parameter yang SUDAH SAMA

| Parameter | Yetti | Apex |
|---|---|---|
| MagicNumber | 1888 | 1888 |
| StartLot | 0.10 | 0.10 |
| Multiplier | 1.5 | 1.5 |
| GridStep | 250 | 250 |
| GeneralTP | 200 | 200 |
| DailyProfitPct | 20 | 20 |
| WeeklyProfitPct | 20 | 20 |
| DrawdownCloseAll | 90 | 90 |
| MarginCloseAll | 20 | 20 |
| Time settings | 01:00–22:00 / Fri 14:00 / Extra 01:06–01:07 | Sama |
| Trailing | FixedDist=50, TriggerDist=160 | Sama |
| MaxDrawdown | 15 | 15 |
| MinMarginLevel | 1000 | 1000 |
| ExtraTime | true | true |
| AdditionalGridStep | 100 | 100 |

### Parameter yang BERBEDA / BELUM ADA di Apex

| Parameter | Yetti | Apex | Prioritas |
|---|---|---|---|
| **News Filter** | true | ❌ Tidak ada | **TINGGI** — Yetti hindari news, Apex tidak |
| **Orders per Step** | **2** | 1 | **TINGGI** — Exposure 2x lipat di Yetti |
| **Re-trade grid before time change** | true | ❌ Tidak ada | **SEDANG** |
| **Bollinger Bands entry** | Ada (observasi visual) | ❌ Hanya MA crossover | **TINGGI** |
| Take equity function | false (disabled) | ❌ Tidak ada | Rendah (disabled) |
| Profit taking % | 2.12% | ❌ Tidak ada | **SEDANG** |
| AutoDryer | false (disabled) | ❌ Tidak ada | Rendah (disabled) |
| Dynamic Pitch | false (disabled) | ❌ Tidak ada | Rendah (disabled) |
| Locking System 1 & 2 | false (disabled) | ❌ Tidak ada | Rendah (disabled) |
| Draw lines on chart | true | ❌ Tidak ada | Rendah |

### Parameter Yetti yang TIDAK ADA di CONTEXT.md

| Parameter | Status |
|---|---|
| Number of orders in one step = 2 | Tidak dicatat di CONTEXT — CONTEXT menyebutkan 1 order per step |
| Re-trade grid before time change = true | Tidak dicatat di CONTEXT |
| News Filter = true (30min before, 60min after) | Exclude list di CONTEXT — tapi Yetti MENGGUNAKANNYA |
| Bollinger Bands | CONTEXT cuma sebut MA crossover, Yetti punya BB juga |
| Take equity function / Profit taking % | Tidak dicatat |

---

*Dokumen ini adalah referensi definitif untuk parameter Yetti Classic v3.03_fix.*
*Setiap perubahan parameter di server Yetti harus di-update ke dokumen ini.*
