# News Filter Setup Guide

## Overview

News Filter mencegah bot entry saat rilis berita ekonomi penting. Semua dilakukan **di dalam EA** — tidak perlu aplikasi terpisah.

## Sumber Data

Data diambil langsung dari **nfs.faireconomy.media** (Fair Economy, Inc. — perusahaan induk ForexFactory).
EA menggunakan fungsi `WebRequest()` untuk fetch JSON calendar via internet.
Format ISO 8601 dengan timezone offset, akurat, tanpa API key.

## Setup (1x saja)

### Step 1: Izinkan akses internet di MT4

```
MT4 → Tools → Options → Expert Advisors → Allow WebRequest for listed URL:
    → Tambah: https://nfs.faireconomy.media
```

![Checkbox harus dicentang, URL harus terdaftar]

### Step 2: Aktifkan News Filter di parameter EA

Buka parameter ApexGrid di chart:
- `NewsFilter` = `true`

**Selesai.** EA langsung fetch data setiap 15 menit. Tidak ada instalasi tambahan.

## Parameter EA

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `NewsFilter` | `false` | Aktifkan/tidak news filter |
| `NewsMinutesBefore` | `30` | Menit sebelum news rilis, bot tidak entry |
| `NewsMinutesAfter` | `60` | Menit setelah news rilis, bot tidak entry |
| `NewsRefreshMin` | `15` | Interval fetch ulang data (menit) |
| `NewsCurrencies` | `"USD,EUR,GBP,..."` | Mata uang yang dimonitor (koma, tanpa spasi) |
| `NewsTimezoneOffset` | `0` | Offset broker time dari UTC (GMT+2 → `2`, EST → `-5`) |

### Menentukan NewsTimezoneOffset

| Broker | Offset |
|--------|--------|
| JDR Securities (GMT+2) | `2` |
| London (GMT+0) | `0` |
| NY (EST = UTC-5) | `-5` |
| Tokyo (GMT+9) | `9` |

Cek server time: MT4 → Market Watch → bandingkan dengan waktu UTC saat ini.

## Cara Kerja

1. EA panggil `WebRequest()` ke `nfs.faireconomy.media` setiap 15 menit
2. Terima JSON → parse event, filter currency yang dipilih
3. Hitung blackout window untuk setiap event: `[event_time - MinutesBefore, event_time + MinutesAfter]`
4. Jika waktu broker masuk window manapun → `IsTradingAllowed()` return false
5. EA tidak buka posisi baru, tapi tetap manage posisi existing

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| EA log: "WebRequest failed" | Pastikan URL sudah terdaftar di Allow WebRequest |
| EA log: "HTTP 429" | Rate limit API — EA akan retry otomatis di tick berikutnya |
| EA log: "0 events in range" | Normal — tidak ada event yang match filter hari ini |
| Internet server putus | EA tetap trading normal tanpa filter (fail-open) |

## Arsitektur Fail-Open

| Skenario | Perilaku |
|----------|---------|
| WebRequest gagal (no internet) | Trading normal |
| API return error (429/500) | Trading normal |
| JSON format berubah | Parse fail → Trading normal |
| Currency filter tidak match event apapun | Tidak ada blackout → Trading normal |
| NewsFilter = false | Fitur dimatikan, tidak ada fetch |

**Akun tidak pernah berhenti trading karena masalah teknis news filter.**
