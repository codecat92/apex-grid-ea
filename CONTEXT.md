# APEX GRID EA — Document of Context
> **Untuk AI Tools:** Baca dokumen ini sebelum mengerjakan apapun.
> Ini adalah source of truth project. Jangan asumsikan hal yang tidak tertulis di sini.

---

## 1. Project Overview

**Nama Bot:** Apex Grid EA
**File Utama:** `src/experts/ApexGrid.mq4`
**Platform:** MetaTrader 4 (MT4)
**Bahasa:** MQL4
**Broker Target:** JDR Securities
**Pair Utama:** GBPUSD
**Timeframe:** M1

**Deskripsi:**
Apex Grid EA adalah implementasi original dari strategi Grid + Martingale trading.
Bot ini terinspirasi dari perilaku Yetti Classic v3.03_fix yang dianalisa melalui
observasi visual (tanpa decompilation).

Bot bekerja dengan membuka posisi berlapis (grid) dengan lot yang semakin besar
(martingale) setiap kali harga bergerak berlawanan arah. Semua posisi ditutup
sekaligus (basket close) ketika trailing stop terpicu.

---

## 2. Team & Tools

| Role | Tools |
|------|-------|
| Developer | Fernando Siahaan (codecat92) |
| Project Manager | Pak Antonius |
| Primary IDE | Cursor |
| Primary AI Coding | OpenCode GO (Deepseek V4 Pro) |
| Consultant AI | Claude Sonnet 4.6 (claude.ai) |
| Version Control | GitHub — github.com/codecat92/apex-grid-ea |
| Testing Platform | MetaTrader 4 Strategy Tester |
| Terminal | Warp |

---

## 3. Repository Structure

```
apex-grid-ea/
├── AGENTS.md                ← instruksi untuk AI coding tools
├── opencode.json            ← konfigurasi OpenCode GO
├── CONTEXT.md               ← dokumen ini, selalu update
├── README.md                ← overview publik
├── .vscode/                 ← konfigurasi VS Code / Cursor
├── strategy-test-result/    ← hasil backtest MT4 (HTML)
├── error-logs/              ← log error debugging
├── src/
│   ├── experts/
│   │   └── ApexGrid.mq4    ← file EA utama
│   ├── indicators/          ← custom indicator (jika ada)
│   └── libraries/           ← fungsi reusable
├── docs/
│   ├── strategy.md                       ← penjelasan strategi
│   ├── parameters.md                     ← dokumentasi parameter
│   ├── user-guide.md                     ← panduan penggunaan
│   ├── report_modul_non_technical.md      ← laporan non-teknis
│   ├── penjelasan_kode_apexGrid.md        ← penjelasan kode per blok (pemula)
│   └── proses_debug.md                   ← jurnal perjalanan debugging
└── tests/
    └── backtest-results/    ← hasil backtest
```

---

## 4. Arsitektur Bot — 5 Layer

```
LAYER 1 — ENTRY SIGNAL
  ⚠️ Yetti asli: Bollinger Bands + MA (belum dikonfirmasi full, observasi visual)
  ApexGrid: MA Crossover (Golden Cross / Death Cross)
  Golden Cross (MA Fast memotong MA Slow ke atas) → mulai BUY grid
  Death Cross  (MA Fast memotong MA Slow ke bawah) → mulai SELL grid
  Bot bisa punya BUY grid DAN SELL grid aktif sekaligus

LAYER 2 — GRID MANAGER
  Level 0 = market order (instant entry) di harga pasar saat sinyal muncul
  Level > 0 = pending stop order (Buy Stop / Sell Stop) di harga grid yang dihitung
  Setiap level dibuka saat harga bergerak Grid Step dari entry terendah (BUY) / tertinggi (SELL)
  Lot setiap level = Start Lot × Multiplier^N
  Contoh: 0.10 → 0.15 → 0.23 → 0.34 → 0.51 → 0.76 → 1.14
  Gap-fill: jika pending order terlewat harga, dihapus lalu diganti market order
  Fallback ke market order jika error 130 (invalid stops, harga terlalu dekat)

LAYER 3 — EXIT MANAGER (Basket Close)
  Tidak ada SL/TP per posisi (SL = 0, TP = 0)
  Trailing stop profit-peak: melacak profit tertinggi basket (bukan harga)
  Trailing aktif setelah harga bergerak Trigger Distance dari entry pertama
  Saat profit basket turun FixedDistance pips (dalam nilai uang) dari puncak → basket close
  General TP: basket close jika rata-rata harga tertimbang lot mencapai GeneralTP pips
  5-minute cooldown setelah basket close sebelum sinyal MA baru bisa entry lagi
  Saat trailing terpicu: SEMUA posisi searah (termasuk pending orders) ditutup sekaligus

LAYER 4 — TIME FILTER
  Bot hanya aktif di jam yang diset
  Jumat ada batas waktu stop untuk hindari gap weekend
  Ada extra trading window di awal sesi

LAYER 5 — RISK SHUTDOWN
  Monitor drawdown, margin level, profit harian/mingguan
  Jika batas terlampaui → stop trading atau close all
```

