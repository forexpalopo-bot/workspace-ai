# Prompt Antigravity — Putaran 9 (jumlah layer Adaptive Sniper)

```text
Lanjutkan riset BioOnePro putaran 9 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 8" di research\NOTES.md saja. EA tetap v82 (tidak perlu kompilasi ulang).

2. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru.
   Semua skenario Y memakai deposit $3000 (sudah diatur per skenario).
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only Y1,Y2,Y3,Y4,Y5 --period-set P3 --results research\results_putaran9.csv
   Lalu dengan perintah yang sama:
   --only Y1,Y2,Y3,Y4,Y5 --period-set P2
   --only Y1,Y2,Y3,Y4,Y5 --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Dari log, catat per run: baris "Rugi di SL ... lot L1 saat ini" dan jumlah "SNIPER SL".
   Setelah selesai, kembalikan deposit tester ke 500.

3. Tambahkan "## Putaran 9" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit, max_dd_pct, rel_dd_pct,
   largest_order_loss, losing_baskets, depth_L2, depth_L3, depth_L4plus, jumlah SNIPER SL, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-09\laporan\.

4. git add research backtests\runs
   git commit -m "Hasil backtest putaran 9"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 9 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
