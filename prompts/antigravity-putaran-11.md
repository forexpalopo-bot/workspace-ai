# Prompt Antigravity — Putaran 11 (validasi A5 + risiko 6% + belajar 60 hari)

```text
Lanjutkan riset BioOnePro putaran 11 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca research\analisis_putaran10.md saja. EA tetap v83 (tidak perlu kompilasi ulang).
   Putaran ini memakai file skenario TERPISAH: research\scenarios_putaran11.json (spread 20 sudah diatur di file itu).

2. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   Tahap A (paling penting): validasi A5 di tahun baru
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran11.json --only A5 --period-set P5 --results research\results_putaran11.csv
   Lalu dengan perintah yang sama: --only A5 --period-set P4
   (Laporan A5 untuk P3/P2/P1D sudah ada dari putaran 10; script otomatis membaca yang sudah ada.)
   Tahap B: B1 dan B2 di kelima periode, urut P5, P4, P3, P2, P1D:
   --only B1,B2 --period-set P5
   --only B1,B2 --period-set P4
   --only B1,B2 --period-set P3
   --only B1,B2 --period-set P2
   --only B1,B2 --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Setelah selesai, kembalikan deposit tester ke 500.

3. Tambahkan "## Putaran 11" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit, max_dd_pct, rel_dd_pct,
   losing_baskets, worst_basket, depth_L4plus, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-11\laporan\.

4. git add research backtests\runs
   git commit -m "Hasil backtest putaran 11"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 11 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
