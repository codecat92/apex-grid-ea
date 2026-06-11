# Apex Grid EA — Strategy

## Overview

Apex Grid EA menerapkan strategi **Grid + Martingale** yang terinspirasi dari Yetti Classic v3.03_fix. Bot membuka posisi berlapis (grid) dengan lot progresif (martingale) dan menutup semua posisi sekaligus (basket close) ketika trailing stop terpicu.

## 5 Layer Arsitektur

### Layer 1 — Entry Signal (MA Crossover)
- **Golden Cross** (MA5 memotong MA40 ke atas) → memulai **BUY grid**
- **Death Cross** (MA5 memotong MA40 ke bawah) → memulai **SELL grid**
- BUY dan SELL grid bisa aktif bersamaan
- Menggunakan SMA period 5 dan 40 pada harga Close

### Layer 2 — Grid Manager
- Setiap level grid dibuka saat harga bergerak **GridStep (250 pips)** dari entry sebelumnya
- Lot setiap level: `StartLot × Multiplier^level`
- Progresi lot: 0.10 → 0.15 → 0.23 → 0.34 → 0.51 → 0.76 → 1.14
- Setiap level membuka **OrdersPerStep (2)** order

### Layer 3 — Exit Manager (Basket Close)
- Tidak ada SL/TP per posisi (SL=0, TP=0)
- Trailing stop aktif setelah harga bergerak **TriggerDistance (160 pips)** dari entry pertama
- Setelah trailing aktif, bot melacak harga terbaik (highest untuk BUY, lowest untuk SELL)
- Jika harga pullback **FixedDistance (50 pips)** dari harga terbaik → **semua posisi searah ditutup**
- Setelah basket close → reset dan tunggu sinyal MA baru

### Layer 4 — Time Filter
- Trading hanya aktif di jam **01:00 – 22:00**
- Jumat: berhenti di **14:00** untuk hindari gap weekend
- Extra window: **01:06 – 01:07** dengan grid step lebih kecil (100 pips)

### Layer 5 — Risk Shutdown
- Daily profit target 20% → stop trading
- Weekly profit target 20% → stop trading
- Drawdown > 90% → close all positions
- Margin level < 1000% → close all positions
- Drawdown > 15% → auto stop trading

## Trading Cycle

```
1. MA Crossover → mulai BUY/SELL grid
2. Level 0 dibuka di harga pasar
3. Harga bergerak ~250 pips berlawanan → Level 1
4. Harga bergerak ~250 pips lagi → Level 2 (dst)
5. Harga berbalik menguntungkan
6. Trailing stop aktif setelah 160 pips
7. Pullback 50 pips → basket close semua posisi
8. Reset, tunggu sinyal MA berikutnya
```

## Lot Calculation

Formula: `Lot = StartLot × Multiplier^Level`

| Level | Multiplier^Level | Lot  |
|-------|-----------------|------|
| 0     | 1.5^0 = 1.00   | 0.10 |
| 1     | 1.5^1 = 1.50   | 0.15 |
| 2     | 1.5^2 = 2.25   | 0.23 |
| 3     | 1.5^3 = 3.38   | 0.34 |
| 4     | 1.5^4 = 5.06   | 0.51 |
| 5     | 1.5^5 = 7.59   | 0.76 |
| 6     | 1.5^6 = 11.39  | 1.14 |
