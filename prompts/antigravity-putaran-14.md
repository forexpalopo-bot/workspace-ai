# Prompt Antigravity — Putaran 14 (recovery di atas A5 dan C1)

```text
Lanjutkan riset BioOnePro putaran 14 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 11–13" di research\NOTES.md saja. EA tetap v85 (tidak perlu kompilasi ulang).

2. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran14.json --only E0,E1,E2,E3,E4 --period-set P5 --results research\results_putaran14.csv
   Lalu dengan perintah yang sama: --period-set P4, --period-set P3, --period-set P2, --period-set P1D
   Jalankan E0 di P5 lebih dulu: hasilnya harus sama dengan A5_P5 (net −$432, DD 25.6%). Jika berbeda jauh, catat dan BERHENTI.
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Dari log E1–E4, hitung jumlah baris "RECOVERY:", "RECOVERY SELESAI", dan "RECOVERY RESET".
   Setelah selesai, kembalikan deposit tester ke 500.

3. Tambahkan "## Putaran 14" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit per periode, max_dd_pct,
   win rate, losing_baskets, worst_basket, max_basket_lots, jumlah RECOVERY / SELESAI / RESET, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-14\laporan\.

4. git add research backtests\runs
   git commit -m "Hasil backtest putaran 14"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 14 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