---

## 5. Parameter Lengkap

### Core Trading
| Parameter | Value | Tipe | Keterangan |
|-----------|-------|------|------------|
| Magic Number | 1888 | int | ID unik bot, untuk bedakan order bot ini dengan order manual |
| Start Lot | 0.10 | double | Ukuran lot pertama di setiap grid |
| Multiplier | 1.5 | double | Pengali lot setiap level grid baru |
| Grid Step | 250 | int | Jarak dalam pips antar level grid |
| General TP | 200 | int | Take profit keseluruhan dalam pips |
| Orders per Step | 2 | int | Jumlah order yang dibuka per level grid (Yetti = 2, Apex default = 1) |

### MA Entry Signal
| Parameter | Value | Tipe | Keterangan |
|-----------|-------|------|------------|
| MA Fast Period | 5 | int | Periode MA cepat (sensitif) |
| MA Slow Period | 40 | int | Periode MA lambat (tren) |
| MA Method | SMA | enum | Simple Moving Average |
| MA Price | Close | enum | Dihitung dari harga penutupan candle |

### Trailing Exit
| Parameter | Value | Tipe | Keterangan |
|-----------|-------|------|------------|
| Use Trailing Stop | true | bool | Aktifkan trailing stop |
| Fixed Distance | 50 | int | Jarak trailing dalam pips |
| Trigger Distance | 160 | int | Jarak minimal sebelum trailing aktif |

### Time Filter
| Parameter | Value | Tipe | Keterangan |
|-----------|-------|------|------------|
| Start Time | 01:00 | string | Jam mulai trading |
| End Time | 22:00 | string | Jam berhenti trading |
| Friday Trade | true | bool | Aktifkan trading hari Jumat |
| Friday Stop | 14:00 | string | Jam stop trading di Jumat |
| Use Extra Time | true | bool | Aktifkan window tambahan |
| Extra Start | 01:06 | string | Jam mulai extra window |
| Extra End | 01:07 | string | Jam akhir extra window |
| Additional Grid Step | 100 | int | Grid step khusus extra window |

### Risk Management
| Parameter | Value | Tipe | Keterangan |
|-----------|-------|------|------------|
| Daily Profit % | 20 | double | Stop trading jika profit harian tercapai |
| Weekly Profit % | 20 | double | Stop trading jika profit mingguan tercapai |
| Drawdown Close All | 90 | double | Tutup semua posisi jika drawdown > 90% |
| Margin Close All | 20 | double | Tutup semua jika margin < 20% |
| Auto Stop Trading | true | bool | Aktifkan auto stop |
| Max Drawdown | 15 | double | Batas drawdown sebelum bot berhenti |
| Min Margin Level | 1000 | double | Batas minimum margin level |

---

## 6. Yang Di-EXCLUDE (dan Alasannya)

| Fitur | Alasan Exclude |
|-------|----------------|
| News Filter | ⚠️ **Yetti PAKAI News Filter (true), 30m before + 60m after.** Belum diimplement di Apex karena butuh wininet.dll. PRIORITAS TINGGI untuk v1.1 |
| Sinyal Eksternal (smart921) | Kita pakai MA Crossover sebagai pengganti sinyal entry |
| Locking System | Disabled di Yetti asli, skip untuk v1.0 |
| AutoDryer | Disabled di Yetti asli, skip untuk v1.0 |
| Dynamic Pitch | Disabled di Yetti asli, skip untuk v1.0 |
| Activation/License | Tidak relevan untuk implementasi kita |
| Draw Lines on Chart | Nice to have, prioritas rendah |

---

## 7. Pola Trading yang Terobservasi dari Yetti

### Siklus Lengkap (dari observasi log):
```
1. MA Crossover terjadi → bot mulai BUY atau SELL grid
2. Grid level 0 dibuka: lot = 0.10 (market order)
3. Harga bergerak ~250 pips berlawanan → level 1: lot = 0.15 (pending BuyStop/SellStop)
4. Harga bergerak ~250 pips lagi → level 2: lot = 0.23 (pending)
   ... dst
5. Gap-fill: jika price melompati pending order tanpa trigger → delete pending + market order
6. Harga berbalik menguntungkan
7. Trailing stop terpicu (profit-peak drop FixedDistance)
8. SEMUA posisi searah (market + pending) ditutup sekaligus (basket close)
9. 5-minute cooldown → bot reset dan tunggu sinyal MA berikutnya
```

### Contoh Lot Progression yang Terobservasi:
```
0.10 → 0.15 → 0.23 → 0.34 → 0.51 → 0.76 → 1.14
(semua dikonfirmasi dari log MT4 Yetti yang sedang live)

⚠️ Yetti buka 2 ORDER per level (OrdersPerStep=2),
   jadi total lot per level = 2 × nilai di atas
```

### Comment Format di Order:
```
"Apex Grid BUY"    ← level 0
"Apex Grid BUY 1"  ← level 1
"Apex Grid BUY 2"  ← level 2
"Apex Grid SELL"   ← level 0
"Apex Grid SELL 1" ← level 1
```

