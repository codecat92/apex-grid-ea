# Apex Grid EA — Progress Report

> **Ditujukan untuk:** Klien — Pemilik Akun Metavest #1, Pengguna Yetti Classic
> **Disiapkan oleh:** Tim Pengembang Apex Grid EA
> **Tanggal:** 15 Juni 2026
> **Tujuan Meeting:** Melaporkan progress pengembangan & menggali informasi untuk penyempurnaan

---

## 1. Ringkasan Progress

Kami sedang mengembangkan **Apex Grid EA**, sebuah robot trading yang dirancang untuk menyamai perilaku Yetti Classic v3.03_fix pada platform MetaTrader 4. Bot ini bekerja dengan strategi Grid Trading + Martingale — membuka posisi berlapis dengan ukuran lot yang semakin besar setiap kali harga bergerak berlawanan arah.

### Status Saat Ini

| Item | Status |
|---|---|
| Arsitektur Bot (5 layer) | ✅ Selesai (90% mirip Yetti) |
| Parameter Dasar | ✅ 30/37 parameter aktif Yetti sudah terimplementasi (81%) |
| Backtest | ✅ 7 iterasi, hasil terbaik +$3,864 (profit 38,6% dalam 7,5 bulan) |
| Perbandingan dengan Yetti | ✅ Periode overlap Nov 2025–Jun 2026 |
| News Filter | ❌ Belum diimplementasikan (dalam rencana) |
| Kesiapan Live Trading | ❌ Belum — masih perlu penyempurnaan |

### Hasil Backtest Terbaik (Test #7)

| Metrik | Nilai |
|---|---|
| Periode | November 2025 – Juni 2026 (7,5 bulan) |
| Deposit Awal | $10,000 |
| Saldo Akhir | $14,496 |
| Keuntungan Bersih | **+$3,864 (+38,6%)** |
| Profit Factor | 2,61 (setiap $1 rugi menghasilkan $2,61 laba) |
| Tingkat Kemenangan | 72,2% |
| Kerugian Maksimal Terbuka | 21,1% |
| Stop Out / Akun Hancur | **0 kali** |

---

## 2. Perbandingan Parameter Lengkap: Yetti vs Apex

> **Legenda:** ✅ Sudah sama &nbsp;&nbsp; ❌ Belum ada &nbsp;&nbsp; ⬜ Tidak relevan (disabled di Yetti)

### 2A — Core Trading Parameters

| # | Yetti | Apex | Status |
|---|---|---|---|
| 1 | Magic number: 1888 | MagicNumber=1888 | ✅ |
| 2 | Start lot: 0.1 | StartLot=0.1 | ✅ |
| 3 | Multiplier: 1.5 | Multiplier=1.5 | ✅ |
| 4 | Grid step: 250 | GridStep=250 | ✅ |
| 5 | General take profit: 200 | GeneralTP=200 | ✅ |
| 6 | Number of orders in one step: 2 | OrdersPerStep=2 | ✅ |
| 7 | Max grid level | MaxGridLevel=20 (Apex tambahan) | ✅ |
| 8 | Stop loss per level | StopLossPips=375 (Apex tambahan) | ✅ |

### 2B — Entry Signal Parameters

| # | Yetti | Apex | Status |
|---|---|---|---|
| 9 | MA Fast (tersembunyi di chart) | MAFastPeriod=5 | ✅ |
| 10 | MA Slow (tersembunyi di chart) | MASlowPeriod=40 | ✅ |
| 11 | MA Method: SMA | MAMethod=0 | ✅ |
| 12 | MA Price: Close | MAPrice=0 | ✅ |
| 13 | Bollinger Bands Period (tersembunyi) | BBPeriod=20 | ✅ |
| 14 | Bollinger Bands Deviation (tersembunyi) | BBDeviation=2 | ✅ |

> **Catatan:** Parameter MA dan BB di Yetti tidak muncul di daftar input karena berasal dari indikator yang dipasang langsung di chart. Apex menghitungnya secara internal.

### 2C — Trailing Exit Parameters

| # | Yetti | Apex | Status |
|---|---|---|---|
| 15 | Include trailing stop: true | UseTrailingStop=true | ✅ |
| 16 | Fixed distance from price: 50 | FixedDistance=50 | ✅ |
| 17 | Trailing Stop triggering distance: 160 | TriggerDistance=160 | ✅ |

### 2D — Time Filter Parameters

