#!/usr/bin/env python3
"""Check relative links in tracked Markdown files and top-level site/*.html pages.

Exits 1 if any relative link points at a missing file. Links into
site/assets/diagrams/ are generated at build time and are only reported.
Usage: python3 scripts/check_links.py   (from anywhere inside the repository)
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
files = subprocess.run(["git", "ls-files"], capture_output=True, text=True, check=True).stdout.split("\n")
targets_files = [f for f in files if f.endswith(".md") or (f.startswith("site/") and f.endswith(".html") and f.count("/") == 1)]
md_link = re.compile(r'\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
html_attr = re.compile(r'''(?:href|src)=["']([^"']+)["']''')
SKIP = ("http://", "https://", "mailto:", "#", "data:")
broken, generated = [], []
checked = 0
for f in sorted(targets_files):
    if not f or not os.path.exists(f):
        continue
    fence = False
    with open(f, encoding="utf-8", errors="replace") as fh:
        for i, line in enumerate(fh, 1):
            s = line.strip()
            if s.startswith("```") or s.startswith("~~~"):
                fence = not fence
                continue
            if fence:
                continue
            tg = md_link.findall(line)
            if f.endswith(".html"):
                tg += html_attr.findall(line)
            for t in tg:
                if t.startswith(SKIP) or t.startswith("<"):
                    continue
                p = t.split("#")[0].split("?")[0]
                if not p:
                    continue
                checked += 1
                if p.startswith("/"):
                    res = os.path.normpath(os.path.join(ROOT, p.lstrip("/")))
                else:
                    res = os.path.normpath(os.path.join(os.path.dirname(f), p))
                if not os.path.exists(res):
                    if f.startswith("site/") and "assets/diagrams/" in p:
                        generated.append(f"{f}:{i} -> {t}")
                    else:
                        broken.append(f"{f}:{i} -> {t}")
print(f"files={len(targets_files)} links_checked={checked}")
print("BROKEN:", len(broken))
print("\n".join(broken))
print("GENERATED (expected):", len(generated))
sys.exit(1 if broken else 0)
