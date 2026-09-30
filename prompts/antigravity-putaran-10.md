# Prompt Antigravity — Putaran 10 (tuning Z1 + validasi 2022/2023)

```text
Lanjutkan riset BioOnePro putaran 10 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 9" di research\NOTES.md saja. EA tetap v83 (tidak perlu kompilasi ulang).

2. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   Tahap A, validasi di tahun baru (paling penting, kerjakan dulu):
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only Z1,Y1 --period-set P4 --results research\results_putaran10.csv
   --only Z1,Y1 --period-set P5
   Cek dulu di History Center bahwa data XAUUSD M1 tahun 2022 dan 2023 tersedia. Jika tidak, catat dan lewati periode itu.
   Tahap B, tuning Z1:
   --only A1,A2,A3,A4,A5,A6 --period-set P3
   --only A1,A2,A3,A4,A5,A6 --period-set P2
   --only A1,A2,A3,A4,A5,A6 --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Setelah selesai, kembalikan deposit tester ke 500.

3. Tambahkan "## Putaran 10" di research\NOTES.md (maksimal 15 baris): tabel run_id, net_profit, max_dd_pct, rel_dd_pct,
   largest_order_loss, losing_baskets, worst_basket, depth_L4plus, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-10\laporan\.

4. git add research backtests\runs
   git commit -m "Hasil backtest putaran 10"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 10 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
