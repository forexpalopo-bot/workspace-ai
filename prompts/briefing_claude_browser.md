# BRIEFING RISET QUANTITATIVE & PENGEMBANGAN EA BioOnePro (v93 -> v94)
**Dokumen Pengantar & Laporan Hasil Backtest Penuh untuk Kolaborasi dengan Claude (Sonnet / Best Model)**
**Disiapkan oleh**: Antigravity Assistant  
**Tanggal**: 2 Oktober 2026  
**Repositori**: `C:\Penelitian_EA\BioOnePro\repo` (Branch: `claude/cek-xb7zbt`)

---

### PANDUAN PENGGUNAAN CHAT INI:
> **Kepada Claude**: Anda sedang berkolaborasi dengan Antigravity (AI Coding & Backtest Execution Assistant) dan Trader/Pengembang dalam penelitian optimasi Expert Advisor institusional **BioOnePro** untuk pair **XAUUSD (Gold)** di MetaTrader 4 (broker IC Markets Raw Spread, deposit \$3000).  
> **Target Model**: Pastikan obrolan ini dijalankan dengan **Claude 3.5 / 3.7 Sonnet (Thinking / Extra Depth Mode)** atau model terkuat yang tersedia untuk analisis kuantitatif mendalam.  
> Bacalah seluruh kronologi, temuan empiris, data backtest 6.5 tahun, dan bedah kerugian di bawah ini untuk merumuskan arsitektur sistem pencegah loss besar (*Big Loss Guard*) generasi berikutnya.

---

## 1. LATAR BELAKANG & TUJUAN PENELITIAN
Penelitian ini bertujuan mengembangkan EA trading otomatis untuk XAUUSD berbasis kombinasi strategi:
1. **Entry L1**: Trend-following pullback berbasis Support/Resistance, Bollinger Bands, MACD, dan ADX.
2. **Manajemen Layer (L2–L5)**: Dynamic Adaptive Averaging ("Sniper"), di mana jarak layer dihitung secara dinamis dari persentil swing H1 (*learning lookback* 40 hari, L2=P50, L3=P70, L4=P85, L5=P93, SL=P98).
3. **Exit Basket**: Target net profit dollar (\$6–\$15) + Stochastic M5 / ATR Trailing Stop basket.
4. **Proteksi Kerugian**:
   - Anggaran risiko basket (*risk budget* 8% balance).
   - *Friday Cutoff* (tidak ada L1 hari Jumat) & *Friday 19:00 Close*.
   - *H4 Close Confirmation* dengan *Hard Multiplier 1.3x* untuk SL (v93 VH1).
   - Jam aturan GMT (*Rule_Time_Mode=1*) sinkron dengan Strategy Tester MT4.

### Pembelajaran dari Putaran 1 s/d 24:
- **v77 (Martingale Buta)**: Bangkrut total pada tren kuat 2024 (drawdown 99.7%).
- **v82 (Adaptive Sniper)**: Terobosan pertama di 2024. Jarak layer melebar mengikuti volatilitas pasar, mengubah kebangkrutan menjadi drawdown terkendali.
- **v83 (Jarak Bernapas Volatilitas)**: Mengalikan jarak layer dengan rasio ATR H1 saat ini vs jangka panjang (0.8x–2.0x).
- **Putaran 23 (Filter Berita)**: DITOLAK KERAS karena memblokir entry saat lonjakan berita justru memangkas profit pembalikan momentum (profit 2022 anjlok 35%).
- **Putaran 24 (Uji Paritas & Data Hole)**: Ditemukan bahwa data history MT4 untuk timeframe M15/M30/H1/H4/D1 memiliki lubang data 5 bulan (Maret–Agustus 2025). Seluruh timeframe telah berhasil dibangun ulang (*rebuilt*) dari 2.352.835 bar M1 murni tanpa ada celah (`celah>4hari=0`).

---

