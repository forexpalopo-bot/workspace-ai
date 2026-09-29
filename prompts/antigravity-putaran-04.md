# Prompt Antigravity — Putaran 4 (validasi periode lain)

```text
Lanjutkan riset BioOnePro putaran 4 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca bagian "Analisis Claude Code atas putaran 3" di research\NOTES.md saja. EA tetap v80 (tidak perlu kompilasi ulang).

2. Siapkan data history (WAJIB, ini inti putaran 4):
   - Buka MT4 dalam keadaan ONLINE dan login ke akun IC Markets (demo boleh).
   - Tools > History Center (F2) > XAUUSD > 1 Minute (M1) > Download. Tunggu sampai selesai, lalu ulangi untuk M5, M15, H1, D1.
   - Buka chart XAUUSD M1 dan H1, lalu tekan Home berkali-kali agar data lama ikut termuat.
   - Cek di History Center bahwa data M1 tersedia minimal sejak 2024.01.02. Catat tanggal data paling awal.
   - Tutup MT4 sebelum menjalankan batch.

3. Jalankan (hapus dulu laporan lama di backtests\runs yang namanya sama bila ada, karena script melewati laporan yang sudah ada):
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only V1 --period-set P1 --results research\results_putaran4.csv
   Lalu untuk P2 dan P3 (jika datanya tersedia):
   ... --only S0,T0,T6,V1 --period-set P2 --results research\results_putaran4.csv
   ... --only S0,T0,T6,V1 --period-set P3 --results research\results_putaran4.csv
   Dari setiap laporan P2/P3, catat "Bars in test", "Modelling quality", dan "Mismatched charts errors".
   Jika sebuah laporan berisi 0 trade atau periodenya terpotong, tulis hal itu di NOTES.md.
   Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 4" di research\NOTES.md (maksimal 12 baris): tanggal data paling awal, tabel run_id, deposit,
   net_profit, max_dd_pct, rel_dd_pct, largest_order_loss, net_per_dd, losing_baskets, depth_L4plus, serta hal aneh yang terlihat di log.
   Salin laporan ke C:\Penelitian_EA\BioOnePro\arsip\putaran-04\laporan\.

5. git add research backtests\runs
   git commit -m "Hasil backtest putaran 4"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\, jangan mengarang angka. Akhiri dengan: "Putaran 4 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
