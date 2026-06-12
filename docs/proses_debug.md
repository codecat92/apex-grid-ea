# Proses Debugging Apex Grid EA

Dokumen ini mencatat perjalanan debugging bot trading Apex Grid EA. Setiap bug yang ditemukan dicatat beserta gejala, penyebab, dan cara perbaikannya. Ditulis dalam bahasa sederhana agar mudah dipahami siapa saja.

---

## 11 Juni 2026

### 09:49 — Project Dimulai
Repository dibuat. File `CONTEXT.md` ditambahkan sebagai dokumen panduan.

---

### 11:14 — v1.00: Kode Pertama Selesai
Semua 5 layer bot selesai ditulis: sinyal masuk (MA crossover), grid manager, basket close, time filter, dan risk shutdown. Total 523 baris kode. Kode ini belum diuji di MT4.

---

### 11:21 — Review Kode + Perbaikan Masal (14 Bug Ditemukan)

**Proses:** AI melakukan review menyeluruh terhadap semua kode dan menemukan 14 masalah — dari yang ringan sampai yang bisa bikin duit hilang.

#### Bug #1: OrderSend tidak dicek hasilnya
- **Gejala:** Kalau broker tolak order (misalnya margin kurang), bot tetap naikkan level grid. Level berikutnya pakai ukuran lot yang salah.
- **Penyebab:** Kode `OrderSend(...)` ditulis tanpa dicek apakah berhasil (return >= 0) atau gagal (return -1).
- **Solusi:** Cek hasil `OrderSend`. Kalau semua order di level itu gagal, kembalikan level counter ke angka sebelumnya.

#### Bug #2: OrderClose tidak dicek hasilnya
- **Gejala:** Kalau penutupan posisi gagal (misalnya harga berubah cepat), posisi tetap terbuka tapi bot sudah reset — posisi jadi "posisi hantu" yang tidak terpantau.
- **Penyebab:** Kode `OrderClose(...)` tidak dicek return-nya. State bot di-reset tanpa peduli hasil close.
- **Solusi:** Cek hasil setiap `OrderClose`. Kalau ada yang gagal, jangan reset state — biarkan coba lagi di tick berikutnya.

#### Bug #3: Tidak ada RefreshRates() sebelum BasketClose
- **Gejala:** Harga `Bid`/`Ask` mungkin sudah basi saat menutup posisi — bisa kena reject requote.
- **Penyebab:** Tidak memanggil `RefreshRates()` sebelum menutup order.
- **Solusi:** Tambahkan `RefreshRates()` sebelum setiap `OrderClose`.

#### Bug #4: Kode hitung harga grid tidak terpakai
- **Gejala:** Untuk level > 0, bot menghitung harga grid dengan rumus, tapi langsung ditimpa dengan harga pasar saat ini.
- **Penyebab:** Loop `for (j < OrdersPerStep)` menimpa ulang variable `price` dengan `Ask`/`Bid`.
- **Solusi:** Hapus kode yang tidak terpakai. Harga pasar selalu dipakai karena trigger grid sudah memastikan harga sudah di jarak yang benar.

#### Bug #5: GeneralTP tidak jalan
- **Gejala:** Parameter `GeneralTP = 200` ada di daftar parameter tapi tidak ada kode yang menggunakannya.
- **Penyebab:** Lupa implementasi.
- **Solusi:** Tambahkan fungsi `CheckGeneralTP()` — cek apakah harga sudah bergerak menguntungkan sejauh `GeneralTP` pips dari entry pertama. Kalau ya, basket close.

#### Bug #6: Bot tidak bisa lanjut setelah stop
- **Gejala:** Bot berhenti karena target profit harian. Besoknya harusnya lanjut, tapi tetap diam.
- **Penyebab:** Kode cek ulang drawdown SAAT INI untuk menentukan boleh lanjut atau tidak. Kalau posisi kebetulan merah pas ganti hari, bot kira masih dalam kondisi drawdown stop.
- **Solusi:** Catat ALASAN kenapa bot berhenti (`STOP_DRAWDOWN`, `STOP_PROFIT`, `STOP_MARGIN`). Saat ganti hari, hanya lanjutkan kalau alasan berhenti BUKAN drawdown.

#### Bug #7: iMA() tidak divalidasi
- **Gejala:** Kalau `iMA()` gagal (return 0 atau negatif), semua nilai MA jadi 0 semua — bisa trigger sinyal palsu.
- **Penyebab:** Tidak ada pengecekan error pada hasil `iMA()`.
- **Solusi:** Tambahkan `if (nilai <= 0) return;` — kalau ada yang error, skip sinyal.

