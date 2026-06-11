# Penjelasan Kode ApexGrid.mq4 — Panduan untuk Pemula

> **Ditujukan untuk:** Programmer pemula yang ingin memahami kode EA (Expert Advisor) MetaTrader 4.
> **Bahasa:** MQL4 | **File:** `src/experts/ApexGrid.mq4` | **Versi:** 1.03

---

## Daftar Isi

| No | Blok Kode | Baris | Halaman |
|----|-----------|-------|---------|
| 1  | Header & Property | 1-9 | 2 |
| 2  | Core Trading Parameters | 14-19 | 3 |
| 3  | MA Entry Signal Parameters | 24-27 | 4 |
| 4  | Trailing Exit Parameters | 32-34 | 5 |
| 5  | Time Filter Parameters | 39-46 | 6 |
| 6  | Risk Management Parameters | 51-57 | 7 |
| 7  | Stop Reason Constants | 62-65 | 8 |
| 8  | Global State Variables | 70-104 | 9 |
| 9  | PipSize() — Helper | 109-112 | 10 |
| 10 | NormalizeLot() — Helper | 117-126 | 10 |
| 11 | LotByLevel() — Helper | 131-133 | 11 |
| 12 | MakeComment() — Helper | 138-141 | 11 |
| 13 | StrToMinutes() — Helper | 146-148 | 12 |
| 14 | CurrentGridStep() — Helper | 153-159 | 12 |
| 15 | IsTradingAllowed() — Time Filter | 164-175 | 13 |
| 16 | LowestBuyPrice() / HighestSellPrice() | 180-207 | 14 |
| 17 | SideProfit() — Profit Calculator | 212-223 | 15 |
| 18 | BasketAvgPrice() — Average Price | 228-240 | 15 |
| 19 | TotalSideLots() — Lot Calculator | 245-256 | 16 |
| 20 | OpenGridLevel() — GRID MANAGER | 263-366 | 17 |
| 21 | BasketClose() — EXIT MANAGER | 372-433 | 20 |
| 22 | CheckTrailing() — TRAILING STOP | 441-482 | 22 |
| 23 | CheckGridLevels() — Grid Expansion | 488-508 | 24 |
| 24 | ManagePendingOrders() — Gap-Fill | 515-541 | 25 |
| 25 | CheckMA() — ENTRY SIGNAL | 548-578 | 26 |
| 26 | CheckGeneralTP() — General TP | 584-603 | 28 |
| 27 | CheckRisk() — RISK SHUTDOWN | 608-662 | 29 |
| 28 | CheckReset() — Daily/Weekly Reset | 667-688 | 31 |
| 29 | OnInit() / OnDeinit() / OnTick() | 693-735 | 32 |

---

## Blok 1 — Header & Property (baris 1-9)

```mql4
//+------------------------------------------------------------------+
//|                                               ApexGrid.mq4       |
//|                                   Apex Grid EA - Grid+Martingale |
//|                          Inspired by Yetti Classic v3.03_fix     |
//+------------------------------------------------------------------+
#property copyright "codecat92"
#property link      ""
#property version   "1.03"
#property strict
```

### Apa yang dilakukan?
Ini adalah **kartu identitas** bot. Sama seperti KTP yang berisi nama, alamat, dan nomor versi. MT4 membaca bagian ini untuk menampilkan informasi bot di jendela Navigator.

### Dampak di MT4:
- `#property copyright` → muncul di tab "Common" saat kamu attach EA ke chart
- `#property version "1.03"` → MT4 tahu ini versi berapa. Penting untuk tracking update.
- `#property strict` → **Mode ketat!** MQL4 akan menolak kode yang "malas" (misalnya variabel tidak dideklarasikan, implicit casting). Ibarat guru killer yang tidak mentolerir jawaban ngawur.

### Dampak ke akun user:
Tidak langsung berdampak. Tapi `#property strict` mencegah bug tersembunyi yang bisa bikin bot salah buka posisi — ini **melindungi uangmu**.

---

## Blok 2 — Core Trading Parameters (baris 14-19)

```mql4
extern int    MagicNumber   = 1888;
extern double StartLot      = 0.10;
extern double Multiplier    = 1.5;
extern int    GridStep      = 250;
extern int    GeneralTP     = 200;
extern int    OrdersPerStep = 1;
```

### Apa yang dilakukan?
Parameter **wajib** yang menentukan bagaimana bot membuka posisi. Kata kunci `extern` artinya parameter ini **bisa diubah langsung dari jendela MT4** tanpa perlu edit kode.

### Analogi:
Bayangkan kamu punya mesin fotokopi otomatis:
- **StartLot** = berapa lembar kertas di tumpukan pertama? (0.10 lot)
- **Multiplier** = setiap kali mesin menambah tumpukan baru, kalikan jumlah kertas dengan 1.5
- **GridStep** = jarak antar tumpukan (250 pips)
- **GeneralTP** = target profit keseluruhan (200 pips)

### Detail per parameter:

| Parameter | Arti | Contoh |
|-----------|------|--------|
| **MagicNumber 1888** | ID unik bot. Semua order yang dibuka bot ini akan punya "stempel" 1888. Bot tidak akan menyentuh order manual kamu (yang tanpa stempel). | Seperti nomor resi pengiriman — hanya paket dengan nomor ini yang diurus bot. |
| **StartLot 0.10** | Ukuran lot pertama. 0.10 lot = $1 per pip di pair USD. | Kalau harga naik 1 pip, profit $1. |
| **Multiplier 1.5** | Setiap level baru, lot dikali 1.5. | Level 0: 0.10 → Level 1: 0.15 → Level 2: 0.23 → dst. |
| **GridStep 250** | Jarak 250 pips sebelum bot buka level berikutnya. | Harga harus bergerak 250 pips berlawanan dulu. |
| **GeneralTP 200** | Kalau rata-rata semua posisi sudah profit 200 pips → tutup semua. | Target take profit global. |
| **OrdersPerStep 1** | Berapa order yang dibuka per level. | Nilai 1 = satu order per level. |

### Dampak ke akun user:
**SANGAT BESAR.** Kalau StartLot terlalu besar atau Multiplier terlalu agresif, margin akun bisa habis dalam beberapa level saja. Ini adalah parameter yang paling menentukan **apakah akunmu selamat atau kena margin call**.

---

## Blok 3 — MA Entry Signal Parameters (baris 24-27)

```mql4
extern int    MAFastPeriod   = 5;
extern int    MASlowPeriod   = 40;
extern int    MAMethod       = 0;   // 0=SMA
extern int    MAPrice        = 0;   // 0=Close
```

### Apa yang dilakukan?
Mengatur **Moving Average** — indikator teknis yang dipakai bot untuk memutuskan kapan mulai trading.

