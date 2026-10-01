# Prompt Antigravity — Putaran 19 MODE CEPAT (EA v89 Full Averaging L20)

```text
Riset BioOnePro putaran 19 MODE CEPAT di C:\Penelitian_EA\BioOnePro\repo. Hemat waktu dan token.

1. git checkout claude/cek-xb7zbt && git pull
   Baca bagian "Putaran 19 — v89 Full Averaging L20" di research\NOTES.md saja.

2. Salin ea\BioOnePro_v89_FullAvg_L20.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan + nomor baris di NOTES.md, commit, push, lalu BERHENTI.

3. 12 run baru (L0, L1, L2, L3 x 3 periode, model control points). K0 TIDAK dijalankan ulang:
   pastikan backtests\runs\K0_P5.htm, K0_P3.htm, dan K0_P1D.htm masih ada (script akan membacanya).
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran19.json --only K0,L0,L1,L2,L3 --period-set P5 --results research\results_putaran19.csv
   Lalu dengan perintah yang sama: --period-set P3 dan --period-set P1D
   Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Cek "Modelling" = Control points, trade > 0,
   "Initial deposit" = 3000 untuk L0-L2 dan 10000 untuk L3. Setelah selesai, kembalikan deposit tester ke 500.

4. Dari tab Journal/Experts tiap run catat:
   - baris "===== FULL AVERAGING v89" dan dua baris sesudahnya (rencana grid saat start) untuk L0 periode P1D,
   - jumlah layer maksimum yang pernah terbuka dalam satu basket (lihat komentar order / laporan),
   - apakah ada "FULL AVG WARNING", "cut-loss"/batas rugi akun (Percent_Loss), atau stop out / margin call.

5. Tambahkan "## Putaran 19" di research\NOTES.md (maksimal 10 baris): tabel run_id, net_profit per periode, total,
   DD maks, win rate, layer maks, jumlah cut-loss akun / MC. Bandingkan dengan K0 (aturan MODE CEPAT) dan tulis DITERIMA/DITOLAK.

6. git add research backtests\runs
   git commit -m "Hasil backtest putaran 19 (v89 full averaging L20)"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 19 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
