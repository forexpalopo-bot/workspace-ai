# Prompt Antigravity — Putaran 16 (penyempurnaan E2)

```text
Lanjutkan riset BioOnePro putaran 16 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 14–15" di research\NOTES.md saja. EA tetap v86 (tidak perlu kompilasi ulang).

2. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Semua skenario deposit $3000.
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran16.json --only G0,G1,G2,G3,G4,G5,G6 --period-set P5 --results research\results_putaran16.csv
   Lalu dengan perintah yang sama: --period-set P4, --period-set P3, --period-set P2, --period-set P1D
   Jalankan G0 di P5 lebih dulu: hasilnya harus sama dengan E2_P5 (net −$392, DD 25.2%). Jika berbeda jauh, catat dan BERHENTI.
   Cek di setiap laporan: jumlah trade > 0, "Initial deposit" = 3000, dan "Spread" = 20 (G6: 35).
   Catat per run: win rate, jumlah "RECOVERY:", "RECOVERY SELESAI", "RECOVERY RESET", "OPPOSITE SIGNAL CUT", dan "EQUITY GUARD".
   Simpan gambar grafik balance (.gif). Setelah selesai, kembalikan deposit tester ke 500.

3. Tambahkan "## Putaran 16" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit per periode, max_dd_pct,
   win rate, losing_baskets, worst_basket, max_basket_lots, jumlah event di atas, serta hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-16\laporan\.

4. git add research backtests\runs
   git commit -m "Hasil backtest putaran 16"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 16 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