### Analogi:
Moving Average seperti **menghitung nilai rata-rata rapor**:
- **MA Fast (5)** = rata-rata 5 candle terakhir → sangat sensitif, naik-turun cepat
- **MA Slow (40)** = rata-rata 40 candle terakhir → lebih kalem, menunjukkan tren besar
- **MAMethod 0** = Simple Moving Average (SMA) — hitung rata-rata biasa (bukan yang diberi bobot)
- **MAPrice 0** = dihitung dari harga Close (penutupan) tiap candle

Kenapa 5 dan 40? Karena timeframe M1 (1 menit), candle bergerak cepat. MA 5 itu = 5 menit terakhir. MA 40 = 40 menit terakhir.

### Dampak ke akun user:
Menentukan **seberapa sering** bot entry. Kalau periode MA terlalu kecil, bot bisa entry terlalu sering (overtrading). Kalau terlalu besar, bot bisa ketinggalan momentum.

---

## Blok 4 — Trailing Exit Parameters (baris 32-34)

```mql4
extern bool   UseTrailingStop = true;
extern int    FixedDistance   = 50;
extern int    TriggerDistance = 160;
```

### Apa yang dilakukan?
Mengatur **kapan bot menutup semua posisi** berdasarkan profit yang sudah dicapai. Ini seperti "safety net" — mengunci profit yang sudah ada.

### Analogi:
Kamu main saham, beli di harga 1000. Harga naik ke 1200 (profit 200). Kamu pasang aturan: "kalau profit turun 50 dari puncak, saya jual semua."
- **TriggerDistance 160** = Trailing baru aktif kalau profit sudah > 160 pips
- **FixedDistance 50** = Kalau profit turun 50 pips (dalam nilai uang) dari puncak → jual semua!

### Kenapa tidak langsung aktif dari awal?
Karena grid baru dibuka perlu "ruang bernapas". Kalau trailing langsung aktif dari 0, bot akan nutup posisi terlalu cepat sebelum grid sempat berkembang.

### Dampak ke akun user:
**Melindungi profit.** Tanpa trailing, bot hanya mengandalkan GeneralTP (200 pips). Dengan trailing, kalau harga tiba-tiba berbalik, profit yang sudah ada tetap terkunci.

---

## Blok 5 — Time Filter Parameters (baris 39-46)

```mql4
extern string StartTime          = "01:00";
extern string EndTime            = "22:00";
extern bool   FridayTrade        = true;
extern string FridayStop         = "14:00";
extern bool   UseExtraTime       = true;
extern string ExtraStart         = "01:06";
extern string ExtraEnd           = "01:07";
extern int    AdditionalGridStep = 100;
```

### Apa yang dilakukan?
**Jam kerja bot.** Bot hanya trading di jam yang ditentukan. Di luar jam itu, bot diam (tidak buka posisi baru), tapi tetap memonitor posisi yang sudah terbuka.

### Analogi:
Bot ini seperti **karyawan shift malam** yang hanya bekerja jam 01:00 - 22:00. Hari Jumat pulang lebih awal (14:00). Ada "extra time" 01:06-01:07 — seperti jam lembur singkat dengan aturan berbeda (GridStep lebih kecil).

### Detail:

| Parameter | Arti |
|-----------|------|
| StartTime 01:00 | Mulai trading jam 1 pagi (sesi London buka) |
| EndTime 22:00 | Berhenti jam 10 malam |
| FridayTrade true | Tetap trading di hari Jumat |
| FridayStop 14:00 | Tapi Jumat berhenti jam 2 siang (hindari gap weekend) |
| ExtraStart 01:06 | Window extra 1 menit (01:06 - 01:07) |
| AdditionalGridStep 100 | Grid step khusus extra time = 100 pips (lebih rapat) |

### Dampak ke akun user:
**Mencegah trading di jam berbahaya.** Sesi Asia (low volatility) dan penutupan Jumat sore sering menghasilkan pergerakan liar. Time filter melindungi akun dari kondisi pasar yang tidak menguntungkan.

---

## Blok 6 — Risk Management Parameters (baris 51-57)

```mql4
extern double DailyProfitPct    = 20.0;
extern double WeeklyProfitPct   = 20.0;
extern double DrawdownCloseAll  = 90.0;
extern double MarginCloseAll    = 20.0;
extern bool   AutoStopTrading   = true;
extern double MaxDrawdown       = 15.0;
extern double MinMarginLevel    = 1000.0;
```

### Apa yang dilakukan?
**Rem darurat.** Parameter ini mencegah akunmu meledak. Kalau kondisi berbahaya terdeteksi, bot akan berhenti sendiri atau menutup semua posisi.

### Analogi:
Ini seperti **sekring listrik di rumah**. Kalau arus listrik terlalu besar, sekring putus — mencegah kebakaran. Parameter risk management adalah sekring untuk akun tradingmu.

### Detail:

| Parameter | Arti | Analogi |
|-----------|------|---------|
| **DailyProfitPct 20%** | Kalau profit hari ini ≥ 20% dari equity awal hari → stop trading. | "Aku sudah cukup hari ini, pulang dulu." |
| **WeeklyProfitPct 20%** | Kalau profit minggu ini ≥ 20% → stop. | Target mingguan tercapai. |
| **DrawdownCloseAll 90%** | Kalau floating loss ≥ 90% dari balance → **tutup semua posisi!** | RUMAH KEBAKARAN — evakuasi total! |
| **MarginCloseAll 20%** | Kalau margin level ≤ 20% → tutup semua. | Hampir kena margin call broker. |
| **AutoStopTrading true** | Aktifkan fitur auto-stop. | Saklar utama rem darurat. |
| **MaxDrawdown 15%** | Kalau floating loss ≥ 15% → stop trading (tidak buka posisi baru). | Lampu kuning: hati-hati, jangan tambah posisi. |
| **MinMarginLevel 1000%** | Kalau margin level ≤ 1000% → stop trading. | Batas aman margin. |

### Dampak ke akun user:
**INILAH PENYELAMAT AKUNMU.** Tanpa risk management, satu pergerakan liar bisa menghabiskan seluruh balance. Dengan parameter ini, bot tahu kapan harus "angkat tangan."

---

## Blok 7 — Stop Reason Constants (baris 62-65)

```mql4
#define STOP_NONE      0
#define STOP_DRAWDOWN  1
#define STOP_PROFIT    2
#define STOP_MARGIN    3
```

### Apa yang dilakukan?
Membuat **kode alasan** kenapa bot berhenti trading. `#define` adalah cara MQL4 memberi nama ke angka — jadi kita bisa menulis `STOP_PROFIT` daripada `2` (lebih mudah dibaca).

### Dampak:
Hanya untuk internal bot. Tidak terlihat di MT4. Tapi kode ini dipakai di log (Print) untuk menunjukkan alasan bot berhenti.

---

