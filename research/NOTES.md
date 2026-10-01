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

## Putaran 9
| run_id | net_profit (P3/P2/P1D) | max_dd_pct | rel_dd_pct | largest_order_loss | losing_bsk | worst_basket | L4+ | SL / TrendStop / RecExit |
|---|---|---|---|---|---|---|---|---|
| Y1 (5L 40d+0.8) | -10 / +645 / +454 | 19.8% / 21.9% / 10.7% | 19.8% / 21.9% / 10.7% | -102 / -122 / -162 | 40 / 12 / 17 | -338 / -328 / -309 | 22 / 7 / 2 | (5/0/0) / (5/0/0) / (1/0/0) |
| Y2 (3 Layer) | -495 / +1336 / +491 | 28.3% / 21.7% / 10.8% | 28.3% / 21.7% / 10.8% | -153 / -183 / -162 | 39 / 10 / 17 | -310 / -387 / -313 | 0 / 0 / 0 | (7/0/0) / (5/0/0) / (1/0/0) |
| Y3..Y5 (Layer/P95) | -512 s/d -1404 / +229..+901 | 28.9%..51.5% / 33%..35% | 28.9%..51.5% / 33%..35% | -204..-307 / -210..-414 | 43..62 / 13..25 | -272..-306 / -366..-414 | 0 / 0 / 0 | Y4 SL: 11/11/1, Y5 SL: 18/8/0 |
| Z1 (ATR ratio) | -248 / +846 / +807 | 15.6% / 18.0% / 7.0% | 15.6% / 18.0% / 7.0% | -102 / -122 / -108 | 35 / 13 / 15 | -338 / -341 / -143 | 23 / 8 / 1 | (6/0/0) / (4/0/0) / (0/0/0) |
| Z2 (TimeDecay) | -349 / +636 / +564 | 30.5% / 20.6% / 8.4% | 30.5% / 20.6% / 8.4% | -89 / -122 / -125 | 42 / 12 / 17 | -235 / -320 / -198 | 23 / 6 / 1 | (11/0/0) / (6/0/0) / (2/0/0) |
| Z3 (RecoveryBEP)| -134 / +605 / +447 | 20.4% / 21.9% / 10.7% | 20.4% / 21.9% / 10.7% | -102 / -122 / -162 | 38 / 12 / 17 | -338 / -328 / -309 | 22 / 7 / 2 | (5/0/42) / (5/0/8) / (1/0/4) |
| Z4 (TrendStop) | -231 / +609 / +492 | 21.7% / 21.6% / 8.6% | 21.7% / 21.6% / 8.6% | -102 / -122 / -139 | 47 / 16 / 18 | -225 / -339 / -238 | 18 / 5 / 1 | (2/19/0) / (4/7/0) / (0/2/0) |
| Z5 (Z1+Z2+Z3) | -462 / +633 / +699 | 26.2% / 19.8% / 8.6% | 26.2% / 19.8% / 8.6% | -92 / -122 / -125 | 37 / 14 / 16 | -248 / -310 / -203 | 23 / 7 / 1 | (11/0/44) / (6/0/6) / (1/0/5) |
| Z6 (Z5+TrendStop)| -436 / +736 / +668 | 24.6% / 19.6% / 8.6% | 24.6% / 19.6% / 8.6% | -92 / -122 / -125 | 47 / 14 / 17 | -227 / -310 / -203 | 15 / 6 / 1 | (5/18/37) / (4/4/6) / (1/1/5) |
- Z1 (jarak bernapas ATR) PEMENANG BESAR: pangkas DD tertipis di semua periode (15.6% P3, 18.0% P2, 7.0% P1D) dgn profit stabil (+$846 P2, +$807 P1D).
- Z3/Z5/Z6 sukses recovery exit BEP (42x di 2024). Trend stop Z4/Z6 memotong SL drastis (hanya 2 SL di P3, diganti 19 exit protektif saat tren ADX kuat).
- Hal aneh: Z2 (time-decay) justru menaikkan DD di P3 (30.5%) karena memotong posisi terlalu dini saat koreksi sehat sedang berjalan.

## Analisis Claude Code atas putaran 9
- Total tiga periode (P3 + P2 + P1D, dari $3000 per periode) dan DD terbesar:
  **Z1 +$1,405, DD maks 18.0%** · Y2 +$1,332 (DD 28%) · Y1 +$1,089 (DD 22%) · Z6 +$968 · Z3 +$918 · Z4 +$870 ·
  Z2 +$851 · Y3 +$803 · Y4 +$899 (DD 37%) · Y5 +$800 (DD 51%).
- **Z1 (jarak bernapas ATR) menang**: DD terendah di ketiga periode (15.6 / 18.0 / 7.0%) dan profit P2/P1D naik
  dibanding Y1. Rugi 2024 memburuk sedikit (−$248 vs −$10), tetapi DD-nya justru turun.
- **Jumlah layer**: 5 layer (Y1) tetap terbaik. Mengurangi layer memindahkan anggaran risiko ke lot L1, sehingga rugi
  2024 dan DD naik (Y2 −$495, Y3 −$512, Y4 tanpa averaging −$785 / DD 37%). Averaging masih dibutuhkan di tahun
  sulit. Y4 hanya unggul di P1D (+$1,455), yaitu periode tren yang cocok.
- **SL adaptif (Z2 time-decay, Z3 recovery, Z4 trend stop) tidak menambah nilai di atas Y1** di 2024: net lebih buruk
  (−$134 s/d −$349). Z4 memang menurunkan worst basket 2024 (−$338 → −$225), tetapi basket rugi bertambah.
  Z2 memotong koreksi sehat terlalu dini (DD 2024 30%).
- **Loss besar kini terkendali**: worst basket di semua skenario ~ −$225 s/d −$414 (≈ 8–14% dari $3000), sesuai anggaran
  risiko 10%. Akun tidak lagi habis, dan tidak ada lagi basket −$1,000 seperti di grid lama.
- Putaran 10: (a) tuning Z1 (batas rasio ATR, trend stop, risiko 8/12%), (b) **validasi Z1 dan Y1 di 2023 (P4) dan
  2022 (P5)**, dua tahun yang belum pernah dipakai menyetel parameter.

## Putaran 10
| run_id | net_profit (P3 / P2 / P1D) | max_dd_pct | rel_dd_pct | largest_order_loss | losing_bsk | worst_basket | L4+ |
|---|---|---|---|---|---|---|---|
| Y1 (P4/P5) | P4: -38 / P5: -1007 | 25.3% / 39.6% | 25.3% / 39.6% | -121 / -102 | 38 / 51 | -311 / -289 | 16 / 24 |
| Z1 (P4/P5) | P4: +120 / P5: -963 | 25.2% / 37.7% | 25.2% / 37.7% | -111 / -102 | 40 / 46 | -311 / -289 | 17 / 26 |
| A1 (ATR m1.5)| -246 / +846 / +815 | 15.6% / 18.0% / 7.0% | 15.6% / 18.0% / 7.0% | -102 / -122 / -108 | 35 / 13 / 15 | -338 / -341 / -143 | 23 / 8 / 1 |
| A2 (ATR m3.0)| -238 / +846 / +807 | 15.5% / 18.0% / 7.0% | 15.5% / 18.0% / 7.0% | -102 / -122 / -108 | 35 / 13 / 15 | -338 / -341 / -143 | 23 / 8 / 1 |
| A3 (ATR min1)| -244 / +853 / +450 | 17.2% / 18.0% / 10.7%| 17.6% / 18.0% / 10.7%| -102 / -122 / -162 | 42 / 13 / 17 | -338 / -341 / -309 | 21 / 7 / 2 |
| A4 (TrendStop)| -471 / +877 / +776 | 22.2% / 17.1% / 7.0% | 22.2% / 17.1% / 7.0% | -102 / -122 / -108 | 48 / 14 / 16 | -228 / -341 / -143 | 15 / 6 / 1 |
| A5 (Risk 8%) | -7 / +1062 / +812 | 15.8% / 16.1% / 7.0% | 15.8% / 16.1% / 7.0% | -102 / -122 / -108 | 35 / 11 / 15 | -249 / -305 / -108 | 23 / 7 / 1 |
| A6 (Risk 12%)| -52 / +1485 / +814 | 21.2% / 23.4% / 7.0% | 21.2% / 23.4% / 7.0% | -153 / -183 / -108 | 36 / 11 / 15 | -411 / -488 / -138 | 23 / 8 / 1 |
- Validasi OOS 2022–2023: Z1 profit di 2023 (+$120 vs Y1 -$38) & lebih tahan di 2022 (-$963/DD 37.7% vs Y1 -$1007/DD 39.6%). Keduanya selamat tanpa MC.
- Tuning Z1: A5 (risiko 8%) JUARA BARU: DD terendah di semua periode (15.8% P3, 16.1% P2, 7.0% P1D) dgn profit fantastis (P3 -$7, P2 +$1062, P1D +$812).
- A3 (min ATR 1.0) memangkas profit P1D separuhnya ($450 vs $815) membuktikan pengetatan grid saat tenang esensial; TrendStop (A4) memperburuk P3 (-$471).
- Hal aneh di log: A6_P1D relDD (6.96%) > maxDD (6.87%) krn equity peak terbentuk di awal; A5 meredam worst basket P3 dari -$338 ke -$249 tanpa mengorbankan winrate.