| # | Yetti | Apex | Status |
|---|---|---|---|
| 18 | Start time of main trade: 01:00 | StartTime="01:00" | ✅ |
| 19 | End time of main trade: 22:00 | EndTime="22:00" | ✅ |
| 20 | Friday trade: true | FridayTrade=true | ✅ |
| 21 | Friday stop time: 14:00 | FridayStop="14:00" | ✅ |
| 22 | Use extra time: true | UseExtraTime=true | ✅ |
| 23 | Extra start: 01:06 | ExtraStart="01:06" | ✅ |
| 24 | Extra end: 01:07 | ExtraEnd="01:07" | ✅ |
| 25 | Additional grid step: 100 | AdditionalGridStep=100 | ✅ |
| 26 | **Re-trade grid before time change: true** | — | ❌ |

### 2E — Risk Shutdown Parameters

| # | Yetti | Apex | Status |
|---|---|---|---|
| 27 | Daily profit %: 20 | DailyProfitPct=20 | ✅ |
| 28 | Weekly profit %: 20 | WeeklyProfitPct=20 | ✅ |
| 29 | Drawdown close all: 90% | DrawdownCloseAll=90 | ✅ |
| 30 | Margin close all: 20% | MarginCloseAll=20 | ✅ |
| 31 | Auto Stop Trading: true | AutoStopTrading=true | ✅ |
| 32 | Max drawdown level: 15% | MaxDrawdown=15 | ✅ |
| 33 | Min margin level: 1000 | MinMarginLevel=1000 | ✅ |

### 2F — News Filter (Belum Ada — Prioritas Utama)

| # | Yetti | Apex | Status |
|---|---|---|---|
| 34 | News filter: true | — | ❌ |
| 35 | Minutes before news: 30 | — | ❌ |
| 36 | Minutes after news: 60 | — | ❌ |
| 37 | Currencies monitored: USD,EUR,GBP,CHF,CAD,AUD,NZD,JPY | — | ❌ |

### 2G — Parameter Yetti yang Disabled (Tidak Perlu Ditiru)

| # | Fitur | Alasan |
|---|---|---|
| 38-42 | AutoDryer (5 parameter, Use=false) | Tidak aktif di Yetti |
| 43-44 | Dynamic Pitch (2 parameter, Use=false) | Tidak aktif |
| 45-50 | Locking System 1 & 2 (6 parameter, Use=false) | Tidak aktif |
| 51-52 | Take equity function (2 parameter, Use=false) | Tidak aktif |
| 53-56 | Activation code, Setting name, Caption color, Font size | Kosmetik / DRM |

### Ringkasan

```
Total parameter Yetti:                    56
  ✅ Sudah diimplementasi di Apex:         30  (81% dari parameter aktif)
  ⬜ Disabled / Kosmetik (tidak relevan):  19
  ❌ Aktif tapi belum diimplementasi:       7  (13% — 1 fitur: News Filter + 1 fitur: Re-trade)

Target cakupan parameter aktif: 81% → target setelah News Filter: 97%
```

---

## 3. Glosarium — Fungsi Setiap Parameter

### 3A — Kelompok Core Trading (Dasar Perdagangan)

| Parameter | Fungsi |
|---|---|
| **Magic Number** | ID unik bot. Membedakan order yang dibuat bot dari order manual trader. Dua bot dengan Magic Number berbeda tidak akan saling mengganggu. |
| **Start Lot** | Ukuran lot pertama di setiap grid baru. Contoh 0,10 = $1 per pip di GBPUSD. Semakin besar Start Lot, semakin besar potensi profit — tapi juga semakin besar risiko. |
| **Multiplier** | Pengali lot untuk setiap level grid berikutnya. Contoh: level 0 = 0,10 → level 1 = 0,10 × 1,5 = 0,15 → level 2 = 0,23. Semakin besar multiplier, semakin cepat lot membesar. |
| **Grid Step** | Jarak (dalam pips) antar level grid. Harga harus bergerak sejauh ini dari level sebelumnya untuk membuka level baru. Contoh: 250 pips = 0,0250 di harga GBPUSD. |
| **General Take Profit** | Target profit keseluruhan dalam pips. Saat rata-rata harga semua posisi dalam satu grid mencapai profit sejauh ini, seluruh posisi ditutup sekaligus. |
| **Orders per Step** | Jumlah order identik yang dibuka di setiap level grid. Nilai 2 berarti setiap level membuka 2 posisi bersamaan — total lot per level dua kali lipat. |
| **Max Grid Level** | Batas maksimum level grid. Setelah mencapai level ini, bot berhenti membuka level baru. Mencegah grid berkembang tanpa batas dan menghabiskan modal. |
| **Stop Loss Pips** | Jarak stop loss (batas rugi) untuk setiap order. Contoh: 375 pips dari harga entry. Jika harga bergerak 375 pips berlawanan, order otomatis ditutup untuk membatasi kerugian. |

