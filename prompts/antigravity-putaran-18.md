# Prompt Antigravity — Putaran 18 MODE CEPAT (EA v88 Trend Pyramid)

```text
Riset BioOnePro putaran 18 MODE CEPAT di C:\Penelitian_EA\BioOnePro\repo. Hemat waktu dan token.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 17 (mode cepat)" di research\NOTES.md saja.

2. Salin ea\BioOnePro_Optimized_v88_Trend_Pyramid.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat di NOTES.md, commit, push, lalu BERHENTI.

3. Hanya 9 run baru (M1, M2, M3 x 3 periode, model control points). K0 TIDAK dijalankan ulang:
   pastikan backtests\runs\K0_P5.htm, K0_P3.htm, dan K0_P1D.htm masih ada (script akan membacanya).
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran18.json --only K0,M1,M2,M3 --period-set P5 --results research\results_putaran18.csv
   Lalu dengan perintah yang sama: --period-set P3 dan --period-set P1D
   Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Cek "Modelling" = Control points, "Initial deposit" = 3000, trade > 0.
   Hitung jumlah baris log "TREND PYRAMID" per run. Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 18" di research\NOTES.md (maksimal 8 baris): tabel run_id, net_profit per periode, total, DD maks,
   win rate, jumlah TREND PYRAMID. Terapkan aturan keputusan MODE CEPAT (bandingkan dengan K0) dan tulis DITERIMA/DITOLAK.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 18 (mode cepat)"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 18 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
