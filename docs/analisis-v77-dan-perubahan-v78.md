# Analisis BioOnePro v77 "Apex Unleashed" dan perubahan v78

Sumber data:
- Kode: `ea/BioOnePro_Optimized_v77_Apex_Unleashed.mq4`
- Backtest: `backtests/v77_XAUUSD_M1_2025-09_2026-09.htm` (IC Markets, XAUUSD M1, Every tick,
  29 Sep 2025 – 25 Sep 2026, deposit $500, spread tetap 20 point)

Catatan satuan: XAUUSD di server ini memakai 3 digit (contoh harga 3813.305), jadi
**1 "pip" EA = $0.01 harga emas**. Contoh: `Grid_Pipstep=1500` berarti $15, dan `TP=10000` berarti $100.
Satu lot = 100 oz, sehingga 1 lot × $1 pergerakan = $100.

---

## 1. Cara kerja EA

### a. Entry L1 (dicek sekali per bar M1)
1. **Rezim tren H1**: EMA50 > EMA200, close > EMA50, dan EMA50 naik → bullish (kebalikannya bearish).
   Kalau tidak ada tren, tidak ada entry, karena `Use_Trend_Directional_Entry=true`.
2. **Pullback searah tren di M1**:
   - BUY: candle bullish, Low menyentuh BB-mid atau BB-lower (atau ada sinyal S/R+BB), close di bawah BB-upper, dan RSI ≤ 68.
   - SELL: kebalikannya.
3. **Filter tambahan**:
   - Stochastic (5,3,2) cross dengan level 35/65.
   - MACD searah posisi.
   - ADX < 32, atau ADX ≥ 32 tetapi DI searah posisi.
   - Jam 03–24 dan bukan jam rollover 23–00.
   - Bukan Jumat ≥ 12:00.
   - Minimal 2 jam sejak close searah terakhir, plus filter RSI-M15 "exhausted".
   - Candle M1 ≤ $2.
   - Spread dan margin masih dalam batas.
4. `Dual_Mode=true`: basket BUY dan SELL bisa terbuka bersamaan.

### b. Exit L1 (satu posisi saja)
- TP $100 praktis tidak pernah kena. Exit sebenarnya selalu lewat SL yang digeser (`s/l`).
- **Trailing**: aktif setelah profit $4, lalu SL mengikuti $4 di belakang harga dengan step $1.5.
- **Stochastic M5 (21,3,3)**: di zona OB/OS, trailing dirapatkan jadi $1.5. Saat stochastic keluar
  dari zona itu, trailing jadi $0.20, sehingga posisi praktis langsung ditutup.
- **Breakeven lock**: setelah profit $15, SL dikunci di +$3.

### c. Averaging (grid martingale)
- **Jarak layer** (mode statis) = $15 × 1.3^(n-1): L2 di −$15, L3 −$34.5, L4 −$59.9, L5 −$92.8, L6 −$135.7, L7 −$191.3.
- **Lot layer**: L2 = 1.6× L1, lalu tiap layer ×1.7 (L3 2.72×, L4 4.62×, L5 7.86×, L6 13.4×, L7 22.7×).
  Mulai L3, lot "adaptif" bisa berada di 0.5–1.35× nilai statis.
- **Syarat tambahan**:
  - L2 ke atas butuh candle konfirmasi (bullish untuk BUY, bearish untuk SELL).
  - L4 ke atas harus menunggu minimal 120 menit.
  - Maksimal 7 layer.
- **Hedge Guard**: saat L4 terbuka, EA membuka posisi berlawanan dengan lot yang sama.
- **Escape Guard**: aktif mulai L4.

### d. Exit basket (2 layer atau lebih)
- **Target net**: $6 (L2), $9 (L3), $15 (L4+), dikali skala lot, plus trailing $0.5.
  Pada hari Jumat, target dipotong 50%.
- **Stochastic M5**: basket ditutup bila net ≥ $1 × skala lot dan stochastic berbalik dari OB/OS.

### e. Proteksi akun
- **Cut-loss floating total** di `Percent_Loss=50%` dari balance. Sesudah itu EA **lanjut trading**,
  karena `Stop_After_Account_Loss=false`.
- **Tutup semua posisi** Jumat pukul 19:00.
- **Lot auto-compounding**: 0.01 lot per $400 balance (`Lot_Base_Balance_Safe=400`).

---

## 2. Hasil backtest v77

