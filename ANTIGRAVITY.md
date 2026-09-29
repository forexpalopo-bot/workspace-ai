# Brief untuk Antigravity: riset backtest BioOnePro (MT4, XAUUSD)

Repo ini dikerjakan bergantian oleh Claude Code (analisis dan kode EA, di cloud) dan Antigravity
(menjalankan MT4 di komputer Windows pengguna). **Git adalah satu-satunya jalur koordinasi.**
Tarik branch terbaru, kerjakan tugas di bawah, lalu commit dan push hasilnya.

Branch kerja: `claude/cek-xb7zbt`

## Konteks singkat
- EA: grid martingale XAUUSD M1 dengan L1 searah tren H1. Lihat `docs/analisis-v77-dan-perubahan-v78.md`.
- Masalah utama v77: tidak ada basket yang rugi, tetapi drawdown floating sempat 43–47%, nyaris
  menyentuh cut-loss 50%. Loss order terbesar selalu **L1 di basket 3 layer** (−$1,792, −$1,652, −$926).
- EA yang diuji: `ea/BioOnePro_Optimized_v79_Apex_PairClose.mq4`. Semua fitur baru default mati;
  skenario S0 harus mereproduksi hasil v77 (net $36,259.95, DD 43.48%).

## Tugas
1. Salin `ea/BioOnePro_Optimized_v79_Apex_PairClose.mq4` ke `<data MT4>/MQL4/Experts/`, lalu kompilasi di MetaEditor.
   - Jika ada error atau warning kompilasi, catat baris dan pesannya di `research/NOTES.md`, commit, lalu **berhenti**.
     Jangan memperbaiki logika EA sendiri.
2. Pastikan data tick XAUUSD M1 tersedia untuk periode P1 dan P2 (`research/scenarios.json`).
   Jika P2 tidak tersedia, jalankan P1 saja dan catat.
3. Jalankan batch (MT4 harus tertutup):
   ```
   python tools/run_mt4_batch.py --terminal "<path>\terminal.exe" --data-dir "<data MT4>" --only S0 --period-set P1
   ```
   Cocokkan S0 dengan v77. Jika hasilnya berbeda jauh, catat di NOTES.md dan berhenti.
   Jika sama, jalankan semua skenario:
   ```
   python tools/run_mt4_batch.py --terminal "<path>\terminal.exe" --data-dir "<data MT4>"
   ```
   - Jika config otomatis tidak jalan di build MT4 tersebut, jalankan manual di Strategy Tester memakai file
     `.set` yang sudah dibuat script di `<data MT4>/tester/`. Simpan laporan sebagai `backtests/runs/<S#>_<P#>.htm`,
     lalu jalankan `python tools/analyze_mt4_report.py backtests/runs/*.htm --csv research/results.csv`.
4. Commit dan push:
   - `research/results.csv`,
   - `backtests/runs/*.htm`,
   - `research/NOTES.md`: temuan singkat maksimal 15 baris, misalnya skenario terbaik menurut `net_per_dd`
     dengan `rel_dd_pct` < 30, dan kejadian aneh di Journal seperti error order atau "PAIR CLOSE gagal".

## Aturan
- Jangan ubah file di `ea/` dan `tools/` kecuali untuk memperbaiki error yang mencegah script berjalan.
  Jika terpaksa, jelaskan perubahannya di NOTES.md.
- Jangan menjalankan optimisasi genetik dengan banyak parameter sekaligus: risiko overfitting tinggi, dan satu tahun data terlalu sedikit.
  Jika ingin menambah skenario, tambahkan entri baru di `research/scenarios.json` (ubah 1–2 parameter per skenario).
- Kriteria "lebih baik", berurutan:
  1. `rel_dd_pct` dan `max_dd_pct` lebih rendah,
  2. `largest_order_loss` lebih kecil,
  3. `net_per_dd` lebih tinggi.
  Net profit terbesar **bukan** kriteria utama.

## Setelah selesai
Beritahu pengguna agar meminta Claude Code membaca `research/results.csv` dan `research/NOTES.md`
untuk analisis putaran berikutnya.
