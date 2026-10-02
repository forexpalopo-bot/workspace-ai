import csv
import numpy as np

def load_trades(csv_path="research/trades_v94_l1_ema200.csv"):
    trades = []
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            trades.append({
                'year': r['open_time'][:4],
                'profit': float(r['profit'])
            })
    return trades

trades = load_trades()
pnls = np.array([t['profit'] for t in trades])
years = sorted(list(set(t['year'] for t in trades)))

print("=" * 80)
print("1. LEAVE-ONE-YEAR-OUT (LOYO) TEST (SELURUH 7 TAHUN)")
print("=" * 80)
print(f"{'Year Excluded':<15} | {'Trades Left':<12} | {'Net Profit':<14} | {'PF':<8} | {'Win Rate':<10}")
print("-" * 80)

for y in years:
    sub = [t['profit'] for t in trades if t['year'] != y]
    sub = np.array(sub)
    net = np.sum(sub)
    wins = sub[sub > 0]
    losses = sub[sub < 0]
    pf = (np.sum(wins) / abs(np.sum(losses))) if len(losses) > 0 else 999.0
    wr = len(wins) / len(sub) * 100
    print(f"Leave {y:<9} | {len(sub):<12} | ${net:>11.2f}  | {pf:>6.2f} | {wr:>8.1f}%")

print("=" * 80)

print("\n" + "=" * 80)
print("2. MONTE CARLO SEQUENCE RESAMPLING (5,000 RUNS)")
print("=" * 80)

np.random.seed(42)
n_sims = 5000
mc_max_dds = []
mc_consec_losses = []

for _ in range(n_sims):
    # Reshuffle order sequence
    shuffled = np.random.permutation(pnls)
    equity = np.cumsum(shuffled) + 3000.0
    peak = np.maximum.accumulate(equity)
    dd_cash = peak - equity
    dd_pct = (dd_cash / peak) * 100.0
    mc_max_dds.append(np.max(dd_pct))
    
    # Calculate consecutive loss streak
    max_streak = 0
    cur_streak = 0
    for p in shuffled:
        if p < 0:
            cur_streak += 1
            if cur_streak > max_streak:
                max_streak = cur_streak
        else:
            cur_streak = 0
    mc_consec_losses.append(max_streak)

print(f"Max DD 50th Percentile (Median) : {np.percentile(mc_max_dds, 50):.2f}%")
print(f"Max DD 90th Percentile          : {np.percentile(mc_max_dds, 90):.2f}%")
print(f"Max DD 95th Percentile          : {np.percentile(mc_max_dds, 95):.2f}%")
print(f"Max DD 99th Percentile          : {np.percentile(mc_max_dds, 99):.2f}%")
print(f"Worst Case Max DD in 5,000 Runs : {np.max(mc_max_dds):.2f}%")
print("-" * 80)
print(f"Consecutive Losses Median       : {np.percentile(mc_consec_losses, 50):.0f} orders")
print(f"Consecutive Losses 95th Pct     : {np.percentile(mc_consec_losses, 95):.0f} orders")
print(f"Consecutive Losses 99th Pct     : {np.percentile(mc_consec_losses, 99):.0f} orders")
print("=" * 80)
