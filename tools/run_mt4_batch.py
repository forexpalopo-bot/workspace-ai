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


def set_deposit(ini_paths, deposit):
    """Tulis/ubah baris deposit= di file ini tester MT4 tanpa menghapus isi lainnya."""
    for path in ini_paths:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if os.path.exists(path):
            text = open(path, encoding="latin-1").read()
            if re.search(r"^deposit=", text, re.M):
                text = re.sub(r"^deposit=.*$", f"deposit={deposit}", text, flags=re.M)
            else:
                text = text.replace("<common>\n", f"<common>\ndeposit={deposit}\n", 1)
        else:
            text = f"<common>\npositions=2\ndeposit={deposit}\ncurrency=USD\nfitnes=0\ngenetic=1\n</common>\n"
        with open(path, "w", encoding="latin-1") as f:
            f.write(text)


def write_ini(path, expert, set_name, report_name, test):
    lines = [
        "[Common]",
        "Profile=Default",
        "",
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
        f"TestReport={report_name}",
        "TestReplaceReport=true",
        "TestShutdownTerminal=true",
        "TestVisualEnable=false",
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

    # Deposit awal tester diatur per run lewat set_deposit() (default $500, bisa di-override "test": {"deposit": ...})
    tester_ini = os.path.join(args.data_dir, "tester", f"{expert}.ini")
    config_ini = os.path.join(args.data_dir, "config", f"{expert}.ini")

    for sc in cfg["scenarios"]:
        if only and sc["id"] not in only:
            continue
        for period in periods:
            run_id = f"{sc['id']}_{period['id']}"
            dest = os.path.join(runs_dir, f"{run_id}.htm")
            test = dict(cfg["test"])
            test.update({"from": period["from"], "to": period["to"]})
            test.update(period.get("test", {}))  # mis. spread khusus data 2 digit
            test.update(sc.get("test", {}))

            if os.path.exists(dest) and os.path.getsize(dest) > 1000:
                print(f"[{run_id}] laporan sudah ada, membaca hasil yang ada ...", flush=True)
            else:
                params = dict(defaults)
                unknown = [k for k in sc.get("params", {}) if k not in defaults]
                if unknown:
                    print(f"[{run_id}] PERINGATAN: input tidak dikenal di EA: {unknown}")
                params.update({k: to_set_value(v) for k, v in sc.get("params", {}).items()})

                set_deposit([tester_ini, config_ini], test.get("deposit", 500))
                set_name = f"{run_id}.set"
                write_set(os.path.join(args.data_dir, "tester", set_name), params)
                ini_path = os.path.join(args.data_dir, f"bt_{run_id}.ini")
                report_name = f"{run_id}.htm"
                write_ini(ini_path, expert, set_name, report_name, test)

                auto_ini_path = r"C:\Users\DELL\Downloads\EA2026\auto_test.ini"
                if os.path.exists(os.path.dirname(auto_ini_path)):
                    write_ini(auto_ini_path, expert, set_name, report_name, test)

                candidates = [
                    os.path.join(args.data_dir, f"{run_id}.htm"),
                    os.path.join(args.data_dir, "tester", f"{run_id}.htm"),
                    os.path.join(args.data_dir, "reports", f"{run_id}.htm"),
                ]
                for c in candidates:
                    if os.path.exists(c):
                        try: os.remove(c)
                        except Exception: pass

                print(f"[{run_id}] menjalankan backtest ... ({sc.get('desc', '')})", flush=True)
                import time
                subprocess.run(["schtasks", "/run", "/tn", "LaunchMT4"], capture_output=True, check=False)
                time.sleep(5)

                start_t = time.time()
                report = None
                while time.time() - start_t < args.timeout:
                    found = None
                    for c in candidates:
                        if os.path.exists(c) and os.path.getsize(c) > 1000:
                            found = c
                            break
                    res = subprocess.run(["tasklist", "/FI", "IMAGENAME eq terminal.exe"], capture_output=True, text=True)
                    term_running = "terminal.exe" in res.stdout
                    if found and not term_running:
                        report = found
                        break
                    if not term_running and (time.time() - start_t > 30):
                        for c in candidates:
                            if os.path.exists(c) and os.path.getsize(c) > 1000:
                                report = c
                                break
                        break
                    time.sleep(5)

                if not report or not os.path.exists(report):
                    print(f"[{run_id}] GAGAL: laporan tidak ditemukan di {report}")
                    continue
                shutil.copyfile(report, dest)
                gif_src = report.replace(".htm", ".gif")
                if os.path.exists(gif_src):
                    shutil.copyfile(gif_src, os.path.join(runs_dir, f"{run_id}.gif"))

            row = {"run_id": run_id, "scenario": sc["id"], "period": period["id"],
                   "spread": test["spread"], "deposit": test.get("deposit", 500), "desc": sc.get("desc", "")}
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
    set_deposit([tester_ini, config_ini], 500)
    return 0


if __name__ == "__main__":
    sys.exit(main())
