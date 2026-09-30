# Catatan riset backtest

Diisi oleh Antigravity setelah menjalankan `research/scenarios.json`. Format bebas, maksimal 15 baris per putaran.

## Putaran 1 (v79)
- **Langkah terakhir berhasil**: Semua skenario (S0–S8 periode P1) berhasil dijalankan dan dianalisis lengkap.
- **Error yang muncul**:
  * Kompilasi EA: 0 error, 0 warning (sukses).
  * Startup awal sempat muncul `zero divide in 'BioOnePro_Optimized_v79_Apex_PairClose.mq4' (3074,55)` karena parameter `Expert=` melampirkan EA ke chart live offline. Diatasi dengan hanya memakai parameter `TestExpert=`.
  * `run_mt4_batch.py` disesuaikan untuk MT4 build 1441 (eksekusi via task scheduler `LaunchMT4` sesi interaktif dan setting deposit $500).
- **Lokasi MT4**:
  * terminal.exe: `C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe`
  * Folder data: `C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5`
- **Data Tick XAUUSD**:
  * P1 (2025.09.29–2026.09.25): **Tersedia** (92.472.987 tick events di `XAUUSD1_0.fxt`).
  * P2 (2025.01.02–2025.09.26): **Tidak tersedia** (file FXT lokal baru dimulai dari 2025.09.29).
- **Temuan Hasil Backtest (P1)**:
  * S0 cocok eksak dengan v77: net $36,335.47 (target $36,259.95), max DD 43.48% (target 43.48%), worst order -$1,791.88.
  * Skenario terbaik kriteria DD: **S5** (max DD 19.36%, rel DD 43.21%, net $3,929.24, net/DD 5.64).
  * Skenario terbaik mitigasi worst order: **S6** (worst order -$91.41 vs -$1,791.88 baseline).
  * S3 gagal (DD 78.74%, net $502.09) karena pair close L2 memotong recovery terlalu dini.

## Analisis Claude Code atas putaran 1
- S0 ≈ v77 (net $36,335 vs $36,260, DD 43.48% identik; beda kecil dari data tick). v79 default = v77. ✔
- **Pair Close (S2/S3/S4/S6) DITOLAK.** Loss order terbesar memang turun (−$1,792 → −$434), tetapi
  relative DD naik ke 61–79%, basket sampai L4+ (9–12 kali, sebelumnya 0), dan total lot basket naik
  (2.66 → 7.05). Penyebabnya: setelah layer terbaru ditutup, grid membuka layer itu lagi, sehingga basket
  berputar dan makin dalam. Fitur tetap ada di kode, tetapi jangan dipakai.
- Escape Guard L3 (S8): net −17%, DD tetap ~43%. Tidak membantu.
- **Kandidat terbaik: S5 (Survive_Adverse_Move_Pips=8000)**: max DD 19.36%, loss order terbesar −$145,
  net/DD 5.64. S7 (Lot_Base 800) mirip, tetapi sedikit lebih buruk.
- Relative DD 43.21% di S5/S6/S7 terjadi di **basket pertama (30 Sep 2025, balance ~$510)**. Dengan balance
  $500, lot sudah minimum (0.01), jadi pembatas lot belum bekerja. Dengan Survive $80, lot 0.01 baru sesuai
  target risiko mulai balance ≈ $800. Putaran 2 menguji ini (R4, deposit $1000).
- Spread 100 + kunci komisi (S1) menurunkan net ~7% dibanding S0. Wajar.

## Putaran 2
| run_id | deposit | net_profit | max_dd_pct | rel_dd_pct | largest_order_loss | net_per_dd |
|---|---|---|---|---|---|---|
| R1_P1 | 500 | 7750.67 | 28.21% | 43.21% | -326.34 | 4.40 |
| R2_P1 | 500 | 2721.90 | 20.00% | 43.21% | -92.34 | 5.01 |
| R3_P1 | 500 | 2092.51 | 15.43% | 43.21% | -74.56 | 6.01 |
| R4_P1 | 1000 | 7249.38 | 21.12% | 24.93% | -257.46 | 5.12 |
| R5_P1 | 500 | 3865.54 | 19.56% | 43.34% | -145.44 | 5.54 |
| R6_P1 | 500 | 1980.98 | 16.23% | 39.72% | -74.85 | 5.69 |
- Log: R4 terbukti pangkas rel DD ke 24.93% (deposit $1000). R3 DD terendah (15.43%). P2 dilewati (offline). Nol order error.

