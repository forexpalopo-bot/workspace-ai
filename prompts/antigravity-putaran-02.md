# Prompt Antigravity — Putaran 2

```text
Lanjutkan riset BioOnePro putaran 2 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca bagian "Analisis Claude Code atas putaran 1" di research\NOTES.md. Tidak perlu membaca file lain.
   EA tetap v79 (tidak berubah, tidak perlu kompilasi ulang). tools\run_mt4_batch.py sekarang
   mengatur deposit per skenario lewat "test": {"deposit": ...} dan menambah kolom "deposit".
   Perubahan penyesuaianmu sebelumnya (schtasks LaunchMT4, pencarian laporan) tetap dipertahankan.
   Jika hasil git pull bentrok dengan perubahan lokalmu, pertahankan versi dari branch dan laporkan.

2. Jalankan skenario putaran 2 (periode P1 saja) dan simpan hasilnya ke file CSV baru:
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only R1,R2,R3,R4,R5,R6 --period-set P1 --results research\results_putaran2.csv
   Untuk R4, cek di laporan bahwa "Initial deposit" = 1000.00. Jika masih 500, catat hal itu, lalu atur deposit
   1000 secara manual di Strategy Tester dan ulangi R4 saja.
   Setelah semua selesai, kembalikan deposit tester ke 500.

3. (Opsional, jika waktunya cukup) Data periode P2 (2025.01.02–2025.09.26):
   coba unduh history XAUUSD M1 lewat MT4 Tools > History Center (F2) > XAUUSD > 1 Minute > Download.
   Jika berhasil, jalankan S0 dan S5 untuk P2:
   ... --only S0,S5 --period-set P2 --results research\results_putaran2.csv
   Catat "Modelling quality" dan "Mismatched charts errors" dari laporan. Jika tidak bisa, lewati dan catat.

4. Tambahkan bagian "## Putaran 2" di research\NOTES.md (maksimal 10 baris): tabel run_id, deposit, net_profit,
   max_dd_pct, rel_dd_pct, largest_order_loss, net_per_dd, serta hal aneh yang terlihat di log.
   Salin laporan ke C:\Penelitian_EA\BioOnePro\arsip\putaran-02\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 2"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\, jangan mengarang angka. Akhiri dengan: "Putaran 2 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
