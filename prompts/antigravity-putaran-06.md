# Prompt Antigravity — Putaran 6 (EA v81)

```text
Lanjutkan riset BioOnePro putaran 6 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 5b" di research\NOTES.md saja.

2. EA baru: salin ea\BioOnePro_Optimized_v81_Apex_TrendWeekend.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan dan barisnya di NOTES.md, commit, push, lalu BERHENTI.

3. Tetap login ke server yang dipakai di putaran 5b (data 2022–2026). Hapus XAUUSD1_0.fxt sebelum tiap periode baru.
   Jalankan dengan urutan berikut (P3 dulu karena paling penting):
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only U1,U2,U3,U4,U5 --period-set P3 --results research\results_putaran6.csv
   Lalu:
   --only U1,U2,U3,U4,U5 --period-set P2
   --only U1,U2,U3,U4,U5 --period-set P1D
   Cek di setiap laporan: jumlah trade > 0 dan "Spread" = 20. Cari baris "WEEKEND: tutup basket" di log U2/U4/U5
   sebagai tanda weekend hold bekerja. Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 6" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit, max_dd_pct, rel_dd_pct,
   largest_order_loss, losing_baskets, depth_L4plus, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-06\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 6"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 6 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