## Analisis Claude Code atas putaran 2
- Hipotesis deposit terbukti: R4 (bertahan $80, deposit $1000) → relative DD 43% → **24.9%**, max DD 21%,
  0 basket rugi, net $7,249 (+725%). **R4 menjadi baseline baru.**
- Makin besar jarak bertahan, makin kecil DD dan profit: $70 → DD 28%, $80 → 19%, $90 → 20%, $100 → 15%.
  Net profit tidak turun mulus ($7.7k → $3.9k → $2.7k → $2.1k) karena efek compounding.
- Spread 200 (R5) hampir tidak berpengaruh dibanding S5 (−2% net). Cut-loss 35% (R6) memotong profit tanpa
  menurunkan DD lebih jauh dari R3.
- Putaran 3 (EA v80): uji Parabolic SAR sebagai (a) gate layer averaging, supaya layer dibuka setelah harga
  berbalik, bukan saat jatuh bebas; dan (b) filter arah L1. Semua di atas baseline R4.

## Putaran 3
| run_id | net_profit | max_dd_pct | rel_dd_pct | largest_order_loss | net_per_dd | depth_L3 | depth_L4plus |
|---|---|---|---|---|---|---|---|
| T0_P1 | 7249.38 | 21.12% | 24.93% | -257.46 | 5.12 | 13 | 0 |
| T1_P1 | 2813.00 | 22.08% | 57.56% | -241.20 | 3.69 | 12 | 0 |
| T2_P1 | 1780.67 | 60.25% | 60.25% | -831.36 | 0.75 | 10 | 1 |
| T3_P1 | 1700.66 | 21.92% | 22.14% | -110.64 | 3.13 | 9 | 0 |
| T4_P1 | 2618.45 | 21.47% | 21.99% | -123.44 | 3.76 | 6 | 0 |
| T5_P1 | 1038.39 | 46.24% | 46.24% | -164.79 | 1.29 | 7 | 1 |
| T6_P1 | 2636.14 | 19.25% | 21.86% | -74.56 | 6.80 | 13 | 0 |
| T7_P1 | 602.09 | 32.52% | 32.52% | -109.86 | 1.27 | 7 | 1 |
- Log: PSAR gate (T1/T2/T5/T7) tunda averaging hingga DD tembus 60% & L4+. Filter L1 (T3/T4) pangkas worst order tapi profit turun. T0/R4 terbaik. Nol error order.

## Analisis Claude Code atas putaran 3
- T0 = R4 persis (net $7,249.38, max DD 21.12%). EA v80 dengan default konsisten. ✔
- **PSAR Averaging Gate DITOLAK** (T1/T2/T5/T7): relative DD naik ke 46–60%, muncul basket L4+ dan basket rugi.
  Menunda layer membuat L1–L2 berat ditahan lebih lama, lalu layer masuk setelah harga memantul, sehingga
  BEP basket nyaris tidak membaik. Ini "Retracement Paradox" yang sudah dicatat di kode lama.
- **PSAR L1 Filter tidak efisien** (T3/T4): loss order terbesar turun dari −$257 ke −$111/−$123 dan rel DD ~22%,
  tetapi jumlah basket turun dari 424 ke 201/258 dan profit turun 64–77%. Hasil ini kalah dari T6
  (hanya mengecilkan lot): DD 19.3%/21.9%, net $2,636, net/DD 6.80 (terbaik).
- Kesimpulan: filter indikator tambahan (PSAR) tidak lebih baik dari pengaturan ukuran lot. DD paling efektif
  ditekan lewat Survive_Adverse_Move_Pips dan deposit yang cukup.
- Rel DD T6 (21.86%, $221) masih terjadi di basket pertama 30 Sep 2025 karena lot minimum 0.01.
  Dengan bertahan $100, lot 0.01 baru sesuai target risiko mulai balance ≈ $1,300. Putaran 4 menguji V1 (deposit $1,500).
