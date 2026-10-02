import sys
import os
from datetime import datetime
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from analyze_mt4_report import parse_report, build_baskets

report_path = sys.argv[1] if len(sys.argv) > 1 else 'backtests/runs/V94_L1_ONLY_FULL.htm'
summary, closed = parse_report(report_path)
baskets = build_baskets(closed)

print(f"Total Baskets: {len(baskets)}")

# Analisis Hari dalam Seminggu saat Buka Posisi
by_day = {0: 'Mon', 1: 'Tue', 2: 'Wed', 3: 'Thu', 4: 'Fri', 5: 'Sat', 6: 'Sun'}
day_stats = {d: {'count': 0, 'wins': 0, 'losses': 0, 'net': 0.0, 'gross_win': 0.0, 'gross_loss': 0.0} for d in by_day.values()}

# Analisis Friday Close (Semua trade yang ditutup Jumat jam 18:00 - 19:59)
friday_cuts_win = []
friday_cuts_loss = []
other_trades = []

for b in baskets:
    dt_open = datetime.strptime(b['orders'][0]['open'], "%Y.%m.%d %H:%M")
    day_name = by_day[dt_open.weekday()]
    
    st = day_stats[day_name]
    st['count'] += 1
    st['net'] += b['pnl']
    if b['pnl'] > 0:
        st['wins'] += 1
        st['gross_win'] += b['pnl']
    elif b['pnl'] < 0:
        st['losses'] += 1
        st['gross_loss'] += b['pnl']
        
    dt_close = datetime.strptime(b['orders'][-1]['close'], "%Y.%m.%d %H:%M")
    # Cek apakah ditutup saat Friday Cut (Jumat >= 18:30)
    if dt_close.weekday() == 4 and (dt_close.hour == 19 or (dt_close.hour == 18 and dt_close.minute >= 45)):
        if b['pnl'] > 0:
            friday_cuts_win.append(b)
        else:
            friday_cuts_loss.append(b)
    else:
        other_trades.append(b)

print("\n" + "=" * 80)
print(f"{'Day of Week':<12} | {'Baskets':<8} | {'Win Rate':<10} | {'Net Profit':<12} | {'Gross Win':<12} | {'Gross Loss':<12}")
print("=" * 80)
for d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']:
    s = day_stats[d]
    wr = (s['wins'] / s['count'] * 100) if s['count'] > 0 else 0
    print(f"{d:<12} | {s['count']:<8} | {wr:<9.1f}% | ${s['net']:<11.2f} | ${s['gross_win']:<11.2f} | ${s['gross_loss']:<11.2f}")
print("=" * 80)

print("\n" + "=" * 80)
print("ANALISIS TOTAL FRIDAY CUTOFF (WINNERS vs LOSERS)")
print("=" * 80)
total_fc_win_pnl = sum(b['pnl'] for b in friday_cuts_win)
total_fc_loss_pnl = sum(b['pnl'] for b in friday_cuts_loss)
total_fc_net = total_fc_win_pnl + total_fc_loss_pnl

print(f"Friday Cut Menang : {len(friday_cuts_win)} basket | Total Profit : +${total_fc_win_pnl:.2f} (Rata-rata: +${total_fc_win_pnl/max(1, len(friday_cuts_win)):.2f})")
print(f"Friday Cut Rugi   : {len(friday_cuts_loss)} basket | Total Loss   : ${total_fc_loss_pnl:.2f} (Rata-rata: ${total_fc_loss_pnl/max(1, len(friday_cuts_loss)):.2f})")
print(f"NET FRIDAY CUT    : {len(friday_cuts_win) + len(friday_cuts_loss)} basket | Net P&L      : ${total_fc_net:.2f}")

other_win = sum(b['pnl'] for b in other_trades if b['pnl'] > 0)
other_loss = sum(b['pnl'] for b in other_trades if b['pnl'] < 0)
print(f"\nTrade Non-FridayCut: {len(other_trades)} basket | Net P&L      : +${other_win + other_loss:.2f} (Win: +${other_win:.2f}, Loss: ${other_loss:.2f})")
print("=" * 80)
