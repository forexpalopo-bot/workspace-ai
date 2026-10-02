import sys, os, re
sys.path.insert(0, 'tools')
from analyze_mt4_report import parse_report, build_baskets

def analyze_losses(htm_path, log_path):
    print(f"\n==================================================================")
    print(f"DISSECTING LOSSES: {htm_path}")
    print(f"==================================================================")
    summary, orders = parse_report(htm_path)
    baskets = build_baskets(orders)
    
    # Load logs to correlate close reason
    logs = []
    if os.path.exists(log_path):
        with open(log_path, encoding='utf-8') as f:
            logs = f.readlines()
            
    losing = [b for b in baskets if b['pnl'] < -50]
    losing.sort(key=lambda b: b['pnl'])
    
    total_losing_pnl = sum(b['pnl'] for b in baskets if b['pnl'] < 0)
    top20_losing_pnl = sum(b['pnl'] for b in losing[:20])
    print(f"Total baskets: {len(baskets)}")
    print(f"Total negative PnL across all losing baskets: ${total_losing_pnl:.2f}")
    print(f"Top 20 worst baskets PnL: ${top20_losing_pnl:.2f} (represents {top20_losing_pnl/total_losing_pnl*100:.1f}% of all basket losses!)")
    
    print("\n--- TOP 20 WORST BASKETS DETAIL ---")
    for i, b in enumerate(losing[:20], 1):
        first_o = b['orders'][0]
        last_o = b['orders'][-1]
        c_time = last_o['close']
        
        # Search log around close time
        close_prefix = c_time[:16] # YYYY.MM.DD HH:MM
        reasons = []
        for l in logs:
            if close_prefix in l and ('SNIPER' in l or 'BATAS' in l or 'WEEKEND' in l or 'TREND STOP' in l or 'SL' in l):
                reasons.append(l.strip())
        reason_str = reasons[-1] if reasons else "Normal close/SL"
        if len(reason_str) > 100:
            reason_str = reason_str[-100:]
            
        print(f"\n#{i:02d} | Loss: ${b['pnl']:7.2f} | Side: {b['side'].upper():4s} | Depth: L{b['n']} | Lots: {b['lots']:.2f}")
        print(f"    Open : {first_o['open']} @ {first_o['op']}")
        print(f"    Close: {last_o['close']} @ {last_o['cp']}")
        print(f"    Log  : {reason_str}")
        for o in b['orders']:
            print(f"      order #{o['id']} lot {o['lots']:.2f} op {o['op']:.2f} -> cp {o['cp']:.2f} | PnL: ${o['profit']:6.2f}")

analyze_losses('backtests/runs/FAT_FULL.htm', 'research/logs/FAT_sniper.txt')
analyze_losses('backtests/runs/FA_FULL.htm', 'research/logs/FA_sniper.txt')
