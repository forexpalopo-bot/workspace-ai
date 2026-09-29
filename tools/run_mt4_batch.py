#!/usr/bin/env python3
"""Jalankan rangkaian backtest MT4 (Windows) dari research/scenarios.json lalu ringkas hasilnya.

Contoh (PowerShell/CMD, dari root repo):
    python tools/run_mt4_batch.py --terminal "C:\\Program Files (x86)\\IC Markets MT4\\terminal.exe" ^
        --data-dir "C:\\Users\\NAMA\\AppData\\Roaming\\MetaQuotes\\Terminal\\<ID>" --only S0,S1

Catatan:
- Tutup MT4 lebih dulu (satu data-dir hanya boleh dipakai satu terminal).
- EA .mq4 harus sudah dikompilasi (.ex4) di <data-dir>/MQL4/Experts.
- Script menulis file .set lengkap (semua input default EA + override skenario) ke <data-dir>/tester,
  config .ini ke <data-dir>, dan laporan ke <data-dir>/reports lalu menyalinnya ke backtests/runs/.
- Kunci config tester MT4 yang dipakai: TestExpert, TestExpertParameters, TestSymbol, TestPeriod,
  TestModel, TestSpread, TestDateEnable, TestFromDate, TestToDate, TestReport, TestReplaceReport,
  TestShutdownTerminal. Bila build MT4 Anda menolak salah satunya, sesuaikan fungsi write_ini().
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from analyze_mt4_report import analyze  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SYMBOLIC = {
    "PERIOD_M1": 1, "PERIOD_M5": 5, "PERIOD_M15": 15, "PERIOD_M30": 30, "PERIOD_H1": 60,
    "PERIOD_H4": 240, "PERIOD_D1": 1440, "PRICE_CLOSE": 0, "PRICE_OPEN": 1, "PRICE_HIGH": 2,
    "PRICE_LOW": 3, "PRICE_MEDIAN": 4, "PRICE_TYPICAL": 5, "PRICE_WEIGHTED": 6,
    "MODE_SMA": 0, "MODE_EMA": 1, "MODE_SMMA": 2, "MODE_LWMA": 3,
}


def read_ea_defaults(mq4_path):
    """Ambil semua input extern/input beserta nilai default dari source EA."""
    params = {}
    pat = re.compile(r'^\s*(?:extern|input)\s+\w+\s+(\w+)\s*=\s*(.+?);')
    for line in open(mq4_path, encoding="latin-1"):
        m = pat.match(line)
        if not m:
            continue
        name, value = m.group(1), m.group(2).strip()
        if value.startswith('"'):
            value = value.strip('"')
        elif value in ("true", "false"):
            value = "1" if value == "true" else "0"
        elif value in SYMBOLIC:
            value = str(SYMBOLIC[value])
        params[name] = value
    return params


def to_set_value(v):
    if isinstance(v, bool):
        return "1" if v else "0"
    return str(v)


def write_set(path, params):
    with open(path, "w", encoding="latin-1", newline="\r\n") as f:
        for k, v in params.items():
            f.write(f"{k}={to_set_value(v)}\n")


def write_ini(path, expert, set_name, report_rel, test):
    lines = [
        f"TestExpert={expert}",
        f"TestExpertParameters={set_name}",
        f"TestSymbol={test['symbol']}",
        f"TestPeriod={test['period']}",
        f"TestModel={test.get('model', 0)}",
        f"TestSpread={test['spread']}",
        "TestOptimization=false",
        "TestDateEnable=true",
        f"TestFromDate={test['from']}",
        f"TestToDate={test['to']}",
        f"TestReport={report_rel}",
        "TestReplaceReport=true",
        "TestShutdownTerminal=true",
    ]
    with open(path, "w", encoding="latin-1", newline="\r\n") as f:
        f.write("\n".join(lines) + "\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--terminal", required=True, help="path terminal.exe")
    ap.add_argument("--data-dir", required=True, help="folder data MT4 (File > Open Data Folder)")
    ap.add_argument("--scenarios", default=os.path.join(REPO, "research", "scenarios.json"))
    ap.add_argument("--only", help="daftar id skenario dipisah koma, mis. S0,S1")
    ap.add_argument("--period-set", help="id periode dari scenarios.json (default: semua)")
    ap.add_argument("--results", default=os.path.join(REPO, "research", "results.csv"))
    ap.add_argument("--timeout", type=int, default=6 * 3600, help="detik per backtest")
    args = ap.parse_args()

    cfg = json.load(open(args.scenarios, encoding="utf-8"))
    ea_src = os.path.join(REPO, cfg["ea_source"])
    defaults = read_ea_defaults(ea_src)
    expert = os.path.splitext(os.path.basename(ea_src))[0]
    only = set(args.only.split(",")) if args.only else None
    periods = [p for p in cfg["periods"] if not args.period_set or p["id"] == args.period_set]

    os.makedirs(os.path.join(args.data_dir, "tester"), exist_ok=True)
    os.makedirs(os.path.join(args.data_dir, "reports"), exist_ok=True)
    runs_dir = os.path.join(REPO, "backtests", "runs")
    os.makedirs(runs_dir, exist_ok=True)

    for sc in cfg["scenarios"]:
        if only and sc["id"] not in only:
            continue
        for period in periods:
            run_id = f"{sc['id']}_{period['id']}"
            params = dict(defaults)
            unknown = [k for k in sc.get("params", {}) if k not in defaults]
            if unknown:
                print(f"[{run_id}] PERINGATAN: input tidak dikenal di EA: {unknown}")
            params.update({k: to_set_value(v) for k, v in sc.get("params", {}).items()})

            test = dict(cfg["test"])
            test.update({"from": period["from"], "to": period["to"]})
            test.update(sc.get("test", {}))

            set_name = f"{run_id}.set"
            write_set(os.path.join(args.data_dir, "tester", set_name), params)
            report_rel = os.path.join("reports", run_id)
            ini_path = os.path.join(args.data_dir, f"bt_{run_id}.ini")
            write_ini(ini_path, expert, set_name, report_rel, test)

            print(f"[{run_id}] menjalankan backtest ... ({sc.get('desc', '')})", flush=True)
            subprocess.run([args.terminal, f"/config:{ini_path}"], timeout=args.timeout, check=False)

            report = os.path.join(args.data_dir, report_rel + ".htm")
            if not os.path.exists(report):
                print(f"[{run_id}] GAGAL: laporan tidak ditemukan di {report}")
                continue
            dest = os.path.join(runs_dir, f"{run_id}.htm")
            shutil.copyfile(report, dest)

            row = {"run_id": run_id, "scenario": sc["id"], "period": period["id"],
                   "spread": test["spread"], "desc": sc.get("desc", "")}
            row.update(analyze(dest))
            new = not os.path.exists(args.results)
            import csv
            with open(args.results, "a", newline="", encoding="utf-8") as f:
                w = csv.DictWriter(f, fieldnames=list(row.keys()))
                if new:
                    w.writeheader()
                w.writerow(row)
            print(f"[{run_id}] net={row['net_profit']} maxDD%={row['max_dd_pct']} "
                  f"relDD%={row['rel_dd_pct']} worstOrder={row['largest_order_loss']}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
