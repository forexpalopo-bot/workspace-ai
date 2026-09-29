# Catatan riset backtest

Diisi oleh Antigravity setelah menjalankan `research/scenarios.json`. Format bebas, maksimal 15 baris per putaran.

## Putaran 1 (v79)
- **Skenario terbaik**: **S5** (Survive_Adverse_Move_Pips 8000), disusul **S6** (S5 + Pair Close L3).
- S5 memangkas max DD (19.36%), net/DD tertinggi (5.64). S6 meminimalkan worst order (-$91.41 vs baseline -$1791.88).
- Tabel ringkasan P1 (data tick P2 tidak tersedia di dataset lokal):
| skenario | net_profit | max_dd_pct | rel_dd_pct | largest_order_loss | net_per_dd |
|---|---|---|---|---|---|
| S0 / S1 | 36335.47 / 33699.43 | 43.48% / 44.02% | 47.19% / 48.57% | -1791.88 / -1705.25 | 3.50 / 3.40 |
| S2 / S4 | 14671.21 / 13626.40 | 39.89% / 41.08% | 60.83% / 61.70% | -433.50 / -422.38 | 3.77 / 3.64 |
| S3 | 502.09 | 78.74% | 78.74% | -254.02 | 0.41 |
| S5 / S6 | 3929.24 / 3522.36 | 19.36% / 21.38% | 43.21% / 43.21% | -145.04 / -91.41 | 5.64 / 5.06 |
| S7 / S8 | 3998.07 / 27923.15 | 24.44% / 43.56% | 43.21% / 47.71% | -154.30 / -1400.74 | 4.48 / 3.42 |
- Log: S3 gagal karena cut di L2 merusak recovery. Pair close L3 (S2/S4/S6) memperpanjang basket ke L4+. Nol order error.
- Tools: run_mt4_batch.py disesuaikan untuk MT4 build 1441 (task scheduler LaunchMT4 dan deposit $500).