#### Bug #8: NormalizeLot pakai 2 desimal keras
- **Gejala:** Beberapa broker pakai 1 desimal untuk lot, bukan 2 — bisa kena reject.
- **Penyebab:** `NormalizeDouble(lot, 2)` — angka 2 ditulis mati.
- **Solusi:** Hitung jumlah desimal dari `MODE_LOTSTEP`. Kalau step 0.1 → 1 desimal, step 0.01 → 2 desimal.

#### Bug #9: RefreshRates() tidak dicek di OpenGridLevel
- **Gejala:** Kalau `RefreshRates()` gagal, `Ask`/`Bid` mungkin basi.
- **Penyebab:** Tidak mengecek nilai balik `RefreshRates()`.
- **Solusi:** Cek return value. Kalau gagal, skip iterasi itu.

#### Bug #10: Tidak ada README.md
- **Gejala:** File README.md tercantum di struktur project tapi tidak ada.
- **Solusi:** Buat README.md.

#### Bug #11: Tidak ada filter weekend
- **Gejala:** Bot bisa aktif di hari Sabtu/Minggu (walaupun market forex tutup).
- **Penyebab:** Hanya dicek hari Jumat, tidak ada guard untuk Sabtu (6) dan Minggu (0).
- **Solusi:** Tambahkan `if (dow == 0 || dow == 6) return false;` di `IsTradingAllowed()`.

#### Bug #12: Bandingkan waktu pakai string
- **Gejala:** Waktu dibandingkan sebagai string "HH:MM". Berfungsi benar tapi rapuh.
- **Solusi:** Konversi ke integer menit (`jam * 60 + menit`) sekali di `OnInit()`. Lebih cepat dan lebih aman.

#### Bug #13: CountSide() tidak pernah dipakai
- **Gejala:** Fungsi `CountSide()` didefinisikan tapi tidak ada yang memanggil.
- **Solusi:** Hapus fungsi yang tidak terpakai.

#### Bug #14: BasketClose pakai OrderTicket() bukan tickets[i]
- **Gejala:** Setelah `OrderSelect(tickets[i], ...)`, kode panggil `OrderTicket()` lagi. Sama saja hasilnya, tapi kurang jelas.
- **Solusi:** Pakai `tickets[i]` langsung — lebih jelas dan tidak boros.

---

### 11:29 — External Review: 2 Bug Kritis Ditemukan

AI reviewer eksternal memberikan penilaian dan menemukan 2 bug akut:

#### Bug #15: Trailing stop tidak jalan saat bot stop
- **Gejala:** Bot kena stop profit → trailing stop berhenti → posisi yang masih terbuka tidak terpantau → bisa balik rugi.
- **Penyebab:** Di `OnTick()`, `CheckTrailing()` dan `CheckGeneralTP()` hanya dipanggil KALAU `G_Stopped == false`. Begitu bot stop, exit manager ikut mati.
- **Solusi:** Pindahkan `CheckTrailing()` dan `CheckGeneralTP()` ke ATAS pengecekan `G_Stopped`. Exit harus selalu jalan — yang diblokir hanya entry dan grid baru.

#### Bug #16: CheckMA() jalan SETIAP tick
- **Gejala:** Di timeframe M1, bisa 60 tick per menit. Fungsi MA dipanggil 60 kali per batang candle — boros dan berisiko false trigger.
- **Penyebab:** Tidak ada guard untuk membatasi pengecekan MA hanya sekali per bar baru.
- **Solusi:** Tambahkan `static datetime lastBar`. Cek hanya kalau waktu bar sekarang berbeda dari bar sebelumnya.

---

### 11:46 — v1.03: Fitur Baru dari Yetti Asli

Berdasarkan observasi Yetti Classic, 5 fitur penting ditambahkan:

1. **Pending stop order:** Level > 0 sekarang pakai BuyStop/SellStop, bukan market order
2. **Basket-average TP:** GeneralTP dihitung dari rata-rata harga tertimbang lot, bukan dari entry pertama
3. **Profit-peak trailing:** Trailing stop sekarang melacak profit puncak dalam nilai uang, bukan harga
4. **Cooldown 5 menit:** Setelah basket close, bot tunggu 5 menit sebelum entry baru
5. **Gap-fill mechanism:** Kalau harga melompati pending order tanpa trigger, hapus pending + ganti market order

