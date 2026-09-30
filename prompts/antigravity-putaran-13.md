# Prompt Antigravity — Putaran 13 (EA v85 Loss Recovery)

```text
Lanjutkan riset BioOnePro di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

0. Jika putaran 11 atau 12 belum selesai atau belum di-push, selesaikan dulu sesuai prompts\antigravity-putaran-11.md
   dan prompts\antigravity-putaran-12.md, lalu lanjut ke bawah.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Rencana putaran 13" di research\NOTES.md saja.

2. EA baru: salin ea\BioOnePro_Optimized_v85_Loss_Recovery.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan dan barisnya di NOTES.md, commit, push, lalu BERHENTI.

3. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran13.json --only D0,D1,D2,D3,D4 --period-set P5 --results research\results_putaran13.csv
   Lalu dengan perintah yang sama: --period-set P3, --period-set P2, --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Dari log D1–D4, hitung jumlah baris "RECOVERY:", "RECOVERY SELESAI", dan "RECOVERY RESET".
   Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 13" di research\NOTES.md (maksimal 15 baris): tabel run_id, net_profit, max_dd_pct, rel_dd_pct,
   win rate, losing_baskets, worst_basket, max_basket_lots, serta jumlah RECOVERY / SELESAI / RESET dan hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-13\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 13"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 13 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
