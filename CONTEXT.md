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
├── CONTEXT.md              ← dokumen ini, selalu update
├── README.md               ← overview publik
├── src/
│   ├── experts/
│   │   └── ApexGrid.mq4   ← file EA utama
│   ├── indicators/         ← custom indicator (jika ada)
│   └── libraries/          ← fungsi reusable
├── docs/
│   ├── strategy.md         ← penjelasan strategi untuk manusia
│   ├── parameters.md       ← dokumentasi semua parameter
│   └── user-guide.md       ← panduan penggunaan
└── tests/
    └── backtest-results/   ← hasil backtest
```

---

## 4. Arsitektur Bot — 5 Layer

```
LAYER 1 — ENTRY SIGNAL
  Trigger: MA Crossover (Golden Cross / Death Cross)
  Golden Cross (MA Fast memotong MA Slow ke atas) → mulai BUY grid
  Death Cross  (MA Fast memotong MA Slow ke bawah) → mulai SELL grid
  Bot bisa punya BUY grid DAN SELL grid aktif sekaligus

LAYER 2 — GRID MANAGER
  Setiap grid level dibuka saat harga bergerak Grid Step dari entry sebelumnya
  Lot setiap level = Start Lot × Multiplier^N
  Contoh: 0.10 → 0.15 → 0.23 → 0.34 → 0.51 → 0.76 → 1.14

LAYER 3 — EXIT MANAGER (Basket Close)
  Tidak ada SL/TP per posisi (SL = 0, TP = 0)
  Trailing stop aktif setelah harga bergerak Trigger Distance dari entry pertama
  Trailing distance = Fixed Distance
  Saat trailing terpicu: SEMUA posisi searah ditutup sekaligus
  Setelah basket close → reset, tunggu sinyal MA baru

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
| Orders per Step | 2 | int | Jumlah order yang dibuka per level grid |

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
| News Filter | Butuh koneksi internet real-time + wininet.dll, terlalu kompleks untuk v1.0 |
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
2. Grid level 0 dibuka: lot = 0.10
3. Harga bergerak ~250 pips berlawanan → level 1: lot = 0.15
4. Harga bergerak ~250 pips lagi → level 2: lot = 0.23
   ... dst
5. Harga berbalik menguntungkan
6. Trailing stop terpicu ("TRAL:::: close on the trawl")
7. SEMUA posisi searah ditutup sekaligus (basket close)
8. Bot langsung reset dan tunggu sinyal MA berikutnya
```

### Contoh Lot Progression yang Terobservasi:
```
0.10 → 0.15 → 0.23 → 0.34 → 0.51 → 0.76 → 1.14
(semua dikonfirmasi dari log MT4 Yetti yang sedang live)
```

### Comment Format di Order:
```
"Apex Grid BUY"    ← level 0
"Apex Grid BUY 1"  ← level 1
"Apex Grid BUY 2"  ← level 2
"Apex Grid SELL"   ← level 0
"Apex Grid SELL 1" ← level 1
```

---

## 8. Development Progress

### Fase Development:
```
Fase 1 — Grid Manager          : ⏳ Belum mulai
Fase 2 — Basket Close/Trailing : ⏳ Belum mulai
Fase 3 — Entry Signal (MA)     : ⏳ Belum mulai
Fase 4 — Time Filter           : ⏳ Belum mulai
Fase 5 — Risk Shutdown         : ⏳ Belum mulai
Fase 6 — Testing & Dokumentasi : ⏳ Belum mulai
```

### File Status:
```
ApexGrid.mq4  : ⏳ Belum dibuat
strategy.md   : ⏳ Belum dibuat
parameters.md : ⏳ Belum dibuat
user-guide.md : ⏳ Belum dibuat
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

*Last updated: 11 Juni 2026 — Fernando Siahaan*
*Update dokumen ini setiap kali ada perubahan signifikan pada arsitektur atau progress*
