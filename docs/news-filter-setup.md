# News Filter Setup Guide

## Overview

News Filter adalah fitur opsional yang mencegah bot entry posisi baru saat ada rilis berita ekonomi penting. Ini melindungi akun dari volatilitas ekstrim saat major news events.

## Komponen

| Komponen | File | Fungsi |
|----------|------|--------|
| **News Fetcher** | `src/tools/news_fetcher.py` | Scrape Forexfactory calendar → output `news_cache.txt` |
| **MQL4 Parser** | `src/experts/ApexGrid.mq4` (`FetchNewsFromFile()`) | Baca file, parse blackout windows |
| **MQL4 Filter** | `src/experts/ApexGrid.mq4` (`IsNewsBlackout()`) | Blokir entry jika dalam blackout window |

## Setup di Windows Server

### Opsi A: Python Script (recommended untuk development)

1. **Install Python 3.10+** di server
2. **Install dependencies:**
   ```cmd
   pip install requests beautifulsoup4 cloudscraper
   ```
3. **Test manual:**
   ```cmd
   python news_fetcher.py --output "C:\Users\...\AppData\Roaming\MetaQuotes\Terminal\<id>\MQL4\Files\news_cache.json" --currencies "USD,EUR,GBP"
   ```
4. **Create Windows Scheduled Task:**
   ```
   Task Name: ApexGridNewsFetcher
   Trigger: At startup, repeat every 15 minutes
   Action: Start a program
     Program: python
     Arguments: C:\path\to\news_fetcher.py --output "C:\...\MQL4\Files\news_cache.json" --currencies "USD,EUR,GBP,CHF,CAD,AUD,NZD,JPY"
   ```
   Path output HARUS mengarah ke folder `MQL4/Files/` terminal MT4.

### Opsi B: Executable (.exe) — untuk server tanpa Python

1. **Build exe di mesin development:**
   ```cmd
   pip install pyinstaller
   pyinstaller --onefile --name news_fetcher news_fetcher.py
   ```
2. **Copy `dist/news_fetcher.exe` ke server**
3. **Create Windows Scheduled Task:**
   ```
   Program: C:\path\to\news_fetcher.exe
   Arguments: --output "C:\...\MQL4\Files\news_cache.json" --currencies "USD,EUR,GBP,CHF,CAD,AUD,NZD,JPY"
   ```

## Konfigurasi di MT4

### Parameter EA (extern)

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `NewsFilter` | `false` | Aktifkan/tidak news filter |
| `NewsMinutesBefore` | `30` | Menit sebelum news rilis, bot tidak entry |
| `NewsMinutesAfter` | `60` | Menit setelah news rilis, bot tidak entry |
| `NewsRefreshMin` | `15` | Interval refresh baca file (menit) |
| `NewsCurrencies` | `"USD,EUR,GBP,..."` | Mata uang yang dimonitor, pisahkan dengan koma |
| `NewsTimezoneOffset` | `"0"` | Offset broker time dari UTC (contoh: GMT+2 → `2`, NY EST → `-5`) |

### Setting NewsTimezoneOffset

Ketik di MT4: **File → Open Data Folder → log** cari log yang menunjukkan server time.
Atau lihat di **Market Watch**, bandingkan dengan UTC sekarang.

| Broker | Offset |
|--------|--------|
| JDR Securities (GMT+2) | `2` |
| NY Close (EST) | `-5` |
| London (GMT) | `0` |
| Tokyo (GMT+9) | `9` |

## Cara Kerja

1. **Windows Scheduler** menjalankan `news_fetcher.py` setiap 15 menit
2. Script scrape ForexFactory, filter currency yang dipilih, tulis ke `news_cache.txt`
3. Format output (pipe-delimited):
   ```
   2026-06-23T14:00:00Z|USD|High
   2026-06-23T16:30:00Z|GBP|Medium
   ```
4. **ApexGrid EA** setiap tick baca file (jika `NewsRefreshMin` sudah lewat)
5. EA hitung blackout window: `[event_utc + offset - MinutesBefore, event_utc + offset + MinutesAfter]`
6. Jika `TimeCurrent()` masuk window manapun → `IsTradingAllowed()` return false
7. **EA tidak membuka posisi baru**, tapi tetap manage posisi existing (trailing, risk check tetap jalan)

## Troubleshooting

### File tidak ditemukan
- Pastikan output path mengarah ke folder `MQL4/Files/` terminal MT4
- Di MT4 log: `Apex Grid News: file not found, clearing cache`
- EA tetap trading normal tanpa filter (fail-open)

### Data tidak match
- Cek apakah `NewsTimezoneOffset` sudah benar
- Cek `NewsCurrencies` — pastikan tidak ada spasi (pakai koma tanpa spasi)
- Cek log Python: `news_fetcher.log`

### ForexFactory berubah struktur
- Hanya perlu update `news_fetcher.py` (script Python), EA tidak perlu diupdate
- Sumber fallback sudah disiapkan (JSON proxy → HTML scrape)
- Selama Python belum diupdate, EA tetap trading normal

## Arsitektur Fail-Open

Seluruh desain News Filter mengikuti prinsip **fail-open**:

| Skenario | Perilaku |
|----------|---------|
| File `news_cache.txt` tidak ada | Trading normal |
| File corrupt / parse error | Trading normal |
| Semua source scraping gagal | File kosong → Trading normal |
| Currency filter tidak match event apapun | Tidak ada blackout → Trading normal |
| NewsFilter = false | Fitur dimatikan, tidak fetch |

**Akun tidak pernah berhenti trading karena masalah teknis news filter.**
