#!/usr/bin/env python3
"""Extract the user's GOG/KaM Remake installers into the local runtime folder."""
from pathlib import Path
import argparse, subprocess
ROOT = Path(__file__).resolve().parent.parent
p = argparse.ArgumentParser()
p.add_argument('--original', type=Path, required=True, help='GOG Peasants Rebellion installer')
p.add_argument('--remake', type=Path, required=True, help='KaM Remake full installer')
a = p.parse_args()
for name, installer in [('original', a.original), ('remake', a.remake)]:
    destination = ROOT / 'out' / name
    destination.mkdir(parents=True, exist_ok=True)
    subprocess.run(['innoextract', '-d', str(destination), str(installer.resolve())], check=True)
runtime = ROOT / 'out/runtime'
runtime.mkdir(exist_ok=True)
original = ROOT / 'out/original'
if not (original / 'data').exists():
    original = original / 'app'
for source, target in [(original / 'data', runtime / 'data'),
                       (ROOT / 'out/remake/app', runtime),
                       (ROOT / 'data', runtime / 'data')]:
    target.mkdir(parents=True, exist_ok=True)
    subprocess.run(['rsync', '-a', str(source) + '/', str(target) + '/'], check=True)
print(runtime)
