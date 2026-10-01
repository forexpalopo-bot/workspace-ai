# Prompt Antigravity — Putaran 15 (EA v86 Signal Guard)

```text
Lanjutkan riset BioOnePro di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

0. Jika putaran 14 belum selesai atau belum di-push, selesaikan dulu sesuai prompts\antigravity-putaran-14.md, lalu lanjut ke bawah.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Rencana putaran 15" di research\NOTES.md saja.

2. EA baru: salin ea\BioOnePro_Optimized_v86_Signal_Guard.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan dan barisnya di NOTES.md, commit, push, lalu BERHENTI.

3. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran15.json --only F1,F2,F3,F4,F5,F6 --period-set P5 --results research\results_putaran15.csv
   Lalu dengan perintah yang sama: --period-set P4, --period-set P3, --period-set P2, --period-set P1D
   Cek di setiap laporan: jumlah trade > 0, "Spread" = 20, dan "Initial deposit" = 3000.
   Catat per run: total trades, win rate, jumlah baris "OPPOSITE SIGNAL CUT" dan "EQUITY GUARD".
   Simpan juga gambar grafik balance (.gif) dari setiap laporan, karena dipakai untuk menilai kestabilan kurva.
   Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 15" di research\NOTES.md (maksimal 15 baris): tabel run_id, net_profit per periode, max_dd_pct,
   total trades, win rate, losing_baskets, worst_basket, jumlah OPPOSITE CUT / EQUITY GUARD, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-15\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 15"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 15 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
