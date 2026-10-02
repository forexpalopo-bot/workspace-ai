import sys
import os
import csv
from datetime import datetime
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from analyze_mt4_report import parse_report

def main():
    htm_path = 'backtests/runs/V94_EMA200_ALIGNED_FULL.htm'
    summary, closed = parse_report(htm_path)
    print(f"Total orders parsed from {htm_path}: {len(closed)}")

    csv_path = 'research/trades_v94_aligned.csv'
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['ticket', 'open_time', 'type', 'lots', 'open_price', 'close_time', 'close_price', 'profit', 'day_of_week', 'duration_minutes'])
        for o in closed:
            dt_o = datetime.strptime(o['open'], "%Y.%m.%d %H:%M")
            dt_c = datetime.strptime(o['close'], "%Y.%m.%d %H:%M")
            dur = (dt_c - dt_o).total_seconds() / 60.0
            dow = dt_o.strftime('%A')
            writer.writerow([o['id'], o['open'], o['type'], o['lots'], o['op'], o['close'], o['cp'], o['profit'], dow, f"{dur:.1f}"])

    trades = []
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            trades.append({
                'ticket': int(r['ticket']),
                'open_time': r['open_time'],
                'close_time': r['close_time'],
                'profit': float(r['profit']),
                'year': r['open_time'][:4],
                'lots': float(r['lots'])
            })

    years = sorted(list(set(t['year'] for t in trades)))
    print("=" * 85)
    print("TABEL KINERJA TAHUNAN RINCI V94_EMA200_ALIGNED_FULL")
    print("=" * 85)
    header = f"{'Tahun':<8} | {'Orders':<8} | {'Win Rate':<10} | {'Gross Win':<12} | {'Gross Loss':<12} | {'Net Profit':<12} | {'PF':<6}"
    print(header)
    print("-" * 85)

    for y in years:
        sub = [t for t in trades if t['year'] == y]
        n = len(sub)
        wins = [t['profit'] for t in sub if t['profit'] > 0]
        losses = [t['profit'] for t in sub if t['profit'] < 0]
        gw = sum(wins)
        gl = sum(losses)
        net = gw + gl
        wr = len(wins) / n * 100 if n > 0 else 0
        pf = (gw / abs(gl)) if abs(gl) > 0 else 999.0
        print(f"{y:<8} | {n:<8} | {wr:>8.1f}% | ${gw:>10.2f} | ${gl:>10.2f} | ${net:>10.2f} | {pf:>5.2f}")
    print("=" * 85)

    tot_gw = sum(t['profit'] for t in trades if t['profit'] > 0)
    tot_gl = sum(t['profit'] for t in trades if t['profit'] < 0)
    tot_net = tot_gw + tot_gl
    tot_pf = tot_gw / abs(tot_gl)
    avg_win = tot_gw / len([t for t in trades if t['profit'] > 0])
    avg_loss = abs(tot_gl) / len([t for t in trades if t['profit'] < 0])
    print(f"TOTAL: {len(trades)} orders | Net: ${tot_net:.2f} | Gross Win: ${tot_gw:.2f} | Gross Loss: ${tot_gl:.2f} | PF: {tot_pf:.2f}")
    print(f"Rata-rata Menang: ${avg_win:.2f} | Rata-rata Rugi: ${avg_loss:.2f} | Payoff Ratio: {avg_win/avg_loss:.3f}")

    is_trades = [t for t in trades if t['year'] in ['2020', '2021', '2022']]
    oos_trades = [t for t in trades if t['year'] in ['2023', '2024', '2025', '2026']]

    is_net = sum(t['profit'] for t in is_trades)
    is_wins = [t['profit'] for t in is_trades if t['profit'] > 0]
    is_losses = [t['profit'] for t in is_trades if t['profit'] < 0]
    is_pf = sum(is_wins) / abs(sum(is_losses)) if is_losses else 999.0

    oos_net = sum(t['profit'] for t in oos_trades)
    oos_wins = [t['profit'] for t in oos_trades if t['profit'] > 0]
    oos_losses = [t['profit'] for t in oos_trades if t['profit'] < 0]
    oos_pf = sum(oos_wins) / abs(sum(oos_losses)) if oos_losses else 999.0

    print(f"\n1. IN-SAMPLE (2020-2022, 3 Tahun Penuh):")
    print(f"   - Total Orders: {len(is_trades)}")
    print(f"   - Win Rate: {len(is_wins)/len(is_trades)*100:.1f}%")
    print(f"   - Gross Win: ${sum(is_wins):.2f} | Gross Loss: ${sum(is_losses):.2f}")
    print(f"   - Net Profit: ${is_net:.2f} | PF: {is_pf:.2f}")

    print(f"\n2. OUT-OF-SAMPLE (2023-2026.09, 3 Tahun 9 Bulan):")
    print(f"   - Total Orders: {len(oos_trades)}")
    print(f"   - Win Rate: {len(oos_wins)/len(oos_trades)*100:.1f}%")
    print(f"   - Gross Win: ${sum(oos_wins):.2f} | Gross Loss: ${sum(oos_losses):.2f}")
    print(f"   - Net Profit: ${oos_net:.2f} | PF: {oos_pf:.2f}")

    # Cek Komisi IC Markets Raw ($7 per round-turn standard lot = $0.07 per 0.01 lot)
    total_lots = sum(t['lots'] for t in trades)
    est_commission = total_lots * 7.0  # $7 per 1.0 lot
    net_after_comm = tot_net - est_commission
    print(f"\n3. AUDIT BIAYA KOMISI (IC Markets Raw $7/lot round turn):")
    print(f"   - Total Lots Terakumulasi: {total_lots:.2f} lots")
    print(f"   - Estimasi Komisi Total: ${est_commission:.2f}")
    print(f"   - Net Profit Setelah Komisi: ${net_after_comm:.2f}")
    print(f"   - Rasio Beban Komisi terhadap Net: {est_commission/tot_net*100:.2f}%")

if __name__ == '__main__':
    main()