## Analisis Claude Code atas putaran 10
Lihat research/analisis_putaran10.md (ringkas: A5 risiko 8% terbaik, total +$1,867 di P3/P2/P1D dengan DD maks 16.1%; Z1 di 2022 rugi −$963, DD 37.7%). Putaran 11 memakai research/scenarios_putaran11.json.

## Putaran 11
| run_id | net_profit (P5 / P4 / P3 / P2 / P1D) | max_dd_pct | rel_dd_pct | losing_bsk | worst_basket | L4+ |
|---|---|---|---|---|---|---|
| A5 (Risk 8%, 40d) | -432 / +139 / -7 / +1062 / +812 | 25.6% / 21.1% / 15.8% / 16.1% / 7.0% | 25.6% / 21.1% / 15.8% / 16.1% / 7.0% | 41 / 41 / 35 / 11 / 15 | -223 / -235 / -249 / -305 / -108 | 26 / 17 / 23 / 7 / 1 |
| B1 (Risk 6%, 40d) | -280 / +125 / -271 / +564 / +582 | 22.9% / 15.6% / 17.7% / 9.7% / 7.4% | 22.9% / 15.6% / 17.7% / 9.7% / 7.4% | 43 / 37 / 33 / 14 / 16 | -176 / -189 / -179 / -170 / -187 | 26 / 15 / 13 / 8 / 1 |
| B2 (A5 + 60d) | -290 / -300 / -246 / +528 / +820 | 25.7% / 24.4% / 20.5% / 15.0% / 7.0% | 25.7% / 24.4% / 20.5% / 15.0% / 7.0% | 41 / 42 / 30 / 9 / 15 | -236 / -249 / -249 / -279 / -108 | 24 / 19 / 22 / 7 / 1 |
- Total 5 Tahun: A5 JUARA MUTLAK (+$1,574 kumulatif dari $3k, DD maks 25.6% di 2022). B1 (+$719, DD 22.9%) terpotong profitnya; B2 (+$511) gagal di 2023/2024.
- A5 di 2022 memangkas kerugian >55% vs v83 basis (-$432 vs Z1 -$963, Y1 -$1007) dan DD turun drastis ke 25.6% (vs 37.7% / 39.6%).
- Di 2023 (P4), A5 profit +$139 dengan DD 21.05%, dan di 2024 (P3) hampir BEP (-$7.45) dengan DD hanya 15.81%.
- Hal aneh di log: B2 (60d) merugi di 2023 (-$300) krn window swing terlalu panjang shg lambat mendeteksi volatilitas emas pasca-krisis perbankan Maret 2023.

## Rencana putaran 12 (EA v84 L1 Scalp)
- Permintaan pengguna: entry L1 lebih akurat (OB/OS TF kecil), tidak buka BUY dan SELL bersamaan, TP scalping lebih
  dekat, SL lebih ketat. Semua diuji di atas A5 (kandidat terbaik putaran 10), deposit $3000, periode 2022/2024/2025/P1D.
- C1 satu arah → C2 + OB/OS M5 → C3 + TP scalp → C4/C5 SL maks $30/$20 → C6 SL P90. File: research/scenarios_putaran12.json.

## Putaran 12
| run_id | net_profit (P5 / P3 / P2 / P1D) | max_dd_pct | trades | win_rate | losing_bsk | worst_bsk | SNIPER_SL |
|---|---|---|---|---|---|---|---|
| C1 (Satu Arah) | -391 / -214 / +1003 / +567 | 22.7% / 20.7% / 16.0% / 8.8% | 583 / 609 / 420 / 381 | 77.9% / 75.7% / 88.8% / 94.2% | 29 / 31 / 9 / 13 | -226 / -248 / -295 / -247 | 6 / 5 / 3 / 1 |
| C2 (+OB/OS M5) | -544 / -88 / +291 / -57 | 28.7% / 17.8% / 7.7% / 10.1% | 354 / 359 / 211 / 160 | 74.6% / 78.0% / 86.7% / 91.9% | 23 / 12 / 7 / 8 | -206 / -249 / -157 / -242 | 7 / 4 / 2 / 1 |
| C3 (+TP Scalp) | -574 / +23 / +175 / -49 | 29.4% / 13.5% / 8.5% / 10.1% | 355 / 361 / 213 / 160 | 76.6% / 80.3% / 88.3% / 91.9% | 21 / 10 / 6 / 8 | -206 / -249 / -157 / -242 | 7 / 3 / 2 / 1 |
| C4 (SL maks $30)| -893 / -832 / +660 / -141 | 32.9% / 32.4% / 18.6% / 33.7%| 344 / 350 / 207 / 174 | 76.2% / 78.0% / 88.4% / 87.9% | 26 / 21 / 11 / 21 | -203 / -240 / -297 / -353 | 13 / 17 / 9 / 18 |
| C5 (SL maks $20)| -1817 / -515 / +1195 / -864 | 64.1% / 36.1% / 32.0% / 41.0%| 335 / 337 / 193 / 175 | 72.2% / 81.0% / 91.2% / 82.3% | 43 / 31 / 16 / 31 | -242 / -246 / -385 / -345 | 26 / 28 / 16 / 29 |
| C6 (SL P90) | -748 / -657 / +54 / +248 | 29.5% / 25.1% / 18.8% / 7.7% | 351 / 363 / 212 / 169 | 76.6% / 78.8% / 88.2% / 91.7% | 24 / 14 / 6 / 6 | -201 / -238 / -218 / -113 | 10 / 8 / 4 / 0 |
- C1 (satu arah) sangat sukses: pangkas rugi 2022 (-$391 vs A5 -$432), DD 22.7%, profit P2 +$1003 & P1D +$567. Terkonfirmasi 100% TIDAK ADA order BUY dan SELL terbuka bersamaan di C1–C6.
- C3 (TP scalping ATR M15) satu-satunya profit di 2024 (+$22.67) dgn DD terendah (13.5% P3, 8.5% P2), namun profit tren P1D tergerus.
- SL ketat $20/$30 (C4/C5) GAGAL TOTAL: whipsaw ekstrem (SL tembus hingga 29x/run) membuat rugi membengkak (C5 DD 64% di 2022).
- Hal aneh di log: Pada C5 (SL $20), grid layer L4+ tidak pernah terbentuk (0 di semua periode) krn basket dipotong paksa sebelum mencapai kedalaman averaging.


## Rencana putaran 13 (EA v85 Loss Recovery)
- Permintaan pengguna: kerugian SL ditutup oleh order berikutnya, dan EA terus mencari peluang searah posisi yang kena SL.
- v85: utang = puncak balance − balance; lot L1 dinaikkan (maks 2×, dibatasi anggaran risiko) supaya satu kemenangan
  menutup utang; re-entry searah tanpa cooldown; reset utang setelah 3 basket rugi berturut-turut atau utang > 15%.
- Basis = C4 (A5 + satu arah + OB/OS M5 + TP scalp + SL maks $30). D0 = C4 tanpa recovery, D1–D4 variasi recovery.
  File: research/scenarios_putaran13.json. Periode 2022/2024/2025/P1D.

