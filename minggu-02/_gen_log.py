#!/usr/bin/env python3
"""Replika buat-log.sh (JS-DVO-02 JOB 2) untuk menghasilkan app.log berformat sama.
Gunakan seed tetap agar angka analisis stabil untuk contoh laporan.
Di Ubuntu, jalankan ./buat-log.sh (bukan skrip ini) untuk menghasilkan data asli kalian.
"""
import random, datetime, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "app.log"
LINES = int(sys.argv[2]) if len(sys.argv) > 2 else 500
SEED = int(sys.argv[3]) if len(sys.argv) > 3 else 42
random.seed(SEED)

IPS = ["10.10.0.11", "10.10.0.12", "10.10.0.13", "172.16.4.7", "192.168.5.20"]
PAGES = ["/", "/health", "/api/orders", "/api/users", "/static/app.js"]
CODES = [200, 200, 200, 200, 201, 301, 404, 404, 500, 502]
NOW = datetime.datetime(2026, 9, 28, 13, 0, 0)

with open(OUT, "w", encoding="utf-8") as f:
    for _ in range(LINES):
        ts = NOW - datetime.timedelta(minutes=random.randrange(1440))
        ts = ts.strftime("%d/%b/%Y:%H:%M:%S +0700")
        ip = random.choice(IPS)
        page = random.choice(PAGES)
        code = random.choice(CODES)
        ms = random.randrange(5, 1205)
        f.write(f'{ip} - - [{ts}] "GET {page} HTTP/1.1" {code} {ms}\n')

print(f"Dibuat: {OUT} ({LINES} baris)")