## Blok 8 — Global State Variables (baris 70-104)

```mql4
string   G_Name            = "Apex Grid";
int      G_Magic           = 1888;
int      G_StartMin        = 0;
...
bool     G_BuyActive       = false;
bool     G_SellActive      = false;
int      G_BuyLevel        = -1;
...
bool     G_Stopped         = false;
int      G_StopReason      = 0;
datetime G_DayStart        = 0;
...
```

### Apa yang dilakukan?
Ini adalah **otak / memori** bot. Semua variabel ini menyimpan "keadaan" bot saat ini — apakah sedang ada grid BUY aktif? Level berapa? Berapa profit puncak?

### Analogi:
Bayangkan bot adalah robot vacuum cleaner. Variabel global ini adalah memorinya:
- "Saya sedang di lantai 2" = `G_BuyActive = true`
- "Saya baru membersihkan 3 ruangan" = `G_BuyLevel = 3`
- "Baterai hampir habis" = `G_Stopped = true`

### Variabel penting yang harus dipahami:

| Variabel | Fungsi |
|----------|--------|
| `G_BuyActive` | Apakah grid BUY sedang aktif? |
| `G_SellActive` | Apakah grid SELL sedang aktif? |
| `G_BuyLevel` | Level grid terakhir yang dibuka (-1 = belum ada). Level 0 = market order pertama. |
| `G_BuyFirstPrice` | Harga entry level 0 (patokan perhitungan jarak). |
| `G_BuyPeak` | Harga tertinggi yang pernah dicapai (BUY). Untuk hitung trailing. |
| `G_BuyPeakProfit` | Profit tertinggi yang pernah dicapai basket (dalam $). |
| `G_BuyTrailing` | Apakah trailing sudah aktif? |
| `G_BuyLastClosed` | Kapan terakhir kali basket BUY ditutup? (untuk cooldown 5 menit) |
| `G_SellTrough` | Harga terendah yang pernah dicapai (SELL). |
| `G_Stopped` | Apakah bot sedang berhenti total? |
| `G_StopReason` | Kenapa berhenti? (lihat Blok 7) |
| `G_DayEquity` | Equity di awal hari (untuk hitung profit harian). |

### Dampak ke akun user:
Variabel ini **mengendalikan semua keputusan trading** bot. Tanpa state tracking, bot tidak akan tahu kapan harus buka level baru, kapan harus basket close, atau kapan harus berhenti.

---

## Blok 9 — PipSize() (baris 109-112)

```mql4
double PipSize() {
   if (Digits == 5 || Digits == 3) return Point * 10;
   return Point;
}
```

### Apa yang dilakukan?
Menghitung **ukuran 1 pip yang sebenarnya** berdasarkan broker.

### Mengapa perlu?
Ada dua jenis broker:
- **4-digit broker:** GBPUSD = 1.2500 (1 pip = 0.0001 = `Point`)
- **5-digit broker:** GBPUSD = 1.25000 (1 pip = 0.00010 = `Point * 10`)

`Digits` adalah jumlah digit di belakang koma yang ditampilkan broker. Kalau 5 atau 3 digit, berarti broker fractional pip — maka 1 pip = 10 Point.

### Dampak:
Kalau fungsi ini salah, semua kalkulasi jarak (GridStep, Trailing, GeneralTP) akan **kacau**. Bot bisa buka posisi di harga yang salah.

---

## Blok 10 — NormalizeLot() (baris 117-126)

```mql4
double NormalizeLot(double lot) {
   double min  = MarketInfo(Symbol(), MODE_MINLOT);
   double max  = MarketInfo(Symbol(), MODE_MAXLOT);
   double step = MarketInfo(Symbol(), MODE_LOTSTEP);
   int digits = (step >= 0.1) ? 1 : 2;
   lot = MathFloor(lot / step) * step;
   if (lot < min) lot = min;
   if (lot > max) lot = max;
   return NormalizeDouble(lot, digits);
}
```

### Apa yang dilakukan?
**Memastikan ukuran lot valid** sesuai aturan broker, lalu **membulatkan** ke bawah ke kelipatan LOTSTEP.

### Analogi:
Kamu mau tarik uang di ATM. ATM hanya mengeluarkan pecahan 50.000. Kamu minta 130.000 — ATM akan memberi 100.000 (dibulatkan ke bawah ke kelipatan terdekat).

### Detail langkah:
1. Cari tahu lot minimum, maksimum, dan step dari broker (`MarketInfo`)
2. Bulatkan lot ke bawah ke kelipatan `step` (`MathFloor`)
3. Kalau lot < minimum → pakai minimum
4. Kalau lot > maksimum → pakai maksimum (biar tidak error)
5. `NormalizeDouble` → pastikan hanya ada 1-2 digit desimal

### Dampak ke akun user:
**Mencegah error OrderSend karena lot tidak valid.** Tanpa ini, bot bisa gagal buka posisi karena lot 0.123 padahal broker hanya menerima kelipatan 0.01.

---

## Blok 11 — LotByLevel() (baris 131-133)

```mql4
double LotByLevel(int level) {
   return NormalizeLot(StartLot * MathPow(Multiplier, level));
}
```

### Apa yang dilakukan?
Menghitung ukuran lot untuk level grid tertentu dengan **rumus Martingale**: `StartLot × Multiplier^level`.

### Contoh perhitungan:
```
Level 0: 0.10 × 1.5^0 = 0.10 × 1    = 0.10
Level 1: 0.10 × 1.5^1 = 0.10 × 1.5  = 0.15
Level 2: 0.10 × 1.5^2 = 0.10 × 2.25 = 0.23 (dibulatkan)
Level 3: 0.10 × 1.5^3 = 0.10 × 3.375= 0.34
Level 4: 0.10 × 1.5^4 = 0.51
Level 5: 0.10 × 1.5^5 = 0.76
Level 6: 0.10 × 1.5^6 = 1.14
```

### Mengapa lot semakin besar?
Strategi Martingale: semakin jauh harga bergerak berlawanan, semakin besar lot dibuka. Saat harga berbalik, posisi-posisi besar ini akan menghasilkan profit besar untuk menutup kerugian posisi-posisi kecil sebelumnya.

### Dampak ke akun user:
**Pedang bermata dua.** Martingale bisa menghasilkan profit besar saat harga berbalik, tapi juga bisa menghabiskan margin dengan cepat jika harga terus bergerak satu arah tanpa koreksi.

---

## Blok 12 — MakeComment() (baris 138-141)

```mql4
string MakeComment(string side, int level) {
   if (level == 0) return G_Name + " " + side;
   return G_Name + " " + side + " " + IntegerToString(level);
}
```

### Apa yang dilakukan?
Membuat **label** (komentar) unik untuk setiap order yang dibuka bot.