- Preset siap pakai: research/presets/BioOnePro_v80_Seimbang_R4.set (bertahan $80, deposit ≥ $1,000) dan
  BioOnePro_v80_DD_Rendah_T6.set (bertahan $100, deposit ≥ $1,500).
- Prioritas berikutnya adalah **validasi di periode lain** (P2 = Jan–Sep 2025, P3 = 2024), karena semua hasil
  sejauh ini hanya dari satu tahun data.

## Putaran 4
- Data M1 awal: Demo01=2022.01.03 (1.52M bar M1), Live04=2025.09.29 (352k bar). File FXT read-only terikat P1.
| run_id | deposit | net_profit | max_dd_pct | rel_dd_pct | largest_order_loss | net_per_dd | losing_baskets | depth_L4plus |
|---|---|---|---|---|---|---|---|---|
| V1_P1 | 1500 | 3772.97 | 11.81% | 14.63% | -108.03 | 6.95 | 1 | 0 |
| S0_P2/P3 | 500 | 0.00 | 0.00% | 0.00% | 0.00 | 0.00 | 0 | 0 |
| T0_P2/P3 | 1000 | 0.00 | 0.00% | 0.00% | 0.00 | 0.00 | 0 | 0 |
| T6_P2/P3 | 1000 | 0.00 | 0.00% | 0.00% | 0.00 | 0.00 | 0 | 0 |
| V1_P2/P3 | 1500 | 0.00 | 0.00% | 0.00% | 0.00 | 0.00 | 0 | 0 |
- Laporan P2/P3: Bars in test=352520, Modelling quality=n/a, Mismatched charts errors=0 (0 trade di semua run).
- Log: P2/P3 0 trade krn XAUUSD1_0.fxt read-only dari 2025.09.29. V1_P1 sukses pangkas rel DD ke 14.63% (max DD 11.81%).
- Catatan: Nol order error. Untuk uji P2/P3 perlu build FXT baru dari data Demo01 (tersedia sejak 2022.01.03).

## Analisis Claude Code atas putaran 4
- **V1 (bertahan $100, deposit $1,500): max DD 11.81%, rel DD 14.63%, net +$3,773 (+252%), net/DD 6.95.**
  Hasil ini mengonfirmasi bahwa DD awal akun disebabkan lot minimum 0.01. V1 adalah setting DD terendah sejauh ini.
- **P2/P3 TIDAK VALID**: semua 0 trade dan "Bars in test" 352520 (= data P1). Tester memakai ulang
  XAUUSD1_0.fxt yang read-only dan hanya berisi data sejak 2025.09.29. Laporan kosong sudah dihapus dari
  backtests/runs, dan baris P2/P3 dihapus dari results_putaran4.csv.
- Putaran 5: login ke server Demo01 (history M1 sejak 2022.01.03), izinkan tester membuat FXT baru,
  lalu ulangi P2/P3. Tambah P1D (periode P1 dengan data Demo01) untuk memastikan hasil dari data demo
  sebanding dengan data Live04.

## Putaran 5
- Server/Akun: ICMarketsSC-Live04 (50063405); data M1 2022–2026 disinkronkan dari Demo01.
| run_id | deposit | net_profit | max_dd_pct | rel_dd_pct | largest_order_loss | losing_baskets | depth_L3 | depth_L4plus | bars_in_test |
|---|---|---|---|---|---|---|---|---|---|
| T0_P3 | 1000 | 0.00 | 0.00% | 0.00% | 0.00 | 0 | 0 | 0 | 354514 |
| S0_P3 | 500 | -497.41 | 99.56% | 99.56% | -79.74 | 41 | 6 | 0 | 355515 |
- Validasi data 2024 (P3): FXT baru BERHASIL dibuat dari history (Bars 354k–355k, 44.78M ticks, Quality 25%).
- Penyebab T0 0 trade: TestSpread=100 > Absolute_Max_Spread_Pips=45 (IsSpreadAllowedForEntry tolak 100% tick).
- Bukti: S0_P3 dengan spread 20 (<45) berhasil buka 307 trade (217 win, 90 loss, MC di $500).
- Di P1 T0 bisa trade karena FXT lama pre-generated punya floating spread ~20-30 pips di dalam tick data.
- Solusi agar T0/T6/V1 jalan di P2/P3: set Use_Dynamic_Spread_Filter=false atau Absolute_Max_Spread_Pips>=100.
- Log: Sesuai instruksi butir 3, proses berhenti karena T0 trade=0. Deposit tester di-restore ke 500.

