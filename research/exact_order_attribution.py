import sys
import os
from datetime import datetime
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from analyze_mt4_report import parse_report, build_baskets

base_summary, base_closed = parse_report('backtests/runs/V94_L1_ONLY_FULL.htm')
ema_summary, ema_closed = parse_report('backtests/runs/V94_L1_EMA200_FULL.htm')

print(f"Base Orders: {len(base_closed)} | EMA200 Orders: {len(ema_closed)}")

# Map open times to match orders between runs
# Since both are M1 sniper L1, matching by open time window (within 5 minutes) identifies the same trade
ema_open_times = set(o['open'] for o in ema_closed)

blocked_orders = []
kept_orders = []

for o in base_closed:
    # check if an order with same open time exists in ema_closed
    if o['open'] in ema_open_times:
        kept_orders.append(o)
    else:
        blocked_orders.append(o)

print(f"Kept Orders: {len(kept_orders)} | Blocked Orders: {len(blocked_orders)}")

# Calculate P&L of blocked orders
blocked_pnl = sum(o['profit'] for o in blocked_orders)
blocked_wins = [o for o in blocked_orders if o['profit'] > 0]
blocked_losses = [o for o in blocked_orders if o['profit'] < 0]

print(f"Total P&L of Blocked Orders: ${blocked_pnl:.2f}")
print(f"Blocked Wins: {len(blocked_wins)} (${sum(o['profit'] for o in blocked_wins):.2f})")
print(f"Blocked Losses: {len(blocked_losses)} (${sum(o['profit'] for o in blocked_losses):.2f})")

# Check Friday cut distribution of blocked orders
def is_fc(o):
    dt = datetime.strptime(o['close'], "%Y.%m.%d %H:%M")
    return dt.weekday() == 4 and (dt.hour == 19 or (dt.hour == 18 and dt.minute >= 45))

blocked_fc = [o for o in blocked_orders if is_fc(o)]
print(f"Blocked Friday Cut Orders: {len(blocked_fc)} | P&L: ${sum(o['profit'] for o in blocked_fc):.2f}")

# Top 20 worst losses of baseline
sorted_base_losses = sorted(base_closed, key=lambda x: x['profit'])
top20_worst = sorted_base_losses[:20]
top20_blocked = [o for o in top20_worst if o in blocked_orders]

print(f"\nTop 20 Worst Losses in Baseline:")
print(f"Worst Order Loss: ${top20_worst[0]['profit']:.2f}")
print(f"Average of Top 20 Worst: ${sum(o['profit'] for o in top20_worst)/20:.2f}")
print(f"Number of Top 20 Worst blocked by EMA200 Veto: {len(top20_blocked)} of 20 ({len(top20_blocked)/20*100:.1f}%)")

print("\n--- Detail Order Terburuk Baseline yang Diblokir oleh EMA 200 ---")
for i, o in enumerate(top20_blocked):
    print(f"#{i+1} Order: {o.get('order', i+1)} | Open: {o['open']} {o['type']} | Close: {o['close']} | Profit: ${o['profit']:.2f}")