### Hasil untuk berbagai skenario:
- Level 0 BUY → `"Apex Grid BUY"`
- Level 1 BUY → `"Apex Grid BUY 1"`
- Level 5 SELL → `"Apex Grid SELL 5"`

### Mengapa penting?
Komentar inilah yang dipakai bot untuk **mengidentifikasi order mana miliknya**. Semua fungsi mencari order dengan cara mencocokkan komentar — bukan MagicNumber saja, tapi juga prefix "Apex Grid BUY" atau "Apex Grid SELL".

---

## Blok 13 — StrToMinutes() (baris 146-148)

```mql4
int StrToMinutes(string t) {
   return StrToInteger(StringSubstr(t, 0, 2)) * 60 + StrToInteger(StringSubstr(t, 3, 2));
}
```

### Apa yang dilakukan?
Mengubah format waktu `"HH:MM"` menjadi **jumlah menit** (integer). Contoh: `"01:30"` → `90` (1 jam × 60 + 30 menit).

### Mengapa perlu?
Lebih mudah membandingkan waktu dalam bentuk menit ketimbang string. `if (now < 90)` lebih sederhana daripada `if (time < "01:30")`.

---

## Blok 14 — CurrentGridStep() (baris 153-159)

```mql4
int CurrentGridStep() {
   if (UseExtraTime) {
      int now = Hour() * 60 + Minute();
      if (now >= G_ExtraStartMin && now <= G_ExtraEndMin) return AdditionalGridStep;
   }
   return GridStep;
}
```

### Apa yang dilakukan?
Mengembalikan **GridStep yang berlaku saat ini**. Normalnya 250 pips, tapi di extra window (01:06-01:07) menjadi 100 pips (lebih rapat).

### Analogi:
Seperti jalan tol — normalnya batas kecepatan 100 km/jam, tapi di zona sekolah jadi 30 km/jam. Bot punya "zona khusus" dengan grid lebih rapat.

---

## Blok 15 — IsTradingAllowed() — TIME FILTER (baris 164-175)

```mql4
bool IsTradingAllowed() {
   if (G_Stopped) return false;
   int dow = DayOfWeek();
   if (dow == 0 || dow == 6) return false;
   int now = Hour() * 60 + Minute();
   if (now < G_StartMin || now > G_EndMin) return false;
   if (dow == 5) {
      if (!FridayTrade) return false;
      if (now >= G_FridayStopMin) return false;
   }
   return true;
}
```

### Apa yang dilakukan?
**Penjaga gerbang.** Fungsi ini memeriksa apakah bot boleh trading saat ini dengan 4 lapis pengecekan:

1. **Bot berhenti?** → Tidak boleh
2. **Hari Sabtu/Minggu?** → Tidak boleh (market tutup)
3. **Di luar jam trading?** → Tidak boleh
4. **Hari Jumat & sudah lewat jam stop?** → Tidak boleh

### Dampak di MT4:
Fungsi ini dipanggil di `OnTick()` (setiap ada pergerakan harga baru). Selama `IsTradingAllowed()` mengembalikan `false`, bot tidak akan membuka posisi baru — tapi **tetap memonitor dan mengelola posisi yang sudah terbuka**.

### Dampak ke akun user:
**Mencegah entry di waktu berbahaya.** Weekend gap adalah musuh trader — harga Senin bisa buka jauh dari harga Jumat. Time filter memastikan tidak ada posisi terbuka saat weekend.

---

## Blok 16 — LowestBuyPrice() / HighestSellPrice() (baris 180-207)

```mql4
double LowestBuyPrice() {
   double low = DBL_MAX;
   string prefix = G_Name + " BUY";
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != G_Magic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      if (OrderOpenPrice() < low) low = OrderOpenPrice();
   }
   return (low == DBL_MAX) ? 0 : low;
}
```

### Apa yang dilakukan?
**Memindai SEMUA order yang sedang terbuka** dan mencari harga terendah (untuk BUY) / tertinggi (untuk SELL) di antara order milik bot ini.

### Mengapa penting?
Grid level baru selalu dibuka **GridStep di bawah harga terendah** (BUY) atau **GridStep di atas harga tertinggi** (SELL). Fungsi ini memberi tahu "di mana posisi terdalam kita saat ini."

### Analogi:
Kamu punya beberapa jebakan beruang di hutan. Kamu perlu tahu jebakan mana yang paling dalam ke jurang — karena jebakan berikutnya harus dipasang lebih dalam lagi.

### Dampak ke akun user:
Menentukan di mana level grid berikutnya akan dibuka. Kalau fungsi ini salah mengidentifikasi harga, grid bisa overlap atau terlalu jauh.

---

## Blok 17 — SideProfit() — Profit Calculator (baris 212-223)

```mql4
double SideProfit(string side) {
   double p = 0;
   string prefix = G_Name + " " + side;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      // ... filter by magic, symbol, comment ...
      p += OrderProfit() + OrderSwap() + OrderCommission();
   }
   return p;
}
```

### Apa yang dilakukan?
Menghitung **total profit bersih** semua posisi di satu sisi (BUY atau SELL), sudah termasuk swap (bunga menginap) dan komisi broker.

### Rumus: `Profit Bersih = Profit + Swap + Komisi`

- **OrderProfit()** = profit dari selisih harga (bisa positif atau negatif)
- **OrderSwap()** = bunga menginap (bisa positif atau negatif, tergantung pair dan arah)
- **OrderCommission()** = komisi broker per lot (selalu negatif)

### Dampak ke akun user:
Ini adalah **angka yang kamu lihat di terminal MT4** untuk basket posisi itu. Fungsi ini dipakai untuk menentukan kapan trailing stop terpicu.

---

## Blok 18 — BasketAvgPrice() — Average Price (baris 228-240)

```mql4
double BasketAvgPrice(string side) {
   double totalLots = 0, weightedPrice = 0;
   string prefix = G_Name + " " + side;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      // ... filter ...
      weightedPrice += OrderOpenPrice() * OrderLots();
      totalLots     += OrderLots();
   }
   return (totalLots > 0) ? (weightedPrice / totalLots) : 0;
}
```

### Apa yang dilakukan?
Menghitung **harga rata-rata tertimbang lot** dari semua posisi dalam satu basket.

### Mengapa "tertimbang lot"?
Karena posisi dengan lot besar punya pengaruh lebih besar. Bayangkan:
- Posisi 1: lot 0.10 di harga 1.2500
- Posisi 2: lot 1.00 di harga 1.2400

Rata-rata biasa = (1.25 + 1.24) / 2 = 1.2450 ❌ (Ini SALAH!)
Rata-rata tertimbang = (0.10×1.25 + 1.00×1.24) / 1.10 = 1.2409 ✅ (Ini BENAR!)

