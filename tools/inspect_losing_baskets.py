import sys
from analyze_mt4_report import parse_report, build_baskets

report_path = sys.argv[1] if len(sys.argv) > 1 else 'backtests/runs/V94_TEST_T2020.htm'
summary, closed = parse_report(report_path)
baskets = build_baskets(closed)
losing = [b for b in baskets if b['pnl'] < 0]

print(f"Total baskets: {len(baskets)}")
print(f"Losing baskets: {len(losing)} ({len(losing)/len(baskets)*100:.1f}%)")
print(f"Winning baskets: {len(baskets)-len(losing)}")

losing_sorted = sorted(losing, key=lambda x: x['pnl'])
print("\n=== TOP 25 LOSING BASKETS ===")
for i, b in enumerate(losing_sorted[:25]):
    n = len(b['orders'])
    tot_lot = b['lots']
    first_op = b['orders'][0]['open']
    last_cl = b['orders'][-1]['close']
    print(f"#{i+1:2d}: Loss={b['pnl']:8.2f} | Orders={n} | Lots={tot_lot:.2f} | Open={first_op} | Close={last_cl}")
    for o in b['orders']:
        print(f"     Order #{o['id']}: {o['type']} {o['lots']} lot at {o['op']} -> {o['cp']} ({o['profit']:.2f})")

friday_cuts = [b for b in losing if "19:00" in b['orders'][-1]['close'] or "18:59" in b['orders'][-1]['close']]
sl_hits = [b for b in losing if b not in friday_cuts]

print("\n=== BREAKDOWN BY LOSS TYPE ===")
print(f"Friday cuts: {len(friday_cuts)} baskets, total loss = {sum(b['pnl'] for b in friday_cuts):.2f}")
print(f"SL / Other hits: {len(sl_hits)} baskets, total loss = {sum(b['pnl'] for b in sl_hits):.2f}")
