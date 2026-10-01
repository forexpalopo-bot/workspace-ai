# Prompt Antigravity — Putaran 17 (uji ketahanan E2)

```text
Lanjutkan riset BioOnePro putaran 17 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 16" di research\NOTES.md saja. EA tetap v86 (tidak perlu kompilasi ulang).

2. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran17.json --only H1,H2,H3,H4,H5,H6,H7,H8 --period-set P5 --results research\results_putaran17.csv
   Lalu dengan perintah yang sama: --period-set P4, --period-set P3, --period-set P2, --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Initial deposit" = 3000, dan "Spread" = 20 (H7: 35, H8: 50).
   Jika H7/H8 masih 0 trade, catat dan lanjutkan skenario lain.
   Setelah selesai, kembalikan deposit tester ke 500.

3. Tambahkan "## Putaran 17" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit per periode, total, max_dd_pct,
   win rate, losing_baskets, worst_basket, max_basket_lots, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-17\laporan\.

4. git add research backtests\runs
   git commit -m "Hasil backtest putaran 17"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 17 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
