# Prompt Antigravity — Putaran 12 (EA v84 L1 Scalp)

```text
Lanjutkan riset BioOnePro di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

0. Jika putaran 11 belum selesai atau belum di-push, selesaikan dulu sesuai prompts\antigravity-putaran-11.md, lalu lanjut ke bawah.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Rencana putaran 12" di research\NOTES.md saja.

2. EA baru: salin ea\BioOnePro_Optimized_v84_Scalp_L1.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan dan barisnya di NOTES.md, commit, push, lalu BERHENTI.

3. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   Memakai file skenario terpisah research\scenarios_putaran12.json (spread 20 sudah diatur).
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran12.json --only C1,C2,C3,C4,C5,C6 --period-set P5 --results research\results_putaran12.csv
   Lalu dengan perintah yang sama: --period-set P3, --period-set P2, --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Catat per run: jumlah trade, win rate (Profit trades %), jumlah baris "SNIPER SL", dan apakah ada BUY dan SELL yang terbuka
   bersamaan (seharusnya tidak ada).
   Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 12" di research\NOTES.md (maksimal 15 baris): tabel run_id, net_profit, max_dd_pct, total trades,
   win rate, losing_baskets, worst_basket, jumlah SNIPER SL, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-12\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 12"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 12 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