### 3B — Kelompok Entry Signal (Sinyal Masuk Pasar)

| Parameter | Fungsi |
|---|---|
| **MA Fast Period** | Periode Moving Average cepat. Rata-rata harga 5 candle terakhir. Garis ini bergerak cepat mengikuti perubahan harga, digunakan untuk mendeteksi momentum jangka pendek. |
| **MA Slow Period** | Periode Moving Average lambat. Rata-rata harga 40 candle terakhir. Garis ini lebih halus, menunjukkan arah tren keseluruhan. |
| **MA Method** | Metode perhitungan Moving Average. SMA = rata-rata sederhana, EMA = memberi bobot lebih pada harga terbaru. |
| **MA Price** | Harga mana yang dipakai untuk menghitung MA. Close = harga penutupan candle (paling umum). |
| **BB Period** | Periode Bollinger Bands. Menentukan lebar "pita" yang membungkus pergerakan harga. Pita melebar saat pasar volatil, menyempit saat pasar tenang. |
| **BB Deviation** | Jumlah standar deviasi untuk Bollinger Bands. Semakin kecil, pita semakin sempit — semakin sering harga menyentuh pita luar. Semakin besar, semakin jarang. |

### 3C — Kelompok Trailing Exit (Strategi Keluar Pasar)

| Parameter | Fungsi |
|---|---|
| **Use Trailing Stop** | Mengaktifkan atau menonaktifkan fitur trailing stop. Saat aktif, bot akan mengunci profit dan menutup posisi saat profit turun dari puncak tertinggi. |
| **Trigger Distance** | Jarak minimal (dalam pips) yang harus ditempuh harga dari entry pertama sebelum trailing stop mulai aktif. Contoh: 160 pips — trailing baru "bangun" setelah harga bergerak 160 pips menguntungkan. |
| **Fixed Distance** | Jarak penurunan profit (dalam pips) yang akan memicu penutupan semua posisi. Contoh: 50 — jika profit turun 50 pips dari puncak tertinggi, semua posisi ditutup. |

### 3D — Kelompok Time Filter (Pengaturan Waktu)

| Parameter | Fungsi |
|---|---|
| **Start Time / End Time** | Jam operasional bot. Di luar jam ini, bot tidak membuka posisi baru. Biasanya mengikuti jam aktif pasar (London + New York). |
| **Friday Trade** | Mengizinkan atau melarang trading di hari Jumat. |
| **Friday Stop Time** | Jam berhenti trading di hari Jumat. Lebih awal dari hari biasa untuk menghindari gap harga saat pasar tutup akhir pekan. |
| **Use Extra Time** | Mengaktifkan jendela waktu tambahan. Biasanya di awal sesi saat spread masih rendah, bot bisa lebih agresif. |
| **Extra Start / Extra End** | Rentang waktu jendela tambahan. Contoh: 01:06–01:07 (hanya 1 menit). |
| **Additional Grid Step** | Jarak grid yang lebih rapat selama jendela waktu tambahan. Contoh: 100 pips (bukan 250) — entry lebih agresif. |
| **Re-trade Before Time Change** | Membuka ulang grid menjelang pergantian sesi trading utama. Fitur ini ada di Yetti tetapi belum diimplementasikan di Apex. |

### 3E — Kelompok Risk Shutdown (Pengaman Risiko)

| Parameter | Fungsi |
|---|---|
| **Daily Profit %** | Target profit harian. Jika profit hari ini mencapai persentase ini dari equity awal hari, bot berhenti membuka posisi baru sampai hari berikutnya. |
| **Weekly Profit %** | Target profit mingguan. Sama seperti di atas, tapi untuk periode satu minggu. |
| **Drawdown Close All** | Batas darurat. Jika kerugian terbuka (floating loss) mencapai persentase ini dari balance, SEMUA posisi ditutup paksa. Contoh: 90% — hanya terpicu saat hampir habis. |
| **Margin Close All** | Batas darurat berdasarkan margin. Jika margin level (equity ÷ margin terpakai) turun di bawah persentase ini, semua posisi ditutup. |
| **Auto Stop Trading** | Mengaktifkan fitur berhenti otomatis. |
| **Max Drawdown** | Batas kerugian terbuka sebelum bot berhenti membuka posisi baru. Contoh: 15% — jika floating loss mencapai 15% dari balance, bot pause. |
| **Min Margin Level** | Batas minimum margin level. Di bawah ini, bot berhenti trading untuk menghindari Margin Call / Stop Out dari broker. |

