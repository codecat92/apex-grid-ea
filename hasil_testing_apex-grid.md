# Laporan Hasil Testing Apex Grid EA

**Tanggal Pengujian:** 12 Juni 2026
**Penguji:** Tim Pengembang (codecat92)
**Platform:** MetaTrader 4 Strategy Tester
**Bot:** Apex Grid EA v1.03
**Pair:** GBPUSD (M1)
**Broker Target:** JDR Securities

---

## 1. Ringkasan Eksekutif

Kami telah melakukan **4 kali pengujian** terhadap Apex Grid EA menggunakan Strategy Tester MT4 dengan berbagai rentang waktu. Hasil menunjukkan bahwa bot **dapat menghasilkan profit dalam kondisi pasar tertentu**, namun memiliki **kelemahan serius** yang dapat menyebabkan kerugian total jika tidak diperbaiki.

**Satu kalimat untuk investor:** Bot ini menghasilkan profit +36% dalam 5 bulan (2024), tapi mati total jika pasar trending panjang tanpa koreksi.

---

## 2. Hasil Pengujian

### Pengujian 1 — Periode Januari–Juni 2026

| Metrik | Nilai |
|---|---|
| Deposit Awal | $10,000 |
| Saldo Akhir | $11,015 |
| Laba Bersih | +$1,015 (+10,1%) |
| Total Transaksi | 14 kali |
| Menang | 9 kali (64%) |
| Kalah | 5 kali (36%) |
| Max Kerugian Terbuka | 23,9% ($2,616) |
| Profit Factor | 1,67 |

**Analisis:** Keuntungan kecil, tapi satu rangkaian BUY grid 4 level rugi -$1,467 sekaligus di akhir periode. Ini pertanda bahaya: **sekali rugi bisa melenyapkan banyak kemenangan kecil.**

---

### Pengujian 2 — Periode 1993–2026 (Uji Ketahanan Ekstrem)

| Metrik | Nilai |
|---|---|
| Deposit Awal | $10,000 |
| Saldo Akhir | $126 |
| Laba Bersih | **-$9,874 (-98,7%)** |
| Total Transaksi | 26 kali |
| Max Kerugian Terbuka | **99,1%** |
| Profit Factor | **0,31** |

**Analisis:** AKUN HANCUR. GBPUSD turun dari 1.67 ke 1.47 (2.000 pip) dalam 7 bulan trending lurus. Grid BUY 4 level tidak mampu bertahan. Ini bukti bahwa **strategi Martingale tidak cocok untuk pasar yang trending panjang.**

---

### Pengujian 3 — Periode 2024–2026

| Metrik | Nilai |
|---|---|
| Deposit Awal | $10,000 |
| Saldo Akhir | $13,672 |
| Laba Bersih | **+$3,672 (+36,7%)** |
| Total Transaksi | 12 kali |
| Menang | 10 kali (83%) |
| Kalah | 2 kali (17%) |
| Max Kerugian Terbuka | 14,0% ($1,598) |
| Profit Factor | **30,6** |

**Analisis:** Hasil terbaik. Semua 3 siklus grid profit. Tapi ada **masalah besar**: setelah 28 Mei 2024, bot berhenti total dan tidak trading lagi selama 2 tahun.

---

### Pengujian 4 — Konfirmasi Pengujian 3

Hasil **hampir identik** dengan Pengujian 3, mengkonfirmasi bahwa:
- Strategi berfungsi di kondisi pasar 2024
- Bug penghentian permanen terjadi di titik yang sama
- Total transaksi sangat sedikit (12 dalam 2,5 tahun)

---

## 3. Temuan Bug

### Bug Kritis: Bot Mati Permanen Setelah Drawdown

**Gejala:** Bot berhenti trading dari Mei 2024 sampai Juni 2026 (2 tahun tanpa aktivitas).

**Penyebab:**
1. Saat grid BUY floating rugi 18%, sistem keamanan mengaktifkan mode STOP
2. Mode STOP hanya menghentikan pembukaan posisi baru, tapi TIDAK menutup posisi yang sedang rugi
3. Ketika posisi akhirnya balik profit dan ditutup, mode STOP tidak pernah di-reset
4. Akibatnya, bot terkunci dalam mode berhenti permanen

**Dampak:** Backtest tidak representatif. 2,5 tahun data hanya 5 bulan yang aktif.

