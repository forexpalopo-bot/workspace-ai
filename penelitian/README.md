# Folder penelitian

Struktur folder di komputer Windows (dibuat Antigravity, lihat `prompts/antigravity-putaran-01.md`):

```
C:\Penelitian_EA\BioOnePro\
  ├─ repo\                   clone repo ini (branch claude/cek-xb7zbt)
  └─ arsip\putaran-XX\
       ├─ laporan\           laporan .htm MT4
       ├─ set\               file .set yang dipakai
       └─ log\               potongan log Journal/Experts
```

Hasil yang dibagikan ke Claude Code lewat git:
- `research/results.csv`: satu baris per backtest (dibuat `tools/run_mt4_batch.py`)
- `research/NOTES.md`: ringkasan temuan tiap putaran
- `backtests/runs/`: laporan .htm tiap skenario