| Metrik | Nilai |
|---|---|
| Net profit | **$36,259.95** (dari $500 → $36,759.95) |
| Profit factor | 3.29 |
| Total trade | 510 (win 84.7%) |
| Max drawdown (equity) | **$10,388 (43.48%)** |
| Relative drawdown | **47.19%** ($2,570) |

Saya menyusun ulang order-order di laporan menjadi 429 siklus basket:

| Kedalaman | Jumlah basket | Menang | Total profit | Rata-rata |
|---|---|---|---|---|
| L1 saja | 360 | 360 | $28,801.68 | $80.00 |
| L2 | 57 | 57 | $6,628.80 | $116.29 |
| L3 | 12 | 12 | $829.48 | $69.12 |
| L4–L7 | 0 | – | – | – |

- Semua basket ditutup dengan profit. "Loss trade" di laporan hanyalah layer L1 yang ditutup rugi di dalam basket yang secara total profit.
- Basket **tidak pernah** mencapai L4, sehingga Hedge Guard, Escape Guard, dan L4–L7 **belum pernah diuji**.
- Sekitar 79% profit datang dari L1. Pertumbuhan bulanan +20% sampai +85% sebagian besar berasal dari compounding lot.

---

## 3. Temuan risiko (paling penting)

### 3.1 Dua kali nyaris terkena cut-loss 50%
- **1 Mei 2026**: basket BUY L3 (0.13 / 0.21 / 0.32 lot di 4621 / 4604 / 4584).
  Relative drawdown mencapai **47.19%**, hanya ~3 poin persen dari batas 50%.
  Menurut estimasi saya, harga emas cuma perlu turun sekitar $2 lagi.
- **19–20 Agustus 2026**: basket BUY L3 (0.59 / 0.94 / 1.13 lot) dengan drawdown **43.48% ($10,388)**.
  Harga perlu turun kira-kira $6 lagi untuk menyentuh 50% (≈ $12,000).

Kalau salah satu dari dua kejadian itu berlanjut sedikit saja, EA akan menutup rugi ~50% balance.
Setelah itu EA tetap lanjut trading dengan lot yang sudah dihitung ulang dari balance yang tersisa setengah.

### 3.2 Layer L4–L7 sebenarnya tidak bisa tercapai
Dengan 0.01 lot per $400, rugi grid mencapai 50% balance ketika harga bergerak **±$60 melawan L1**.
Itu tepat di level L4 (−$59.9). Jadi `Max_Buy_Layers=7` hanya ada di atas kertas:
cut-loss 50% hampir selalu terpicu sebelum L4 bisa membantu.

Pergerakan emas $60 dalam satu hari bukan kejadian langka di harga $4,000+.
Periode uji satu tahun ini kebetulan tidak memuat pergerakan seperti itu melawan posisi yang terbuka.

Hubungan jarak bertahan dengan ukuran lot (model grid statis, 7 layer, batas 50%):

| `Lot_Base_Balance_Safe` | Cut-loss 50% terpicu pada gerakan melawan L1 |
|---|---|
| 400 (sekarang) | ~$60 |
| 600 | ~$70 |
| 800 | ~$80 |
| 1200 | ~$97 |
| 2000 | ~$119 |

Karena martingale, setiap tambahan jarak bertahan membutuhkan pengurangan lot yang tajam:
- bertahan $80 → lot ~50% dari sekarang,
- bertahan $100 → lot ~30%,
- bertahan $120 → lot ~20%.

### 3.3 Biaya transaksi terlalu optimistis
- Spread tester tetap 20 point = **$0.02**, dan tidak ada komisi (profit tiap order sama persis dengan
  pergerakan harga). Spread XAUUSD live umumnya beberapa kali lebih lebar, apalagi saat rilis berita
  dan rollover. Akun Raw juga dikenai komisi per lot.
- 69 dari 360 trade L1 (19%) hanya mendapat < $0.25 per oz. Kebanyakan berasal dari kuncian trailing
  $0.20 milik Stochastic. Di akun live, trade-trade ini cenderung menjadi rugi kecil.
- Tambahan biaya $0.08–$0.25 per oz pada volume 118 lot kira-kira setara $0.9k–$3k.
  Efek compounding membuat dampak sebenarnya lebih besar.
- Trailing $0.20 di data M1 yang diinterpolasi (modelling quality "n/a") juga bisa lebih indah daripada eksekusi nyata.

### 3.4 Bug di kode v77
1. **Order Hedge (Magic+777) tidak ikut dikelola proteksi akun.**
   `closeallpair()`, `IsManagedOrderBookFlat()`, dan `GetManagedOpenNetProfit()` hanya mengenali `Magic`. Akibatnya:
   - cut-loss 50% tidak menghitung P/L hedge,
   - close-all (target, stop, dan tombol) tidak menutup hedge,
   - di tester, weekend close Jumat 19:00 bisa meninggalkan hedge terbuka sampai Senin.
     Di sini `hitung()` tidak pernah dipanggil selama jendela weekend dan timer dimatikan.
