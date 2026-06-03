#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Template'i dagitima hazir temiz zip'e paketler (allowlist — kisisel/sisme haric).

Kullanim:
  python bin/package.py            # sadece template dagitimi
  python bin/package.py --training # + egitim kiti (PDF/PPTX) ayri zip
Cikti: dist/claude-context-template-v<VERSION>.zip  (+ egitim-kit-v<VERSION>.zip)
"""
import os, sys, zipfile, fnmatch

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION = open(os.path.join(ROOT, "VERSION")).read().strip() if os.path.exists(os.path.join(ROOT,"VERSION")) else "0.0.0"
DIST = os.path.join(ROOT, "dist")

# --- DAGITILACAK template (allowlist) ---
TEMPLATE_INCLUDE = [
    "templates/**",                 # .claude sablonu + docs/CONTEXT + plans + ADR
    "bin/bootstrap.ps1", "bin/bootstrap.sh",
    "bin/update-all.sh", "bin/projects.txt",
    "README.md", "CHANGELOG.md", "VERSION",
    # rehber dokumanlari (markdown)
    "docs/GELISTIRICI_REHBERI.md", "docs/LEADER_PLAYBOOK.md",
    "docs/PROJE_OZEL_KAVRAM.md", "docs/PROJE_OZEL_OLUSTURMA.md",
    "docs/PROJE_OZEL_ORNEK_SENARYO.md",
    "docs/USAGE.md", "docs/PATTERNS.md", "docs/WORKFLOW_GUIDE.md",
    "docs/DEPLOY.md",
]
# --- her zaman HARIC (allowlist icine girse bile) ---
EXCLUDE = [
    "**/node_modules/**", "**/_icons/**", "**/_icons_red/**",
    "**/__pycache__/**", "**/*.pyc",
    "**/.git/**", "**/.DS_Store",
    "TUM_PROJE_KODLARI.txt", "kodlari_topla_v2.bat",
    "**/*.original.md",
]
# --- egitim kiti (opsiyonel ayri zip) ---
TRAINING_INCLUDE = [
    "docs/acemi/*.pdf", "docs/seviye/*.pdf", "docs/desktop/*.pdf",
    "docs/chat/*.pdf", "docs/cowork/*.pdf",
    "docs/sunum/*.pdf", "docs/sunum/*.pptx",
]

def excluded(rel):
    return any(fnmatch.fnmatch(rel, pat) for pat in EXCLUDE)

def match_any(rel, patterns):
    for pat in patterns:
        if pat.endswith("/**"):
            if rel == pat[:-3] or rel.startswith(pat[:-2]): return True
        elif fnmatch.fnmatch(rel, pat):
            return True
    return False

def collect(patterns):
    files = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        # node_modules vb erken budama
        dirnames[:] = [d for d in dirnames if d not in
                       ("node_modules","_icons","_icons_red","__pycache__",".git","dist")]
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT).replace("\\","/")
            if excluded(rel): continue
            if match_any(rel, patterns):
                files.append((full, rel))
    return sorted(set(files), key=lambda t: t[1])

def make_zip(name, files):
    os.makedirs(DIST, exist_ok=True)
    out = os.path.join(DIST, name)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for full, rel in files:
            z.write(full, arcname="claude-context-template/"+rel)
    size = os.path.getsize(out)/1024/1024
    print(f"  + {name}  ({len(files)} dosya, {size:.1f} MB)")
    return out

def main():
    training = "--training" in sys.argv
    print(f"=== Paketleme — v{VERSION} ===")
    tpl = collect(TEMPLATE_INCLUDE)
    if not tpl:
        print("HATA: template dosyasi bulunamadi"); sys.exit(1)
    make_zip(f"claude-context-template-v{VERSION}.zip", tpl)
    if training:
        tr = collect(TRAINING_INCLUDE)
        if tr: make_zip(f"egitim-kit-v{VERSION}.zip", tr)
        else: print("  ! egitim kiti bos (PDF/PPTX yok)")
    print(f"\nCikti: {DIST}")
    print("Devir: zip'i ac, README.md + docs/LEADER_PLAYBOOK.md ile basla.")

if __name__ == "__main__":
    main()
