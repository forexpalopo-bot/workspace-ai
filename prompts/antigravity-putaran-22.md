# Prompt Antigravity — Putaran 22 MODE CEPAT (EA v92 Big Loss Guard)

```text
Riset BioOnePro putaran 22 MODE CEPAT di C:\Penelitian_EA\BioOnePro\repo. Fokus: order rugi besar.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 20–21 + rencana putaran 22" di research\NOTES.md
   (berisi jawaban atas 3 pertanyaanmu, hasil bedah rugi 5 tahun, dan tabel 21 basket SL).

2. Salin ea\BioOnePro_v92_BigLossGuard.mq4 ke <folder data>\MQL4\Experts\ dan tools\ExportBars.mq4 ke <folder data>\MQL4\Scripts\,
   lalu kompilasi keduanya. Jika ada error atau warning, catat pesan + nomor baris di NOTES.md, commit, push, lalu BERHENTI.

3. Cek kesetaraan kode (1 run): D0 = v92 default, harus identik dengan P2.
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran22.json --only P2,D0 --period-set P5 --results research\results_putaran22.csv
   Net D0_P5 harus sama dengan P2_P5 (−223.xx). Jika selisih > $1, catat di NOTES.md, commit, push, lalu BERHENTI.
   Dari log tester run D0_P5, salin semua baris yang mengandung "SNIPER PLAN" atau "SNIPER SL" ke research\logs\D0_P5_sniper.txt.

4. 12 run baru (Q1, Q2, Q3, Q4 x 3 periode, model control points, deposit 3000). P2 TIDAK dijalankan ulang:
   ... --only P2,Q1,Q2,Q3,Q4 --period-set P5   lalu --period-set P3   lalu --period-set P1D
   (perintah lain sama dengan langkah 3). Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Cek trade > 0.
   Per run hitung baris log "SNIPER SL", "FRIDAY BEP EXIT", dan "WEEKEND". Setelah selesai, kembalikan deposit tester ke 500.

5. Ekspor data harga (untuk analisis konteks SL oleh Claude Code):
   Buka chart XAUUSD dari server/data yang SAMA dengan backtest, jalankan script ExportBars dua kali: InpTF=60 lalu InpTF=15
   (InpFrom 2022.01.01, InpTo 2026.09.30). Salin <folder data>\MQL4\Files\XAUUSD_60.csv dan XAUUSD_15.csv ke research\data\.
   Tulis di NOTES.md jumlah bar, tanggal bar pertama/terakhir, dan jumlah digit harga dari pesan "ExportBars" di tab Experts.

6. Pertanyaan untuk Claude di aplikasi (jawab di NOTES.md bagian "Jawaban Antigravity putaran 22", maksimal 30 baris):
   a. Untuk tiap baris tabel 21 basket SL: apakah ada berita USD berdampak tinggi (NFP, CPI, PPI, FOMC/rate decision, PCE, GDP,
      pidato Ketua Fed) di antara waktu L1 buka dan waktu SL? Tulis: tanggal SL — nama event, atau "tidak ada".
      Pakai sumber kalender ekonomi yang bisa dipercaya. Bila tidak yakin, tulis "tidak yakin". Jangan menebak.
   b. Dari 21 kejadian itu, berapa yang SL-nya terjadi saat sesi Asia (00:00–08:00 server), London (08:00–15:00), dan New York (15:00–24:00)?
   c. Pendapatmu (maksimal 5 baris): pola berulang apa yang terlihat di chart H1 sebelum SL (mis. breakout range Asia, gap, tren D1 searah SL)?
      Pola mana yang menurutmu paling layak dijadikan aturan EA?

7. Tambahkan "## Putaran 22" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit per periode, total, DD maks,
   jumlah SNIPER SL, jumlah FRIDAY BEP EXIT, rugi basket terbesar. Bandingkan dengan P2 (+$1,023): DITERIMA bila total ≥ +10%
   atau DD turun ≥ 3 poin tanpa profit turun > 10%.

8. git add research backtests\runs
   git commit -m "Hasil backtest putaran 22 (v92 big loss guard) + data harga + jawaban analisis"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah file yang sudah ada di folder ea\ (EA baru boleh dibuat sebagai file terpisah dengan penjelasan di NOTES.md).
Jangan mengarang angka atau event berita. Akhiri dengan: "Putaran 22 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
