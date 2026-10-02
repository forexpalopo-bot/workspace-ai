import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from analyze_mt4_report import parse_report

def audit_q1(htm_path):
    s, closed = parse_report(htm_path)
    print(f"=== {os.path.basename(htm_path)} (Deposit: ${s['deposit']}, Net: ${s['net_profit']}, Max DD: {s['max_dd']}) ===")
    
    # Track equity drawdown
    bal = float(s['deposit'])
    peak = bal
    peak_date = ""
    max_dd = 0.0
    dd_peak = 0.0
    dd_trough = 0.0
    trough_date = ""
    
    dd_events = []
    
    for o in closed:
        p = float(o['profit'])
        bal += p
        if bal > peak:
            peak = bal
            peak_date = o['close']
        dd = peak - bal
        if dd > max_dd:
            max_dd = dd
            dd_peak = peak
            dd_trough = bal
            trough_date = o['close']
            dd_events.append((peak_date, trough_date, round(max_dd, 2), o['lots'], o['open'], o['close'], p))
            
    print(f"Max Closed DD: ${max_dd:.2f} | Peak: ${dd_peak:.2f} ({peak_date}) -> Trough: ${dd_trough:.2f} ({trough_date})")
    print("5 peningkatan DD terbesar:")
    for ev in dd_events[-5:]:
        print(f"  Peak: {ev[0]} -> Trough: {ev[1]} | DD: ${ev[2]} | Last Trade Lot: {ev[3]} | Profit: ${ev[6]}")

if __name__ == '__main__':
    audit_q1('backtests/runs/V94_EMA200_ALIGNED_FULL.htm')
    print()
    audit_q1('backtests/runs/V94_10K_RISK1PCT_FULL.htm')