### Fitur Yetti yang Belum Ada di Apex:
| Fitur | Prioritas | Keterangan |
|---|---|---|
| **News Filter** | TINGGI | 30m sebelum + 60m setelah news, Yetti tidak trading |
| **Bollinger Bands entry** | TINGGI | Observasi visual di chart Yetti |
| **OrdersPerStep = 2** | TINGGI | Yetti buka 2 order per level grid |
| **Re-trade grid before time change** | SEDANG | Yetti buka ulang grid sebelum sesi ganti |
| **Profit taking %** | SEDANG | Yetti punya fitur take equity 2.12% |

### Dokumentasi Referensi:
- **Parameter Yetti definitif:** `yetti_parameter.md` (dicatat dari server live, 12 Juni 2026)
- **Kinerja Yetti live:** `yetti_performance_summary.md` (dari laporan All History, 15 Juni 2026)

### Benchmark Yetti Live (Target ApexGrid):

| Metrik | Yetti (Live, 9 bln) | Apex (Backtest, 2.5 thn) |
|---|---|---|
| Total Trade | **1,215** | 12 |
| Profit Factor | 3.08 | 30.55 |
| Max Drawdown | **3.44%** | 14.03% |
| Win Rate | 68.89% | 83.33% |
| Avg Win : Avg Loss | $79.82 : $57.35 | $379 : $62 |
| Frekuensi/Bulan | **135 trade** | 0.4 trade |
| Lot Maksimum | 5.77 (level 10) | 0.33 (level 3) |
| Orders/Level | **2** | 1 |
| Stop Loss | ✅ (level 10 [sl]) | ❌ |
| News Filter | ✅ Aktif | ❌ |

> **Kesenjangan terbesar:** Frekuensi trade (337×), kedalaman grid (level 10 vs 3), dan News Filter.

---

## 8. Development Progress

### Fase Development:
```
Fase 1 — Grid Manager          : ✅ Selesai (Layer 2)
Fase 2 — Basket Close/Trailing : ✅ Selesai (Layer 3)
Fase 3 — Entry Signal (MA)     : ✅ Selesai (Layer 1)
Fase 4 — Time Filter           : ✅ Selesai (Layer 4)
Fase 5 — Risk Shutdown         : ✅ Selesai (Layer 5)
Fase 6 — Testing & Dokumentasi : ⏳ Perlu testing di MT4
```

### Changelog Ringkas:
```
v1.00 — Semua 5 layer dasar: MA entry, Grid market order, Basket close, Time filter, Risk shutdown
v1.02 — Fix: OrderSend/OrderClose error handling, GeneralTP, lot decimal, time filter, stop reason
v1.03 — Fitur Yetti-aligned: pending stop orders, basket-average TP, profit-peak trailing,
        post-close cooldown 5 menit, gap-fill mechanism, error 130 fallback
v1.03f1 — Fix: RefreshRates bail-out dihapus (block order di Strategy Tester)
v1.03f2 — Fix: margin level default 0 → DBL_MAX (trigger STOP_MARGIN tanpa posisi)
v1.03f3 — Fix: iTime() → Time[] (bar guard silent fail saat history desync)
v1.03f4 — Fix: OrderDelete return unchecked, tickets[] uninitialized (compiler warnings)
v1.04 — Yetti-aligned: OrdersPerStep=2, MaxGridLevel+StopLoss, Bollinger Bands entry filter, cooldown=0, daily reset all stop reasons
```

### File Status:
```
ApexGrid.mq4                    : ✅ Dibuat (v1.04, 765 baris)
strategy.md                     : ✅ Dibuat
parameters.md                   : ✅ Dibuat
user-guide.md                   : ✅ Dibuat
report_modul_non_technical.md   : ✅ Dibuat
penjelasan_kode_apexGrid.md     : ✅ Dibuat
proses_debug.md                 : ✅ Dibuat
```

---

## 9. Rules of Development

1. **Setiap kode harus disertai penjelasan** — apa yang dilakukan, kenapa, dan efeknya di MT4
2. **Commit message harus jelas** — format: `feat:`, `fix:`, `docs:`, `test:`
3. **Update CONTEXT.md** setiap kali ada perubahan arsitektur atau progress
4. **Report WA setiap jam 17:00** — progress harian ke grup Pak Anton
5. **Vibe coding workflow** — OpenCode GO (Deepseek) untuk generate, Cursor untuk review, Claude untuk konsultasi

---

## 10. Referensi

- Yetti Classic v3.03_fix — dianalisa via observasi visual (tanpa decompilation)
- Laporan investigasi lengkap: `docs/Investigasi_Yetti_Classic_EA.docx`
- MQL4 Documentation: https://docs.mql4.com
- Metavest EA (project sebelumnya): github.com/codecat92/metavest-ea

---

*Last updated: 15 Juni 2026 — Tambah benchmark Yetti live (1,215 trade, PF 3.08, DD 3.44%), kinerja summary, gap analysis*
*Update dokumen ini setiap kali ada perubahan signifikan pada arsitektur atau progress*