## Analisis Claude Code atas putaran 5
- **Diagnosis Antigravity soal T0 sebagian benar, tapi solusinya bukan mematikan filter spread.** Data Demo01
  berformat **2 digit** (harga 2068.36), sedangkan Live04 3 digit. Di data 2 digit, TestSpread 100 point = **$1.00**
  (100 pips EA) > batas 45 pips, sehingga semua entry diblokir. Solusinya: pakai spread 20 point (= $0.20, realistis).
  Periode P2/P3/P1D sekarang memakai "test": {"spread": 20} secara otomatis. Filter spread tetap aktif.
- **S0 (setting v77 asli, $500) di 2024 bangkrut**: −$497, DD 99.6%, 41 basket rugi, akun habis Juni 2024.
  Basket terburuk adalah SELL L3 melawan reli emas April 2024 yang ditutup paksa oleh weekend close Jumat 19:00
  (−$190, −$188) dan cut-loss 50% (−$159). Ini bukti pertama bahwa **hasil P1 tidak otomatis berlaku di periode lain**.
- Catatan: spread di S0_P3 $0.20, sedangkan S0_P1 hanya $0.02. Sebagian perbedaan hasil mungkin karena biaya.
  P1D (P1 dengan data Demo01 dan spread $0.20) akan menunjukkan seberapa besar pengaruhnya.
- Putaran 5b: jalankan T0/T6/V1 di P3 dan P2, dan T0/S0 di P1D.

## Putaran 5b
| run_id | deposit | net_profit | max_dd_pct | rel_dd_pct | largest_order_loss | losing_baskets | depth_L3 | depth_L4plus |
|---|---|---|---|---|---|---|---|---|
| S0_P3 | 500 | -497.41 | 99.56% | 99.56% | -79.74 | 41 | 6 | 0 |
| T0/T6_P3 | 1000 | -996.31 | 99.66% | 99.66% | -126.62 | 26 | 9 | 1 |
| V1_P3 | 1500 | -759.55 | 65.83% | 65.83% | -189.23 | 30 | 16 | 6 |
| S0_P2 | 500 | 1279.40 | 21.29% | 23.90% | -88.92 | 28 | 4 | 0 |
| T0_P2 | 1000 | 851.82 | 61.67% | 61.67% | -392.28 | 8 | 7 | 3 |
| T6/V1_P2 | 1000/1500 | 219.92/111.11 | 55.25%/53.40% | 55.25%/53.40% | -242.43/-405.56 | 7 | 5 | 2 |
| S0_P1D | 500 | 44702.36 | 46.28% | 49.12% | -2462.36 | 66 | 16 | 0 |
| T0_P1D | 1000 | 8052.03 | 22.35% | 25.83% | -296.94 | 2 | 16 | 0 |
- Log: Spread 20 terverifikasi di semua run (MQ 25%). 2024 (P3) bull run bobol semua setting; P1D konsisten dgn Live04.

## Analisis Claude Code atas putaran 5b
- **P1D ≈ Live04** (T0: net $8,052, DD 22.4% vs $7,249 / 21.1%). Data Demo01 dan spread $0.20 tidak mengubah
  kesimpulan untuk P1, jadi hasil P1 bukan sekadar efek spread murah.
- **2024 (P3): semua setting rugi.** T0 dan T6 −99.7% (hasilnya identik karena di balance $1000 lot sudah minimum
  0.01), V1 −51% (DD 65.8%), S0 bangkrut.
  **2025 Jan–Sep (P2):** untung tipis, tetapi DD 53–62% (3 basket BUY L4 Juni 2025 = −$1,200 pada T0).
