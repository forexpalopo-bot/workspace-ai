import csv
import numpy as np

def analyze_annual_and_wf(csv_path="research/trades_v94_l1_ema200.csv"):
    trades = []
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            trades.append({
                'ticket': int(r['ticket']),
                'open_time': r['open_time'],
                'close_time': r['close_time'],
                'profit': float(r['profit']),
                'year': r['open_time'][:4]
            })

    years = sorted(list(set(t['year'] for t in trades)))

    print("=" * 85)
    print("      TABEL KINERJA TAHUNAN RINCI (YEAR-BY-YEAR AUDIT) BIOONEPRO V94 (EMA 200)      ")
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

    # Walk-Forward Analysis (IS: 2020-2022, OOS: 2023-2026)
    is_trades = [t for t in trades if t['year'] in ['2020', '2021', '2022']]
    oos_trades = [t for t in trades if t['year'] in ['2023', '2024', '2025', '2026']]

    print("\n" + "=" * 85)
    print("                WALK-FORWARD ANALYSIS (IN-SAMPLE vs OUT-OF-SAMPLE)               ")
    print("=" * 85)
    print(f"1. IN-SAMPLE (2020 - 2022, 3 Tahun Penuh):")
    is_net = sum(t['profit'] for t in is_trades)
    is_wins = [t['profit'] for t in is_trades if t['profit'] > 0]
    is_losses = [t['profit'] for t in is_trades if t['profit'] < 0]
    is_pf = sum(is_wins) / abs(sum(is_losses)) if is_losses else 999.0
    print(f"   - Total Orders: {len(is_trades)}")
    print(f"   - Win Rate: {len(is_wins)/len(is_trades)*100:.1f}%")
    print(f"   - Gross Win: ${sum(is_wins):.2f} | Gross Loss: ${sum(is_losses):.2f}")
    print(f"   - Net Profit: ${is_net:.2f} | PF: {is_pf:.2f}")

    print(f"\n2. OUT-OF-SAMPLE (2023 - 2026.09, 3 Tahun 9 Bulan):")
    oos_net = sum(t['profit'] for t in oos_trades)
    oos_wins = [t['profit'] for t in oos_trades if t['profit'] > 0]
    oos_losses = [t['profit'] for t in oos_trades if t['profit'] < 0]
    oos_pf = sum(oos_wins) / abs(sum(oos_losses)) if oos_losses else 999.0
    print(f"   - Total Orders: {len(oos_trades)}")
    print(f"   - Win Rate: {len(oos_wins)/len(oos_trades)*100:.1f}%")
    print(f"   - Gross Win: ${sum(oos_wins):.2f} | Gross Loss: ${sum(oos_losses):.2f}")
    print(f"   - Net Profit: ${oos_net:.2f} | PF: {oos_pf:.2f}")

    print(f"\n3. WALK-FORWARD EFFICIENCY (WFE):")
    # Annualized Return comparison
    is_ann = is_net / 3.0
    oos_ann = oos_net / 3.75
    wfe = (oos_ann / is_ann) * 100 if is_ann > 0 else 0
    print(f"   - In-Sample Annual Profit: ${is_ann:.2f}/tahun")
    print(f"   - Out-of-Sample Annual Profit: ${oos_ann:.2f}/tahun")
    print(f"   - Walk-Forward Efficiency Ratio: {wfe:.1f}% (> 50% adalah lulus standar institusional)")
    print("=" * 85)

if __name__ == '__main__':
    analyze_annual_and_wf()
