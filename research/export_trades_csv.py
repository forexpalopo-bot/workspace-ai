import sys
import os
import csv
from datetime import datetime
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from analyze_mt4_report import parse_report

def export_trades(report_htm, output_csv):
    summary, closed = parse_report(report_htm)
    print(f"Exporting {len(closed)} orders from {report_htm} to {output_csv}...")
    
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['ticket', 'open_time', 'type', 'lots', 'open_price', 'close_time', 'close_price', 'profit', 'day_of_week', 'duration_minutes'])
        
        for o in closed:
            dt_o = datetime.strptime(o['open'], "%Y.%m.%d %H:%M")
            dt_c = datetime.strptime(o['close'], "%Y.%m.%d %H:%M")
            dur = (dt_c - dt_o).total_seconds() / 60.0
            dow = dt_o.strftime('%A')
            writer.writerow([
                o['id'], o['open'], o['type'], o['lots'], o['op'],
                o['close'], o['cp'], o['profit'], dow, f"{dur:.1f}"
            ])
    print(f"Sukses! File tersimpan: {output_csv} ({os.path.getsize(output_csv)} bytes)")

if __name__ == '__main__':
    export_trades('backtests/runs/V94_L1_ONLY_FULL.htm', 'research/trades_v94_l1_only.csv')
    if os.path.exists('backtests/runs/V94_L1_EMA200_FULL.htm'):
        export_trades('backtests/runs/V94_L1_EMA200_FULL.htm', 'research/trades_v94_l1_ema200.csv')
