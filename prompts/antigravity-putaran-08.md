# Prompt Antigravity — Putaran 8 (Adaptive Sniper, deposit $3000)

```text
Lanjutkan riset BioOnePro putaran 8 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 6–7" di research\NOTES.md saja. EA tetap v82 (tidak perlu kompilasi ulang).

2. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru.
   Semua skenario X memakai deposit $3000 (sudah diatur per skenario).
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only X1,X2,X3,X4,X5 --period-set P3 --results research\results_putaran8.csv
   Lalu dengan perintah yang sama:
   --only X1,X2,X3,X4,X5 --period-set P2
   --only X1,X2,X3,X4,X5 --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Dari log, catat untuk setiap run: baris "Rencana dari L1" dan "Rugi di SL ... lot L1 saat ini", jumlah "SNIPER SL",
   dan lot L1 pertama yang benar-benar dibuka (dari laporan).
   Setelah selesai, kembalikan deposit tester ke 500.

3. Tambahkan "## Putaran 8" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit, max_dd_pct, rel_dd_pct,
   largest_order_loss, losing_baskets, depth_L2, depth_L3, depth_L4plus, jumlah SNIPER SL, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-08\laporan\.

4. git add research backtests\runs
   git commit -m "Hasil backtest putaran 8"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 8 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