- Mekanisme kerugian 2024 (V1_P3): dari −$2,244 total basket rugi, **~−$1,485 (66%) berasal dari weekend close
  Jumat 19:00** yang merealisasikan basket L2–L4 yang sedang minus. Sisanya basket dalam (L4–L5), mayoritas
  **SELL melawan reli harian** (−$682 untuk L5 SELL).
- Kesimpulan: EA ini **bergantung pada kondisi pasar**. Pengaturan lot saja tidak cukup untuk tahun dengan tren kuat.
  Putaran 6 (EA v81) menguji tiga penangkal:
  (1) filter tren D1 (EMA50) untuk L1,
  (2) weekend hold: hanya basket profit yang ditutup Jumat; basket rugi < 20% ditahan dan order baru diblokir,
  (3) stop basket 20% balance mulai L2 (fitur lama Use_Side_Basket_Loss_Guard).
  Diuji di P3, P2, dan P1D, supaya perbaikan untuk 2024 tidak merusak hasil periode lain.

## Putaran 6
| run_id | net_profit | max_dd_pct | rel_dd_pct | largest_order_loss | losing_baskets | depth_L4plus |
|---|---|---|---|---|---|---|
| U1 (P3/P2/P1D) | -512.37 / -422.70 / +2512.07 | 66.97% / 88.79% / 23.20% | 66.97% / 88.79% / 23.20% | -134.09 / -272.72 / -131.33 | 22 / 7 / 1 | 2 / 3 / 0 |
| U2 (P3/P2/P1D) | -994.86 / -203.72 / +8052.03 | 99.57% / 77.99% / 25.83% | 99.57% / 77.99% / 25.83% | -178.78 / -398.22 / -296.94 | 24 / 7 / 2 | 2 / 4 / 0 |
| U3 (P3/P2/P1D) | -841.44 / +176.24 / +3507.13 | 89.74% / 58.19% / 29.44% | 89.74% / 58.19% / 29.44% | -83.47 / -147.93 / -383.53 | 50 / 10 / 5 | 0 / 0 / 0 |
| U4 (P3/P2/P1D) | -599.38 / -585.26 / +2512.07 | 81.17% / 88.79% / 23.20% | 81.17% / 88.79% / 23.20% | -221.94 / -272.72 / -131.33 | 13 / 7 / 1 | 3 / 3 / 0 |
| U5 (P3/P2/P1D) | -554.83 / -69.29 / +1136.82 | 75.24% / 57.79% / 26.46% | 75.24% / 57.79% / 26.46% | -91.31 / -140.34 / -80.24 | 19 / 9 / 4 | 0 / 0 / 0 |
- Log: "WEEKEND: tutup basket" terkonfirmasi aktif pada U2/U4/U5 di hari Jumat ketika net basket sedang minus.
- Spread 20 valid di semua run. Filter D1 (U1/U4/U5) memangkas profit P1D ($2512 vs $8052). U3 satu-satunya profit di P2 (+176.24, DD 58%), dan membatasi depth_L4plus=0 di semua periode.

## Rencana putaran 7 (EA v82 Adaptive Sniper)
- v82 = v81 + mode Adaptive Sniper (lihat docs/desain-v82-adaptive-sniper.md): jarak layer = persentil swing H1
  20 hari, lot L2+ menargetkan BEP dalam jarak pantulan biasa, SL basket di P98, lot L1 dari anggaran risiko per basket.
- Putaran 6 (U1–U5) sudah selesai dijalankan oleh Antigravity (lihat hasil di atas).
- Skenario Sniper W1–W5 (deposit $1000). Prioritas: P3 (2024) → P2 → P1D.

