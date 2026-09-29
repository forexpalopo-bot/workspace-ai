# workspace-ai

Riset EA BioOnePro (MT4, XAUUSD).

| Path | Isi |
|---|---|
| `ea/BioOnePro_Optimized_v77_Apex_Unleashed.mq4` | Versi asli v77 |
| `ea/BioOnePro_Optimized_v78_Apex_Guarded.mq4` | v78: perbaikan bug hedge, laporan risiko grid, opsi pembatas lot, dan kunci biaya |
| `backtests/v77_XAUUSD_M1_2025-09_2026-09.htm` | Laporan Strategy Tester v77 |
| `ea/BioOnePro_Optimized_v79_Apex_PairClose.mq4` | v79: v78 + Partial Pair Close (default mati) untuk memangkas loss besar L1 |
| `docs/analisis-v77-dan-perubahan-v78.md` | Analisis cara kerja, hasil backtest, risiko, dan daftar perubahan |
| `tools/analyze_mt4_report.py` | Ringkas laporan Strategy Tester (.htm) menjadi metrik dan statistik basket |
| `tools/run_mt4_batch.py` | Jalankan batch backtest MT4 dari `research/scenarios.json` (di Windows) |
| `research/` | Skenario uji, hasil (`results.csv`), dan catatan |
| `ANTIGRAVITY.md` | Brief tugas backtest untuk Antigravity |
| `prompts/antigravity-putaran-01.md` | Prompt siap-salin untuk Antigravity |
| `penelitian/README.md` | Struktur folder penelitian di komputer |
