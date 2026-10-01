# Prompt Antigravity — Putaran 23 MODE CEPAT (EA v93: jam GMT + filter berita)

```text
Riset BioOnePro putaran 23 MODE CEPAT di C:\Penelitian_EA\BioOnePro\repo.

1. git checkout claude/cek-xb7zbt && git pull
   Baca "Analisis Claude Code atas putaran 22 + rencana pengembangan" di research\NOTES.md
   (ada temuan penting: data tester memakai jam GMT, server broker GMT+2/+3).

2. Buat kalender berita USD berdampak tinggi 2022.01.01 – 2026.09.30: research\data\news_usd_high.csv
   Format per baris (tanpa spasi tambahan):  YYYY.MM.DD HH:MM,USD,Nama event      <- waktu dalam GMT
   Baris pertama boleh header: time,currency,event
   Event: Nonfarm Payrolls, CPI, PPI, Core PCE, GDP (advance), Retail Sales, ISM Manufacturing PMI, ISM Services PMI,
   FOMC rate decision, FOMC press conference, Ketua Fed testimony (Senat/DPR).
   Sumber wajib resmi/terpercaya: jadwal BLS (NFP, CPI, PPI), BEA (PCE, GDP), Census (Retail Sales), ISM, federalreserve.gov (FOMC),
   atau riwayat kalender ForexFactory. Jam rilis AS: 08:30 ET (data), 10:00 ET (ISM), 14:00 ET (FOMC), 14:30 ET (konferensi pers).
   Konversi ET → GMT dengan aturan DST Amerika (EDT = GMT−4, EST = GMT−5).
   Simpan daftar URL sumber di research\data\news_sources.txt. JANGAN mengarang tanggal: bila satu bulan tidak bisa dipastikan,
   lewati dan catat di news_sources.txt. Tulis jumlah event per tahun di NOTES.md.
   Salin news_usd_high.csv ke <folder data>\tester\files\ (untuk Strategy Tester) dan ke <folder data>\MQL4\Files\ (untuk live).

3. Salin ea\BioOnePro_v93_NewsTime.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi.
   Jika ada error atau warning, catat pesan + nomor baris di NOTES.md, commit, push, lalu BERHENTI.

4. Cek kesetaraan (1 run): D1 = v93 default, harus identik dengan Q3.
   python tools\run_mt4_batch.py --terminal "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\terminal.exe" --data-dir "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5" --scenarios research\scenarios_putaran23.json --only Q3,D1 --period-set P5 --results research\results_putaran23.csv
   Net D1_P5 harus = Q3_P5 (+150.12). Jika selisih > $1, catat, commit, push, BERHENTI.

5. 12 run baru (H1, H2, H3, H4 x 3 periode, control points, deposit 3000). Q3 TIDAK dijalankan ulang:
   ... --only Q3,H1,H2,H3,H4 --period-set P5   lalu --period-set P3   lalu --period-set P1D
   Hapus XAUUSD1_0.fxt sebelum tiap periode baru. Cek trade > 0.
   Untuk H3/H4: pastikan tab Journal memuat "NEWS FILE: <N> event dimuat". Jika muncul "gagal membuka", file belum ada di
   <folder data>\tester\files\ — perbaiki lalu ulangi run H3/H4 tersebut.
   Per run hitung baris log "SNIPER SL". Setelah selesai, kembalikan deposit tester ke 500.

6. Pertanyaan untuk Claude di aplikasi (jawab di NOTES.md bagian "Jawaban Antigravity putaran 23", maksimal 15 baris):
   a. Konfirmasi zona waktu data tester: jalankan visual mode singkat di periode P5, lihat jam bar terakhir hari Jumat dan
      bar pertama hari Senin di data tester, bandingkan dengan chart live server. Apakah data tester GMT (selisih 2–3 jam)?
   b. Periode P2 (2025.01–2025.09) dan P1 memakai data/server apa? Harga di CSV ExportBars 2025 tidak cocok dengan harga order V2_P2.
   c. Pendapatmu (maksimal 5 baris): setelah filter berita, risiko besar apa yang masih tersisa menurut chart?

7. Tambahkan "## Putaran 23" di research\NOTES.md (maksimal 12 baris): tabel run_id, net_profit per periode, total, DD maks,
   jumlah SNIPER SL, rugi basket terbesar, jumlah trade. Bandingkan dengan Q3 (+$1,695, DD 27.7%): DITERIMA bila total ≥ +10%,
   atau DD turun ≥ 3 poin tanpa profit turun > 10%.

8. git add research backtests\runs
   git commit -m "Hasil backtest putaran 23 (v93 jam GMT + filter berita) + kalender berita"
   git push origin claude/cek-xb7zbt

Aturan: jangan ubah file yang sudah ada di folder ea\ (EA baru boleh dibuat sebagai file terpisah dengan penjelasan di NOTES.md).
Jangan mengarang angka atau tanggal event. Akhiri dengan: "Putaran 23 selesai dan sudah di-push" atau "Push gagal: <alasan>".
```