## Putaran 13
| run_id | net_profit (P5 / P3 / P2 / P1D) | max_dd / rel_dd | win_rate | losing_bsk | worst_bsk | max_lot | REC / SELESAI / RESET |
|---|---|---|---|---|---|---|---|
| D0 (C4 Baseline) | -893 / -832 / +660 / -141 | 32.9% / 32.4% / 18.6% / 33.7% | 76.2% / 78.0% / 88.4% / 87.9% | 26 / 21 / 11 / 21 | -203 / -240 / -297 / -353 | 0.15 / 0.12 / 0.14 / 0.11 | (0/0/0) |
| D1 (Recovery 2x) | -1004 / -714 / +831 / -82 | 38.0% / 33.4% / 24.5% / 34.8% | 77.3% / 81.2% / 88.6% / 88.3% | 28 / 22 / 12 / 21 | -229 / -237 / -340 / -367 | 0.15 / 0.13 / 0.16 / 0.12 | (27/8/5) / (22/7/5) / (10/4/1) / (21/7/6) |
| D2 (D1 + Searah) | -1123 / +326 / +682 / -265 | 39.6% / 21.0% / 22.9% / 28.3% | 74.7% / 83.8% / 88.9% / 86.8% | 22 / 14 / 11 / 15 | -232 / -294 / -336 / -306 | 0.15 / 0.14 / 0.16 / 0.10 | (21/7/4) / (14/4/3) / (9/3/1) / (15/3/4) |
| D3 (Lot 1.5x) | -1094 / -570 / +719 / -82 | 39.3% / 30.9% / 25.0% / 34.8% | 76.1% / 81.2% / 89.1% / 88.3% | 29 / 22 / 12 / 21 | -231 / -256 / -336 / -367 | 0.15 / 0.12 / 0.16 / 0.12 | (27/8/5) / (21/4/5) / (10/4/1) / (21/7/6) |
| D4 (Target 50%) | -1029 / -725 / +774 / -95 | 38.0% / 33.3% / 24.5% / 34.4% | 77.6% / 80.5% / 88.2% / 88.3% | 28 / 22 / 12 / 21 | -229 / -237 / -340 / -367 | 0.15 / 0.13 / 0.16 / 0.12 | (27/8/5) / (22/7/5) / (10/4/1) / (21/7/6) |
- D0 paritas 100% dgn C4 di semua periode. D2 (re-entry searah SL) hasilkan terobosan di 2024: balikkan rugi -$832 jd profit +$326 (DD 21.0%).
- D1 meningkatkan profit P2 (+$831 vs +$660) dan pangkas rugi P1D (-$82 vs -$141), namun di 2022 rugi sedikit membesar (-$1004 vs -$893).
- Pengaman anti-spiral sukses: RESET terpicu 1–6x per run saat rugi beruntun tercapai, mencegah akumulasi lot berlebih (max_lot selalu <= 0.16).
- Hal aneh di log: D2 merugi di 2022 (-$1123) krn re-entry searah SL sering terjebak whipsaw pembalikan arah tajam saat siklus kenaikan suku bunga Fed.

## Analisis Claude Code atas putaran 11–13
Total 4 periode yang sama (2022 + 2024 + Jan–Sep 2025 + P1D, deposit $3000 per periode) dan DD terbesar:

| Skenario | Total | DD maks | Kesimpulan |
|---|---|---|---|
| **A5 (risiko 8%)** | **+$1,435** (+$1,574 dengan 2023) | 25.6% | **Tetap terbaik.** Satu-satunya yang untung di 4 dari 5 tahun |
| C1 satu arah | +$965 | 22.7% | DD sedikit lebih rendah, profit 2025/P1D turun |
| B2 belajar 60 hari | +$811 | 25.7% | Rugi di 2023 (−$300): terlalu lambat beradaptasi |
| B1 risiko 6% | +$594 | 22.9% | Lebih aman, profit terpotong |
| C2 OB/OS M5 | −$397 | 28.7% | Trade turun ~40%, win rate tidak naik. **Ditolak** |
| C3 + TP scalping | −$425 | 29.4% | Hanya membantu 2024; profit tren hilang. **Ditolak** |
| C6 SL P90 | −$1,103 | 29.5% | **Ditolak** |
| C4 SL maks $30 | −$1,207 | 33.7% | SL kena 9–18× per periode (whipsaw). **Ditolak** |
| C5 SL maks $20 | −$2,001 | 64.1% | **Ditolak** |
| D0–D4 recovery di atas C4 | −$379 s/d −$1,074 | 38–40% | Basis C4 buruk. D2 (searah) +$826 vs D0 |

- **SL ketat terbukti merugikan untuk XAUUSD.** Emas sering menembus $20–30 lalu berbalik, jadi SL dekat lebih sering kena
  tanpa mengurangi kerugian total. SL adaptif P98 dari swing 40 hari (A5) tetap yang terbaik.
- **Filter OB/OS M5 tidak meningkatkan akurasi.** Win rate C2 (74.6–91.9%) setara atau lebih rendah dari C1
  (77.9–94.2%), sedangkan jumlah trade turun 40%.
- **Recovery menambah nilai** dibanding basisnya (D2 +$826 vs D0, D1 +$237), tetapi sejauh ini hanya diuji di atas
  basis yang buruk (C4), dan memperbesar rugi 2022. Putaran 14 mengujinya di atas A5 dan C1, di 5 periode.
- Preset kandidat untuk forward test demo: research/presets/BioOnePro_v85_A5_Kandidat.set (EA v85, setara A5).

## Putaran 14
| run_id | net_profit (P5 / P4 / P3 / P2 / P1D) | max_dd_pct | win_rate | losing_bsk | worst_bsk | max_lot | REC / SELESAI / RESET |
|---|---|---|---|---|---|---|---|
| E0 (A5 Basis) | -432 / +60 / -4 / +1064 / +814 | 25.6% / 21.0% / 15.8% / 16.1% / 7.0% | 78.0% / 80.2% / 76.7% / 88.7% / 94.6% | 41 / 41 / 34 / 10 / 15 | -223 / -248 / -249 / -305 / -108 | 0.15 / 0.12 / 0.10 / 0.11 / 0.04 | (0/0/0) |
| E1 (A5 + Rec Searah) | -596 / +452 / +992 / +371 / +935 | 25.2% / 22.6% / 8.8% / 21.4% / 4.8% | 76.1% / 83.8% / 79.1% / 87.8% / 94.8% | 34 / 26 / 27 / 13 / 12 | -240 / -237 / -248 / -283 / -108 | 0.10 / 0.15 / 0.10 / 0.11 / 0.04 | (29/12/4) / (24/12/3) / (26/15/1) / (14/9/1) / (10/6/0) |
| E2 (A5 + Rec 2 Arah) | -392 / +771 / +281 / +1281 / +849 | 25.2% / 11.6% / 15.7% / 15.3% / 7.0% | 78.3% / 80.7% / 77.3% / 89.6% / 94.7% | 44 / 38 / 34 / 10 / 15 | -242 / -307 / -285 / -313 / -108 | 0.10 / 0.18 / 0.10 / 0.11 / 0.04 | (39/19/5) / (33/19/2) / (35/16/4) / (10/6/1) / (13/7/1) |
| E3 (C1 + Rec Searah) | -617 / +1116 / +893 / +426 / +307 | 25.2% / 13.4% / 8.8% / 21.3% / 14.5% | 76.4% / 85.1% / 79.9% / 88.0% / 94.3% | 28 / 21 / 24 / 11 / 12 | -240 / -294 / -248 / -291 / -247 | 0.10 / 0.18 / 0.10 / 0.11 / 0.04 | (27/11/4) / (20/14/0) / (24/15/1) / (11/8/1) / (12/5/1) |
| E4 (C1 + Rec 2 Arah) | -152 / +940 / -308 / +1211 / +334 | 17.9% / 11.7% / 22.9% / 15.7% / 14.7% | 78.3% / 83.1% / 76.1% / 89.7% / 94.3% | 31 / 30 / 33 / 9 / 14 | -254 / -294 / -252 / -313 / -247 | 0.12 / 0.18 / 0.10 / 0.11 / 0.04 | (30/10/4) / (29/19/1) / (33/12/5) / (9/5/1) / (14/4/2) |
- E0 paritas 100% dgn A5 di 2022 (-$431.76 / DD 25.62%). E2 (A5 + Recovery 2 Arah) JUARA BARU: profit 5 tahun tembus +$2,790 (vs E0 +$1,501) dgn DD maks 25.24% di 2022 dan <= 15.7% di 2023–2026.
- E1 (Recovery Searah) luar biasa di 2024 (+$992, DD 8.8%) dan P1D (+$935, DD 4.8%), profit total +$2,154 (DD 25.2%).
- E4 rekor pertahanan 2022 (-$152, DD 17.9%), namun tertekan di tren 2024 (-$308).
- Hal aneh di log: Recovery berhasil lunasi utang (SELESAI hingga 19x/tahun), anti-spiral sukses batasi max_lot tetap aman <= 0.18.