## 2. HASIL BACKTEST PENUH SELURUH HISTORY (6 TAHUN 7 BULAN)
**Rentang**: 15 Februari 2020 s/d 25 September 2026 (Rentang kontinu penuh)  
**Deposit Awal**: \$3,000.00 | **Spread**: 20 points (\$0.20 XAUUSD, 2-digit feed) | **Error Data**: 0

| Metrik Kinerja | FA (Control Points, H4 Confirm) | FB (Control Points, Intrabar SL) | FAT (Every Tick, H4 Confirm) | FBT (Every Tick, Intrabar SL) |
|---|---|---|---|---|
| **Total Net Profit** | **+$1,232.41 (+41.1%)** | +$293.12 (+9.8%) | **+$856.28 (+28.5%)** | +$406.36 (+13.5%) |
| **Profit Factor** | **1.07** | 1.02 | **1.05** | 1.02 |
| **Maximal Drawdown ($)** | **$888.28** | $1,314.74 | **$1,208.20** | $1,546.45 |
| **Maximal Drawdown (%)** | **28.37%** | 38.18% | **32.57%** | 41.65% |
| **Total Closed Orders** | 3,922 | 3,901 | 3,954 | 3,939 |
| **Total Baskets** | 3,247 | 3,256 | 3,259 | 3,273 |
| **Jumlah Kejadian SL** | **23 kali** | 37 kali | **24 kali** | 36 kali |
| **Modelling Quality** | N/A (Model 1) | N/A (Model 1) | 25.00% (313.8M ticks) | 25.00% (313.8M ticks) |
| **Mismatched Errors** | 0 | 0 | 0 | 0 |
| **Status Adaptif Swing** | Aktif dinamis (legs 107–151, SL 3,290–15,668 pips, 0 legs < 5) | Aktif dinamis | Aktif dinamis | Aktif dinamis |

### Rincian Profit & Frekuensi SL per Tahun (FAT Every Tick):
- **2020**: Profit +$161.62 | SL: 3 kali
- **2021**: Profit +$4.82 | SL: 5 kali *(Reli yield US 10Y, emas jatuh $1959 -> $1676)*
- **2022**: Profit +$45.63 | SL: 5 kali *(Siklus agresif kenaikan suku bunga Fed)*
- **2023**: Profit +$31.32 | SL: 4 kali *(Krisis SVB Maret & lonjakan OPEC+ April)*
- **2024**: Profit **-$338.99** | SL: 6 kali *(Reli All-Time-High emas dari $2050 ke $2700+)*
- **2025**: Profit +$158.69 | SL: 1 kali
- **2026 (s/d Sep)**: Profit +$793.32 | SL: 0 kali
- **TOTAL**: **Net +$856.28 | SL: 24 kali**

---

## 3. PARADOKS UTAMA & BEDAH BEDAH KERUGIAN TERBESAR (THE ASYMMETRY PROBLEM)

### Paradoks Statistik:
- Dari **3,259 basket** yang dieksekusi di `FAT_FULL`, sebanyak **3,235 basket MENANG (Win Rate = 99.26%)**!
- Hanya **24 basket yang terkena SL (0.74%)**.
- **Namun kerugian kotor dari 24 basket SL tersebut mencapai -$7,500+**, yang memangkas keuntungan kotor basket menang (\$8,300+) menjadi hanya net **+$856.28**!
- Ketika 4–6 SL terjadi beruntun dalam satu tahun (seperti di 2021 dan 2024), drawdown mencapai **28%–32%** dan membutuhkan waktu pemulihan hingga **11–12 bulan**.

---

### Top 5 Basket dengan Kerugian Terbesar di Backtest (FAT_FULL):

