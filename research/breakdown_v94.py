import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from analyze_mt4_report import parse_report, build_baskets

report_path = sys.argv[1] if len(sys.argv) > 1 else 'backtests/runs/V94_TIER_M1_FULL.htm'
summary, closed = parse_report(report_path)
baskets = build_baskets(closed)

print(f"Summary Total Trades: {summary.get('total_trades')}, Net: {summary.get('net_profit')}, MaxDD: {summary.get('max_dd')}")
print(f"Total Baskets: {len(baskets)}")

by_year = {}
for b in baskets:
    y = b['orders'][0]['open'][:4]
    if y not in by_year:
        by_year[y] = {'baskets': 0, 'orders': 0, 'net': 0.0, 'wins': 0, 'losses': 0, 'worst': 0.0, 'l4plus': 0}
    by_year[y]['baskets'] += 1
    by_year[y]['orders'] += len(b['orders'])
    by_year[y]['net'] += b['pnl']
    if b['pnl'] > 0:
        by_year[y]['wins'] += 1
    elif b['pnl'] < 0:
        by_year[y]['losses'] += 1
    if b['pnl'] < by_year[y]['worst']:
        by_year[y]['worst'] = b['pnl']
    if len(b['orders']) >= 4:
        by_year[y]['l4plus'] += 1

print("\n--- ANNUAL BREAKDOWN OF BASKETS ---")
print(f"{'Year':<6} | {'Baskets':<8} | {'Orders':<8} | {'Net Profit':<12} | {'WinRate':<8} | {'Worst Basket':<12}")
print("-" * 65)
for y in sorted(by_year.keys()):
    st = by_year[y]
    wr = (st['wins'] / st['baskets'] * 100.0) if st['baskets'] > 0 else 0
    print(f"{y:<6} | {st['baskets']:<8} | {st['orders']:<8} | ${st['net']:<11.2f} | {wr:<7.1f}% | ${st['worst']:<11.2f}")