### Dampak ke akun user:
Dipake untuk **GeneralTP check**. Kalau harga sudah bergerak melebihi GeneralTP dari rata-rata tertimbang ini, basket ditutup.

---

## Blok 19 — TotalSideLots() — Lot Calculator (baris 245-256)

```mql4
double TotalSideLots(string side) {
   double lots = 0;
   string prefix = G_Name + " " + side;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      // ... filter ...
      lots += OrderLots();
   }
   return lots;
}
```

### Apa yang dilakukan?
Menghitung **total lot** dari semua posisi dalam satu basket (BUY atau SELL).

### Dampak ke akun user:
Dipake untuk konversi **pips → nilai uang** di fungsi trailing stop. Karena FixedDistance dalam pips harus dikonversi ke dollar berdasarkan total lot.

---

## Blok 20 — OpenGridLevel() — GRID MANAGER (baris 263-366)

```mql4
void OpenGridLevel(string side) {
   int level;
   int cmd, slip = 3;
   bool isPending;
   // ... tentukan level, cmd, isPending ...

   double lot = LotByLevel(level);
   string cmt = MakeComment(side, level);

   // LEVEL 0: Market order
   if (level == 0) { /* ... RefreshRates, catat first price ... */ }

   // LEVEL > 0: Hitung harga pending order
   if (isPending) { /* ... LowestBuyPrice/HighestSellPrice - step ... */ }

   // KIRIM ORDER
   for (int j = 0; j < OrdersPerStep; j++) {
      int ticket = OrderSend(/* ... */);
      if (ticket < 0) {
         if (isPending && err == 130) {
            // Fallback ke market order
         }
      }
   }

   // GAGAL? Rollback level
   if (!anySucceeded) { /* ... */ }
}
```

### APA INI ADALAH JANTUNG BOT.
Fungsi ini yang **membuka posisi** — bisa market order (level 0) atau pending stop order (level > 0). Mari kita bongkar langkah demi langkah.

### Flowchart:

```
OpenGridLevel("BUY") dipanggil
    │
    ├─ Tentukan level: G_BuyLevel + 1
    │
    ├─ LEVEL 0?
    │   ├─ YA: Market order (OP_BUY)
    │   │       RefreshRates(), catat first price
    │   │
    │   └─ TIDAK (Level > 0):
    │       Pending BuyStop di bawah harga terendah
    │
    ├─ Hitung lot: StartLot × Multiplier^level
    │
    ├─ Kirim order ke broker (OrderSend)
    │   ├─ SUKSES → lanjut
    │   ├─ ERROR 130 (harga terlalu dekat) → fallback market order
    │   └─ ERROR LAIN → log error
    │
    └─ Ada yang sukses? 
        ├─ YA → selesai
        └─ TIDAK → rollback: G_BuyLevel--, reset state
```

### Detail Error 130 (Bullshit stops):

Error 130 adalah error paling umum di MT4 — artinya **"stops terlalu dekat dengan harga pasar"**. Setiap broker punya aturan STOPLEVEL (jarak minimal pending order dari harga saat ini). Kalau bot menghitung harga pending yang terlalu dekat, broker menolak dengan error 130.

**Solusi bot:** Kalau kena error 130, langsung buka **market order** (harga pasar) sebagai gantinya. Lebih baik buka sekarang daripada gagal terus.

### Dampak ke akun user:
**KRUSIAL.** Fungsi ini yang benar-benar membuka posisi di akunmu. Setiap kali dipanggil, lot baru masuk ke akun. Kalau fungsi ini error, posisi tidak terbuka — grid tidak lengkap — strategi bisa gagal.

---

## Blok 21 — BasketClose() — EXIT MANAGER (baris 372-433)

```mql4
void BasketClose(string side) {
   // 1. KUMPULKAN SEMUA TICKET
   int tickets[500];
   int n = 0;
   for (/* semua order */) {
      if (/* milik bot, symbol sama, side sama */) {
         tickets[n] = OrderTicket();
         n++;
      }
   }

   // 2. TUTUP SATU PER SATU
   for (int i = 0; i < n; i++) {
      if (OrderType() == OP_BUY)
         OrderClose(tickets[i], OrderLots(), Bid, ...);
      else
         OrderClose(tickets[i], OrderLots(), Ask, ...);
   }

   // 3. RESET STATE
   G_BuyActive = false;
   G_BuyLevel = -1;
   G_BuyLastClosed = TimeCurrent();
   // ... reset semua variabel BUY ...
}
```

### Apa yang dilakukan?
**Menutup SEMUA posisi** dalam satu basket (BUY atau SELL) sekaligus — termasuk pending order yang belum terisi.

### Kenapa disebut "Basket Close"?
Karena semua posisi diperlakukan sebagai satu "keranjang" (basket). Tidak ada penutupan satu per satu — tutup semua atau tidak sama sekali.

### Langkah detail:

1. **Kumpulkan ticket:** Loop semua order, kumpulkan ticket number yang sesuai (magic number cocok, symbol cocok, prefix komentar cocok)
2. **Tutup berurutan:** Loop semua ticket yang terkumpul, panggil `OrderClose()` satu per satu
3. **Reset state:** Semua variabel BUY atau SELL dikembalikan ke nilai awal (false, -1, 0). Catat waktu penutupan untuk cooldown.

### Kenapa BUY tutup di Bid, SELL tutup di Ask?
- **BUY** dibuka di Ask, ditutup di Bid → profit = Bid - Ask_open
- **SELL** dibuka di Bid, ditutup di Ask → profit = Bid_open - Ask

Ini aturan dasar Forex: buy di harga jual (Ask), sell di harga beli (Bid). Saat menutup, kebalikannya.

### Dampak ke akun user:
**Inilah realisasi profit atau loss.** Semua floating P/L berubah menjadi realized P/L. Balance akun bertambah (profit) atau berkurang (loss). Setelah basket close, cooldown 5 menit mencegah bot langsung entry lagi.

---

## Blok 22 — CheckTrailing() — TRAILING STOP (baris 441-482)

```mql4
void CheckTrailing() {
   if (!UseTrailingStop) return;

   double pip    = PipSize();
   double pipVal = pip * MarketInfo(Symbol(), MODE_TICKVALUE) / MarketInfo(Symbol(), MODE_TICKSIZE);

   // BUY trailing
   if (G_BuyActive) {
      double dist   = (Bid - G_BuyFirstPrice) / pip;
      double profit = SideProfit("BUY");
      if (dist >= TriggerDistance) G_BuyTrailing = true;
      if (G_BuyTrailing) {
         if (profit > G_BuyPeakProfit) G_BuyPeakProfit = profit;
         double drop      = G_BuyPeakProfit - profit;
         double threshold = FixedDistance * pipVal * TotalSideLots("BUY");
         if (drop >= threshold && drop > 0) BasketClose("BUY");
      }
   }
   // SELL trailing (mirror)
}
```