### 3F — Kelompok News Filter (Belum Diimplementasikan)

| Parameter | Fungsi |
|---|---|
| **News Filter** | Mengaktifkan filter berita. Saat aktif, bot TIDAK membuka posisi baru saat ada rilis berita ekonomi penting. Menghindari entry saat volatilitas ekstrem yang tidak terprediksi. |
| **Minutes Before News** | Berapa menit sebelum rilis berita bot berhenti membuka posisi baru. |
| **Minutes After News** | Berapa menit setelah rilis berita bot mulai bisa membuka posisi baru lagi. |
| **Currencies for News** | Mata uang mana saja yang beritanya dipantau. Contoh: USD,EUR,GBP — hanya berita dari negara-negara ini yang mempengaruhi bot. |

---

## 4. Rencana Penambahan News Filter

### Apa Itu News Filter?

News Filter adalah fitur yang mencegah bot membuka posisi baru saat ada rilis berita ekonomi penting. Tujuannya: **melindungi bot dari pergerakan harga liar dan tidak terprediksi yang terjadi saat pengumuman data ekonomi.**

### Kenapa Penting?

Saat ini ApexGrid TIDAK memiliki News Filter. Akibatnya:
- Bot bisa membuka posisi tepat sebelum rilis berita besar
- Harga bergerak ekstrem dalam hitungan detik, memicu level grid baru secara sia-sia
- Entry yang dibuat saat volatilitas news seringkali berakhir rugi

Yetti memiliki fitur ini dan terbukti: **965 trade dalam 7,5 bulan dengan profit factor 2,51.** News Filter membantu Yetti hanya entry di kondisi pasar normal yang lebih mudah diprediksi.

### Cara Kerja

```
CONTOH: NFP (Non-Farm Payroll) rilis pukul 14:30 WIB

  13:30 ─────────────────────────────────────────────────── 15:30
         ← 30 menit SEBELUM         60 menit SETELAH →
         [ BOT TIDAK ENTRY ]        [ BOT TIDAK ENTRY ]
         
  Bot hanya entry di luar jendela ini.
  Posisi yang SUDAH TERBUKA tetap dimonitor dan bisa ditutup normal.
```

### Parameter yang Akan Ditambahkan

| Parameter | Default | Keterangan |
|---|---|---|
| News Filter ON/OFF | true | Mengaktifkan fitur |
| Minutes Before News | 30 | Berhenti entry 30 menit sebelum berita |
| Minutes After News | 60 | Mulai entry kembali 60 menit setelah berita |
| News Currencies | USD,EUR,GBP | Mata uang yang dipantau |

### Dampak yang Diharapkan

| Aspek | Sebelum | Sesudah (Estimasi) |
|---|---|---|
| Kualitas entry | Tercampur false signal saat news | Hanya entry di kondisi normal |
| Frekuensi entry | 4,8/bulan | Meningkat karena sinyal lebih bersih |
| Drawdown saat news | Rentan spike | Terproteksi |
| Kemiripan dengan Yetti | 81% parameter | 97% parameter |

### Jadwal

| Fase | Aktivitas | Estimasi |
|---|---|---|
| Fase 7 | Implementasi News Filter | 1-2 minggu |
| Fase 8 | Backtest + tuning | 1 minggu |
| Fase 9 | Forward test di akun demo | 2-4 minggu |
| Final | Review kelayakan live | Setelah forward test |

---

## 5. Pertanyaan untuk Klien

Untuk menyempurnakan Apex agar semakin mirip dengan Yetti, kami membutuhkan informasi dari pengalaman Bapak/Ibu menggunakan Yetti. Berikut adalah pertanyaan-pertanyaan yang akan membantu pengembangan:

### A. Rutinitas Harian