## Putaran 7
| run_id | net_profit (P3 / P2 / P1D) | max_dd_pct | rel_dd_pct | worst_order | losing_bsk | L3 | L4+ |
|---|---|---|---|---|---|---|---|
| W1 (5L, 10%) | -211.65 / +380.41 / +757.16 | 32.43% / 27.17% / 15.62% | 32.43% / 27.17% / 15.62% | -78.93 / -61.91 / -107.93 | 48 / 12 / 16 | 9 / 15 / 0 | 1 / 1 / 0 |
| W2 (5L, 20%) | -496.61 / +1140.59 / +777.92 | 56.16% / 34.05% / 17.90% | 56.16% / 34.05% / 17.90% | -78.93 / -121.34 / -107.93 | 41 / 10 / 15 | 21 / 13 / 3 | 12 / 8 / 1 |
| W3 (4L, 15%) | -319.23 / +498.18 / +803.42 | 40.89% / 29.31% / 16.81% | 40.89% / 29.31% / 16.81% | -78.93 / -121.34 / -107.93 | 43 / 11 / 16 | 20 / 14 / 2 | 7 / 7 / 0 |
| W4 (W3+D1+WH)| -416.06 / +274.90 / +468.51 | 46.26% / 34.10% / 18.25% | 46.26% / 34.10% / 18.25% | -78.93 / -118.93 / -286.15 | 21 / 9 / 7 | 14 / 9 / 1 | 4 / 7 / 0 |
| W5 (W3+Time24)| -407.77 / +340.11 / +355.86 | 53.24% / 28.94% / 15.21% | 53.24% / 28.94% / 15.21% | -67.93 / -117.72 / -98.94 | 64 / 15 / 24 | 17 / 12 / 1 | 4 / 8 / 0 |
- Swing W1: P3 (984/1263/1592/2755/9012, L2=1263, SL=9012); P2 (1371/1754/2468/3951/5176, L2=1754, SL=5176); P1D (1905/2385/3737/5492/6899, L2=2385, SL=6899).
- SNIPER SL per run (P3/P2/P1D): W1=10/6/0, W2=9/3/0, W3=9/4/0, W4=9/5/0, W5=5/4/0 (W5 time-stop: 37/7/13).
- Log: W1 menekan DD 2024 (P3) drastis dari 99% ke 32.4%, dan seluruh skenario W konsisten profit di P2 ($274–$1140) dan P1D ($355–$803) dgn DD < 35%.
- Hal aneh: Lot L1 dinamis dihitung < 0.01 (0.003–0.006) sehingga broker mengeksekusi lot minimum 0.01, membuat risiko aktual per basket sedikit lebih besar dari target % balance.


## Analisis Claude Code atas putaran 6–7
- **Fitur v81 (U1–U5) DITOLAK.** Semua rugi di 2024 (−51% s/d −99%) dan sebagian besar rugi di P2.
  Filter D1 memotong profit P1D dari $8,052 ke $2,512. Weekend hold (U2) tidak mengubah P1D dan memperburuk P2/P3.
- **Adaptive Sniper = kemajuan pertama di 2024.** W1: P3 −21% (DD 32%, sebelumnya akun habis), P2 +38% (DD 27%),
  P1D +76% (DD 15.6%). **Semua W profit di P2 dan P1D, dan tidak ada yang bangkrut di P3.** W1 paling seimbang.
  W2 (risiko 20%) profit P2 terbesar, tetapi DD 2024 56%.
- Harga keamanannya: profit P1D jauh lebih kecil (W1 +76% vs T0 +805%), karena L2 jarang terbentuk
  (L2 P1D di $24; hanya 3 basket L2) dan L1 dikunci 0.01.
- **Masalah 1: lot L1 terhitung 0.003–0.006, dipaksa jadi 0.01** di deposit $1000, sehingga lot adaptif
  belum pernah benar-benar diuji. Putaran 8 memakai deposit $3000.
- **Masalah 2: SL P98 tidak stabil.** Di 2024, P98 = 9012 pips ($90) padahal P93 = 2755. Dengan ~20 hari data,
  P98 hanya ditentukan 1–2 swing ekstrem. Diuji SL P95 (X4) dan belajar 40 hari (X3).
- Putaran 8 (deposit $3000, P3/P2/P1D): X1 = W1, X2 = grid lebih rapat + SL P95, X3 = belajar 40 hari,
  X4 = SL P95, X5 = lot layer lebih ringan (BEP 0.8).