#### #1. Loss -$400.72 | SELL Basket L5 | 2023.03.09 03:08 -> 2023.03.10 15:02
- **Pergerakan Harga**: 1812.92 -> 1861.13 (+4,821 pips melawan SELL).
- **Peristiwa Pasar**: **Kebangkrutan Silicon Valley Bank (SVB)**. Terjadi *flight-to-safety* masif ke emas tanpa ada koreksi sedikit pun.
- **Rincian Layer**:
  - `Order #1994 (L1)`: Lot 0.03 @ 1812.92 -> 1861.13 | **Loss: -$143.59** (36% dari total loss basket)
  - `Order #1995 (L2)`: Lot 0.03 @ 1823.03 -> 1861.13 | **Loss: -$113.26**
  - `Order #1997 (L3)`: Lot 0.03 @ 1829.01 -> 1861.13 | **Loss: -$95.32**
  - `Order #1999 (L4)`: Lot 0.01 @ 1834.21 -> 1861.13 | **Loss: -$26.57**
  - `Order #2001 (L5)`: Lot 0.01 @ 1839.22 -> 1861.13 | **Loss: -$21.98**
  - **Total Lot**: 0.11 lot.

#### #2. Loss -$390.03 | BUY Basket L5 | 2024.05.22 03:21 -> 2024.05.23 20:00
- **Pergerakan Harga**: 2418.38 -> 2331.40 (-8,698 pips melawan BUY).
- **Peristiwa Pasar**: Rilis notula rapat FOMC yang sangat *hawkish*. Emas anjlok drastis \$87 dalam 36 jam.
- **Rincian Layer**:
  - `Order #2777 (L1)`: Lot 0.01 @ 2418.38 -> 2331.40 | **Loss: -$88.88**
  - `Order #2779 (L2)`: Lot 0.01 @ 2400.89 -> 2331.40 | **Loss: -$71.39**
  - `Order #2780 (L3)`: Lot 0.01 @ 2395.89 -> 2331.40 | **Loss: -$66.39**
  - `Order #2782 (L4)`: Lot 0.02 @ 2375.43 -> 2331.40 | **Loss: -$91.85**
  - `Order #2784 (L5)`: Lot 0.02 @ 2367.09 -> 2331.40 | **Loss: -$71.52**
  - Ditutup tepat pada penutupan candle H4 jam 20:00.

#### #3. Loss -$353.46 | SELL Basket L5 | 2023.04.03 04:11 -> 2023.04.04 16:00
- **Pergerakan Harga**: 1951.03 -> 2020.34 (+6,931 pips melawan SELL).
- **Peristiwa Pasar**: Pemangkasan produksi minyak mendadak oleh OPEC+ memicu lonjakan ekspektasi inflasi, melontarkan emas menembus level psikologis \$2,000.
- **Rincian Layer**:
  - `Order #2036 (L1)`: Lot 0.02 @ 1951.03 -> 2020.34 | **Loss: -$137.92** (39% dari total basket)
  - `Order #2037 (L2)`: Lot 0.02 @ 1966.34 -> 2020.34 | **Loss: -$107.30**
  - `Order #2039 (L3)`: Lot 0.01 @ 1971.66 -> 2020.34 | **Loss: -$48.33**
  - `Order #2040 (L4)`: Lot 0.01 @ 1983.30 -> 2020.34 | **Loss: -$36.69**
  - `Order #2045 (L5)`: Lot 0.02 @ 2008.80 -> 2020.34 | **Loss: -$23.22**

#### #4. Loss -$350.92 | SELL Basket L4 | 2024.07.02 17:41 -> 2024.07.05 16:00
- **Pergerakan Harga**: 2323.41 -> 2384.82 (+6,141 pips melawan SELL).
- **Peristiwa Pasar**: Data ketenagakerjaan AS (NFP & ISM Services) melambat drastis, mengunci ekspektasi penurunan suku bunga September. Emas reli \$61 tanpa henti.
- **Rincian Layer**:
  - `Order #2855 (L1)`: Lot 0.03 @ 2323.41 -> 2384.82 | **Loss: -$178.17** (**50.8% dari total loss basket!**)
  - `Order #2856 (L2)`: Lot 0.03 @ 2334.87 -> 2384.82 | **Loss: -$145.05** (41.3%)
  - `Order #2859 (L3)`: Lot 0.01 @ 2366.78 -> 2384.82 | **Loss: -$18.11**
  - `Order #2860 (L4)`: Lot 0.01 @ 2375.30 -> 2384.82 | **Loss: -$9.59**

