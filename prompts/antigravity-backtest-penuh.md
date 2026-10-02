# Prompt Antigravity — Backtest Penuh Seluruh History MT4 (v93: VH1 vs SL intrabar)

```text
Riset BioOnePro: BACKTEST PENUH seluruh history MT4 di C:\Penelitian_EA\BioOnePro\repo. Akun DEMO saja.
Forward test v93 tetap berjalan; pekerjaan ini memakai Strategy Tester saja.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Rencana backtest penuh" di research\NOTES.md.

2. CEK KELENGKAPAN DATA (wajib sebelum backtest)
   a. Salin tools\CheckHistory.mq4 ke <folder data>\MQL4\Scripts\ dan kompilasi.
   b. Login ke server/akun yang SAMA dengan data backtest selama ini (Demo01, harga 2 digit). Buka chart XAUUSD,
      jalankan CheckHistory. Salin <folder data>\MQL4\Files\history_check_XAUUSD.txt ke research\data\history_check_sebelum.txt.
   c. Jika timeframe M5/M15/M30/H1/H4/D1 mulai lebih lambat dari M1, atau punya "celah>4hari" yang tidak ada di M1:
      - Backup dulu: salin folder <folder data>\history\<server>\ ke C:\Penelitian_EA\BioOnePro\arsip\history_backup\.
      - Bangun ulang timeframe tersebut dari M1 dengan script bawaan PeriodConverter (chart XAUUSD M1 offline,
        ExtPeriodMultiplier = 5, 15, 30, 60, 240, 1440 satu per satu), lalu tutup dan buka lagi MT4.
      - Jalankan CheckHistory lagi -> research\data\history_check_sesudah.txt.
   d. Tentukan rentang FULL: mulai = tanggal terawal di mana SEMUA timeframe sudah ada + 45 hari (pemanasan statistik Sniper),
      akhir = hari Jumat terakhir yang datanya lengkap. Isi "from" dan "to" di research\scenarios_full.json (format YYYY.MM.DD).
      Jika Digits = 3, ubah "spread" di file itu menjadi 200 dan catat alasannya.

3. BACKTEST CONTROL POINTS (cepat dulu)
   Hapus <folder data>\tester\history\XAUUSD1_0.fxt, lalu:
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_full.json --only FA,FB --results research\results_full.csv --timeout 43200
   Untuk tiap run, dari log tester:
   - salin semua baris "SNIPER PLAN" dan "SNIPER SL" ke research\logs\<run>_sniper.txt
   - hitung baris error "mismatched" / "unmatched data" / "not enough" di tab Journal
   - hitung SNIPER PLAN dengan "legs=" kurang dari 5, per tahun (tanda statistik swing tidak terisi)

4. BACKTEST EVERY TICK (lama, jalankan setelah langkah 3 beres)
   Hapus XAUUSD1_0.fxt lagi, lalu perintah yang sama dengan --only FAT,FBT
   Catat "Modelling quality" dan "Mismatched charts errors" dari laporan.

5. Tulis "## Backtest penuh" di research\NOTES.md (maksimal 15 baris): hasil CheckHistory (sebelum/sesudah), rentang FULL,
   lalu untuk FA, FB, FAT, FBT: net profit, profit factor, DD maks ($ dan %), jumlah trade, jumlah SNIPER SL,
   jumlah error data, jumlah plan legs<5 per tahun. Evaluasi mendalam dikerjakan Claude Code, jadi cukup angka mentah.

6. Pertanyaan untuk Claude di aplikasi (jawab di NOTES.md "Jawaban backtest penuh", maksimal 10 baris):
   a. Lihat grafik equity (.gif) FA dan FB: di tanggal berapa drawdown terdalam terjadi, berapa lama pulihnya,
      dan peristiwa pasar apa yang terjadi saat itu? Jangan menebak; tulis "tidak yakin" bila tidak tahu.
   b. Apakah ada periode panjang (> 2 bulan) di mana grafik datar atau turun terus? Sebutkan tanggalnya.

7. git add research backtests\runs
   git commit -m "Backtest penuh seluruh history MT4 (v93 VH1 vs SL intrabar)"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah file di ea\ atau parameter EA. Jangan mengarang angka. Jika langkah 2 gagal, catat, commit, push, lalu BERHENTI.
Akhiri dengan: "Backtest penuh selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
