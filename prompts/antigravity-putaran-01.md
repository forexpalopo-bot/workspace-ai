# Prompt Antigravity — Putaran 1

Salin seluruh teks di dalam blok berikut ke Antigravity.

```text
Kamu membantu riset EA MT4 "BioOnePro" (XAUUSD M1). Analisis dan kode EA dikerjakan Claude Code di repo GitHub.
Tugasmu: menyiapkan folder penelitian di komputer ini, menjalankan backtest di MT4, lalu mengirim hasilnya lewat git.
Kerjakan langkah demi langkah dan hemat: jangan membaca atau menjelaskan ulang seluruh kode EA.

LANGKAH 1 — Siapkan folder penelitian di komputer ini
Buat struktur berikut (jika sudah ada, pakai yang ada):
C:\Penelitian_EA\BioOnePro\
  ├─ repo\                       <- clone repo di sini
  └─ arsip\putaran-01\
       ├─ laporan\               <- salinan laporan .htm dari MT4
       ├─ set\                   <- salinan file .set yang dipakai
       └─ log\                   <- potongan log Journal/Experts yang penting
Lalu jalankan:
  git clone https://github.com/forexpalopo-bot/workspace-ai.git C:\Penelitian_EA\BioOnePro\repo
  cd C:\Penelitian_EA\BioOnePro\repo
  git checkout claude/cek-xb7zbt
  git pull
Setelah itu baca file ANTIGRAVITY.md di root repo. File itu adalah brief tugas lengkap dan aturannya wajib diikuti.

LANGKAH 2 — Temukan MT4
Cari lokasi terminal.exe MT4 (IC Markets) dan folder datanya. Folder data bisa dilihat di MT4 lewat
File > Open Data Folder, biasanya C:\Users\<nama>\AppData\Roaming\MetaQuotes\Terminal\<ID>.
Jika tidak yakin, tanyakan kepada saya, jangan menebak.

LANGKAH 3 — Kompilasi EA
Salin repo\ea\BioOnePro_Optimized_v79_Apex_PairClose.mq4 ke <folder data>\MQL4\Experts\, lalu kompilasi dengan MetaEditor
(metaeditor.exe /compile:"<path file .mq4>" /log). Jika ada error, tulis pesan error dan nomor barisnya
di repo\research\NOTES.md, commit, push, lalu BERHENTI dan beri tahu saya.

LANGKAH 4 — Backtest baseline (S0)
Tutup MT4, lalu jalankan dari folder repo:
  python tools\run_mt4_batch.py --terminal "<path terminal.exe>" --data-dir "<folder data>" --only S0 --period-set P1
Hasil S0 harus mendekati v77: net profit $36,259.95 dan max drawdown 43.48%.
Jika berbeda jauh atau laporan tidak terbentuk, catat di research\NOTES.md, commit, push, lalu BERHENTI.
Jika config otomatis tidak berjalan, jalankan S0 manual di Strategy Tester (Every tick, spread 20,
2025.09.29–2026.09.25, file .set dari <folder data>\tester\S0_P1.set). Simpan laporannya sebagai
repo\backtests\runs\S0_P1.htm, lalu jalankan:
  python tools\analyze_mt4_report.py backtests\runs\S0_P1.htm --csv research\results.csv

LANGKAH 5 — Semua skenario
Jika S0 cocok, jalankan semua skenario (S0–S8, periode P1 dan P2):
  python tools\run_mt4_batch.py --terminal "<path terminal.exe>" --data-dir "<folder data>"
Jika data tick periode P2 tidak tersedia, jalankan P1 saja dan catat hal itu.

LANGKAH 6 — Arsip lokal dan kirim hasil
- Salin laporan .htm ke arsip\putaran-01\laporan\, file .set ke arsip\putaran-01\set\,
  dan baris penting dari log MT4 (error order, "PAIR CLOSE", "GRID RISK REPORT", "CUT-LOSS") ke arsip\putaran-01\log\.
- Isi repo\research\NOTES.md di bagian "Putaran 1" (maksimal 15 baris):
  * skenario terbaik menurut urutan kriteria di ANTIGRAVITY.md,
  * tabel singkat: skenario, net_profit, max_dd_pct, rel_dd_pct, largest_order_loss, net_per_dd,
  * kejadian aneh yang terlihat di log.
- Commit dan push ke branch claude/cek-xb7zbt:
  git add research backtests\runs
  git commit -m "Hasil backtest putaran 1 (v79)"
  git push origin claude/cek-xb7zbt

ATURAN
- Jangan ubah logika EA (folder ea\). Jika script di tools\ perlu diperbaiki agar bisa berjalan, lakukan
  perbaikan minimal dan jelaskan di NOTES.md.
- Jangan menjalankan optimisasi genetik dengan banyak parameter sekaligus.
- Jangan mengarang angka. Semua angka harus berasal dari laporan MT4.
- Setelah selesai, katakan kepada saya: "Putaran 1 selesai, minta Claude Code membaca research/results.csv dan research/NOTES.md".
```