---

### 12:23 — Sinkronisasi Dokumentasi
Dokumen `CONTEXT.md` diperbarui agar sesuai dengan kondisi kode v1.03 yang sebenarnya.

---

### 12:51 — Dokumentasi untuk Pemula
Dibuat dokumen penjelasan kode per blok untuk programmer pemula dalam bahasa Indonesia.

---

## 12 Juni 2026

### 10:14 — Peringatan Compiler MT4 (3 Warning)

Setelah dicompile di MetaTrader 4, muncul 3 warning:

#### Warning #1: tickets uninitialized
- **Pesan:** `possible use of uninitialized variable 'tickets'`
- **Lokasi:** Fungsi `BasketClose()`, baris deklarasi `int tickets[500]`
- **Penyebab:** Compiler MT4 (`#property strict`) tidak bisa membuktikan bahwa array sudah diisi sebelum dibaca.
- **Apa akibatnya:** Sebenarnya aman — loop pertama menulis, loop kedua membaca dengan batas `n`. Tapi warning tetap perlu dihilangkan.
- **Solusi:** Tambahkan `ArrayInitialize(tickets, 0)` setelah deklarasi.

#### Warning #2 & #3: OrderDelete tidak dicek
- **Pesan:** `return value of 'OrderDelete' should be checked`
- **Lokasi:** Fungsi `ManagePendingOrders()`, dua tempat (BUYSTOP dan SELLSTOP)
- **Penyebab:** `OrderDelete()` return `bool` — `true` kalau berhasil, `false` kalau gagal. Kalau gagal (pending order sudah terisi duluan), bot tetap kirim market order → bisa double posisi.
- **Solusi:** Cek hasil `OrderDelete()`. Kalau berhasil baru kirim market order. Kalau gagal, log error.

---

### 10:18 — Bot Diam Meski MA Sudah Bersilangan 3 Kali

- **Gejala:** Di test, MA sudah Golden Cross / Death Cross berkali-kali tapi bot tidak membuka posisi sama sekali.
- **Penyebab:** `iTime(Symbol(), 0, 0)` — fungsi ini query history buffer. Di MT4, saat EA baru start atau setelah reconnect, history buffer mungkin belum siap dan return 0. `static lastBar` juga 0 di awal. `0 == 0` → `return` langsung. CheckMA() tidak pernah benar-benar jalan.
- **Solusi:** Ganti `iTime(Symbol(), 0, 0)` dengan `Time[0]`. `Time[]` adalah array bawaan chart yang selalu tersedia, tidak tergantung history buffer.

---

### 12:07 — Bot Langsung STOP di Tick Pertama (STOP_MARGIN)

- **Gejala:** Begitu EA ditaruh di chart, langsung status `G_Stopped = true`. Tidak ada order yang terbuka. Bot diam total.
- **Penyebab:** Fungsi `CheckRisk()` menghitung margin level dengan rumus `(Equity / Margin) * 100`. Saat tidak ada posisi, `AccountMargin()` return 0. Rumus menghasilkan 0. Lalu dicek: `0 < MarginCloseAll(20)` → TRUE → bot langsung `STOP_MARGIN`.
- **Mengapa ini serius:** Bot mati sebelum sempat membuka posisi apapun. Ini adalah bug yang membuat bot sama sekali tidak berfungsi di awal.
- **Solusi:** Kalau margin = 0, set margin level ke `DBL_MAX` (nilai paling besar yang bisa disimpan komputer). Artinya: "tidak ada posisi = risiko margin nol = aman".

---

### 12:18 — RefreshRates Gagal di Strategy Tester

- **Gejala:** Di MT4 Strategy Tester, log menunjukkan sinyal MA terdeteksi ("MA signal: Golden Cross"), tapi selalu diikuti "RefreshRates failed at level 0". Tidak ada order yang terbuka sepanjang backtest.
- **Penyebab:** Di `OpenGridLevel()`, saat level 0, kode memanggil `RefreshRates()` dan kalau gagal langsung `return` + rollback state. Di Strategy Tester, `RefreshRates()` sering return `false` meski data tick sebenarnya sudah tersedia dan `Ask`/`Bid` sudah benar.
- **Mengapa ini serius:** Semua sinyal terdeteksi tapi 0 order terbuka. Backtest menghasilkan hasil kosong — tidak bisa mengukur performa bot.
- **Solusi:** Hapus `return` + rollback saat `RefreshRates()` gagal. Tetap panggil `RefreshRates()` (best effort), tapi lanjut kirim order. Kalau harga benar-benar invalid, `OrderSend` akan gagal dan error handling yang sudah ada akan menanganinya.

