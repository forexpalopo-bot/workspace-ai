# Prompt Antigravity — Putaran 17 MODE CEPAT (EA v87)

```text
Riset BioOnePro putaran 17 MODE CEPAT di C:\Penelitian_EA\BioOnePro\repo. Hemat waktu dan token.
(Prompt ini menggantikan prompt putaran 17 sebelumnya. Jangan jalankan H1–H8.)

1. git checkout claude/cek-xb7zbt && git pull
   Baca bagian "MODE CEPAT" dan "Rencana putaran 17 cepat" di research\NOTES.md saja.

2. Salin ea\BioOnePro_Optimized_v87_Fast_Regime.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat di NOTES.md, commit, push, lalu BERHENTI.

3. Hanya 12 run (4 skenario x 3 periode), model control points (sudah diatur di file skenario):
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran17.json --only K0,K1,K2,K3 --period-set P5 --results research\results_putaran17.csv
   Lalu dengan perintah yang sama: --period-set P3 dan --period-set P1D
   Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Cek "Modelling" di laporan = Control points, "Initial deposit" = 3000, trade > 0.
   Hitung jumlah baris log "DAILY LOSS LIMIT" dan "L1 PARTIAL TP" per run. Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 17" di research\NOTES.md (maksimal 8 baris): tabel run_id, net_profit per periode, total, DD maks,
   win rate, jumlah event di atas. Terapkan aturan keputusan MODE CEPAT dan tulis paket mana yang DITERIMA/DITOLAK.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 17 (mode cepat)"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 17 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
