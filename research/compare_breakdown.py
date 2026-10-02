import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from analyze_mt4_report import parse_report, build_baskets

files = {
    'Tiered (3->2->1)': 'backtests/runs/V94_TIER_M1_FULL.htm',
    'L1-Only (Sniper)': 'backtests/runs/V94_L1_ONLY_FULL.htm',
    'Base (Binary)': 'backtests/runs/V94_BASE_M1_FULL.htm'
}

data = {}
for name, fpath in files.items():
    s, closed = parse_report(fpath)
    baskets = build_baskets(closed)
    by_year = {}
    for b in baskets:
        y = b['orders'][0]['open'][:4]
        if y not in by_year:
            by_year[y] = {
                'baskets': 0, 'orders': 0, 'net': 0.0,
                'gross_win': 0.0, 'gross_loss': 0.0,
                'wins': 0, 'losses': 0, 'worst': 0.0,
                'l1_count': 0, 'l2_count': 0, 'l3_count': 0
            }
        by_year[y]['baskets'] += 1
        num_ord = len(b['orders'])
        by_year[y]['orders'] += num_ord
        if num_ord == 1:
            by_year[y]['l1_count'] += 1
        elif num_ord == 2:
            by_year[y]['l2_count'] += 1
        elif num_ord >= 3:
            by_year[y]['l3_count'] += 1
        by_year[y]['net'] += b['pnl']
        if b['pnl'] > 0:
            by_year[y]['wins'] += 1
            by_year[y]['gross_win'] += b['pnl']
        elif b['pnl'] < 0:
            by_year[y]['losses'] += 1
            by_year[y]['gross_loss'] += b['pnl']
        if b['pnl'] < by_year[y]['worst']:
            by_year[y]['worst'] = b['pnl']
    data[name] = by_year

years = sorted(list(set(list(data['Tiered (3->2->1)'].keys()) + list(data['L1-Only (Sniper)'].keys()))))

print("=" * 110)
print(f"{'Year':<5} | {'Metric':<18} | {'Tiered Gate (3->2->1)':<24} | {'L1-Only (Sniper)':<24} | {'Delta (Tier - L1)':<18}")
print("=" * 110)

tot_t_net = 0.0
tot_l_net = 0.0

for y in years:
    t = data['Tiered (3->2->1)'].get(y, {'net':0,'baskets':0,'orders':0,'wins':0,'losses':0,'worst':0,'gross_win':0,'gross_loss':0,'l1_count':0,'l2_count':0,'l3_count':0})
    l = data['L1-Only (Sniper)'].get(y, {'net':0,'baskets':0,'orders':0,'wins':0,'losses':0,'worst':0,'gross_win':0,'gross_loss':0,'l1_count':0,'l2_count':0,'l3_count':0})
    
    tot_t_net += t['net']
    tot_l_net += l['net']
    diff_net = t['net'] - l['net']
    
    t_wr = (t['wins'] / t['baskets'] * 100.0) if t['baskets'] > 0 else 0
    l_wr = (l['wins'] / l['baskets'] * 100.0) if l['baskets'] > 0 else 0
    
    t_avg_w = (t['gross_win'] / t['wins']) if t['wins'] > 0 else 0
    t_avg_l = (t['gross_loss'] / t['losses']) if t['losses'] > 0 else 0
    l_avg_w = (l['gross_win'] / l['wins']) if l['wins'] > 0 else 0
    l_avg_l = (l['gross_loss'] / l['losses']) if l['losses'] > 0 else 0
    
    print(f"{y:<5} | Net Profit         | ${t['net']:>10.2f}             | ${l['net']:>10.2f}             | ${diff_net:>+10.2f}")
    print(f"      | Baskets (Win Rate) | {t['baskets']:>4d} ({t_wr:>5.1f}%)            | {l['baskets']:>4d} ({l_wr:>5.1f}%)            | {t['baskets'] - l['baskets']:>+4d} baskets")
    print(f"      | Orders (L1/L2/L3)  | {t['orders']:>4d} ({t['l1_count']}/{t['l2_count']}/{t['l3_count']})          | {l['orders']:>4d} ({l['l1_count']}/{l['l2_count']}/{l['l3_count']})          | {t['orders'] - l['orders']:>+4d} orders")
    print(f"      | Avg Win / Avg Loss | +${t_avg_w:>5.2f} / ${t_avg_l:>6.2f}     | +${l_avg_w:>5.2f} / ${l_avg_l:>6.2f}     | -")
    print(f"      | Worst Basket       | ${t['worst']:>10.2f}             | ${l['worst']:>10.2f}             | ${t['worst'] - l['worst']:>+10.2f}")
    print("-" * 110)

print(f"TOTAL | Net Profit         | ${tot_t_net:>10.2f}             | ${tot_l_net:>10.2f}             | ${tot_t_net - tot_l_net:>+10.2f}")
print("=" * 110)