---

### 13:00 — EA Mati Permanen Setelah Floating Drawdown (2 Tahun Diam)

- **Gejala:** Backtest Jan 2024 – Jun 2026: EA hanya trading 5 bulan pertama (Jan–Mei 2024). Dari 28 Mei 2024 sampai akhir backtest (11 Juni 2026), tidak ada SATU pun posisi terbuka — 2 tahun diam total. Tidak mungkin MA5/MA40 di M1 tidak pernah bersilangan selama 2 tahun.
- **Penyebab:** Dua bug bekerja sama:

  **Bug A — `CheckRisk()` membaca floating drawdown, bukan closed drawdown.**
  - Grid BUY 4 level floating selama 2 bulan (Mar–Mei 2024). Floating loss ~$2,230 di balance $12,268 = ddPct 18% > MaxDrawdown 15%.
  - Bot set `STOP_DRAWDOWN`, tapi TIDAK menutup posisi — hanya blokir entry baru.
  - Beberapa saat kemudian posisi floating jadi profit dan ditutup trailing. Saldo aman.

  **Bug B — `CheckReset()` tidak pernah me-reset `STOP_DRAWDOWN`.**
  - Kode sengaja skip `STOP_DRAWDOWN` di daily reset: `if (G_StopReason != STOP_DRAWDOWN)`.
  - Meski posisi sudah tutup profit, drawdown sudah 0%, `G_Stopped` tetap `true` SELAMANYA.

- **Dampak:** Backtest tidak representatif (5 bulan dari 2.5 tahun). Live trading bisa mati permanen hanya karena floating loss sesaat yang akhirnya profit.
- **Solusi:** Ubah `CheckReset()` — untuk `STOP_DRAWDOWN` dan `STOP_MARGIN`, re-check kondisi saat ini saat daily reset. Kalau drawdown/margin sudah sehat, lanjutkan trading.

```mql4
// SEBELUM (bug):
if (G_StopReason != STOP_DRAWDOWN) {
   G_Stopped = false;
   G_StopReason = STOP_NONE;
}

// SESUDAH (fix):
if (G_StopReason == STOP_DRAWDOWN) {
   double ddNow = (AccountBalance() > 0) ? (AccountBalance() - AccountEquity()) / AccountBalance() * 100 : 0;
   if (ddNow < MaxDrawdown) { G_Stopped = false; G_StopReason = STOP_NONE; }
} else if (G_StopReason == STOP_MARGIN) {
   double mrgNow = (AccountMargin() > 0) ? (AccountEquity() / AccountMargin()) * 100 : DBL_MAX;
   if (mrgNow >= MinMarginLevel) { G_Stopped = false; G_StopReason = STOP_NONE; }
} else if (G_StopReason != STOP_NONE) {
   G_Stopped = false;
   G_StopReason = STOP_NONE;
}
```

---

## Ringkasan: 20 Bug Ditemukan & Diperbaiki

| # | Kapan | Apa | Dampak | Status |
|---|-------|-----|--------|--------|
| 1-14 | 11 Jun, 11:21 | Review awal: 14 bug (error handling, dead code, missing feature) | Beragam — dari ringan sampai kritis | ✅ |
| 15 | 11 Jun, 11:29 | Trailing stop mati saat bot stop | Posisi tidak terpantau | ✅ |
| 16 | 11 Jun, 11:29 | MA dicek tiap tick, boros | Performa + false trigger | ✅ |
| 17 | 12 Jun, 10:14 | 3 warning compiler MT4 | Peringatan strict mode | ✅ |
| 18 | 12 Jun, 10:18 | Bot diam — iTime desync | Tidak ada order terbuka | ✅ |
| 19 | 12 Jun, 12:07 | Stop di tick pertama — margin 0 | Bot mati total | ✅ |
| 20 | 12 Jun, 12:18 | RefreshRates gagal di tester | Backtest kosong | ✅ |
| 21 | 12 Jun, 13:00 | STOP_DRAWDOWN tidak pernah reset — EA mati permanen | 2 tahun tanpa trade | ✅ |

---

*Terakhir diperbarui: 12 Juni 2026 — Fernando Siahaan*
