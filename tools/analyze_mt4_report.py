#!/usr/bin/env python3
"""Ringkas laporan Strategy Tester MT4 (.htm) BioOnePro menjadi metrik + statistik basket.

Pemakaian:
    python tools/analyze_mt4_report.py laporan1.htm [laporan2.htm ...] [--csv hasil.csv]

Hanya memakai pustaka standar Python 3.
"""
import argparse
import collections
import csv
import html
import re
import sys

SUMMARY_KEYS = {
    "Initial deposit": "deposit",
    "Total net profit": "net_profit",
    "Profit factor": "profit_factor",
    "Maximal drawdown": "max_dd",
    "Relative drawdown": "rel_dd",
    "Total trades": "total_trades",
}


def _cells(row_html):
    return [html.unescape(re.sub(r"<[^>]+>", "", c)).strip()
            for c in re.findall(r"<td[^>]*>(.*?)</td>", row_html, re.S)]


def parse_report(path):
    text = open(path, encoding="latin-1", errors="replace").read()
    summary = {}
    orders = {}
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", text, re.S):
        cells = _cells(row)
        # Baris ringkasan: label, nilai, label, nilai, ...
        for i in range(0, len(cells) - 1):
            key = SUMMARY_KEYS.get(cells[i])
            if key and key not in summary:
                summary[key] = cells[i + 1]
        # Baris transaksi: #, waktu, tipe, order, lot, harga, SL, TP, profit, balance
        if len(cells) >= 9 and cells[0].isdigit() and re.match(r"\d{4}\.\d\d\.\d\d", cells[1]):
            typ, oid = cells[2], int(cells[3])
            if typ in ("buy", "sell"):
                orders[oid] = dict(id=oid, type=typ, open=cells[1], lots=float(cells[4]), op=float(cells[5]))
            elif oid in orders and typ in ("s/l", "t/p", "close", "close at stop") and len(cells) >= 10:
                orders[oid].update(close=cells[1], cp=float(cells[5]),
                                   profit=float(cells[8] or 0), bal=float(cells[9] or 0))
    closed = [o for o in sorted(orders.values(), key=lambda o: o["id"]) if "close" in o]
    return summary, closed


def build_baskets(orders):
    """Kelompokkan order satu arah yang waktunya tumpang-tindih menjadi satu basket."""
    baskets = []
    for o in orders:
        for b in baskets:
            if b["side"] == o["type"] and o["open"] < b["end"]:
                b["orders"].append(o)
                b["end"] = max(b["end"], o["close"])
                break
        else:
            baskets.append(dict(side=o["type"], orders=[o], end=o["close"]))
    for b in baskets:
        b["n"] = len(b["orders"])
        b["pnl"] = sum(x["profit"] for x in b["orders"])
        b["lots"] = sum(x["lots"] for x in b["orders"])
    return baskets


def _num(s):
    m = re.match(r"-?[\d.]+", (s or "").replace(" ", ""))
    return float(m.group()) if m else None


def _pct(s):
    m = re.search(r"([\d.]+)%", s or "")
    return float(m.group(1)) if m else None


def analyze(path):
    summary, orders = parse_report(path)
    baskets = build_baskets(orders)
    depth = collections.Counter(b["n"] for b in baskets)
    losing_orders = [o["profit"] for o in orders if o["profit"] < 0]
    net = _num(summary.get("net_profit"))
    max_dd_money = _num(summary.get("max_dd"))
    return {
        "report": path,
        "net_profit": net,
        "profit_factor": _num(summary.get("profit_factor")),
        "max_dd_money": max_dd_money,
        "max_dd_pct": _pct(summary.get("max_dd")),
        "rel_dd_pct": _num(summary.get("rel_dd")),
        "net_per_dd": round(net / max_dd_money, 2) if net and max_dd_money else None,
        "orders": len(orders),
        "baskets": len(baskets),
        "losing_baskets": sum(1 for b in baskets if b["pnl"] < 0),
        "worst_basket": round(min((b["pnl"] for b in baskets), default=0), 2),
        "largest_order_loss": round(min(losing_orders, default=0), 2),
        "gross_order_loss": round(sum(losing_orders), 2),
        "depth_L1": depth.get(1, 0),
        "depth_L2": depth.get(2, 0),
        "depth_L3": depth.get(3, 0),
        "depth_L4plus": sum(v for k, v in depth.items() if k >= 4),
        "max_basket_lots": round(max((b["lots"] for b in baskets), default=0), 2),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("reports", nargs="+")
    ap.add_argument("--csv", help="tulis/tambahkan hasil ke file CSV")
    args = ap.parse_args()

    rows = [analyze(p) for p in args.reports]
    for r in rows:
        print(" | ".join(f"{k}={v}" for k, v in r.items()))
    if args.csv:
        import os
        new = not os.path.exists(args.csv)
        with open(args.csv, "a", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            if new:
                w.writeheader()
            w.writerows(rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
