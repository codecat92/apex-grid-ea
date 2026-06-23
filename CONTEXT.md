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

## 4. Arsitektur Bot — 6 Layer

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

LAYER 6 — NEWS FILTER (v1.07)
   Mencegah entry saat rilis berita ekonomi penting
   WebRequest() langsung ke nfs.faireconomy.media (Fair Economy, Inc.)
   Tanpa aplikasi terpisah — semua di dalam EA
   Currency filter: user pilih mata uang mana yang dimonitor
   Fail-open: jika fetch gagal, EA tetap trading normal
   Setup user: Tools→Options→Expert Advisors→Allow WebRequest + centang NewsFilter
   Lihat docs/news-filter-setup.md untuk panduan lengkap
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

### News Filter (v1.07)
| Parameter | Value | Tipe | Keterangan |
|-----------|-------|------|------------|
| News Filter | false | bool | Aktifkan news filter |
| News Minutes Before | 30 | int | Menit sebelum news rilis (no entry) |
| News Minutes After | 60 | int | Menit setelah news rilis (no entry) |
| News Refresh Min | 15 | int | Interval refresh baca file news (menit) |
| News Currencies | USD,EUR,GBP,... | string | Daftar mata uang yang dimonitor (koma) |
| News Timezone Offset | 0 | int | Offset jam broker dari UTC |

---

## 6. Yang Di-EXCLUDE (dan Alasannya)

| Fitur | Alasan Exclude |
|-------|----------------|
| News Filter | ✅ **SUDAH DIIMPLEMENT v1.07.** 30m before + 60m after. Butuh news_fetcher.py (Python) atau news_fetcher.exe (PyInstaller) + Windows Scheduler |
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
| **Re-trade grid before time change** | SEDANG | Yetti buka ulang grid sebelum sesi ganti |
| **Profit taking %** | SEDANG | Yetti punya fitur take equity 2.12% |

### Dokumentasi Referensi:
- **Parameter Yetti definitif:** `yetti_parameter.md` (dicatat dari server live, 12 Juni 2026)
- **Kinerja Yetti live:** `yetti_performance_summary.md` (dari laporan All History, 15 Juni 2026)
- **Perbandingan Yetti vs Apex:** `perbandingan_yetti_vs_apex.md` (periode overlap Nov 2025–Jun 2026)

### Benchmark Yetti Live vs Apex (Periode Overlap Nov 2025 – Jun 2026):

| Metrik | Yetti (Live) | Apex (Backtest) | Gap |
|---|---|---|---|
| Total Trade | **965** | 36 | 26.8× |
| Net Profit | **+$26,359** | +$3,864 | 6.8× |
| Profit Factor | 2.51 | 2.61 | ✅ Setara |
| Win Rate | 68.8% | 72.2% | ✅ Setara |
| Frekuensi/Bulan | **125 trade** | 4.8 trade | 26× |
| Max Consecutive Loss | 4 | 4 | ✅ SAMA |
| Avg Win : Avg Loss | $66 : $59 | $241 : $239 | Rasio setara |
| Auto-SL | ✅ Built-in | ✅ 375 pips | ✅ |
| Stop Out | 0 | 0 | ✅ SAMA |

> **Gap terbesar:** Frekuensi entry (26×). Root cause: News Filter + Re-trade before time change belum diimplement.

---

## 8. Development Progress

### Fase Development:
```
Fase 1 — Grid Manager          : ✅ Selesai (Layer 2)
Fase 2 — Basket Close/Trailing : ✅ Selesai (Layer 3)
Fase 3 — Entry Signal (MA)     : ✅ Selesai (Layer 1)
Fase 4 — Time Filter           : ✅ Selesai (Layer 4)
Fase 5 — Risk Shutdown         : ✅ Selesai (Layer 5)
Fase 6 — Testing & Dokumentasi : ✅ Selesai (7 backtest, perbandingan Yetti, laporan final)
Fase 7 — News Filter           : ✅ Selesai — v1.07, branch feat/news-filter (Layer 6)
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
v1.06 — StopLossPips extern (375 pips), ganti hardcoded GridStep*2 jadi konfigurable
v1.07 — News Filter (Layer 6): news_fetcher.py scrape Forexfactory, blackout window
         before/after news, currency filter, fail-open architecture
```

### File Status:
```
ApexGrid.mq4                    : ✅ Dibuat (v1.07, ~900 baris)
strategy.md                     : ✅ Dibuat
parameters.md                   : ✅ Dibuat
user-guide.md                   : ✅ Dibuat
news-filter-setup.md            : ✅ Dibuat (panduan setup News Filter)
news_fetcher.py                 : ✅ Dibuat (scraper Forexfactory calendar + PyInstaller spec)
report_modul_non_technical.md   : ✅ Dibuat
penjelasan_kode_apexGrid.md     : ✅ Dibuat
proses_debug.md                 : ✅ Dibuat
yetti_parameter.md              : ✅ Dibuat (parameter Yetti dari server live)
yetti_performance_summary.md    : ✅ Dibuat (kinerja Yetti 1,215 trade)
perbandingan_yetti_vs_apex.md   : ✅ Dibuat (analisis periode overlap)
hasil_testing_apex-grid.md      : ✅ Dibuat (laporan 4 test awal)
laporan-testing_Senin-15-Juni-2026.md : ✅ Dibuat (laporan harian PM)
Apex_progress_report.md         : ✅ Dibuat (progress report untuk klien)
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

*Last updated: 23 Juni 2026 — v1.07 News Filter implementasi, branch feat/news-filter, multi-source scraper + fail-open architecture*
*Update dokumen ini setiap kali ada perubahan signifikan pada arsitektur atau progress*