## Putaran 8
| run_id | net_profit (P3/P2/P1D) | max_dd_pct | rel_dd_pct | worst_order | losing_bsk | L2 | L3 | L4+ | SL_cnt |
|---|---|---|---|---|---|---|---|---|---|
| X1 (W1 $3k) | -429.92 / +1301.35 / +831.88 | 22.5% / 17.0% / 8.8% | 22.5% / 17.0% / 8.8% | -98.6 / -121.3 / -107.9 | 40 / 10 / 15 | 40 / 13 / 10 | 22 / 13 / 3 | 20 / 8 / 1 | 7 / 3 / 0 |
| X2 (Rapat+P95)| -603.84 / +279.23 / +493.91 | 28.1% / 32.7% / 10.0% | 28.1% / 32.7% / 10.5% | -128.5 / -113.8 / -157.1 | 38 / 14 / 17 | 51 / 17 / 11 | 28 / 11 / 3 | 20 / 11 / 4 | 10 / 8 / 2 |
| X3 (40 Hari)| -16.86 / +562.46 / +441.54 | 21.8% / 20.4% / 10.6% | 21.8% / 20.4% / 10.6% | -101.9 / -122.1 / -161.9 | 37 / 10 / 18 | 40 / 14 / 7 | 24 / 14 / 1 | 22 / 7 / 2 | 4 / 4 / 1 |
| X4 (SL P95) | -529.05 / +1672.69 / +800.05 | 30.8% / 20.4% / 15.4% | 30.8% / 20.4% / 15.4% | -125.0 / -164.0 / -213.9 | 41 / 10 / 14 | 39 / 13 / 11 | 24 / 14 / 5 | 18 / 7 / 0 | 11 / 4 / 1 |
| X5 (BEP 0.8) | -230.24 / +1259.54 / +832.35 | 21.0% / 19.3% / 8.8% | 21.0% / 19.3% / 8.8% | -147.9 / -178.4 / -107.9 | 40 / 12 / 15 | 40 / 13 / 10 | 23 / 13 / 3 | 19 / 8 / 1 | 7 / 3 / 0 |
- Deposit $3000 mengaktifkan lot adaptif L1 (0.01–0.03 aktual terbuka). Semua skenario untung di P2 & P1D dengan DD < 33% (P1D DD < 11%).
- X3 (belajar 40 hari) paling stabil di 2024 (P3 hampir BEP, hanya -$16.86 dgn 4 SL). X4 menghasilkan profit P2 tertinggi (+$1,672).
- Hal aneh: Pada P1D, initial lot L1 tetap 0.01 (terhitung 0.011) karena volatilitas H1 20 hari tinggi sehingga kalkulasi risiko SL menuntut lot kecil.


## Analisis Claude Code atas putaran 8
- Deposit $3000 membuat lot L1 adaptif bekerja (0.01–0.03). Semua X profit di P2 dan P1D; DD P1D < 16%.
- Tiga periode (P3 / P2 / P1D, % dari $3000):
  X1 −14% / +43% / +28% (DD 22/17/9) · **X3 (40 hari) −0.6% / +19% / +15%** (DD 22/20/11) ·
  **X5 (BEP 0.8) −7.7% / +42% / +28%** (DD 21/19/9) · X4 (SL P95) −18% / +56% / +27% · X2 ditolak.
  X5 lebih baik dari X1 di semua periode. X3 paling tahan di 2024.
- **Temuan kunci (bedah basket X3/X5 di 2024): layer dalam merugikan.** Basket L4+ yang menang total hanya +$36/+$54,
  sedangkan L4+ yang kalah (SL + weekend) −$1,230/−$1,512. Basket L2–L3 juga net negatif di 2024.
  Hampir semua profit datang dari **L1 yang menang** (+$1,336/+$1,784). Di P2 polanya sama: L4+ −$413 vs +$19.
  Artinya, averaging dalam lebih sering berakhir di SL daripada menyelamatkan basket.
- Putaran 9 (deposit $3000, basis Y1 = X3 + X5): uji jumlah layer maksimal 5/3/2/1.
  Y4 (tanpa averaging, hanya L1 + SL adaptif) adalah kontrol, untuk mengukur apakah averaging masih menambah nilai.
  Y5 = 3 layer + SL P95.
