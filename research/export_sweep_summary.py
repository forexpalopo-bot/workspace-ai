import csv
import os
import sys

def summarize_sweep(csv_path="research/results_sensitivity_and_controls.csv"):
    if not os.path.exists(csv_path):
        print(f"File {csv_path} does not exist.")
        return

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print("=" * 105)
    print("      RINGKASAN UJI SENSITIVITAS (EMA 50/150/250) & NEGATIVE CONTROL (REVERSE VETO)      ")
    print("=" * 105)
    header = f"{'Scenario':<18} | {'Description':<32} | {'Net Profit':<12} | {'PF':<6} | {'Max DD':<18} | {'Orders':<8}"
    print(header)
    print("-" * 105)

    for r in rows:
        sc = r.get('scenario', '')
        desc = r.get('desc', '')[:30]
        net = float(r.get('net_profit', 0))
        pf = float(r.get('profit_factor', 0))
        dd_pct = float(r.get('max_dd_pct', 0))
        dd_cash = float(r.get('max_dd_money', 0))
        orders = int(r.get('orders', 0))

        print(f"{sc:<18} | {desc:<32} | ${net:>10.2f} | {pf:>5.2f} | ${dd_cash:>8.2f} ({dd_pct:>5.2f}%) | {orders:>8}")

    print("=" * 105)

if __name__ == '__main__':
    csv_file = sys.argv[1] if len(sys.argv) > 1 else "research/results_sensitivity_and_controls.csv"
    summarize_sweep(csv_file)
