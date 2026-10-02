# Prompt Antigravity — Putaran 24 VALIDASI EVERY TICK (v93: Q3 vs H1)

```text
Riset BioOnePro putaran 24 (validasi) di C:\Penelitian_EA\BioOnePro\repo.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Evaluasi Claude Code atas putaran 23" di research\NOTES.md (ada 3 catatan proses untukmu).

2. EA ea\BioOnePro_v93_NewsTime.mq4 sudah terkompilasi dari putaran 23. Jika file di repo berubah sejak itu, kompilasi ulang.

3. 10 run Every Tick (model 0, spread 20, deposit 3000), 5 periode:
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran24.json --only VQ3,VH1 --period-set P5 --results research\results_putaran24.csv
   Ulangi dengan --period-set P4, P3, P2, P1D. Hapus XAUUSD1_0.fxt sebelum tiap periode baru.
   Cek di tiap laporan: "Modelling quality" (catat angkanya), "Initial deposit" = 3000, trade > 0.
   Per run hitung baris log "SNIPER SL". Setelah selesai, kembalikan deposit tester ke 500.

4. Tambahkan "## Putaran 24" di research\NOTES.md (maksimal 12 baris): tabel per periode untuk VQ3, VH1, dan V2 (v91 P2 dari
   tabel validasi sebelumnya): net, DD maks, jumlah SNIPER SL, rugi basket terbesar; lalu total 5 periode.
   Keputusan: pemenang = total net lebih tinggi DAN DD maks tidak lebih dari 2 poin di atas yang lain; jika tidak ada yang memenuhi,
   pilih DD maks yang lebih rendah. Tulis "PEMENANG: VQ3" atau "PEMENANG: VH1".

5. git add research backtests\runs
   git commit -m "Hasil putaran 24: validasi Every Tick 5 tahun v93 (Q3 vs H1)"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah file yang sudah ada di folder ea\. Jangan mengarang angka. Akhiri dengan:
"Putaran 24 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
