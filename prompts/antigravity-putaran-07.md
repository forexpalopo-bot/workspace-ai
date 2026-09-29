# Prompt Antigravity — Putaran 7 (EA v82 Adaptive Sniper + skenario putaran 6)

```text
Lanjutkan riset BioOnePro putaran 7 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.
(Prompt ini menggantikan prompt putaran 6. Jika putaran 6 sudah sempat dijalankan, commit hasilnya dulu.)

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Rencana putaran 7" di research\NOTES.md saja.

2. EA baru: salin ea\BioOnePro_Optimized_v82_Adaptive_Sniper.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan dan barisnya di NOTES.md, commit, push, lalu BERHENTI.

3. Tetap login ke server dengan data 2022–2026. Hapus XAUUSD1_0.fxt sebelum tiap periode baru.
   Urutan (P3 dulu):
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only W1,W2,W3,W4,W5,U1,U2,U3,U4,U5 --period-set P3 --results research\results_putaran7.csv
   Lalu, dengan perintah yang sama:
   --only W1,W2,W3,W4,W5,U1,U2,U3,U4,U5 --period-set P2
   --only W1,W2,W3,W4,W5,U1,U2,U3,U4,U5 --period-set P1D
   Cek di setiap laporan: jumlah trade > 0 dan "Spread" = 20.
   Dari log tester W1–W5, salin ke arsip\putaran-07\log\:
   - baris "ADAPTIVE SNIPER", "Swing P30", "Rencana dari L1", dan "Rugi di SL" (muncul saat start),
   - 5 baris "SNIPER PLAN" pertama,
   - jumlah baris "SNIPER SL", "SNIPER TIME STOP", dan "WEEKEND: tutup basket".
   Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 7" di research\NOTES.md (maksimal 15 baris):
   - tabel run_id, net_profit, max_dd_pct, rel_dd_pct, largest_order_loss, losing_baskets, depth_L3, depth_L4plus,
   - persentil swing dan rencana jarak dari log W1 untuk setiap periode,
   - jumlah SNIPER SL per run W,
   - hal aneh yang terlihat di log.
   Salin laporan ke arsip\putaran-07\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 7"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\ atau parameter EA, jangan mengarang angka. Akhiri dengan: "Putaran 7 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