### Apa yang dilakukan?
**Mengunci profit.** Bayangkan kamu punya safety net yang terpasang di bawahmu saat kamu naik tangga. Semakin tinggi kamu naik, net juga ikut naik — tapi kalau kamu jatuh, net menangkapmu.

### Analogi naik tangga:
1. Kamu mulai di lantai 1 (profit = $0, puncak = $0)
2. Naik ke lantai 5 (profit = $50, puncak = $50) ← net naik ke $45
3. Naik ke lantai 10 (profit = $100, puncak = $100) ← net naik ke $95
4. **Terpeleset!** Jatuh ke lantai 6 (profit = $60)
5. Net di $95 menangkap → **BASKET CLOSE!** Kamu tetap profit $95.

### Cara kerja kode:
1. **Hitung jarak** dari first price ke harga sekarang (dalam pips)
2. **TriggerDistance 160** = trailing baru aktif setelah harga bergerak 160 pips dari entry pertama
3. **Lacak profit puncak:** Setiap tick, update `G_BuyPeakProfit` kalau profit sekarang lebih tinggi
4. **Cek penurunan:** Hitung selisih profit puncak vs sekarang
5. **Konversi threshold:** `FixedDistance × pipVal × TotalLot` — karena threshold dalam NILAI UANG ($), bukan pips
6. **Trigger:** Kalau penurunan ≥ threshold → `BasketClose()`

### Mengapa threshold dikali TotalSideLots?
Karena FixedDistance 50 pips adalah 50 pips untuk **1 lot standar**. Kalau basket punya total 2 lot, 50 pips = 2× nilai uang 1 lot. Makanya threshold disesuaikan dengan total lot.

### Dampak ke akun user:
**Profit protector.** Tanpa trailing, bot hanya punya GeneralTP (200 pips). Dengan trailing, kalau harga balik setelah profit 50 pips, profit tetap terkunci di sekitar 45 pips. Ini mencegah "profit jadi loss."

---

## Blok 23 — CheckGridLevels() — Grid Expansion (baris 488-508)

```mql4
void CheckGridLevels() {
   double pip  = PipSize();
   int step    = CurrentGridStep();
   double dist;

   // BUY: harga turun GridStep dari level terdalam
   if (G_BuyActive) {
      double lowest = LowestBuyPrice();
      if (lowest == 0) lowest = G_BuyFirstPrice;
      dist = (lowest - Bid) / pip;
      if (dist >= step) OpenGridLevel("BUY");
   }

   // SELL: harga naik GridStep dari level tertinggi
   if (G_SellActive) {
      double highest = HighestSellPrice();
      if (highest == 0) highest = G_SellFirstPrice;
      dist = (Ask - highest) / pip;
      if (dist >= step) OpenGridLevel("SELL");
   }
}
```

### Apa yang dilakukan?
Setiap tick, bot memeriksa: **"Apakah harga sudah bergerak cukup jauh berlawanan arah untuk membuka level grid baru?"**

### Logika:
- **BUY**: Harga turun. Hitung jarak dari harga terendah ke Bid sekarang. Kalau ≥ GridStep (250 pips) → buka level baru.
- **SELL**: Harga naik. Hitung jarak dari Ask sekarang ke harga tertinggi. Kalau ≥ GridStep → buka level baru.

### Dampak ke akun user:
Fungsi ini yang **menentukan kapan grid berkembang**. Setiap kali terpicu, posisi baru dibuka dengan lot lebih besar → margin usage naik → risiko meningkat. Tapi ini juga inti strategi: semakin dalam grid, semakin besar potensi recovery.

---

## Blok 24 — ManagePendingOrders() — Gap-Fill (baris 515-541)

```mql4
void ManagePendingOrders() {
   double pip = PipSize();
   for (/* semua order */) {
      if (OrderType() != OP_BUYSTOP && OrderType() != OP_SELLSTOP) continue;
      
      // BUYSTOP: harga sudah lewat jauh di bawah pending?
      if (OrderType() == OP_BUYSTOP && Ask <= OrderOpenPrice() - 5 * pip) {
         OrderDelete(OrderTicket());   // hapus pending
         OrderSend(OP_BUY, ...);        // ganti market order
      }
      // SELLSTOP: harga sudah lewat jauh di atas pending?
      if (OrderType() == OP_SELLSTOP && Bid >= OrderOpenPrice() + 5 * pip) {
         OrderDelete(OrderTicket());   // hapus pending
         OrderSend(OP_SELL, ...);       // ganti market order
      }
   }
}
```

### Apa yang dilakukan?
**Menjaring order yang terlewat.** Bayangkan kamu pasang jebakan tikus di titik A. Tikusnya ternyata lompat langsung ke titik C, melewati titik A. Jebakan di A tidak terpicu. Fungsi ini mendeteksi situasi itu dan **memindahkan jebakan langsung ke posisi tikus sekarang** (market order).

### Kenapa ini terjadi?
Pending order (BuyStop/SellStop) hanya terpicu kalau harga **menyentuh** levelnya. Kalau harga "gap" (meloncat) karena volatilitas tinggi, pending order tidak akan terisi. Gap-fill memastikan grid tetap lengkap.

### Kondisi trigger:
- **BuyStop**: harga Ask sudah **di bawah** harga pending minus 5 pips → harga sudah "lewat", delete + market buy
- **SellStop**: harga Bid sudah **di atas** harga pending plus 5 pips → harga sudah "lewat", delete + market sell

### Dampak ke akun user:
**Menjaga integritas grid.** Tanpa gap-fill, grid bisa bolong (ada level yang tidak terisi). Grid yang tidak lengkap akan mengubah titik impas (break-even) keseluruhan — bisa menyebabkan kerugian lebih besar.

---

## Blok 25 — CheckMA() — ENTRY SIGNAL (baris 548-578)

```mql4
void CheckMA() {
   static datetime lastBar = 0;
   datetime currentBar = iTime(Symbol(), 0, 0);
   if (currentBar == lastBar) return;
   lastBar = currentBar;

   double fast1 = iMA(..., 1);   // bar 1 (baru selesai)
   double slow1 = iMA(..., 1);
   double fast2 = iMA(..., 2);   // bar 2 (sebelumnya)
   double slow2 = iMA(..., 2);

   int cooldownSec = 300;

   // Golden Cross: fast memotong slow KE ATAS
   if (!G_BuyActive && fast2 <= slow2 && fast1 > slow1) {
      if (G_BuyLastClosed == 0 || TimeCurrent() - G_BuyLastClosed >= cooldownSec) {
         OpenGridLevel("BUY");
      }
   }

   // Death Cross: fast memotong slow KE BAWAH
   if (!G_SellActive && fast2 >= slow2 && fast1 < slow1) {
      if (G_SellLastClosed == 0 || TimeCurrent() - G_SellLastClosed >= cooldownSec) {
         OpenGridLevel("SELL");
      }
   }
}
```