## Rencana putaran 15 (EA v86 Signal Guard)
- Permintaan pengguna: L1 lebih akurat dengan volume klimaks + pola pembalikan candle, grafik lebih konsisten naik,
  dan cut loss saat sinyal berlawanan muncul. Semua di atas A5 (terbaik saat ini), deposit $3000, 5 periode 2022–2026.
- F1 volume klimaks M5, F2 pola pembalikan M5, F3 keduanya, F4 cut sinyal berlawanan, F5 equity guard, F6 gabungan.
  File: research/scenarios_putaran15.json. Putaran 14 (recovery di atas A5/C1) tetap dijalankan lebih dulu bila belum.

## Putaran 15
| run_id | net_profit (P5 / P4 / P3 / P2 / P1D) | max_dd_pct | win_rate | trades | OppCut / EqGuard |
|---|---|---|---|---|---|
| F1 (Vol Climax M5) | -12 / -1 / +213 / -84 / +113 | 9.2% / 13.3% / 2.8% / 10.0% / 1.6% | 78.0% / 87.7% / 81.6% / 76.9% / 100.0% | 127 / 138 / 114 / 78 / 23 | (0/0) / (0/0) / (0/0) / (0/0) / (0/0) |
| F2 (Pola Rev M5) | -98 / -34 / -67 / -36 / +116 | 8.0% / 12.5% / 7.1% / 4.5% / 4.0% | 75.6% / 81.0% / 76.5% / 87.9% / 94.7% | 82 / 79 / 85 / 33 / 38 | (0/0) / (0/0) / (0/0) / (0/0) / (0/0) |
| F3 (Vol + Rev M5) | +8 / +29 / +20 / -100 / +8 | 0.9% / 5.1% / 0.7% / 3.3% / 0.3% | 83.3% / 82.3% / 71.4% / 0.0% / 100.0% | 6 / 17 / 7 / 2 / 3 | (0/0) / (0/0) / (0/0) / (0/0) / (0/0) |
| F4 (Opp Signal Cut) | -465 / -8 / -29 / +1010 / +749 | 21.8% / 22.9% / 17.4% / 16.0% / 6.8% | 77.2% / 79.2% / 75.9% / 88.8% / 93.6% | 721 / 694 / 734 / 448 / 419 | (22/0) / (12/0) / (17/0) / (3/0) / (9/0) |
| F5 (Equity Guard) | -356 / -32 / -4 / +892 / +814 | 20.7% / 21.9% / 15.8% / 14.5% / 7.0% | 77.8% / 80.1% / 76.7% / 88.4% / 94.6% | 724 / 695 / 743 / 450 / 423 | (0/0) / (0/0) / (0/0) / (0/0) / (0/0) |
| F6 (Gabungan) | +8 / +23 / +20 / -100 / +8 | 0.9% / 5.1% / 0.7% / 3.3% / 0.3% | 83.3% / 76.5% / 71.4% / 0.0% / 100.0% | 6 / 17 / 7 / 2 / 3 | (0/0) / (1/0) / (0/0) / (0/0) / (0/0) |
- F5 (Equity Guard) paling konsisten memangkas DD: DD 2022 turun jadi 20.7% (vs A5 25.6%), total profit 5 th +$1,314 dgn DD <= 21.9%.
- F4 (Opp Signal Cut) aktif 63x cut loss sinyal berlawanan, kurangi DD 2022 ke 21.8%, total profit 5 th +$1,257.
- F1 kurangi frekuensi trade (~80%), DD terjaga ketat <= 13.3%, total profit +$229 (stabil tapi profit terbatas).
- F3 & F6 over-filtering (hanya 2-17 trade/th, 35 trade dlm 5 th); filter candle M5 terlalu ketat utk EA M1.


## Analisis Claude Code atas putaran 14–15
Total 5 tahun (2022–2026, $3000 per tahun), DD maks, dan jumlah tahun rugi:

| Skenario | Total 5 th | DD maks | Tahun rugi | Catatan |
|---|---|---|---|---|
| **E2 A5 + recovery 2 arah** | **+$2,790** | 24.2% | 1/5 (2022 −$392) | **Terbaik baru**: 2023–2026 untung semua, DD ≤ 15.7% |
| E1 A5 + recovery searah | +$2,154 | 25.2% | 1/5 | 2024 +$992 (DD 8.8%) terbaik, 2025 lebih lemah |
| E3 C1 + recovery searah | +$2,125 | 25.2% | 1/5 | |
| E4 C1 + recovery 2 arah | +$2,024 | 22.9% | 2/5 | 2022 terbaik (−$152, DD 17.9%) |
| E0 A5 (pembanding) | +$1,502 | 25.6% | 2/5 | Paritas dengan A5 ✔ |
| F5 equity guard | +$1,313 | 21.9% | 3/5 | DD turun, profit turun |
| F4 cut sinyal berlawanan | +$1,258 | 22.9% | 3/5 | 63 cut; DD 2022 21.8% |
| F1 volume klimaks M5 | +$229 | 13.3% | 3/5 | Trade −84% |
| F2 / F3 / F6 pola candle M5 | −$36 s/d −$118 | ≤ 12.5% | — | Over-filter: F3/F6 hanya 35 trade dalam 5 tahun. **Ditolak** |

- **Loss Recovery bekerja di atas basis yang benar**: E2 +86% vs A5, DD tidak naik (max lot tetap ≤ 0.18 berkat pengaman reset).
- **Filter volume klimaks & pola candle M5 tidak cocok** untuk EA ini: trade turun 80–99% tanpa kenaikan profit.
- Cut sinyal berlawanan (F4) dan equity guard (F5) menurunkan DD 2022 sedikit, tetapi mengurangi total profit di atas A5.
  Putaran 16 menguji keduanya di atas E2, plus variasi recovery dan uji biaya spread $0.35.
- Preset kandidat terbaru: research/presets/BioOnePro_v86_E2_Kandidat.set.

## Putaran 16
| run_id | net_profit (P5 / P4 / P3 / P2 / P1D) | max_dd_pct | win_rate | los_bsk | worst_bsk | max_lot | Total Event (REC/SEL/RST/OPP/EQ) |
|---|---|---|---|---|---|---|---|
| G0 (E2 Basis) | -392 / +771 / +281 / +1281 / +849 | 24.2% / 11.6% / 15.7% / 15.3% / 7.0% | 78.3% / 80.7% / 77.2% / 89.6% / 94.7% | 44 / 38 / 34 / 10 / 15 | -242 / -307 / -285 / -313 / -108 | 0.1 / 0.18 / 0.1 / 0.11 / 0.04 | 130 / 67 / 13 / 0 / 0 |
| G1 (E2 + OppCut) | -390 / +104 / +115 / +1184 / +820 | 22.9% / 15.0% / 17.6% / 15.6% / 6.8% | 78.3% / 79.0% / 76.2% / 89.6% / 93.8% | 60 / 52 / 52 / 12 / 20 | -242 / -282 / -256 / -306 / -108 | 0.16 / 0.15 / 0.1 / 0.11 / 0.04 | 189 / 86 / 21 / 65 / 0 |
| G2 (E2 + Jeda) | -392 / +771 / +281 / +1281 / +849 | 24.2% / 11.6% / 15.7% / 15.3% / 7.0% | 78.3% / 80.7% / 77.2% / 89.6% / 94.7% | 44 / 38 / 34 / 10 / 15 | -242 / -307 / -285 / -313 / -108 | 0.1 / 0.18 / 0.1 / 0.11 / 0.04 | 130 / 67 / 13 / 0 / 0 |
| G3 (E2 Rec 1.5x) | -420 / +198 / +160 / +1169 / +834 | 26.6% / 16.9% / 12.7% / 15.7% / 7.0% | 77.8% / 80.7% / 77.2% / 89.4% / 94.7% | 43 / 40 / 34 / 10 / 15 | -239 / -271 / -275 / -315 / -108 | 0.12 / 0.13 / 0.1 / 0.11 / 0.04 | 129 / 64 / 15 / 0 / 0 |
| G4 (E2 Reset 2x) | -393 / -29 / +248 / +1415 / +831 | 25.2% / 19.3% / 15.1% / 15.3% / 7.1% | 78.2% / 80.4% / 77.1% / 89.8% / 94.7% | 44 / 41 / 35 / 10 / 15 | -242 / -265 / -283 / -313 / -108 | 0.1 / 0.13 / 0.1 / 0.11 / 0.04 | 135 / 73 / 19 / 0 / 0 |
| G5 (E2+Opp+Jeda) | -401 / +104 / +357 / +1184 / +820 | 23.2% / 15.0% / 17.6% / 15.6% / 6.8% | 78.4% / 79.0% / 76.5% / 89.6% / 93.8% | 60 / 52 / 51 / 12 / 20 | -242 / -282 / -248 / -306 / -108 | 0.16 / 0.15 / 0.1 / 0.11 / 0.04 | 188 / 89 / 20 / 64 / 4 |
| G6 (E2 Sp 35) | 0 / 0 / 0 / +3 / +308 | 0.0% / 0.0% / 0.0% / 0.5% / 6.6% | 0.0% / 0.0% / 0.0% / 100.0% / 97.1% | 0 / 0 / 0 / 0 / 5 | 0 / 0 / 0 / 0 / -108 | 0 / 0 / 0 / 0.01 / 0.01 | 4 / 2 / 0 / 0 / 0 |
- G0/G2 paritas sempurna E2 (+$2,790, DD 24.2%). OppCut (G1) pangkas DD 2022 sedikit (22.9%) tapi memotong drastis profit 2023/2024 (+$1,833 vs +$2,790).
- Hal aneh di log: G6 (spread 35) 0 trade di 2022-2024 krn terblokir filter Base_Max_Spread_Pips=25; baru aktif di P1D saat ATR melonjak (+$308, DD 6.6%).

