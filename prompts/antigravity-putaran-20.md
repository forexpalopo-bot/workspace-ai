# Prompt Antigravity — Putaran 20 MODE CEPAT (EA v90: L20 + weekend hold + entry L1 v238Z)

```text
Riset BioOnePro putaran 20 MODE CEPAT di C:\Penelitian_EA\BioOnePro\repo. Hemat waktu dan token.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 19 + rencana putaran 20" di research\NOTES.md saja.

2. Salin ea\BioOnePro_v90_FullAvg_L1v238.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan + nomor baris di NOTES.md, commit, push, lalu BERHENTI.

3. 12 run baru (N0, N1, N2, N3 x 3 periode, model control points). K0 dan L0 TIDAK dijalankan ulang:
   pastikan backtests\runs\K0_*.htm dan L0_*.htm (P5, P3, P1D) masih ada (script akan membacanya).
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran20.json --only K0,L0,N0,N1,N2,N3 --period-set P5 --results research\results_putaran20.csv
   Lalu dengan perintah yang sama: --period-set P3 dan --period-set P1D
   Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Cek "Modelling" = Control points, "Initial deposit" = 3000, trade > 0.
   Setelah selesai, kembalikan deposit tester ke 500.

4. Untuk tiap run catat dari laporan/log: jumlah trade, layer maksimum dalam satu basket, jumlah baris "WEEKEND: tutup basket",
   dan apakah ada cut-loss akun (batas rugi) atau stop out / margin call.

5. Tambahkan "## Putaran 20" di research\NOTES.md (maksimal 10 baris): tabel run_id, net_profit per periode, total, DD maks,
   win rate, jumlah trade, layer maks, cut-loss/MC. Bandingkan dengan K0 (aturan MODE CEPAT) dan tulis DITERIMA/DITOLAK.

6. git add research backtests\runs
   git commit -m "Hasil backtest putaran 20 (v90 L20 + entry L1 v238Z)"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 20 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
