# Prompt Antigravity — Putaran 5b

```text
Lanjutkan riset BioOnePro putaran 5b di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 5" di research\NOTES.md saja.
   Penting: JANGAN matikan Use_Dynamic_Spread_Filter. Runner sekarang otomatis memakai spread 20 point
   (= $0.20 di data 2 digit) untuk periode P2, P3, dan P1D.

2. Hapus laporan T0_P3 yang 0 trade: del backtests\runs\T0_P3.* dan hapus barisnya dari research\results_putaran5.csv.

3. Jalankan (hapus XAUUSD1_0.fxt sebelum tiap periode baru, dan jangan dibuat read-only):
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only T0,T6,V1 --period-set P3 --results research\results_putaran5.csv
   Lalu:
   --only S0,T0,T6,V1 --period-set P2
   --only S0,T0 --period-set P1D
   Untuk setiap laporan, cek: jumlah trade > 0, "Spread" di laporan = 20, dan catat "Modelling quality".
   Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 5b" di research\NOTES.md (maksimal 12 baris): tabel run_id, deposit, net_profit, max_dd_pct,
   rel_dd_pct, largest_order_loss, losing_baskets, depth_L3, depth_L4plus, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-05\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 5b"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 5b selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