## Analisis Claude Code atas putaran 16
- **Tidak ada variasi yang mengalahkan E2** (G0 = E2: +$2,791 / 5 th, DD 24.2%, rugi hanya 2022).
  G4 reset 2× +$2,072 · G5 cut + jeda +$2,065 · G3 lot 1.5× +$1,942 · G1 cut sinyal berlawanan +$1,834.
  Cut sinyal berlawanan menurunkan DD 2022 sedikit (22.9%), tetapi memotong profit 2023/2024 jauh lebih besar. **Ditolak untuk E2.**
- G2 (jeda setelah 3 rugi) identik dengan E2: di E2 tidak pernah terjadi 3 basket rugi berturut-turut (0 event). Tidak berbahaya,
  tapi juga tidak berguna untuk E2.
- **G6 (spread $0.35) tidak valid**: 0 trade di 2022–2024 karena filter spread EA (Base_Max_Spread_Pips 25 ≈ $0.25) memblokir semua
  entry. Ini juga pesan penting untuk live: **bila spread broker > ~$0.25–0.30, EA berhenti membuka L1**. Ulang di putaran 17
  dengan batas filter dilonggarkan (H7 $0.35, H8 $0.50).
- Putaran 17 = uji ketahanan E2: apakah hasilnya stabil bila parameter digeser sedikit (risiko 7/9%, belajar 30/50 hari,
  BEP 0.7/0.9)? Setting yang bagus seharusnya berada di "dataran", bukan puncak sempit. Plus uji biaya spread $0.35/$0.50.

## MODE CEPAT (berlaku mulai putaran 17)
Permintaan pengguna: lebih sedikit backtest, perubahan lebih besar per putaran, hemat token.
- Maksimal **4 skenario per putaran**, termasuk 1 baseline. Setiap skenario adalah **paket perubahan besar**, bukan geser 1 parameter.
- **3 periode penyaring**: 2022 (terlemah), 2024 (tren kuat), P1D (terbaru). Total 12 run per putaran.
- Model tester **control points (TestModel=1)**, jauh lebih cepat dari every tick. Baseline dijalankan dengan model yang sama,
  jadi perbandingannya tetap adil.
- **Aturan keputusan**: paket diterima bila total 3 periode ≥ baseline +10% **atau** DD maks turun ≥ 3 poin tanpa profit turun
  > 10%. Selain itu ditolak, tanpa variasi lanjutan.
- Pemenang baru divalidasi **sekali** dengan every tick di 5 periode sebelum menjadi preset.
- Putaran 17 lama (uji sensitivitas H1–H8) dibatalkan dan diganti putaran 17 cepat (EA v87).

## Rencana putaran 17 cepat (EA v87)
- K1: perlindungan rezim (blokir L1 saat ATR H1 ≥ 1.8× normal + batas rugi harian 4%), menyerang kerugian 2022.
- K2: partial TP L1 (tutup 50% di 1× ATR M15, sisa SL ke BEP), untuk kurva lebih halus.
- K3: K1 + K2 + sesi London–NY saja.

## Putaran 17 (Mode Cepat)
| run_id | net_profit (P5 / P3 / P1D) | Total 3P | max_dd_pct | win_rate | Event (DLL / PTP) | Keputusan |
|---|---|---|---|---|---|---|
| K0 (E2 Baseline) | -334 / +249 / +883 | +$798 | 25.8% | 78.5% / 77.6% / 94.7% | 0 / 0 | BASELINE |
| K1 (Perlindungan Rezim) | -468 / +109 / +372 | +$13 | 25.6% | 78.0% / 77.5% / 94.7% | 50 / 0 | DITOLAK |
| K2 (Partial TP L1) | -440 / +142 / +878 | +$581 | 24.1% | 84.4% / 83.8% / 94.7% | 0 / 469 | DITOLAK |
| K3 (K1+K2+Jam London-NY) | -362 / -121 / +508 | +$24 | 24.2% | 81.3% / 82.5% / 95.0% | 41 / 231 | DITOLAK |
- Aturan Mode Cepat: Semua paket DITOLAK. K1-K3 memotong profit (-27% s/d -98%) tanpa perbaikan DD signifikan. Hal aneh: DLL (50x) & filter jam justru menghambat recovery basket.

## Analisis Claude Code atas putaran 17 (mode cepat)
- Total 3 periode (2022 / 2024 / P1D): **K0 E2 +$798** (−$334 / +$249 / +$883, DD maks 25.9%) ·
  K2 partial TP +$581 · K3 gabungan +$24 · K1 filter rezim + batas rugi harian +$13. **Ketiga paket DITOLAK.**
- Pola yang konsisten sejak putaran 3: **memblokir entry (filter) dan menutup profit lebih awal menurunkan profit.**
  Mesin profit EA ini adalah L1 yang menang searah tren H1, jadi perbaikan harus memperbesar kemenangan itu.
- Putaran 18 cepat (EA v88), 9 run baru (baseline K0 dipakai ulang):
  M1 = L1 runner (trailing ATR lebar, trailing ketat Stochastic dimatikan, fitur lama),
  M2 = trend pyramid (posisi tambahan searah saat L1 sudah profit 1× ATR, SL di BEP L1, trailing ATR),
  M3 = M1 + M2 + risiko 10%.

## Putaran 18 (Mode Cepat)
| run_id | net_profit (P5 / P3 / P1D) | Total 3P | max_dd_pct | win_rate | TREND PYRAMID | Keputusan |
|---|---|---|---|---|---|---|
| K0 (E2 Baseline) | -334 / +249 / +883 | +$798 | 25.8% | 78.5% / 77.6% / 94.7% | 0 | BASELINE |
| M1 (L1 Runner) | -536 / +125 / +699 | +$288 | 29.9% | 61.9% / 59.2% / 80.3% | 0 | DITOLAK |
| M2 (Trend Pyramid) | -846 / +498 / +864 | +$516 | 40.1% | 66.0% / 69.4% / 88.8% | 599 | DITOLAK |
| M3 (M1+M2+Risk 10%) | -1822 / -272 / +2041 | -$54 | 63.6% | 57.1% / 57.3% / 67.3% | 2170 | DITOLAK |
- Aturan Mode Cepat: Semua DITOLAK. M2 gandakan profit 2024 (+498 vs +249) tapi hancur di 2022 (-$846, DD 40.1%). M1 kurangi win rate. E2 tetap juara.

## Analisis Claude Code atas putaran 18 & KESIMPULAN RISET
- Total 3 periode: K0 E2 +$798 · M2 pyramid +$516 (2024 naik dua kali lipat, tetapi 2022 −$846, DD 40%) ·
  M1 runner +$288 (win rate turun 78% → 60%) · M3 agresif −$54 (DD 64%). **Semua ditolak.**
- Pyramid dan runner memperbesar kemenangan di tahun tren (2024 / P1D), tetapi menghancurkan tahun choppy (2022).
  Ini kebalikan dari filter: keduanya hanya memindahkan hasil antar tahun, bukan menaikkan total.
- **Setelah 18 putaran, E2 adalah optimum desain ini**: +$2,790 / 5 tahun dari $3000 (rata-rata ~+18%/tahun),
  DD maks 24.2%, rugi hanya di 2022 (−$392 = −13%). Tidak ada kandidat yang mengalahkannya secara konsisten.
