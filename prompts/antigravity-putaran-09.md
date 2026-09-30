# Prompt Antigravity — Putaran 9 (gabungan: jumlah layer + SL adaptif v83)

```text
Lanjutkan riset BioOnePro putaran 9 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.
(Prompt ini menggantikan prompt putaran 9 sebelumnya. Jika Y1–Y5 sudah sempat dijalankan, commit hasilnya dulu.)

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Rencana putaran 9 (gabungan, EA v83)" di research\NOTES.md saja.

2. EA baru: salin ea\BioOnePro_Optimized_v83_Adaptive_Sniper_SL.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan dan barisnya di NOTES.md, commit, push, lalu BERHENTI.

3. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only Y1,Y2,Y3,Y4,Y5,Z1,Z2,Z3,Z4,Z5,Z6 --period-set P3 --results research\results_putaran9.csv
   Lalu dengan perintah yang sama:
   --only Y1,Y2,Y3,Y4,Y5,Z1,Z2,Z3,Z4,Z5,Z6 --period-set P2
   --only Y1,Y2,Y3,Y4,Y5,Z1,Z2,Z3,Z4,Z5,Z6 --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Dari log, hitung per run jumlah baris "SNIPER SL", "SNIPER TREND STOP", dan "SNIPER RECOVERY EXIT".
   Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 9" di research\NOTES.md (maksimal 15 baris): tabel run_id, net_profit, max_dd_pct, rel_dd_pct,
   largest_order_loss, losing_baskets, worst_basket, depth_L4plus, dan jumlah SL / TREND STOP / RECOVERY EXIT,
   serta hal aneh yang terlihat di log. Salin laporan ke arsip\putaran-09\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 9"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 9 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
