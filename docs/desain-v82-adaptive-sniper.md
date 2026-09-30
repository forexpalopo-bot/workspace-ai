# Desain v82 "Adaptive Sniper"

Diaktifkan dengan `Use_Adaptive_Sniper=true`. Semua logika entry L1, exit basket (target net + trailing),
filter spread, dan fitur v78–v81 tetap sama. Yang berubah adalah **jarak layer, lot layer, SL basket, dan lot L1**.

## 1. Belajar dari pergerakan harga beberapa hari terakhir
Setiap bar H1 baru, EA memindai `Sniper_Learn_Days` (default 20) hari H1 dan mencari swing high/low
(`Sniper_Swing_Depth` = 3 bar kiri/kanan). Panjang setiap kaki swing (high↔low, dalam pips EA) dikumpulkan dan
diurutkan. Dari situ EA mengetahui, misalnya, "50% pergerakan dalam 20 hari terakhir tidak lebih dari $14".

## 2. Jarak averaging adaptif ("sniper")
Layer ditempatkan pada **jarak dari harga L1** sesuai persentil panjang swing:

| Layer | Default | Makna |
|---|---|---|
| L2 | P50 | Separuh swing biasa berbalik sebelum titik ini |
| L3 | P70 | |
| L4 | P85 | |
| L5 | P93 | |
| SL basket | P98 | Hanya 2% swing yang lebih panjang: kemungkinan besar tren, bukan koreksi |

Saat pasar bergerak lebar (misalnya 2024), semua jarak otomatis melebar. Saat pasar tenang, jaraknya menyempit.
Jarak minimum antar layer `Sniper_Min_Step_Pips` (default 500 = $5). Rencana ini **dibekukan saat L1 dibuka**,
supaya satu basket memakai aturan yang konsisten. Waktu masuk layer tetap harus lolos konfirmasi candle dan jeda
minimum antar layer yang sudah ada.

## 3. Lot L2+ untuk mencapai BEP
Saat layer baru dibuka, lotnya dihitung supaya **BEP basket berada `target BEP` dari harga sekarang**.
Target BEP = `Sniper_BEP_Fraction` (0.6) × swing P50 (`Sniper_BEP_Percentile`), yaitu pantulan yang biasa terjadi:
`lot_baru = total_lot × (gap − target) / target`.
Lot dibatasi minimal sama dengan layer sebelumnya dan maksimal `Sniper_Max_Lot_Mult` (2×).

## 4. SL L1/basket adaptif + anggaran risiko
- **SL basket** di jarak P98 dari L1. Kalau harga sampai di sana, seluruh basket ditutup
  (log: `SNIPER SL`).
- **Anggaran risiko**: rugi seluruh basket di harga SL ≤ `Sniper_Max_Basket_Risk_Pct` % balance (default 10%).
  - Lot L1 dihitung dari rencana lengkap agar batas ini terpenuhi.
  - Lot layer baru dipotong bila akan melampauinya. Kalau sisa anggaran < lot minimum, layer **dilewati**.
- **Time-stop** opsional (`Sniper_Time_Stop_Hours`): basket yang masih rugi setelah N jam ditutup.

Dengan desain ini, **rugi terburuk per basket terukur**. Grid lama tidak punya batas ini, sehingga di 2024
kerugian menumpuk sampai akun habis.

## Konsekuensi yang perlu diketahui
- Win rate akan turun, karena basket yang dulu "diselamatkan" martingale sekarang ditutup di SL.
  Harapannya, kerugian itu kecil dan terkendali.
- Pada contoh statistik emas yang realistis, rugi di SL untuk rencana 5 layer ≈ $250–370 per 0.01 lot L1.
  Dengan risiko 10% per basket, lot 0.01 baru sesuai target mulai balance ≈ **$2,500–3,700**. Di balance
  lebih kecil, lot L1 terpaksa 0.01 (minimum broker); anggaran risiko lalu memangkas atau melewati layer.
