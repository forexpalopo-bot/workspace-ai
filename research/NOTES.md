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