### Apa yang dilakukan?
Mendeteksi **MA Crossover** — momen ketika Moving Average cepat memotong Moving Average lambat. Inilah **sinyal entry** bot.

### Apa itu MA Crossover?

```
Golden Cross (sinyal BUY):
   MA Fast (garis merah) memotong MA Slow (garis biru) DARI BAWAH KE ATAS
   → Artinya: tren naik dimulai → saatnya BUY
   
   Sebelum: Fast 1.2490 ≤ Slow 1.2500
   Sesudah: Fast 1.2510 > Slow 1.2500  ← CROSSOVER!

Death Cross (sinyal SELL):
   MA Fast memotong MA Slow DARI ATAS KE BAWAH
   → Artinya: tren turun dimulai → saatnya SELL
   
   Sebelum: Fast 1.2510 ≥ Slow 1.2500
   Sesudah: Fast 1.2490 < Slow 1.2500  ← CROSSOVER!
```

### Mengapa pakai data bar 1 dan bar 2?
Untuk membandingkan **sebelum dan sesudah**. Bar 1 adalah candle yang baru selesai. Bar 2 adalah candle sebelumnya. Kalau di bar 2 Fast ≤ Slow, tapi di bar 1 Fast > Slow → crossover baru terjadi!

### Static variable `lastBar`:
`static` artinya nilai variabel ini **tidak hilang** setiap kali fungsi dipanggil. Ini dipakai supaya sinyal MA hanya dicek **sekali per candle baru** — tidak setiap tick (setiap pergerakan harga dalam candle yang sama).

### Cooldown 5 menit (300 detik):
Setelah basket close, bot tidak boleh langsung entry lagi. Kenapa? Karena setelah basket close, harga sering masih "chaotic." Cooldown memberi waktu pasar untuk stabil.

### Dampak ke akun user:
**Menentukan kapan bot mulai trading.** Ini adalah pelatuk (trigger) seluruh strategi. Tanpa sinyal MA, bot tidak akan pernah membuka posisi pertama. Tapi begitu crossover terjadi, seluruh mekanisme grid + martingale mulai berjalan.

---

## Blok 26 — CheckGeneralTP() — General TP (baris 584-603)

```mql4
void CheckGeneralTP() {
   if (GeneralTP <= 0) return;
   double pip = PipSize();

   if (G_BuyActive) {
      double avg = BasketAvgPrice("BUY");
      if (avg > 0 && (Bid - avg) / pip >= GeneralTP) BasketClose("BUY");
   }
   if (G_SellActive) {
      double avg = BasketAvgPrice("SELL");
      if (avg > 0 && (avg - Ask) / pip >= GeneralTP) BasketClose("SELL");
   }
}
```

### Apa yang dilakukan?
Memeriksa apakah basket sudah mencapai **target profit keseluruhan** (GeneralTP = 200 pips).

### Perhitungan:
- **BUY**: Jarak dari **harga rata-rata tertimbang** ke **Bid sekarang**. Kalau ≥ 200 pips → basket close.
- **SELL**: Jarak dari **Ask sekarang** ke **harga rata-rata tertimbang**. Kalau ≥ 200 pips → basket close.

### Kenapa pakai rata-rata tertimbang, bukan harga level 0?
Karena posisi di level yang berbeda punya lot berbeda. Contoh ekstrem: level 6 lot 1.14 lebih berpengaruh daripada level 0 lot 0.10. Rata-rata tertimbang mencerminkan harga impas (break-even) yang sebenarnya.

### Dampak ke akun user:
**Take profit otomatis.** Bedanya dengan trailing: GeneralTP adalah target tetap (fixed). Trailing adalah target mengambang (floating). Kalau harga bergerak cepat dan langsung mencapai 200 pips, GeneralTP yang akan menutup basket — bahkan sebelum trailing aktif.

---

## Blok 27 — CheckRisk() — RISK SHUTDOWN (baris 608-662)

```mql4
void CheckRisk() {
   double eq    = AccountEquity();
   double bal   = AccountBalance();
   double ddPct = (bal > 0) ? (bal - eq) / bal * 100 : 0;
   double mrgLv = (AccountMargin() > 0) ? (eq / AccountMargin()) * 100 : 0;

   // AUTO STOP: drawdown melebihi MaxDrawdown (15%)
   if (AutoStopTrading && ddPct >= MaxDrawdown) { G_Stopped = true; ... }

   // CLOSE ALL: drawdown kritis (90%)
   if (ddPct >= DrawdownCloseAll) { BasketClose(BUY); BasketClose(SELL); G_Stopped = true; }

   // CLOSE ALL: margin kritis (< 20%)
   if (mrgLv < MarginCloseAll) { BasketClose(BUY); BasketClose(SELL); G_Stopped = true; }

   // STOP TRADING: margin di bawah minimum (1000%)
   if (mrgLv < MinMarginLevel) { G_Stopped = true; }

   // STOP: profit harian tercapai (20%)
   if (dayPct >= DailyProfitPct) { G_Stopped = true; }

   // STOP: profit mingguan tercapai (20%)
   if (weekPct >= WeeklyProfitPct) { G_Stopped = true; }
}
```

### Apa yang dilakukan?
**Rem darurat multi-level.** Memeriksa kondisi akun dan mengambil tindakan sesuai tingkat keparahan.

### Level Bahaya:

```
Level 0 (AMAN) — Drawdown < 15%, Margin > 1000%
   └─ Bot trading normal

Level 1 (WASPADA) — Drawdown ≥ 15% ATAU Margin < 1000%
   └─ G_Stopped = true → tidak buka posisi baru
   └─ Posisi existing tetap dimonitor (bisa trailing close)

Level 2 (KRITIS) — Drawdown ≥ 90% ATAU Margin < 20%
   └─ BasketClose SEMUA posisi! (BUY + SELL)
   └─ G_Stopped = true → tidak bisa buka posisi baru
```

### Perhitungan Drawdown:
```
Drawdown% = (Balance - Equity) / Balance × 100%
```
Contoh: Balance $1000, Equity $850 (floating loss $150)
→ Drawdown = ($1000 - $850) / $1000 × 100% = 15% ← tepat di batas!

### Perhitungan Margin Level:
```
Margin Level% = Equity / Margin × 100%
```
Contoh: Equity $1000, Margin terpakai $200
→ Margin Level = $1000 / $200 × 100% = 500% ← masih aman

### Profit harian/mingguan:
Di-reset setiap hari/minggu baru oleh fungsi `CheckReset()`.

