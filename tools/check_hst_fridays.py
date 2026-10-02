import struct
from datetime import datetime

def check_hst(hst_path):
    with open(hst_path, 'rb') as f:
        header = f.read(148)
        records = []
        while True:
            buf = f.read(60)
            if len(buf) < 60: break
            t = struct.unpack('<qddddqiq', buf)[0]
            dt = datetime.utcfromtimestamp(t)
            records.append(dt)

    fridays = [r for r in records if r.weekday() == 4]
    print(f"File: {hst_path}")
    print(f"Total bars: {len(records)}, Friday bars: {len(fridays)}")
    
    # Cek bar terakhir hari Jumat tiap bulan
    for yr in [2022, 2023, 2024, 2025]:
        for mo in [1, 7]:
            sub = [r for r in fridays if r.year == yr and r.month == mo]
            if sub:
                # Ambil Jumat terakhir di bulan itu
                last_friday_day = max(r.day for r in sub)
                day_bars = [r for r in sub if r.day == last_friday_day]
                last_bar = max(day_bars)
                print(f"{yr}-{mo:02d} (Jumat tgl {last_friday_day:02d}): Bar terakhir jam {last_bar.strftime('%H:%M')}")

if __name__ == '__main__':
    p = r'C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5\history\ICMarketsSC-Live04\XAUUSD60.hst'
    check_hst(p)
