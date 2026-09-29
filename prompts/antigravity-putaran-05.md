# Prompt Antigravity — Putaran 5 (ulang validasi P2/P3 dengan data Demo01)

```text
Lanjutkan riset BioOnePro putaran 5 di C:\Penelitian_EA\BioOnePro\repo. Kerjakan dengan hemat.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 4" di research\NOTES.md saja.

2. Masalah putaran 4: P2/P3 memakai ulang XAUUSD1_0.fxt read-only (data P1), sehingga semua run 0 trade.
   Perbaiki begini:
   a. Buka MT4 dan LOGIN ke akun server ICMarketsSC-Demo01 (yang punya history M1 sejak 2022.01.03).
      Pastikan chart XAUUSD M1 menampilkan data 2024.
   b. Cadangkan <folder data>\tester\history\XAUUSD1_0.fxt ke C:\Penelitian_EA\BioOnePro\arsip\fxt_P1_live04\,
      lalu hapus atribut read-only dan hapus file aslinya (juga file XAUUSD*_0.fxt lain yang read-only), agar tester
      membuat FXT baru dari history Demo01.
   c. Tutup MT4. Runner memakai akun terakhir yang login, jadi pastikan yang terakhir login adalah Demo01.

3. Uji satu run dulu:
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --only T0 --period-set P3 --results research\results_putaran5.csv
   Syarat valid: laporan menunjukkan periode 2024, "Bars in test" BUKAN 352520, dan jumlah trade > 0.
   Jika tidak valid, catat pesan dari Journal tester di NOTES.md, commit, push, lalu BERHENTI.

4. Jika valid, jalankan sisanya (perintah yang sama, ganti --only/--period-set):
   --only S0,T6,V1 --period-set P3
   --only S0,T0,T6,V1 --period-set P2
   --only T0 --period-set P1D
   Sebelum tiap periode baru, hapus XAUUSD1_0.fxt agar FXT dibuat ulang untuk rentang tanggal yang benar
   (jangan buat read-only lagi). Setelah selesai, kembalikan deposit tester ke 500.

5. Tambahkan "## Putaran 5" di research\NOTES.md (maksimal 12 baris): server dan akun yang dipakai, lalu tabel run_id, deposit,
   net_profit, max_dd_pct, rel_dd_pct, largest_order_loss, losing_baskets, depth_L3, depth_L4plus, dan "Bars in test".
   Catat juga hal aneh yang terlihat di log. Salin laporan ke C:\Penelitian_EA\BioOnePro\arsip\putaran-05\laporan\.

6. git add research backtests\runs
   git commit -m "Hasil backtest putaran 5"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah folder ea\, jangan mengarang angka. Akhiri dengan: "Putaran 5 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