2. **Hedge dikirim dengan `OrderSend` langsung**, tanpa normalisasi lot, cek margin, retry, maupun log error.
3. **Lot averaging adaptif dihitung di setiap tick** selama basket berisi 2 layer atau lebih, padahal jarak grid belum tercapai.
   Fungsi ini memindai 336 bar H1 dengan `iFractals`, sehingga backtest jadi lambat. Hasil perhitungannya
   hanya dipakai ketika layer benar-benar dibuka.
4. **Ukuran pip tidak seragam**: tiga fungsi menghitung ulang `Point*10` sendiri sehingga mengabaikan `Pip_Unit_Override`.

---

## 4. Perubahan di v78 (`ea/BioOnePro_Optimized_v78_Apex_Guarded.mq4`)

**Dengan semua input baru di nilai default, sinyal, lot, dan exit tetap identik dengan v77.**
Perbedaannya hanya muncul ketika hedge terbuka (L4+), yaitu bug fix nomor 1–2.

| # | Perubahan | Efek |
|---|---|---|
| 1 | Helper `IsEAMagic()`: hedge ikut dihitung di cut-loss akun, close-all, dan weekend close | Tidak ada lagi hedge "yatim" |
| 2 | `OpenHedgeOrder()` lewat `OPE()` dengan lot `NR()`, cek margin, retry, dan log. Filter spread tidak diterapkan karena ini proteksi | Hedge lebih andal |
| 3 | Lot adaptif dihitung hanya saat layer akan dibuka | Backtest lebih cepat, hasil sama |
| 4 | Semua ukuran pip memakai `pt` | Konsisten dengan `Pip_Unit_Override` |
| 5 | **Grid Risk Report** di tab Journal saat start, plus baris "Cut-loss grid" di panel chart | Anda langsung tahu di jarak berapa akun kena cut-loss |
| 6 | Input `Survive_Adverse_Move_Pips` (0 = off) | Lot L1 otomatis dikecilkan supaya cut-loss tidak kena sebelum gerakan X |
| 7 | Input `Max_L1_Lot` (0 = off) | Batas atas lot hasil compounding |
| 8 | Input `Commission_Per_Lot_RoundTurn` dan `Min_L1_Lock_Pips` (0 = off) | Trailing L1 tidak mengunci profit di bawah biaya |

Contoh Grid Risk Report untuk deposit $500:

```
L1 | jarak dari L1=0 pips (0.00) | lot~0.01 | total lot~0.01 | rugi saat harga di 1500 pips = ...
L2 | jarak dari L1=1500 pips (15.00) | lot~0.02 | ...
...
CUT-LOSS 50.0% tercapai bila harga bergerak ~6xxx pips (6x.xx harga) melawan L1. ...
```

---

## 5. Rekomendasi pengujian

1. **Kompilasi** v78 di MetaEditor, lalu jalankan backtest yang sama dengan setting default.
   Hasilnya seharusnya sama dengan v77. Kalau berbeda, laporkan ke saya. Saya tidak bisa mengompilasi MQL4 di lingkungan ini.
2. **Uji dengan biaya yang realistis**: naikkan spread tester (misalnya 100–300 point, yaitu $0.10–$0.30),
   lalu isi `Commission_Per_Lot_RoundTurn` sesuai akun Anda dan `Min_L1_Lock_Pips=10`.
3. **Pilih level risiko** dengan membandingkan satu per satu:
   - `Survive_Adverse_Move_Pips=8000` (bertahan $80, lot ~50%).
     Perkiraan kasar: drawdown maksimum sekitar separuhnya, profit akhir turun ke kisaran ribuan dolar, bukan puluhan ribu.
   - `Survive_Adverse_Move_Pips=10000` (bertahan $100, lot ~30%).
   - Atau cukup naikkan `Lot_Base_Balance_Safe` ke 800–1200.
4. **Uji periode lain** yang lebih ekstrem, misalnya Maret 2020, 2022, dan April 2025.
   Satu tahun data tanpa satu pun basket L4 belum membuktikan ketahanan grid.
5. Untuk akun live, pertimbangkan `Stop_After_Account_Loss=true`. Dengan begitu EA berhenti setelah cut-loss
   besar dan tidak langsung lanjut dengan lot baru.
