# workspace-ai

Riset EA BioOnePro (MT4, XAUUSD).

| Path | Isi |
|---|---|
| `ea/BioOnePro_Optimized_v77_Apex_Unleashed.mq4` | Versi asli v77 |
| `ea/BioOnePro_Optimized_v78_Apex_Guarded.mq4` | v78: perbaikan bug hedge, laporan risiko grid, opsi pembatas lot, dan kunci biaya |
| `backtests/v77_XAUUSD_M1_2025-09_2026-09.htm` | Laporan Strategy Tester v77 |
| `ea/BioOnePro_Optimized_v79_Apex_PairClose.mq4` | v79: v78 + Partial Pair Close (default mati) untuk memangkas loss besar L1 |
| `ea/BioOnePro_Optimized_v80_Apex_PSAR.mq4` | v80: v79 + Parabolic SAR (gate averaging + filter L1, default mati) |
| `ea/BioOnePro_Optimized_v81_Apex_TrendWeekend.mq4` | v81: v80 + filter tren D1 + weekend hold (default mati) |
| `ea/BioOnePro_Optimized_v82_Adaptive_Sniper.mq4` | v82: v81 + mode Adaptive Sniper (default mati) |
| `ea/BioOnePro_Optimized_v83_Adaptive_Sniper_SL.mq4` | v83: v82 + SL adaptif (time-decay, trend stop), jarak bernapas, recovery exit |
| `ea/BioOnePro_Optimized_v84_Scalp_L1.mq4` | v84: v83 + entry L1 OB/OS TF kecil, TP scalping, batas SL maksimum |
| `ea/BioOnePro_Optimized_v85_Loss_Recovery.mq4` | v85: v84 + pemulihan kerugian setelah SL (lot recovery terbatas, re-entry searah) |
| `ea/BioOnePro_Optimized_v86_Signal_Guard.mq4` | v86: v85 + filter volume klimaks, pola candle, cut loss sinyal berlawanan, equity guard |
| `ea/BioOnePro_E2_Final.mq4` | Versi final hasil riset (v86 + setting E2 sebagai default) |
| `ea/BioOnePro_v89_FullAvg_L20.mq4` | v89: averaging penuh sampai L20, jarak adaptif ATR D1 + volatilitas H1, tanpa SL basket (uji putaran 19) |
| `ea/BioOnePro_v90_FullAvg_L1v238.mq4` | v90: v89 + tahan basket rugi saat weekend, lot bertahap per N layer, entry L1 gaya v238Z (uji putaran 20) |
| `ea/BioOnePro_v91_E2_LossGuard.mq4` | v91 (Antigravity): E2 + tanpa L1 baru hari Jumat; preset juara `research/presets/BioOnePro_v91_P2_LossGuard.set` |
| `ea/BioOnePro_v92_BigLossGuard.mq4` | v92: default = v91 P2, + 4 fitur anti rugi besar (grid renggang, SL konfirmasi H1, Friday BEP exit, jam akhir L1) |
| `ea/BioOnePro_v93_NewsTime.mq4` | v93: default = v92 Q3 (SL konfirmasi close H1), aturan jam memakai GMT di live, filter berita dari file CSV |
| `tools/ExportBars.mq4` | Script MT4: ekspor bar OHLC ke CSV untuk analisis konteks harga |
| `docs/desain-v82-adaptive-sniper.md` | Desain mode Adaptive Sniper |
| `docs/analisis-v77-dan-perubahan-v78.md` | Analisis cara kerja, hasil backtest, risiko, dan daftar perubahan |
| `tools/analyze_mt4_report.py` | Ringkas laporan Strategy Tester (.htm) menjadi metrik dan statistik basket |
| `tools/run_mt4_batch.py` | Jalankan batch backtest MT4 dari `research/scenarios.json` (di Windows) |
| `research/` | Skenario uji, hasil (`results*.csv`), catatan, dan preset `.set` (kandidat terbaru: `presets/BioOnePro_v85_A5_Kandidat.set`) |
| `ANTIGRAVITY.md` | Brief tugas backtest untuk Antigravity |
| `prompts/antigravity-putaran-01.md` | Prompt siap-salin untuk Antigravity |
| `penelitian/README.md` | Struktur folder penelitian di komputer |