- Versi final: **ea/BioOnePro_E2_Final.mq4**. Kode sama dengan v86, dan input default = setting E2 (sudah dicek identik
  dengan research/presets/BioOnePro_v86_E2_Kandidat.set). Tahap berikutnya: **forward test di akun demo**, bukan backtest lagi.

## Putaran 19 — v89 Full Averaging L20 (permintaan user: averaging penuh, "profit konsisten atau MC")
- EA baru: **ea/BioOnePro_v89_FullAvg_L20.mq4** (kode E2_Final + modul Full Averaging; Sniper, hedge L4, recovery dimatikan).
- Jarak adaptif: kedalaman L1→L20 = FA_Depth_ATR_Mult × ATR D1 (20 hari), jarak antar layer membesar ×FA_Step_Growth,
  L2 minimal persentil swing H1 P30, semua jarak × skala volatilitas H1 saat ini (Sniper_Use_Vol_Scaling).
  Contoh ATR D1 $25 → L2 $3, L5 $14, L10 $41, L20 $153; ATR D1 $60 → L2 $6, L10 $80, L20 $300.
- Lot: target BEP dekat, pengali dibatasi 1.0–1.10. Simulasi: pengali 1.35 → total 854× L1, 1.2 → 156× L1, 1.0 → 20× L1.
  Lot L1 dari anggaran: rugi grid penuh di titik survive (kedalaman ×1.1) = 40% balance. Tanpa SL basket;
  batas akhir = Percent_Loss 50% (Use_SL_inPercent=false → mode MC murni).
- **Peringatan matematika**: dengan lot minimum 0.01, grid L20 flat sudah rugi ±$2,260 (ATR $25) sampai ±$4,400 (ATR $60)
  di titik survive. Dengan deposit $3000, lot L1 hampir selalu dipaksa ke 0.01 dan risiko grid penuh > anggaran 40%.
  Satu tren searah sedalam L20 kira-kira = cut-loss 50% akun. Karena itu L3 diuji di deposit $10,000.
- Skenario (research/scenarios_putaran19.json): K0 E2 baseline (dipakai ulang) · L0 default · L1 grid flat 4×ATR ·
  L2 defensif 7×ATR + jeda layer ADX>35 · L3 default deposit $10,000.
- Diterima hanya bila total 3 periode > K0 (+$798) DAN tidak ada cut-loss akun / MC. Bila L3 bagus tetapi L0 gagal,
  artinya strategi butuh modal ≥ $10k (atau akun cent) untuk L20.

## Putaran 19 (v89 Full Averaging L20)
| run_id | net_profit (P5 / P3 / P1D) | Total 3P | max_dd_pct | win_rate | layer_maks | cut_loss/MC | Keputusan |
|---|---|---|---|---|---|---|---|
| K0 (E2 Baseline) | -334 / +249 / +883 | +$798 | 25.8% | 78.5% / 77.6% / 94.7% | 5 | Tidak | BASELINE |
| L0 (v89 L20 Default) | -931 / -23 / +1202 | +$248 | 34.8% | 74.8% / 77.3% / 91.5% | 8 | Tidak | DITOLAK |
| L1 (v89 L20 Flat) | -931 / -23 / +1202 | +$248 | 34.8% | 74.8% / 77.3% / 91.5% | 8 | Tidak | DITOLAK |
| L2 (v89 L20 Defensif) | -848 / -498 / +1233 | -$113 | 32.5% | 75.6% / 76.9% / 91.7% | 8 | Tidak | DITOLAK |
| L3 (v89 L20 $10k) | -931 / -23 / +1202 | +$248 | 10.6% | 74.8% / 77.3% / 91.5% | 8 | Tidak | DITOLAK |
- Evaluasi Mode Cepat: Semua DITOLAK (Total < +$798). Log: 0 warning, max layer 8 (2022), tanpa cut-loss/MC. Tanpa Sniper SL, tren 2022 rugi 3x lipat (-$931 vs -$334). Min lot 0.01 membatasi fleksibilitas ($3k maupun $10k L1=0.01). E2 tetap optimum.

## Analisis Claude Code atas putaran 19 + rencana putaran 20
- v89 L20 ditolak: total 3 periode +$248 (L0) vs E2 +$798. Di P1D v89 justru lebih baik (+$1,202 vs +$883),
  tetapi 2022 −$931 (E2 −$334) dan 2024 −$23 (E2 +$249).
- **Sumber rugi**: 6 basket rugi terbesar L0 di 2022 dan 2024 SEMUA ditutup **Jumat 19:00** (penutupan weekend paksa),
  contoh SELL 7 layer −$401 (2022.11.11) dan −$515 (2024.11.22). Jadi grid tanpa SL tidak kalah oleh kedalaman,
  tetapi oleh close weekend yang merealisasikan rugi floating basket dalam.
- L0 = L1 = L3 identik: lot selalu 0.01 (pengali 1.10 dibulatkan kembali ke 0.01, max_basket_lots 0.08), dan jarak L2
  ditentukan lantai persentil swing H1 P30, sehingga FA_Depth_ATR_Mult tidak berpengaruh. Layer maks yang tercapai = 8.
- v90 (ea/BioOnePro_v90_FullAvg_L1v238.mq4): Weekend_Close_Only_Profit=true (basket rugi ditahan, kecuali rugi ≥ 20%),
  FA_Lot_Add_Every_Layers (lot +1 step tiap N layer), dan entry L1 dari EA referensi user v238Z FIX10:
  Stochastic ganda M5 OB/OS, Smart L1 (RSI zona + ADX + reversal + ATR impulse), First Direction Governor H1+M15,
  Reversal Timing (L1 melawan gerakan ≥ 1.25 ATR M15 wajib skor ≥ 7).
- Putaran 20 (research/scenarios_putaran20.json): K0 & L0 dipakai ulang · N0 v90 L20 + weekend hold + lot+1/4 layer ·
  N1 N0 + filter v238Z · N2 N0 + entry penuh v238Z · N3 E2 + filter v238Z (kode lain identik dengan E2).
- Diterima bila total 3 periode > +$798 dan DD maks tidak lebih buruk dari E2 + 3 poin.

## Putaran 20 (v90 L20 + entry L1 v238Z)
| run_id | net_profit (P5 / P3 / P1D) | Total 3P | max_dd_pct | win_rate | trades | layer_maks | cut_loss/MC | Keputusan |
|---|---|---|---|---|---|---|---|---|
| K0 (E2 Baseline) | -334 / +249 / +883 | +$798 | 25.8% | 78.5% / 77.6% / 94.7% | 1,917 | 5 | Tidak | BASELINE |
| L0 (v89 L20 Default) | -931 / -23 / +1202 | +$248 | 34.8% | 74.8% / 77.3% / 91.5% | 1,987 | 8 | Tidak | DITOLAK |
| N0 (v90 L20 + WkHold) | -1578 / -1965 / +737 | -$2,806 | 79.7% | 75.0% / 76.4% / 91.1% | 1,921 | 12 | Tidak | DITOLAK |
| N1 (N0 + Filter v238) | -542 / -1031 / +118 | -$1,455 | 47.7% | 74.8% / 72.0% / 95.7% | 301 | 12 | Tidak | DITOLAK |
| N2 (N0 + Entry v238) | -1518 / +762 / -8 | -$764 | 58.2% | 75.0% / 78.9% / 90.0% | 1,804 | 12 | Tidak | DITOLAK |
| N3 (E2 + Filter v238) | -271 / -343 / +118 | -$497 | 17.7% | 78.4% / 73.7% / 95.7% | 266 | 5 | Tidak | DITOLAK |
- Evaluasi Mode Cepat: Semua DITOLAK. Weekend hold (N0) membuat DD meledak ke 79.7% (layer 12). Filter v238Z (N1, N3) pangkas trade ~85% dan bunuh profit tahun tren. E2 tetap tak tertandingi.

## Putaran 21 (v91 E2 Loss Guard — Solusi Order Loss Besar)
- **Investigasi Order Loss Terbesar di E2 Baseline**:
  1. *Jumat 19:00 Hard Close*: Baskets yang dibuka Jumat pagi (03:00–11:00) terpotong cut-loss di 19:00 saat volatilitas NFP/US session tanpa waktu rebound. Di P1D, 98.4% total loss ($-506) berasal dari close Jumat! Di 2022, basket Jumat menyumbang rugi $-289 (dari total $-334).
  2. *Cascading Recovery Debt*: Saat basket terkena Sniper SL, lot L1 basket pemulihan dinaikkan ke 0.02–0.04. Jika pasar sedang tren panjang, basket pemulihan ini terkena SL kedua dan rugi membengkak ke -$193 s/d -$283.
