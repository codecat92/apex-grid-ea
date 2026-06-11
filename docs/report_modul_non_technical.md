# Apex Grid EA — Laporan Non-Teknis untuk Pengguna Umum

> **Dokumen ini ditujukan untuk pembaca NON-TEKNIS** — tidak perlu latar belakang
> programming untuk memahaminya. Dokumen ini menjelaskan apa itu bot Apex Grid,
> bagaimana cara kerjanya dengan bahasa sederhana, dan apa yang bisa Anda atur.

---

## Daftar Isi

1. [Apa Itu Apex Grid EA?](#1-apa-itu-apex-grid-ea)
2. [Bagaimana Bot Ini Bekerja? (Siklus Trading)](#2-bagaimana-bot-ini-bekerja-siklus-trading)
3. [5 Lapisan Pelindung — Arsitektur Bot](#3-5-lapisan-pelindung--arsitektur-bot)
4. [Perbandingan dengan Yetti Classic](#4-perbandingan-dengan-yetti-classic)
5. [Parameter yang Bisa Anda Ubah & Pengaruhnya](#5-parameter-yang-bisa-anda-ubah--pengaruhnya)
6. [Manajemen Risiko — Fitur Pengaman](#6-manajemen-risiko--fitur-pengaman)
7. [Peringatan Penting — Use at Your Own Risk](#7-peringatan-penting--use-at-your-own-risk)

---

## 1. Apa Itu Apex Grid EA?

**Apex Grid EA** adalah sebuah **robot trading otomatis** (Expert Advisor) yang
berjalan di platform MetaTrader 4. Robot ini dirancang khusus untuk pair
**GBPUSD** di timeframe **M1 (1 menit)**.

### Analogi Sederhana

Bayangkan Anda punya asisten yang bertugas membeli dan menjual mata uang secara
otomatis selama 24 jam. Asisten ini:

- **Tidak tidur** — bisa memantau pasar 24 jam
- **Tidak emosi** — tidak panik saat harga turun atau serakah saat harga naik
- **Disiplin** — selalu mengikuti aturan yang sudah ditetapkan
- **Cepat** — bisa membuka dan menutup transaksi dalam hitungan milidetik

### Strategi Dasar: Grid + Martingale

Bot ini menggunakan dua strategi yang digabungkan:

| Strategi | Penjelasan Sederhana |
|----------|---------------------|
| **Grid** | Bot membuka transaksi secara berlapis (seperti tangga). Setiap kali harga bergerak berlawanan 250 pips, bot membuka transaksi baru. Semakin banyak lapisan, semakin besar potensi profit saat harga berbalik. |
| **Martingale** | Ukuran transaksi diperbesar di setiap lapisan baru. Kalau lapisan pertama 0.10 lot, lapisan kedua 0.15 lot, ketiga 0.23 lot, dan seterusnya. Tujuannya: transaksi yang lebih besar bisa menutup kerugian dari transaksi kecil di bawahnya. |

> **Peringatan**: Strategi martingale bisa sangat berbahaya jika harga terus
> bergerak satu arah tanpa berbalik. Bot ini dilengkapi fitur pengaman untuk
> membatasi kerugian, tapi risikonya tetap nyata. (Lihat [Bagian 7](#7-peringatan-penting--use-at-your-own-risk))

---

## 2. Bagaimana Bot Ini Bekerja? (Siklus Trading)

### Satu Siklus Penuh — Dari Awal Sampai Akhir:

```
LANGKAH 1 — SINYAL MASUK
  Bot melihat grafik GBPUSD. Ada dua garis Moving Average (MA):
  - MA Cepat (periode 5) — garis yang peka, mengikuti harga terkini
  - MA Lambat (periode 40) — garis yang lebih stabil, menunjukkan tren besar

  Ketika MA Cepat memotong MA Lambat KE ATAS  → Bot mulai BELI (BUY grid)
  Ketika MA Cepat memotong MA Lambat KE BAWAH → Bot mulai JUAL (SELL grid)

  Bot bisa melakukan BELI dan JUAL sekaligus!
  (Dua "keranjang" terpisah yang dikelola masing-masing)


LANGKAH 2 — MEMBUKA LAPISAN (GRID)
  Level 0: Bot langsung beli/jual di harga pasar sekarang
           Misal: BUY 0.10 lot di harga 1.2500

  Harga turun 250 pips (ke 1.2250) → Level 1: Bot beli lagi 0.15 lot
  Harga turun 250 pips lagi (ke 1.2000) → Level 2: Bot beli lagi 0.23 lot
  ...dan seterusnya sampai harga berbalik

  Setiap level berikutnya ukuran lot-nya 1.5× lebih besar dari sebelumnya.

  Contoh progresi lot (dari observasi Yetti Classic):
  0.10 → 0.15 → 0.23 → 0.34 → 0.51 → 0.76 → 1.14


LANGKAH 3 — MENUNGGU HARGA BERBALIK
  Bot menunggu sampai harga kembali naik (untuk BUY grid).
  Tidak ada batas rugi per transaksi — semua posisi dibiarkan terbuka.


LANGKAH 4 — TRAILING STOP AKTIF
  Begitu harga sudah bergerak menguntungkan sejauh 160 pips (Trigger Distance)
  dari transaksi pertama, bot mengaktifkan "trailing stop".

  Trailing stop = bot mengunci profit. Begitu profit turun 50 pips
  (Fixed Distance) dari puncak profit, semua transaksi langsung ditutup.


LANGKAH 5 — BASKET CLOSE (TUTUP SEMUA)
  SEMUA transaksi yang searah (BUY semua / SELL semua) ditutup sekaligus
  dalam satu "keranjang". Bot mencetak di log: "TRAL:::: close on the trawl"


LANGKAH 6 — RESET DAN TUNGGU
  Bot kembali ke Langkah 1, menunggu sinyal MA berikutnya.
  Tidak langsung buka posisi baru — ada cooldown 5 menit.
```

---

## 3. 5 Lapisan Pelindung — Arsitektur Bot

Bot ini dibangun dengan 5 lapisan (layer), masing-masing punya tugas spesifik.
Ibarat mobil: tidak hanya mesin, tapi ada rem, sabuk pengaman, dan airbag.

```
LAPISAN 1 — SINYAL MASUK
  "Kapan bot mulai trading?"
  Menggunakan Moving Average Crossover.
  Bot hanya mulai jika ada sinyal, tidak asal buka posisi.

  ⬇️

LAPISAN 2 — PENGELOLA GRID
  "Berapa banyak dan berapa besar transaksi?"
  Mengatur lapisan transaksi dan ukuran lot.
  Memastikan lot sesuai aturan broker (tidak terlalu kecil/besar).

  ⬇️

LAPISAN 3 — PENUTUPAN (EXIT)
  "Kapan semua transaksi ditutup?"
  Trailing stop mengunci profit. Tidak ada stop loss per transaksi —
  semua ditutup sekaligus saat trailing terpicu.

  ⬇️

LAPISAN 4 — FILTER WAKTU
  "Jam berapa bot boleh trading?"
  Bot hanya aktif di jam yang ditentukan (default: 01:00–22:00).
  Jumat berhenti lebih awal (14:00) untuk hindari risiko gap weekend.
  Ada jendela trading tambahan di menit tertentu (01:06–01:07).

  ⬇️

LAPISAN 5 — REM DARURAT (RISK SHUTDOWN)
  "Kapan bot harus berhenti total?"
  - Drawdown (kerugian) > 15% → bot berhenti trading
  - Drawdown > 90% → bot tutup semua posisi + berhenti total
  - Margin < 20% → bot tutup semua posisi + berhenti total
  - Profit harian 20% tercapai → bot berhenti (kunci profit)
  - Profit mingguan 20% tercapai → bot berhenti (kunci profit)
```

---

## 4. Perbandingan dengan Yetti Classic

Apex Grid EA terinspirasi dari **Yetti Classic v3.03_fix**, sebuah EA komersial
yang sudah terbukti di pasar. Perbandingan dibuat berdasarkan observasi visual
dan analisa log Yetti (tanpa decompile / membongkar kode asli).

### Persamaan (Behaviour yang Ditiru)

| Aspek | Yetti Classic | Apex Grid EA |
|-------|--------------|--------------|
| **Strategi** | Grid + Martingale | Grid + Martingale (✅ identik) |
| **Sinyal Masuk** | MA Crossover (diduga external signal) | MA Crossover (SMA 5 vs 40) |
| **Progresi Lot** | 0.10 → 0.15 → 0.23 → 0.34 → 0.51 → 0.76 → 1.14 | Sama persis (Multiplier 1.5) |
| **Jarak Grid** | ~250 pips antar level | 250 pips (GridStep) |
| **Penutupan** | Basket close via trailing stop | Basket close via trailing stop (✅ identik) |
| **Trailing Trigger** | "TRAL:::: close on the trawl" | Output log yang sama (✅ identik) |
| **Komentar Order** | "Apex Grid BUY", "Apex Grid BUY 1", dst. | Format komentar sama (✅ identik) |
| **No SL/TP** | Tidak ada SL/TP per transaksi | Tidak ada SL/TP per transaksi |
| **Dual Grid** | BUY grid dan SELL grid bisa aktif bersamaan | Bisa aktif bersamaan |

### Perbedaan (Yang Sengaja Dibuat Berbeda atau Di-exclude)

| Aspek | Yetti Classic | Apex Grid EA | Alasan |
|-------|--------------|-------------|--------|
| **News Filter** | Ada (hindari trading saat berita besar) | Tidak ada | Terlalu kompleks untuk versi awal, perlu koneksi internet real-time |
| **Sinyal Eksternal** | Diduga pakai sinyal dari smart921 | Menggunakan MA Crossover built-in | Lebih sederhana dan tidak bergantung pada sinyal luar |
| **Locking System** | Ada (disabled) | Tidak diimplementasi | Di Yetti asli juga dimatikan, tidak perlu |
| **AutoDryer** | Ada (disabled) | Tidak diimplementasi | Di Yetti asli juga dimatikan |
| **Dynamic Pitch** | Ada (disabled) | Tidak diimplementasi | Di Yetti asli juga dimatikan |
| **Lisensi/Aktivasi** | Ada sistem lisensi | Tidak ada | Tidak relevan untuk bot kita |
| **Garis di Chart** | Menggambar level grid di grafik | Tidak ada | Prioritas rendah, nice-to-have |

### Ringkasan Perbandingan

Apex Grid EA meniru **perilaku inti** Yetti Classic secara akurat — sinyal
masuk, progresi martingale, basket close dengan trailing. Perbedaan utama
adalah Apex Grid **lebih sederhana dan transparan**: tidak ada fitur yang
disembunyikan, tidak ada lisensi, dan semua parameter bisa diubah pengguna
secara bebas.

---

## 5. Parameter yang Bisa Anda Ubah & Pengaruhnya

Semua parameter bisa diubah dari jendela "Inputs" saat Anda memasang bot di
chart MetaTrader 4. Berikut penjelasan setiap parameter dengan bahasa sederhana
dan efeknya ke hasil trading.

---

### A. Parameter Inti Trading

#### Magic Number: `1888`
> **Apa ini?** Nomor ID unik bot, seperti KTP-nya transaksi.  
> **Pengaruh:** Semua transaksi yang dibuka bot ini akan diberi label 1888.
> Ini membedakan transaksi bot dari transaksi manual Anda.  
> **Tips:** Jika Anda menjalankan beberapa bot sekaligus di akun yang sama,
> pastikan masing-masing punya Magic Number berbeda supaya tidak bentrok.

#### Start Lot: `0.10`
> **Apa ini?** Ukuran transaksi pertama di setiap grid.  
> **Pengaruh ke hasil trading:** Ini adalah **tombol paling kritis**.
> Semakin besar Start Lot, semakin besar profit — tapi juga semakin besar
> risiko. Karena sistem martingale, setiap lapisan berikutnya dikalikan 1.5×,
> jadi lot level 5 bisa mencapai **7.6×** lebih besar dari Start Lot.  
> **Rekomendasi:**
> - Akun demo: coba 0.10
> - Akun live kecil ($100–$500): gunakan 0.01
> - Akun live standar ($1000+): 0.05–0.10

#### Multiplier: `1.5`
> **Apa ini?** Faktor pengali lot setiap level grid baru.  
> **Pengaruh ke hasil trading:** Semakin besar multiplier, semakin cepat
> lot membesar di level berikutnya, sehingga profit juga bisa lebih cepat —
> tapi risikonya berlipat.  
> | Multiplier | Level 0 | Level 1 | Level 2 | Level 3 | Level 4 | Level 5 |
> |-----------|---------|---------|---------|---------|---------|---------|
> | 1.2 | 0.10 | 0.12 | 0.14 | 0.17 | 0.21 | 0.25 |
> | 1.5 | 0.10 | 0.15 | 0.23 | 0.34 | 0.51 | 0.76 |
> | 2.0 | 0.10 | 0.20 | 0.40 | 0.80 | 1.60 | 3.20 |
> **Rekomendasi:** Jangan ubah kecuali Anda benar-benar paham risikonya.
> 1.5 sudah cukup agresif.

#### Grid Step: `250`
> **Apa ini?** Jarak antar lapisan grid, dalam satuan pips.  
> **Pengaruh ke hasil trading:** Semakin kecil Grid Step, semakin sering
> bot membuka lapisan baru → lebih cepat mencapai banyak level → lot
> membesar lebih cepat. Ini bisa menguntungkan di pasar yang sering
> bolak-balik, tapi berbahaya di pasar yang tren kuat.  
> **Rekomendasi:**
> - 200–300 pips: standar, cocok untuk GBPUSD
> - < 100 pips: sangat agresif, hanya untuk testing
> - > 400 pips: terlalu lebar, jarang terpicu

#### General TP: `200`
> **Apa ini?** Target profit keseluruhan dalam pips.  
> **Pengaruh:** Ketika rata-rata harga semua transaksi (dibobot lot) sudah
> profit 200 pips, semua posisi searah ditutup.  
> **Catatan:** Trailing stop adalah mekanisme penutupan utama. General TP
> hanya backup.

#### Orders per Step: `1`
> **Apa ini?** Jumlah transaksi yang dibuka di setiap level grid.  
> **Pengaruh:** Per level, bot bisa buka 1, 2, atau lebih transaksi
> identik. Ini mengalikan eksposur.  
> **Rekomendasi:** Biarkan di 1 untuk pemula.

---

### B. Parameter Sinyal Masuk — Moving Average

#### MA Fast Period: `5`
> **Apa ini?** Berapa banyak candle terakhir yang dihitung untuk MA Cepat.  
> **Pengaruh:** Semakin kecil angkanya (misal 3), MA makin sensitif — lebih
> sering menghasilkan sinyal, tapi lebih banyak sinyal palsu. Semakin besar
> (misal 10), sinyal lebih jarang tapi lebih terpercaya.  
> **Rekomendasi:** Biarkan 5.

#### MA Slow Period: `40`
> **Apa ini?** Berapa banyak candle terakhir untuk MA Lambat.  
> **Pengaruh:** Angka besar (misal 50–100) menghasilkan sinyal yang lebih
> mengikuti tren jangka panjang. Angka kecil (20) lebih reaktif.  
> **Rekomendasi:** Biarkan 40.

#### MA Method: `SMA (Simple Moving Average)`
> **Opsi:** SMA, EMA, SMMA, LWMA.  
> **Pengaruh:** SMA adalah rata-rata sederhana. EMA lebih sensitif terhadap
> harga terbaru. LWMA memberi bobot lebih ke harga terbaru.  
> **Rekomendasi:** SMA sudah cukup untuk strategi ini.

#### MA Price: `Close (Harga Penutupan)`
> **Opsi:** Close, Open, High, Low, Median, Typical, Weighted.  
> **Pengaruh:** Harga mana yang dipakai untuk menghitung MA. Close (harga
> penutupan candle) adalah yang paling umum.  
> **Rekomendasi:** Biarkan Close.

---

### C. Parameter Trailing Exit

#### Use Trailing Stop: `true`
> **Apa ini?** Tombol on/off untuk trailing stop.  
> **Pengaruh:** Kalau dimatikan (false), bot HANYA akan menutup transaksi
> lewat General TP atau Risk Shutdown. Trailing stop adalah mekanisme
> penutupan utama — **sangat tidak disarankan mematikan ini**.

#### Fixed Distance: `50`
> **Apa ini?** "Jarak aman" trailing — berapa pips profit harus turun dari
> puncak sebelum semua transaksi ditutup.  
> **Pengaruh ke hasil trading:**
> - Semakin kecil (misal 20): profit lebih sering terkunci, tapi sering
>   tertutup terlalu cepat sebelum harga lanjut menguntungkan
> - Semakin besar (misal 100): bot lebih sabar menunggu, profit bisa lebih
>   besar, tapi risiko profit yang sudah ada hilang lebih banyak kalau harga
>   berbalik tajam
> **Rekomendasi:** 30–70 pips. Default 50 cukup seimbang.

#### Trigger Distance: `160`
> **Apa ini?** Jarak minimum profit sebelum trailing stop diaktifkan.  
> **Pengaruh:** Sebelum harga bergerak 160 pips dari transaksi pertama,
> trailing BELUM aktif — artinya bot tidak akan menutup posisi meskipun
> profit naik-turun. Setelah 160 pips tercapai, trailing baru mulai bekerja.  
> **Rekomendasi:** 120–200 pips. Default 160 masuk akal untuk GBPUSD.

---

### D. Parameter Filter Waktu

#### Start Time: `"01:00"` / End Time: `"22:00"`
> **Apa ini?** Jam buka dan tutup bot.  
> **Pengaruh:** Di luar jam ini, bot TIDAK akan membuka posisi baru.
> Tapi posisi yang sudah terbuka tetap dipantau (trailing dan risk shutdown
> tetap aktif).  
> **Alasan:** Sesi Asia (01:00) sampai penutupan sesi Amerika (22:00)
> adalah jam paling aktif untuk GBPUSD.  
> **Catatan:** Format 24 jam. Contoh: "01:00", "14:30", "22:00".

#### Friday Trade: `true`
> **Apa ini?** Apakah bot boleh trading di hari Jumat.  
> **Pengaruh:** Kalau dimatikan, bot libur total di hari Jumat.

#### Friday Stop: `"14:00"`
> **Apa ini?** Jam berhenti di hari Jumat.  
> **Pengaruh:** Bot akan berhenti membuka posisi baru setelah jam 14:00 di
> hari Jumat. Ini penting karena pasar tutup di akhir pekan — kalau ada
> posisi terbuka saat weekend, Senin pagi bisa terjadi "gap" harga yang
> merugikan.

#### Use Extra Time: `true`
> **Apa ini?** Mengaktifkan jendela trading tambahan.  
> **Pengaruh:** Bot akan aktif di jam yang sangat singkat (default 01:06–01:07)
> dengan Grid Step yang lebih kecil (100 pips). Ini adalah waktu spesifik
> yang terinspirasi dari perilaku Yetti Classic untuk menangkap pergerakan
> di awal sesi.

#### Extra Start: `"01:06"` / Extra End: `"01:07"`
> Jendela waktu ekstra (hanya 1 menit!) di awal sesi.

#### Additional Grid Step: `100`
> Grid step yang digunakan selama jendela ekstra. Lebih kecil dari Grid Step
> normal (250) karena jendela waktunya sangat singkat.

---

### E. Parameter Manajemen Risiko (PENTING!)

#### Daily Profit %: `20.0`
> **Apa ini?** Target profit harian dalam persen.  
> **Pengaruh:** Begitu profit equity hari ini mencapai 20%, bot akan berhenti
> trading. Ini adalah fitur **mengunci profit** — mencegah bot "balas dendam"
> dan menghilangkan profit yang sudah didapat.  
> **Rekomendasi:** 10–30%. Semakin kecil semakin aman.

#### Weekly Profit %: `20.0`
> **Apa ini?** Target profit mingguan.  
> **Pengaruh:** Sama seperti Daily Profit, tapi dihitung per minggu.
> Begitu tercapai, bot berhenti dan baru aktif lagi Senin depan.

#### Drawdown Close All: `90.0`
> **Apa ini?** Rem darurat paling ekstrem.  
> **Pengaruh:** Jika kerugian (drawdown) mencapai 90% dari saldo, bot akan
> **menutup SEMUA posisi** yang masih terbuka dan berhenti total.  
> **Peringatan:** Pada titik ini, akun Anda hampir habis. Ini adalah
> perlindungan terakhir — jangan mengandalkan ini sebagai strategi utama!

#### Margin Close All: `20.0`
> **Apa ini?** Level margin kritis.  
> **Pengaruh:** Jika margin level (equity dibagi margin) turun di bawah 20%,
> bot akan menutup semua posisi. Ini adalah batas di mana broker biasanya
> akan melakukan margin call / stop out.

#### Auto Stop Trading: `true`
> **Apa ini?** Mengaktifkan fitur auto-stop saat drawdown mencapai batas tertentu.  
> **Pengaruh:** Harus ON. Kalau dimatikan, bot tidak akan berhenti meskipun
> mengalami kerugian besar.

#### Max Drawdown: `15.0`
> **Apa ini?** Batas kerugian maksimum yang ditoleransi.  
> **Pengaruh ke hasil trading:** Begitu drawdown mencapai 15%, bot berhenti
> membuka posisi baru (posisi yang sudah ada tetap dikelola oleh trailing
> dan risk shutdown).  
> **Ini adalah parameter keamanan Anda yang paling penting.**
> - 15% (default) = konservatif, cocok untuk live
> - 30% = agresif, lebih banyak kesempatan profit tapi risiko lebih besar
> - 50%+ = sangat berbahaya

#### Min Margin Level: `1000.0`
> **Apa ini?** Level margin minimum yang diizinkan.  
> **Pengaruh:** Jika margin level turun di bawah 1000%, bot akan berhenti
> membuka posisi baru. 1000% artinya equity Anda 10× lebih besar dari margin
> yang digunakan — ini adalah level yang sehat.

---

## 6. Manajemen Risiko — Fitur Pengaman

Bot ini memiliki **6 fitur pengaman** yang bekerja secara otomatis. Ibarat
mobil: Anda tidak hanya punya rem, tapi juga ABS, airbag, dan sabuk pengaman.
Semuanya bekerja tanpa Anda harus menekan tombol apa pun.

### Ringkasan Fitur Pengaman:

| Fitur | Apa yang Dilakukan | Kapan Aktif |
|-------|-------------------|-------------|
| **Auto Stop** | Menghentikan bot dari membuka posisi baru | Drawdown > 15% |
| **Daily Profit Lock** | Menghentikan bot setelah profit harian tercapai | Profit harian > 20% |
| **Weekly Profit Lock** | Menghentikan bot setelah profit mingguan tercapai | Profit mingguan > 20% |
| **Drawdown Emergency** | Menutup SEMUA posisi + berhenti total | Drawdown > 90% |
| **Margin Protection** | Menutup semua posisi jika margin menipis | Margin < 20% |
| **Time Filter** | Bot hanya trading di jam tertentu | Di luar jam 01:00–22:00 |

### Yang Perlu Diwaspadai:

1. **Risiko Gap Weekend** — Jika ada posisi terbuka saat Jumat tutup, Senin
   pagi harga bisa "loncat" jauh (gap). Bot mengurangi risiko ini dengan
   berhenti trading di Jumat jam 14:00. Tapi kalau Anda mengubah setting ini,
   risikonya kembali ke Anda.

2. **Risiko Tren Kuat Satu Arah** — Jika GBPUSD bergerak lurus naik atau
   turun tanpa koreksi (contoh: saat ada berita besar), bot akan terus membuka
   lapisan grid dan lot akan membesar. Semakin banyak lapisan, semakin besar
   eksposur. Inilah kenapa fitur Auto Stop di 15% drawdown sangat penting.

3. **Risiko Berita Ekonomi** — Apex Grid TIDAK memiliki News Filter (tidak
   seperti Yetti Classic). Artinya bot tetap akan trading saat ada berita
   penting (NFP, FOMC, GDP, CPI, dll.) yang biasanya menyebabkan pergerakan
   harga ekstrem. Jika Anda khawatir, hentikan bot secara manual sebelum
   jadwal berita besar.

---

## 7. Peringatan Penting — Use at Your Own Risk

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ⚠️  PERINGATAN RISIKO — BACA DENGAN SEKSAMA  ⚠️          ║
║                                                              ║
║   1. Trading forex memiliki RISIKO TINGGI. Anda bisa         ║
║      KEHILANGAN SELURUH MODAL.                               ║
║                                                              ║
║   2. Strategi martingale bisa menyebabkan kerugian           ║
║      BESAR dalam waktu SINGKAT jika pasar bergerak           ║
║      melawan posisi Anda.                                    ║
║                                                              ║
║   3. Bot ini BELUM melalui pengujian menyeluruh.             ║
║      Fase 6 — Testing masih ⏳ BERJALAN.                     ║
║                                                              ║
║   4. TIDAK ADA JAMINAN profit. Performa masa lalu            ║
║      (dari Yetti Classic) TIDAK menjamin hasil di            ║
║      masa depan untuk Apex Grid EA.                          ║
║                                                              ║
║   5. Bot ini terinspirasi dari Yetti Classic, tapi            ║
║      BUKAN clone 100%. Ada perbedaan signifikan              ║
║      dalam fitur dan implementasi.                           ║
║                                                              ║
║   6. SELALU uji coba di akun DEMO terlebih dahulu            ║
║      selama minimal 2–4 minggu sebelum menggunakan           ║
║      di akun LIVE.                                           ║
║                                                              ║
║   7. Gunakan HANYA uang yang Anda RELA HILANG.               ║
║      Jangan trading dengan uang kebutuhan hidup.             ║
║                                                              ║
║   8. Anda bertanggung jawab PENUH atas semua                 ║
║      keputusan trading dan pengaturan parameter.             ║
║      Developer TIDAK bertanggung jawab atas                  ║
║      kerugian yang terjadi.                                  ║
║                                                              ║
║             ⚠️  USE AT YOUR OWN RISK  ⚠️                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### Checklist Sebelum Menggunakan di Akun Live:

- [ ] Sudah uji di akun DEMO minimal 2 minggu
- [ ] Sudah uji di Strategy Tester MT4 (minimal 3 bulan data)
- [ ] Paham cara kerja Grid + Martingale
- [ ] Paham semua parameter dan pengaruhnya
- [ ] Sudah atur Max Drawdown sesuai toleransi risiko
- [ ] Sudah atur Start Lot sesuai ukuran akun
- [ ] Tidak menggunakan uang kebutuhan hidup
- [ ] Siap menerima kemungkinan kehilangan seluruh modal

### Target Pengujian (Fase 6 — Sedang Berjalan):

| Jenis Tes | Status | Keterangan |
|-----------|--------|------------|
| Backtest MT4 | ⏳ Perlu dilakukan | Uji dengan data historis 6–12 bulan |
| Forward test Demo | ⏳ Perlu dilakukan | Uji di akun demo real-time |
| Stress test | ⏳ Perlu dilakukan | Uji di kondisi pasar ekstrem |
| Live test (kecil) | ⏳ Perlu dilakukan | Uji di akun live dengan lot minimal |

---

## Penutup

Apex Grid EA adalah robot trading yang ambisius — dibangun untuk meniru
perilaku Yetti Classic yang sudah terbukti, dengan transparansi penuh dan
kontrol yang bisa disesuaikan pengguna.

Bot ini **bukan "mesin uang instan"**. Bot ini adalah **alat bantu trading**
yang, seperti alat apa pun, hasilnya tergantung pada:
- Pengaturan parameter yang tepat
- Kondisi pasar
- Manajemen risiko yang disiplin
- Dan... sedikit keberuntungan

**Trading yang sukses adalah trading yang bertahan lama, bukan yang profit
besar dalam semalam.**

---

*Laporan ini disusun oleh tim Apex Grid EA.*  
*Terakhir diperbarui: 11 Juni 2026*  
*File: `docs/report_modul_non_technical.md`*