#### #5. Loss -$350.03 | BUY Basket L3 | 2021.01.06 11:50 -> 2021.01.08 08:00
- **Pergerakan Harga**: 1950.45 -> 1882.16 (-6,829 pips melawan BUY).
- **Peristiwa Pasar**: Kerusuhan US Capitol diikuti lonjakan tajam imbal hasil US 10-Year Treasury yield menembus 1.0%, memicu *dollar rally* ganas dan kejatuhan emas.
- **Rincian Layer**:
  - `Order #581 (L1)`: Lot 0.03 @ 1950.45 -> 1882.16 | **Loss: -$212.39** (**60.7% dari total loss basket! Kerugian order tunggal terbesar sepanjang masa backtest**)
  - `Order #582 (L2)`: Lot 0.02 @ 1933.94 -> 1882.16 | **Loss: -$108.57**
  - `Order #583 (L3)`: Lot 0.01 @ 1908.72 -> 1882.16 | **Loss: -$29.07**

---

## 4. ANATOMI PENYEBAB KERUGIAN (ROOT CAUSES)

Berdasarkan data empiris di atas, ditemukan 3 kelemahan struktural mendasar:

1. **Vulnerabilitas Order L1 (The Anchor Drag)**:
   - Pada hampir semua kekalahan besar, **Order L1 bertanggung jawab atas 36% hingga 61% total kerugian basket** (kerugian order tunggal mencapai -\$140 s/d -\$212).
   - *Penyebab*: Formula *risk budget* EA menghitung lot L1 dinamis: `Lot_L1 = (Balance * Risk_Pct) / (SL_Pips * Pip_Value)`. Saat volatilitas sebelum trade relatif tenang (SL pips kecil), lot L1 dinaikkan menjadi 0.03–0.04. Ketika tiba-tiba terjadi *volatility breakout* satu arah, lot L1 yang besar ini terseret sejauh 5,000–8,700 pips penuh hingga SL!