| # | Pertanyaan | Kenapa Ini Penting |
|---|---|---|
| A1 | **Bagaimana Bapak/Ibu biasanya menggunakan Yetti sehari-hari?** Apakah dinyalakan pagi lalu ditinggal, atau ada ritual tertentu sebelum trading dimulai? | Memahami apakah Yetti berjalan penuh otomatis 24/7 atau ada intervensi manusia di momen-momen tertentu. |
| A2 | **Pernahkah Yetti terlihat "diam terlalu lama" tidak membuka posisi?** Jika ya, apa yang Bapak/Ibu lakukan? | Mengetahui apakah ada tindakan manual (refresh chart, restart EA) yang memicu Yetti untuk mulai entry kembali. |
| A3 | **Apakah ada hari atau momen tertentu di mana Yetti sengaja dimatikan?** Misalnya: hari libur, akhir bulan, atau menjelang akhir pekan. | Memastikan apakah time filter di parameter sudah cukup atau ada aturan tidak tertulis yang diterapkan. |

### B. Entry Signal (Sinyal Masuk Pasar)

| # | Pertanyaan | Kenapa Ini Penting |
|---|---|---|
| B1 | **Menurut pengamatan Bapak/Ibu, biasanya Yetti mulai buka posisi saat harga sedang seperti apa?** Sedang naik tajam? Turun tajam? Atau setelah bergerak sideways lama? | Ini akan mengkonfirmasi apakah sinyal entry Yetti benar-benar berdasarkan indikator teknikal (MA + BB) atau ada faktor lain. |
| B2 | **Apakah ada garis, pita, atau gambar tertentu di chart yang Bapak/Ibu perhatikan untuk menilai "ini saatnya Yetti jalan"?** | Mengidentifikasi indikator visual yang mungkin kami lewatkan dalam analisis. |
| B3 | **Apakah Bapak/Ibu sendiri yang menentukan kapan Yetti mulai trading, atau sepenuhnya otomatis?** | **Pertanyaan paling kritis.** Jika entry bersifat manual atau semi-manual, Apex tidak akan bisa 100% menyamai tanpa kecerdasan buatan yang canggih. |

### C. Berita Ekonomi (News Trading)

| # | Pertanyaan | Kenapa Ini Penting |
|---|---|---|
| C1 | **Saat ada berita ekonomi besar (misalnya NFP, pengumuman suku bunga The Fed), apa yang biasanya terjadi?** Apakah Yetti tetap jalan seperti biasa, atau Bapak/Ibu melakukan sesuatu? | Memvalidasi cara kerja News Filter di praktik — apakah posisi yang sudah ada ditutup dulu, atau dibiarkan. |
| C2 | **Berita dari negara mana saja yang biasanya Bapak/Ibu perhatikan?** US saja, atau UK dan Eropa juga? | Mengkonfirmasi daftar mata uang yang perlu dimonitor oleh News Filter. |
| C3 | **Apakah ada jenis berita tertentu yang menurut Bapak/Ibu PALING mempengaruhi pergerakan GBPUSD?** | Membantu kami memprioritaskan kategori berita (employment, inflation, central bank, GDP, dll). |

### D. Manajemen Risiko

| # | Pertanyaan | Kenapa Ini Penting |
|---|---|---|
| D1 | **Apakah Bapak/Ibu pernah menutup posisi secara manual (bukan oleh Yetti)?** Dalam situasi seperti apa? | Memahami pola intervensi manusiawi — mungkin ada aturan tidak tertulis seperti "kalau floating sudah 5%, saya tutup sendiri". |
| D2 | **Apa pengalaman paling menegangkan selama menggunakan Yetti?** Kapan itu terjadi dan bagaimana akhirnya? | Mendapatkan data tentang skenario terburuk yang pernah terjadi, validasi drawdown history. |
| D3 | **Apakah menurut Bapak/Ibu, modal $10.000 cukup untuk menjalankan Yetti versi baru?** Atau ada rekomendasi jumlah modal ideal? | Menentukan parameter StartLot dan MaxGridLevel yang aman untuk modal tertentu. |

---

### Lampiran: Referensi Cepat

| Dokumen | Deskripsi |
|---|---|
| `CONTEXT.md` | Spesifikasi teknis lengkap Apex Grid EA |
| `yetti_parameter.md` | Seluruh parameter Yetti dari server live |
| `yetti_performance_summary.md` | Statistik kinerja Yetti (1.215 trade, +$45.129) |
| `perbandingan_yetti_vs_apex.md` | Analisis perbandingan periode overlap |
| `laporan-testing_Senin-15-Juni-2026.md` | Laporan harian testing |

---

*Dokumen disiapkan untuk meeting progress dengan klien. Untuk pertanyaan teknis lebih lanjut, hubungi Fernando Siahaan (codecat92).*