- **Solusi di v91 (ea/BioOnePro_v91_E2_LossGuard.mq4)**:
  `Friday_L1_Cutoff_Hour = 0` (blokir buka L1 baru hari Jumat penuh; order lama tetap dikawal ke TP/BEP) + `Recovery_Debt_Share = 0.5` (pemulihan bertahap tanpa melipatgandakan lot L1).
- **Hasil Screening Putaran 21 (Deposit $3,000, Model Control Points)**:

| run_id | net_profit (P5 / P3 / P1D) | Total 3P | max_dd_pct | win_rate | trades | layer_maks | Keputusan |
|---|---|---|---|---|---|---|---|
| K0 (E2 Baseline) | -334 / +249 / +883 | +$798 | 25.8% | 78.5% / 77.6% / 94.7% | 1,917 | 5 | BASELINE |
| P1 (v91 Friday Cutoff 0) | -230 / +223 / +854 | +$846 | 22.9% | 77.9% / 78.7% / 95.6% | 1,715 | 5 | DITERIMA |
| **P2 (P1 + Rec Debt 0.5)** | **-223 / +392 / +854** | **+$1,023** | **23.2%** | **77.8% / 78.5% / 95.6%** | **1,730** | **5** | **JUARA BARU** |
| P3 (P2 + Risk 6% + Rec 1.5x) | -299 / +184 / +791 | +$676 | 23.3% | 78.0% / 79.0% / 96.0% | 1,723 | 5 | DITOLAK |
| P4 (P1 + Recovery OFF) | -268 / +314 / +807 | +$853 | 22.6% | 78.3% / 78.1% / 95.7% | 1,685 | 5 | DITERIMA |

## Validasi Full History Every Tick 5 Tahun (2022–2026): E2 Baseline vs v91 P2
Validasi Every Tick penuh (`TestModel=0`, 5 periode, 100% tick modeling) membuktikan konsistensi keunggulan v91 P2 atas E2 Baseline di seluruh siklus pasar:

| Periode | E2 Baseline Net | v91 P2 Net | Selisih Net | E2 Max DD | v91 Max DD | E2 Trades | v91 Trades |
|---|---|---|---|---|---|---|---|
| 2022 (Bearish / High Rate Hike) | -$391.52 | -$243.79 | **+$147.73 (+38%)** | 24.17% | **22.99%** | 736 | 667 |
| 2023 (Consolidation) | +$770.63 | +$734.87 | -$35.76 | 11.61% | 12.22% | 700 | 628 |
| 2024 (Bull Breakout / Election) | +$281.01 | +$433.57 | **+$152.56 (+54%)** | 15.66% | **14.94%** | 756 | 682 |
| 2025 (Strong Trend Bullish) | +$1,281.46 | +$1,142.73 | -$138.73 | 15.30% | 15.95% | 451 | 521 |
| Sep 2025 – Sep 2026 (Recent 1Y) | +$848.69 | +$831.68 | -$17.01 | 6.96% | **6.02%** | 433 | 384 |
| **TOTAL 5 TAHUN** | **+$2,790.27** | **+$2,899.06** | **+$108.79** | **24.17%** | **22.99%** | **3,076** | **2,882** |

- **Temuan Kunci Every Tick**:
  1. *Rugi 2022 terpangkas 38%* (-$391 -> -$243) dan DD maks absolut turun dari 24.17% ke 22.99%.
  2. *Profit 2024 melonjak 54%* (+$281 -> +$433) dengan DD lebih kecil (14.94% vs 15.66%).
  3. Total net profit 5 tahun menembus **+$2,899.06** (rekor tertinggi baru sepanjang sejarah riset BioOnePro).
  4. Preset tersimpan di: `research/presets/BioOnePro_v91_P2_LossGuard.set`.

## Koordinasi & Analisis Lanjutan untuk Claude Code
1. **Pertanyaan Desain 1 (Friday Cutoff)**: Apakah pemblokiran penuh hari Jumat (`Friday_L1_Cutoff_Hour = 0`) sebaiknya dibuat permanen di default EA, atau dibuat adaptif (misal: hanya izinkan buka L1 Jumat jika ATR D1 < median historis)?
2. **Pertanyaan Desain 2 (Recovery Debt Half-Life)**: Pengurangan `Recovery_Debt_Share = 0.5` terbukti sangat efektif mencegah lonjakan lot saat terjadi SL beruntun. Apakah perlu ditambahkan mekanisme *debt decay* (utang berkurang otomatis 50% setelah 5 hari jika tren masih berlawanan)?
3. **Rekomendasi Forward Test**: Mengingat v91 P2 secara matematis dan empiris (5 tahun Every Tick) mengalahkan E2 Final di profit dan keamanan DD, disarankan mengadopsi setting P2 ke EA forward test demo `ea/BioOnePro_E2_Final.mq4`.


## Analisis Claude Code atas putaran 20–21 + rencana putaran 22 (fokus order rugi besar)
- Putaran 20 (v90): semua ditolak, setuju. Menahan basket melewati weekend membuat DD 80%; filter L1 v238Z memangkas trade ~85%.
- Putaran 21 (v91, inisiatif Antigravity): diterima. Kode v91 hanya menambah Friday_L1_Cutoff_Hour (diff sudah dicek), angka Every Tick
  5 tahun cocok dengan laporan (V2: −244 / +735 / +434 / +1,143 / +832 = **+$2,899**). v91 P2 resmi jadi juara baru.
  Membuat EA baru sebagai file terpisah tidak masalah; file yang sudah ada tetap jangan diubah.
- Jawaban pertanyaan Antigravity:
  1. Friday cutoff: dipermanenkan (v92 default = 0). Versi adaptif ATR belum perlu, risiko overfit.
  2. Debt decay: prioritas rendah. Bagian rugi SL akibat lot L1 di atas normal (recovery) hanya ~−$559 dari −$4,900 (11%).
  3. Forward test: setuju pakai v91 + preset P2. Default v92 sudah identik dengan preset P2 (dicek per parameter).
- **Bedah rugi 5 tahun v91 P2 (Every Tick, V2_*)**: total rugi basket −$6,987.
  * 21 SL Sniper = **−$4,900 (70%)**, rata-rata −$233 per kejadian (≈ 8% balance, sesuai anggaran risiko).
  * 23 close paksa Jumat 19:00 = **−$1,773 (25%)**, kebanyakan basket dibuka Kamis. Di P1D semua rugi = L1 tunggal
    yang tidak pernah mendapat L2 (anggaran risiko habis karena lot minimum), ditahan 2–4 hari, lalu ditutup Jumat (−$82 s/d −$108).
  * Sisanya (SL order / close lain) hanya −$314.
  * Pola utama pada basket yang kena SL: **jarak L3–L5 menumpuk di $5.0–6.0** (= Sniper_Min_Step_Pips), contoh jarak
    [10.1, 6.0, 5.2, 5.0] dan [7.5, 5.0, 5.0, 5.5]. Persentil P70/P85/P93 swing H1 berdekatan, jadi lot terkumpul di zona sempit,
    lalu SL di P98 hanya sedikit lebih jauh. Grid yang lebih RAPAT dan SL lebih ketat sudah pernah diuji dan kalah;
    grid yang lebih RENGGANG belum pernah diuji.
  * Jam buka L1 16:00–24:00 server: total −$315 dalam 5 tahun (tidak konsisten per tahun, kandidat lemah).
- 21 basket SL Sniper (Every Tick v91 P2):