### Bug Minor: Kualitas Data Rendah (25%)

Data M1 dari server JDR tidak lengkap. Akurasi backtest tidak bisa dipastikan. Perlu data dari server MetaQuotes untuk hasil yang terpercaya.

---

## 4. Perbandingan dengan Yetti Classic V3.03

Apex Grid mencapai **75-80% kemiripan** dengan Yetti Classic asli:

| Aspek | Sudah Mirip | Belum Mirip |
|---|---|---|
| Grid + Martingale | ✅ | |
| Basket Close | ✅ | |
| Trailing Profit-Peak | ✅ | |
| Time Filter | ✅ | |
| Entry Signal | | ❌ Yetti pakai Bollinger Bands, ApexGrid cuma MA crossover |
| Frekuensi Trading | | ❌ Yetti lebih agresif, ApexGrid terlalu jarang (cooldown 5 menit) |
| Parameter | | ❌ ApexGrid terlalu konservatif (GridStep 250 vs Yetti 100–200) |

---

## 5. Kelebihan Bot

1. **Profit factor tinggi di pasar ranging** (30,6 di pengujian 2024)
2. **Win rate 83%** saat kondisi pasar mendukung
3. **Arsitektur bersih** — kode terstruktur rapi dalam 5 layer
4. **Multi-arah** — BUY dan SELL grid bisa jalan bersamaan
5. **Keamanan bertingkat** — ada 4 jenis penghentian (drawdown, margin, profit harian, profit mingguan)

---

## 6. Kelemahan Bot

1. **Fatal:** Martingale + trending panjang = akun hancur (terbukti di pengujian 2)
2. **Rasio risk-reward tidak seimbang** — avg profit $380 vs potensi loss $14,000
3. **Frekuensi trading sangat rendah** — 12 trade dalam 2,5 tahun tidak cukup untuk income stabil
4. **BUY grid lemah** — win rate BUY cuma 33%, jauh di bawah SELL 87%
5. **Bug penghentian permanen** — bot mati sendiri tanpa pemberitahuan
6. **Kualitas backtest rendah** — hasil belum bisa dipastikan tanpa data M1 lengkap

---

## 7. Rekomendasi

### Untuk Developer:
1. **Perbaiki bug STOP_DRAWDOWN** — reset otomatis saat tidak ada posisi terbuka
2. **Tambahkan Bollinger Bands** untuk entry signal (mirip Yetti asli)
3. **Hapus cooldown 5 menit** atau kurangi menjadi 1 menit
4. **Pertimbangkan batas maksimum level grid** (misal: maks 5 level)
5. **Download data M1 dari MetaQuotes server** untuk backtest akurat

### Untuk Investor / Manajer:
1. **JANGAN digunakan live** sampai bug diperbaiki dan backtest 90%+ kualitas selesai
2. **Gunakan akun demo JDR minimal 3 bulan** untuk forward test sebelum live
3. **Siapkan modal minimal $5,000** — dengan lot awal 0.10, drawdown $10,000 bisa tembus 20-30% di akun lebih kecil
4. **Bot ini cocok untuk pasar ranging (sideways)**, berbahaya untuk pasar trending

---

## 8. Status Saat Ini

| Item | Status |
|---|---|
| Kode EA | v1.03 (739 baris) — semua 5 layer terimplementasi |
| Backtest 25% | ✅ Selesai 4 pengujian |
| Backtest 90%+ | ❌ Belum — butuh data M1 lengkap |
| Forward Test Demo | ❌ Belum dimulai |
| Kesiapan Live | ❌ Belum siap |
| Target Kemiripan Yetti | 75-80% tercapai |

---

## 9. Data Mentah Pengujian

File hasil pengujian lengkap tersedia di folder `strategy-test-result/`:
- `StrategyTester.html` — Pengujian Jan–Jun 2026
- `StrategyTester2.htm` — Pengujian 1993–2026 (akun hancur)
- `StrategyTester3.htm` — Pengujian 2024–2026 (profit + bug)
- `StrategyTester4.htm` — Pengujian konfirmasi 2024–2026

---

*Dokumen ini disusun sebagai bagian dari Fase 6 development — Testing & Dokumentasi.*
*Bahasa sengaja dibuat sederhana agar mudah dipahami oleh semua pemangku kepentingan.*