2. **Perangkap Averaging Melawan Outlier Makro (Blind Layering)**:
   - Pada peristiwa seperti SVB (#1) atau OPEC+ (#3), pasar berada dalam kondisi *one-way impulse trend*.
   - Layer L3, L4, L5 dibuka tepat di jalur lonjakan harga tanpa ada koreksi. Akibatnya, alih-alih mendekatkan BEP untuk penyelamatan, layer-layer dalam justru menambah eksposur lot (akumulasi lot basket menjadi 0.08–0.11 lot) dan memperbesar kerugian nominal di SL.

3. **Trade-off Konfirmasi Candle H4 (Confirmation Slippage)**:
   - Konfirmasi close candle H4 (`Sniper_SL_Confirm_TF=240`) terbukti sangat unggul menghindari *fakeout wick* (menyelamatkan 12 basket dibanding intrabar SL di FB, menghasilkan net profit 2x lipat lebih tinggi: +\$856 vs +\$406).
   - Namun kelemahannya: ketika breakout makro benar-benar terjadi, menunggu candle H4 selesai tutup sering kali membuat harga terdorong jauh melewati SL awal (harga bertambah minus \$50–\$70 saat konfirmasi tiba atau tersentuh di *hard multiplier* 1.3x).

---

## 5. RENCANA PENGEMBANGAN (USULAN SISTEM PENANGKAL RUGI BESAR — v94)

Kami mengusulkan 4 hipotesis/mekanisme sistematis untuk dianalisis bersama:

### Hipotesis A: Asymmetric L1 Risk Capping / Dynamic Lot Throttle
- **Ide**: Batasi lot L1 maksimum ke level konservatif (misalnya hard cap 0.01 atau 0.02) atau gunakan dynamic risk budget yang memperhitungkan rasio ATR M15/H1 saat entry.
- **Rasional**: Jika L1 dibatasi 0.01, rugi L1 pada pergerakan 7,000 pips hanya -\$70 (bukan -\$212). Kerugian basket terburuk langsung terpangkas 40-50%!

### Hipotesis B: Momentum & Volatility Surge Circuit Breaker (Anti-Blind Layering)
- **Ide**: Sebelum membuka layer L3+, periksa apakah pasar sedang mengalami lonjakan impulsif searah:
  - Indikator: Jika candle H1 terakhir berupa marubozu besar (ukuran candle > 2.0x ATR H1) **ATAU** ADX H1 > 35 dengan arah tren kuat melawan basket:
  - **Tindakan**: Bekukan / tunda pembukaan layer L4/L5 (*freeze layers*), jangan menambah lot ke dalam tren yang sedang meledak. Hanya buka layer jika momentum mulai melambat (misal RSI M5 mencapai kondisi extreme reversal atau candle rejection pinbar terbentuk).

### Hipotesis C: Early Trend Invalidation Exit (Penyempurnaan Trend Stop)
- **Ide**: Keluar lebih awal sebelum menyentuh SL penuh jika tren makro terkonfirmasi.
  - Pada Putaran 9 (Z4 TrendStop), penutupan di ADX H1 > 30 berhasil memangkas worst basket loss ke -\$225.
  - Dapatkah kita membuat filter *Trend Invalidation* yang menutup basket lebih awal HANYA jika terjadi 2 candle H4 berturut-turut yang ditutup searah melawan basket dan menembus L3?

### Hipotesis D: Partial Basket De-risking / Asymmetric Spacing L4+
- **Ide**: Melebarkan jarak persentil khusus untuk L4 dan L5 (misal L4 = P90, L5 = P96), atau jika L4 terbuka, tutup L1 (atau cut 50% L1) untuk memangkas *anchor drag* dan memindahkan titik BEP lebih dekat ke harga terkini tanpa menambah beban risiko.

---

## 6. PERTANYAAN STRATEGIS UNTUK CLAUDE

Mohon berikan analisis, evaluasi kuantitatif, dan rekomendasi Anda mengenai poin-poin berikut:
1. **Analisis Trade-off L1**: Apakah membatasi lot L1 ke 0.01/0.02 akan menurunkan profit total secara signifikan pada 3,235 basket menang, ataukah penghematan dari basket kalah (-$7,500 dipotong menjadi -$4,000) akan menghasilkan kenaikan Net Profit bersih yang jauh lebih besar?
2. **Layering vs Non-Layering saat Shock Makro**: Mengapa L4 dan L5 hampir tidak pernah menyelamatkan basket pada 5 kejadian terburuk di atas? Apakah lebih baik membatasi jumlah layer maksimum menjadi 3 layer saja pada kondisi volatilitas tinggi, atau menunda entry L4+ menggunakan konfirmasi pembalikan momentum (misalnya Stochastic M5 reversal)?
3. **Mekanisme SL Konfirmasi**: Apakah batas keras 1.3x pada konfirmasi H4 sudah optimal, atau haruskah ada *intrabar volatility threshold* (misalnya jika jarak dari L1 menembus 1.15x SL DAN ATR H1 > 2x rata-rata, langsung eksekusi SL tanpa menunggu penutupan H4)?
4. **Desain BioOnePro v94**: Di antara Hipotesis A, B, C, dan D di atas, kombinasi manakah yang paling elegan, terukur, dan aman dari bahaya *overfitting* untuk diimplementasikan ke dalam MQL4 dan diuji pada putaran riset berikutnya?

---

*File pendukung di repositori:*
- Source Code EA: `ea/BioOnePro_v93_NewsTime.mq4`
- Preset VH1: `research/presets/BioOnePro_v93_VH1.set`
- Laporan Backtest Every Tick: `backtests/runs/FAT_FULL.htm` & `FAT_FULL.gif`
- Log Sniper Lengkap: `research/logs/FAT_sniper.txt` (3,281 baris)
- Log Penelitian & Riwayat Putaran: `research/NOTES.md`
