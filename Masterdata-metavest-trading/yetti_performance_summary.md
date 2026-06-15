# Yetti Classic v3.03_fix — Performance Summary (Live Account)

> **Sumber:** Laporan Account History MT4 — Akun live JDR Securities 15023 "Metavest #1"
> **Dicatat pada:** *Senin, 15 Juni 2026*
> ⚠️ **PENTING:** Data diambil dari laporan All History. Angka bisa berubah jika ada trade baru.

---

## 1. Ringkasan Akun

| Item | Nilai |
|---|---|
| Akun | 15023 |
| Nama | Metavest #1 |
| Broker | JDR Securities Limited |
| Mata Uang | USD |
| Pair | GBPUSD M1 |
| **Periode Trading (terobservasi)** | **~September 2025 – Juni 2026 (~9 bulan)** |
| Net Deposit/Withdrawal | **-$10,000** (telah ditarik) |
| Balance Saat Ini | **$35,129.85** |
| Equity | $35,107.05 |
| Margin Terpakai | $50.42 |
| Free Margin | $35,056.63 |

---

## 2. Statistik Kinerja Utama

| Metrik | Nilai | Kategori |
|---|---|---|
| **Closed Trade P/L** | **+$45,129.85** | ⭐⭐⭐⭐⭐ Luar Biasa |
| **Profit Factor** | **3.08** | ⭐⭐⭐⭐⭐ (profit 3× lipat dari loss) |
| **Total Trade** | **1,215** | ~135 trade/bulan, ~4.5 trade/hari |
| **Win Rate** | **68.89%** (837/1215) | ⭐⭐⭐⭐ |
| **Max Drawdown (Balance)** | **$1,741.25 (3.44%)** | ⭐⭐⭐⭐⭐ Sangat Aman |
| **Relative Drawdown** | **8.87% ($1,018.94)** | ⭐⭐⭐⭐⭐ |
| Expected Payoff | $37.14 per trade | Profit konsisten per trade |

---

## 3. Analisis Profit/Loss

| Metrik | Nilai |
|---|---|
| Gross Profit | $66,808.80 |
| Gross Loss | $21,678.95 |
| Largest Profit Trade | **$2,580.48** |
| Largest Loss Trade | **-$358.53** |
| Average Profit Trade | $79.82 |
| Average Loss Trade | -$57.35 |
| **Rasio Avg Win : Avg Loss** | **1.39 : 1** |

---

## 4. Win Rate Per Arah

| Arah | Total | Win Count | Win Rate |
|---|---|---|---|
| **SELL (Short)** | 636 | 440 | **69.18%** |
| **BUY (Long)** | 579 | 397 | **68.57%** |

> Kedua arah hampir seimbang — BUY dan SELL sama-sama menguntungkan.

---

## 5. Streak (Kemenangan & Kekalahan Beruntun)

| Metrik | Nilai |
|---|---|
| Max Consecutive Wins | **21 kali** — total profit $615.66 |
| Max Consecutive Losses | **11 kali** — total loss -$299.98 |
| Max Consecutive Profit (jumlah) | **11 kali** — total profit **$4,360.72** |
| Max Consecutive Loss (jumlah) | **7 kali** — total loss **-$1,741.25** |
| Rata-rata Win Streak | **4 kali berturut-turut** |
| Rata-rata Loss Streak | 2 kali berturut-turut |

---

## 6. Kedalaman Grid (Lot Progression Observasi)

| Level | Lot | Comment Tag |
|---|---|---|
| 0 | 0.10 | `Yetti Start Buy` / `Yetti Start Sell` |
| 1 | 0.15 | `(1)` |
| 2 | 0.23 | `(2)` |
| 3 | 0.34 | `(3)` |
| 4 | 0.51 | `(4)` |
| 5 | 0.76 | `(5)` |
| 6 | 1.14 | `(6)` |
| 7 | 1.71 | `(7)` |
| 8 | 2.56 | `(8)` |
| 9 | 3.84 | `(9)` |
| 10 | 5.77 | `(10)` — disertai `[sl]` (Stop Loss) |

> **Catatan:** Di level 10, Yetti menggunakan **Stop Loss** untuk membatasi risiko. Ini adalah fitur mitigasi yang **tidak dimiliki ApexGrid**.

---

## 7. Open Positions & Working Orders

### Posisi Terbuka Saat Laporan Dibuat
| Ticket | Open | Type | Lot | Entry | Current | P/L |
|---|---|---|---|---|---|---|
| 8995852 | 15 Jun 01:00 | Sell | 0.10 | 1.34252 | 1.34446 | -$19.40 |
| 8995939 | 15 Jun 01:05 | Sell | 0.15 | 1.34512 | 1.34446 | +$9.90 |
| 8996345 | 15 Jun 03:32 | Buy | 0.10 | 1.34564 | 1.34431 | -$13.30 |

**Floating P/L: -$22.80**

### Working Orders (Pending): **Tidak ada**

---

## 8. Ringkasan Bulanan (Observasi)

Berdasarkan analisis data trade:

| Bulan | Estimasi Trade | Karakteristik |
|---|---|---|
| Sep 2025 | ~130 | Banyak level 1-3, small wins |
| Okt 2025 | ~120 | Grid sedang, stabil |
| Nov 2025 | ~130 | — |
| Des 2025 | ~120 | — |
| Jan 2026 | ~130 | — |
| Feb 2026 | ~120 | — |
| Mar 2026 | ~130 | — |
| Apr 2026 | ~140 | **Bulan paling volatile** — grid sampai level 10, profit besar (+$2,580, +$1,533) tapi floating loss signifikan |
| Mei 2026 | ~135 | **BUY grid loss terdalam** — hold 20 hari, level 10 dengan SL, total loss basket -$500 s/d -$2,000 |
| 1-15 Jun 2026 | ~50 | Aktif trading, 3 posisi floating saat ini |

---

## 9. Perbandingan Langsung Yetti vs ApexGrid

| Metrik | **Yetti Live (9 bulan)** | **Apex Backtest (2.5 tahun)** | Selisih |
|---|---|---|---|
| **Total Trade** | **1,215** | **12** | **100× lebih banyak** |
| Profit Factor | 3.08 | 30.55 | Apex lebih tinggi (sample kecil) |
| Max Drawdown | **3.44%** | **14.03%** | Yetti 4× lebih aman |
| Win Rate | 68.89% | 83.33% | Apex lebih tinggi (sample kecil) |
| Avg Win | $79.82 | $379.64 | Perbedaan lot & struktur |
| Avg Loss | -$57.35 | -$62.14 | Hampir sama |
| Rasio W/L | 1.39:1 | 6.1:1 | Apex lebih baik (tapi 12 trade saja) |
| Lot Maksimum | **5.77 (level 10)** | **0.33 (level 3)** | Yetti 17× lebih dalam |
| Kedalaman Grid | Sampai level 10 | Hanya level 3 | Yetti jauh lebih agresif |
| Grid per Siklus | 2 order/level (OrdersPerStep=2) | 1 order/level | Yetti 2× exposure |
| Frekuensi/Bulan | **~135 trade** | **~0.4 trade** | Yetti 337× lebih sering |
| Swap Cost | Signifikan ($50-$140) | Adanya trx hold 1-2 bulan | Yetti lebih efisien |
| **Stop Loss** | **Ada di level 10 [sl]** | **Tidak ada** | Yetti punya perlindungan |
| News Filter | **Aktif** | Tidak ada | Bedanya signifikan |

---

## 10. Insight Kunci untuk Developer

### Kenapa Yetti jauh lebih baik dari Apex?

1. **Frekuensi Entry** — Yetti 337× lebih sering entry. MA crossover saja di M1 tidak cukup. Yetti menggunakan **Bollinger Bands + MA** + kemungkinan di-trigger manual oleh operator.

2. **Grid Kedalaman** — Yetti berani masuk sampai level 10 (5.77 lot) dengan modal yang cukup. ApexGrid hanya level 3 karena parameter konservatif + data backtest 25% memaksa keluar prematur.

3. **OrdersPerStep = 2** — Setiap level, Yetti membuka **2 order**. Ini mempercepat basket mencapai profit, tapi juga memperbesar risiko.

4. **Stop Loss di Level Ekstrem** — Trade terbesar Yetti (level 10, 5.77 lot) menggunakan SL. Ini mencegah drawdown tak terkendali. Apex tidak punya mekanisme ini.

5. **News Filter Aktif** — Yetti tidak trading 30 menit sebelum dan 60 menit setelah news. Menghindari slippage dan spike yang bisa trigger level grid baru secara sia-sia.

6. **Swap Management** — Yetti cenderung tutup trade dalam 1-3 hari (swap cost rendah). Beberapa trade ApexGrid hold 1-2 bulan karena trailing tidak terpicu.

### Rekomendasi Perbaikan ApexGrid:

| Prioritas | Perbaikan | Dampak |
|---|---|---|
| **#1 KRITIS** | **Tambah Bollinger Bands entry** | Naikkan frekuensi trade 10-50× |
| **#2 KRITIS** | **OrdersPerStep = 2** | Samakan exposure dengan Yetti |
| **#3 TINGGI** | **Implement News Filter** | Hindari false entry saat news |
| **#4 TINGGI** | **Tambahkan Max Level + Stop Loss** | Mencegah akun hancur di trending |
| **#5 TINGGI** | **Hilangkan cooldown 5 menit** | Percepat re-entry |
| **#6 SEDANG** | **Basket-level stop loss** | Seperti Yetti [sl] di level tinggi |
| **#7 SEDANG** | **Optimasi trailing untuk tutup < 3 hari** | Kurangi swap cost |

---

## 11. Status Posisi Saat Dokumen Dibuat

```
Floating P/L: -$22.80
Posisi terbuka: 3 (2 Sell + 1 Buy)
Margin terpakai: $50.42 (dari $35,107 equity = 0.14%)
Status: SANGAT AMAN — margin usage < 1%
```

---

*Dokumen ini adalah referensi kinerja untuk membandingkan Yetti Classic dengan Apex Grid EA.*
*Update setelah setiap penarikan laporan dari server live.*