- Persentil dan parameter default adalah titik awal yang masuk akal, bukan hasil optimasi. Kebenarannya
  hanya bisa dibuktikan lewat backtest di 2024, 2025, dan P1.

---

# v83: SL adaptif dan jarak "bernapas"

Dasarnya temuan putaran 8. Kerugian besar datang dari basket L2+ yang **bertahan lama**:
median umur basket rugi ~25 jam, sedangkan basket menang ~16 jam. Setelah 24 jam, peluang menang/kalah
tinggal sekitar 50:50, padahal kekalahannya jauh lebih besar. Semua fitur default mati.

| Fitur | Cara kerja | Masalah yang diserang |
|---|---|---|
| **Jarak bernapas** `Sniper_Use_Vol_Scaling` | Jarak layer (dari rencana persentil yang dibekukan) dikali rasio ATR H1(14) / ATR H1 jangka panjang, dibatasi 0.8–2.0×. Dicek ulang setiap tick. | Saat pasar mendadak cepat, layer tidak terkena "jatuh bebas"; saat tenang, averaging lebih rapat. |
| **SL time-decay** `Sniper_Use_SL_Time_Decay` | Setelah 12 jam, SL basket mengetat linear sampai 60% dari SL awal di jam ke-36. Hanya bisa mengetat, dan tidak pernah lebih dekat dari layer terdalam + jarak minimum. | Basket tua yang kemungkinan besar sedang melawan tren ditutup lebih awal, dengan rugi lebih kecil. |
| **Trend-confirm stop** `Sniper_Use_Trend_Stop` | Basket ≥ 3 layer ditutup bila close H1 sudah melewati layer terdalam, ADX H1 ≥ 30, dan DI melawan basket. | Keluar sebelum SL penuh ketika tren terkonfirmasi. |
| **Recovery exit** `Sniper_Use_Recovery_Exit` | Basket ≥ 2 layer yang berumur ≥ 12 jam ditutup begitu net ≥ 0, tanpa menunggu target $6–15. | Mencegah basket tua yang sempat kembali ke BEP jatuh lagi dan berakhir di SL atau weekend close. |

Anggaran risiko per basket (lot L1 dan batas lot layer) tetap dihitung dari SL awal, sehingga semua fitur
ini hanya bisa **mengurangi** rugi maksimum, tidak menambahnya.

---

# v84: L1 Scalp (semua default mati)

| Fitur | Parameter | Cara kerja |
|---|---|---|
| **Entry L1 di OB/OS TF kecil** | `Use_L1_OBOS_Filter`, `L1_OBOS_TF=5` | Selain syarat lama (tren H1, pullback BB, MACD, dll.), L1 BUY hanya dibuka bila Stochastic(14,3,3) M5 sempat ≤ 20 dalam 3 bar terakhir **dan** %K berbalik naik di atas %D. SELL kebalikannya (≥ 80, lalu turun). Tujuannya masuk dekat titik balik pullback, bukan di tengah pergerakan. |
| **Tidak buka BUY dan SELL bersamaan** | `Dual_Mode=false` (fitur lama) | L1 baru hanya dibuka bila tidak ada basket terbuka di arah mana pun. |
| **TP scalping** | `Use_Scalp_TP`, ATR M15 × 1.0, batas $2–$8 | TP L1 dekat dan adaptif terhadap volatilitas, dikunci saat order dibuka. Trailing lama tetap aktif, jadi profit masih bisa dikunci lebih awal. |
| **SL lebih ketat** | `Sniper_SL_Max_Pips` (mis. 3000 = $30) | Membatasi jarak SL basket dari L1. Layer averaging yang posisinya melewati SL otomatis tidak dipakai, dan lot L1 dihitung ulang dari anggaran risiko dengan SL yang lebih dekat. |

Konsekuensi SL yang lebih dekat: **rugi per kejadian lebih kecil**, tetapi SL tersentuh **lebih sering**.
Anggaran risiko per basket (8%) tetap sama, jadi lot L1 sedikit lebih besar saat SL lebih dekat.