### Dampak ke akun user:
**INI YANG MENYELAMATKAN AKUN DARI KEBANGKRUTAN.** Bayangkan bot sudah buka 7 level grid, floating loss besar, lalu harga terus bergerak berlawanan. Tanpa risk shutdown, akun bisa MC (Margin Call) — semua uang habis. Dengan risk shutdown, bot tutup semua di batas yang masih bisa ditoleransi.

---

## Blok 28 — CheckReset() — Daily/Weekly Reset (baris 667-688)

```mql4
void CheckReset() {
   datetime today  = iTime(Symbol(), PERIOD_D1, 0);
   datetime thisWk = iTime(Symbol(), PERIOD_W1, 0);

   if (today != G_DayStart) {
      G_DayStart = today;
      G_DayEquity = AccountEquity();
      if (G_StopReason != STOP_DRAWDOWN) {
         G_Stopped = false;
         G_StopReason = STOP_NONE;
      }
   }

   if (thisWk != G_WeekStart) {
      G_WeekStart = thisWk;
      G_WeekEquity = AccountEquity();
      if (G_StopReason == STOP_PROFIT) {
         G_Stopped = false;
         G_StopReason = STOP_NONE;
      }
   }
}
```

### Apa yang dilakukan?
**Kalender otomatis bot.** Setiap hari/minggu baru, bot:
1. Mencatat equity awal (sebagai patokan profit harian/mingguan)
2. Me-reset status stopped (kecuali stopped karena drawdown — itu serius, tidak bisa reset otomatis)

### Kenapa STOP_DRAWDOWN tidak di-reset?
Drawdown artinya akun sedang dalam bahaya serius. Reset harian tidak boleh menghidupkan bot lagi kalau akun masih sekarat. Harus tunggu minggu baru atau intervensi manual.

### Kenapa STOP_PROFIT di-reset mingguan?
Profit target tercapai di minggu lalu → minggu baru, target baru. Bot boleh trading lagi.

### Dampak ke akun user:
**Otomatisasi jadwal.** Tanpa ini, kamu harus manual reset bot setiap hari. Dengan CheckReset, profit target harian di-reset otomatis jam 00:00 setiap hari.

---

## Blok 29 — OnInit() / OnDeinit() / OnTick() (baris 693-735)

```mql4
int OnInit() {
   G_Magic = MagicNumber;
   G_StartMin = StrToMinutes(StartTime);
   // ... inisialisasi semua variabel global ...
   Print("Apex Grid EA initialized.");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   Print("Apex Grid EA deinitialized.");
}

void OnTick() {
   CheckReset();

   // RISK & EXIT (selalu jalan, bahkan saat stopped)
   ManagePendingOrders();
   CheckRisk();
   CheckTrailing();
   CheckGeneralTP();

   // ENTRY & GRID (hanya saat trading allowed & tidak stopped)
   if (!IsTradingAllowed() || G_Stopped) return;

   CheckMA();          // Layer 1: Sinyal entry
   CheckGridLevels();  // Layer 2: Grid management
}
```

### Apa yang dilakukan?

**OnInit()** — Dipanggil **sekali** saat EA di-attach ke chart.
- Menginisialisasi semua variabel global
- Mencatat equity awal harian dan mingguan
- Print log ke Experts tab: "Apex Grid EA initialized."

**OnDeinit()** — Dipanggil **sekali** saat EA di-remove dari chart.
- Hanya print log. Tidak menutup posisi (itu keputusan user).

**OnTick()** — Dipanggil **SETIAP KALI** harga bergerak (setiap tick).
- Ini adalah **main loop** bot. Setiap tick:
  1. `CheckReset()` — reset kalau hari/minggu baru
  2. `ManagePendingOrders()` — gap-fill pending order
  3. `CheckRisk()` — periksa kondisi darurat
  4. `CheckTrailing()` — trailing stop
  5. `CheckGeneralTP()` — target profit
  6. **JIKA trading allowed & tidak stopped:**
     - `CheckMA()` — cek sinyal entry baru
     - `CheckGridLevels()` — cek perlu buka level baru

### Kenapa Risk & Exit selalu jalan, tapi Entry hanya saat allowed?
Karena **posisi yang sudah terbuka tetap harus dikelola**, bahkan di luar jam trading. Kalau pasar bergerak 300 pips di jam 23:00 (di luar jam trading), trailing tetap harus bisa nutup posisi — kamu tidak mau posisi mengambang tidak terpantau.

Tapi **entry baru hanya boleh di jam trading** — tidak ada posisi baru yang dibuka di luar jam yang ditentukan.

### Dampak ke akun user:
OnTick adalah **jantung yang berdetak** — setiap tick (bisa ratusan kali per menit di M1), bot menjalankan seluruh logika trading. Urutan pemanggilan fungsi menentukan prioritas: **keamanan dulu (risk), baru cari peluang (entry).**

---

## Rangkuman: Bagaimana Semua Blok Bekerja Bersama

Bayangkan bot ini sebagai **robot pabrik** yang bekerja dalam siklus:

```
SETIAP TICK (pergerakan harga):
│
├─ CEK KALENDER ──────────────────────────────────────┐
│  "Apakah sudah hari/minggu baru?"                     │
│  Kalau ya → reset target profit                       │
│                                                       │
├─ MONITOR POSISI EXISTING ────────────────────────────┤
│  • Gap-fill: "Ada pending order yang terlewat?"       │
│  • Trailing: "Profit sudah turun dari puncak?"         │
│  • GeneralTP: "Sudah profit 200 pips?"                │
│  • Risk check: "Drawdown/margin masih aman?"          │
│                                                       │
├─ APAKAH BOLEH ENTRY? ────────────────────────────────┤
│  "Jam trading? Bukan weekend? Tidak stopped?"         │
│  │                                                    │
│  ├─ YA → Cek sinyal + grid                            │
│  │   • MA Crossover? → Buka grid baru                 │
│  │   • Harga sudah menjauh GridStep? → Tambah level   │
│  │                                                    │
│  └─ TIDAK → Kembali ke atas, tunggu tick berikutnya   │
│                                                       │
└─ TUNGGU TICK BERIKUTNYA ─────────────────────────────┘
```

---

## Tips Membaca Kode MQL4 untuk Pemula

1. **Fungsi selalu diawali tipe data** (void, int, double, bool, string)
2. **Loop = for()** untuk mengulangi aksi ke semua order
3. **OrderSelect()** = "pilih order nomor X, biar bisa dibaca datanya"
4. **continue** = "skip, lanjut ke order berikutnya"
5. **MarketInfo()** = tanya ke broker tentang aturan mereka
6. **Print()** = tulis ke log (tidak terlihat di chart, tapi terlihat di tab Experts)
7. **static** = variabel yang nilainya "diingat" di antara panggilan fungsi

---

*Dokumen dibuat: 11 Juni 2026*
*Untuk pertanyaan, buka issue di: github.com/codecat92/apex-grid-ea*