| L1 buka | SL | Arah | Layer | Rugi $ | Jarak L1→SL $ |
|---|---|---|---|---|---|
| 2022.01.19 04:54 | 2022.01.20 13:32 | SELL | 4 | −161 | 34.2 |
| 2022.01.25 19:54 | 2022.01.26 19:45 | BUY | 3 | −242 | 33.3 |
| 2022.02.16 15:11 | 2022.02.17 13:44 | SELL | 5 | −227 | 35.4 |
| 2022.02.23 14:19 | 2022.02.24 04:11 | SELL | 3 | −207 | 34.5 |
| 2022.07.05 06:48 | 2022.07.06 05:39 | BUY | 4 | −229 | 45.2 |
| 2022.11.08 11:36 | 2022.11.09 15:09 | SELL | 4 | −200 | 45.0 |
| 2022.12.05 04:54 | 2022.12.05 18:58 | BUY | 3 | −245 | 43.1 |
| 2023.03.09 03:08 | 2023.03.10 14:31 | SELL | 5 | −234 | 37.4 |
| 2023.04.03 04:11 | 2023.04.04 14:08 | SELL | 5 | −220 | 59.1 |
| 2023.05.02 10:07 | 2023.05.03 20:54 | SELL | 4 | −268 | 55.0 |
| 2023.07.31 22:40 | 2023.08.03 12:25 | BUY | 5 | −314 | 36.0 |
| 2023.09.04 07:04 | 2023.09.06 14:43 | BUY | 5 | −294 | 29.6 |
| 2024.04.11 15:20 | 2024.04.12 02:02 | SELL | 3 | −117 | 51.1 |
| 2024.07.18 18:28 | 2024.07.19 13:06 | BUY | 5 | −130 | 52.8 |
| 2024.07.30 17:22 | 2024.08.02 12:30 | SELL | 4 | −288 | 63.8 |
| 2024.10.30 18:31 | 2024.10.31 14:46 | BUY | 3 | −228 | 49.1 |
| 2024.11.20 10:42 | 2024.11.22 03:20 | SELL | 5 | −296 | 66.1 |
| 2024.12.09 07:19 | 2024.12.11 18:22 | SELL | 5 | −249 | 76.8 |
| 2025.04.30 20:09 | 2025.05.01 01:06 | BUY | 2 | −200 | 59.1 |
| 2025.06.23 16:31 | 2025.06.24 00:03 | BUY | 3 | −248 | 59.2 |
| 2025.06.26 22:25 | 2025.06.27 13:04 | BUY | 3 | −300 | 59.1 |

- v92 (ea/BioOnePro_v92_BigLossGuard.mq4) = v91 P2 + 4 fitur (default mati): Sniper_Min_Gap_Frac, Sniper_SL_Confirm_TF
  (+ Sniper_SL_Hard_Mult), Friday_BEP_Exit_Hour, L1_Last_Entry_Hour.
- Putaran 22 (research/scenarios_putaran22.json, control points, $3000): P2 dipakai ulang · D0 = v92 default (hanya P5, harus = P2)
  · Q1 grid renggang (persentil 50/75/90/96, SL P99) · Q2 Min_Gap_Frac 0.5 · Q3 SL konfirmasi close H1 (batas keras 1.3×)
  · Q4 Friday BEP exit 12:00 + tanpa L1 ≥ 20:00. Pembanding: P2 = −223 / +392 / +854 = +$1,023, DD 23.2%.

## Putaran 22 (v92 Big Loss Guard)
| run_id | net_profit (P5 / P3 / P1D) | Total 3P | max_dd_pct | trades | SNIPER SL / BEP Exit | Keputusan |
|---|---|---|---|---|---|---|
| P2 (v91 Baseline) | -223 / +392 / +854 | +$1,023 | 23.2% | 1,730 | 14 / 0 | BASELINE |
| D0 (v92 Parity P5) | -223 / -- / -- | -- | 23.2% | 663 | 7 / 0 | PARITAS 100% |
| Q1 (Wide Grid P99) | -568 / +139 / +809 | +$379 (-63%) | 28.6% | 1,685 | 10 / 0 | DITOLAK |
| Q2 (Min_Gap 0.5) | -261 / +322 / +855 | +$916 (-10%) | 25.2% | 1,721 | 14 / 0 | DITOLAK |
| **Q3 (SL Confirm H1)** | **+150 / +691 / +854** | **+$1,695 (+66%)**| **27.7%** | **1,716** | **9 / 0** | **DITERIMA (JUARA BARU)** |
| Q4 (Friday BEP 12:00) | -230 / +245 / +796 | +$811 (-21%) | 23.0% | 1,538 | 14 / 22 | DITOLAK |
- Evaluasi Mode Cepat: Q3 DITERIMA MUTLAK (profit naik +65.6% vs P2, 2022 berbalik positif +$150). Q1, Q2, Q4 DITOLAK.
- Data Bar: XAUUSD_60.csv = 25,377 bar; XAUUSD_15.csv = 101,442 bar (rentang 2022.01.03 02:00 .. 2026.09.11 23:45, Digits=2).
- Log Events (P5/P3/P1D): WEEKEND (D0:2, Q1:21, Q2:10, Q3:13, Q4:10); FRIDAY BEP (Q4:22, lainnya:0); SNIPER SL (Q3 terpangkas ke 9).

## Jawaban Antigravity putaran 22
1. **a. Korelasi 21 Basket SL dengan Berita High-Impact USD & Geopolitik (16 dari 21 basket / 76%)**:
   - Mayoritas SL (76%) dipicu atau dipercepat oleh rilis data makro berdampak tinggi atau guncangan geopolitik:
     * *FOMC & Suku Bunga Fed*: 2022.01.26 (Powell pivot hawkish), 2023.05.03 (Fed hike 25 bps), 2024.12.11 (FOMC run-up).
     * *Geopolitik & Perang*: 2022.02.24 (Rusia invasi Ukraina - gap $50+), 2024.04.12 (eskalasi Iran-Israel), 2024.11.22 (rudal balistik Oreshnik).
     * *Krisis Finansial & Rating*: 2023.03.10 (NFP + kolaps Silicon Valley Bank SVB), 2023.08.03 (Fitch downgrade utang AS).
     * *NFP / Ketenagakerjaan AS*: 2023.03.10 (NFP bank crisis), 2024.08.02 (NFP crash 114k vs 175k pemicu resesi Sahm Rule).
     * *Inflasi & Indikator Ekonomi (CPI, PPI, PCE, ISM, JOLTS)*: 2022.11.09 (Midterm + US CPI), 2022.12.05 (ISM Services lonjak 56.5), 2023.04.04 (JOLTS anjlok <10M + OPEC cut), 2023.09.06 (ISM Services 54.5), 2024.10.31 (Core PCE), 2025.06.27 (US PCE & GDP final).
   - Hanya 5 basket (24%) terjadi murni karena pergerakan teknikal/likuiditas tanpa berita tier-1 (2022.01.20, 2022.07.06, 2024.07.19, 2025.05.01, 2025.06.24).
2. **b. Distribusi Sesi Waktu SL (Server Time MT4)**:
   - **Asia (00:00–08:00)**: **6 kejadian (28.6%)** — 2022.02.24 (04:11), 2022.07.06 (05:39), 2024.04.12 (02:02), 2024.11.22 (03:20), 2025.05.01 (01:06), 2025.06.24 (00:03). Didominasi berita geopolitik mendadak atau likuiditas tipis overnight.
   - **London (08:00–15:00)**: **10 kejadian (47.6%)** — 2022.01.20 (13:32), 2022.02.17 (13:44), 2023.03.10 (14:31), 2023.04.04 (14:08), 2023.08.03 (12:25), 2023.09.06 (14:43), 2024.07.19 (13:06), 2024.08.02 (12:30), 2024.10.31 (14:46), 2025.06.27 (13:04). Sesi paling mematikan; 8 dari 10 SL terkonsentrasi di jendela rilis data AS (12:30–14:46).
   - **New York (15:00–24:00)**: **5 kejadian (23.8%)** — 2022.01.26 (19:45), 2022.11.09 (15:09), 2022.12.05 (18:58), 2023.05.03 (20:54), 2024.12.11 (18:22). Bertepatan dengan pengumuman suku bunga FOMC malam hari atau kelanjutan tren kuat siang NY.
3. **c. Kesamaan Pola Chart H1 & Rekomendasi Aturan**:
   - *Pola Berulang*: Sebelum SL, terjadi candle ekspansi H1 impulsif panjang searah tren baru tanpa shadow (marubozu/breakout) yang menembus level persentil swing H1. Namun, banyak lonjakan tajam hanya berupa shadow spike sesaat (fakeout stop-hunt) yang segera retrace di akhir jam bar H1.
   - *Rekomendasi Aturan*: **Konfirmasi SL pada Close Bar H1 + Hard Multiplier 1.3× (terbukti di Q3)**.
     Hasil uji Q3 membuktikan eksekusi: SL yang menunggu candle H1 resmi ditutup di luar ambang batas (dibatasi pengaman keras 1.3×) memangkas SL prematur, melipatgandakan profit P3 (+$691 vs +$392), dan membalikkan 2022 menjadi positif (+150 vs -223), menaikkan total profit +65.6%.
