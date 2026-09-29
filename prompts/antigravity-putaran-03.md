# Prompt Antigravity — Putaran 3

```text
Lanjutkan riset BioOnePro putaran 3 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca bagian "Analisis Claude Code atas putaran 2" di research\NOTES.md saja.

2. EA baru: salin ea\BioOnePro_Optimized_v80_Apex_PSAR.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan dan barisnya di research\NOTES.md, commit, push, lalu BERHENTI.

3. Jalankan putaran 3 (P1, deposit $1000 sudah diatur per skenario):
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only T0,T1,T2,T3,T4,T5,T6,T7 --period-set P1 --results research\results_putaran3.csv
   Jalankan T0 lebih dulu. T0 harus sama dengan R4 (net $7,249.38, max DD 21.12%). Jika berbeda jauh, catat dan BERHENTI.
   Pastikan "Initial deposit" di laporan = 1000. Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan bagian "## Putaran 3" di research\NOTES.md (maksimal 10 baris): tabel run_id, net_profit, max_dd_pct,
   rel_dd_pct, largest_order_loss, net_per_dd, depth_L3, depth_L4plus, serta hal aneh yang terlihat di log.
   Salin laporan ke C:\Penelitian_EA\BioOnePro\arsip\putaran-03\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 3"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\, jangan mengarang angka. Akhiri dengan: "Putaran 3 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
