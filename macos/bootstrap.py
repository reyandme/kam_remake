#!/usr/bin/env python3
"""Provision the pinned native Pascal toolchain without changing the system FPC."""
from pathlib import Path
import hashlib
import os
import shutil
import subprocess
import urllib.request
import zipfile
ROOT = Path(__file__).resolve().parent.parent
TOOLS = Path(os.environ.get('KAM_TOOLS', ROOT.parent / 'kam-tools')).resolve()
TOOLS.mkdir(parents=True, exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
SDK = subprocess.check_output(['xcrun', '--show-sdk-path'], text=True).strip()
FPC_REV = 'ef2a6d6bbd23f3db160c2e93c800b7d1b342af03'
LAZ_REV = '98f9c7a7a102139e43b39050ebbb5c48d805f59f'
BASS_SHA256 = 'dfadd6238896b02b144b2870655fb9ee2445fc84d5c00f7e1c56faf9343ce59c'

def run(*cmd, cwd=None, log=None):
    if log:
        with open(ROOT / 'out' / log, 'w') as output:
            subprocess.run([str(x) for x in cmd], cwd=cwd, check=True,
                           stdout=output, stderr=subprocess.STDOUT)
    else:
        subprocess.run([str(x) for x in cmd], cwd=cwd, check=True)

def checkout(url, name, revision):
    destination = TOOLS / name
    if not destination.exists():
        run('git', 'init', destination)
        run('git', '-C', destination, 'remote', 'add', 'origin', url)
        run('git', '-C', destination, 'fetch', '--depth', '1', 'origin', revision)
        run('git', '-C', destination, 'checkout', '--detach', revision)
    actual = subprocess.check_output(['git', '-C', str(destination), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != revision:
        raise SystemExit(f'{destination}: expected {revision}, found {actual}')
    return destination

run('brew', 'install', 'fpc', 'innoextract', 'openal-soft', 'libvorbis', 'libogg')
fpc = checkout('https://gitlab.com/freepascal.org/fpc/source.git', 'fpc-source', FPC_REV)
lazarus = checkout('https://gitlab.com/freepascal.org/lazarus/lazarus.git', 'lazarus', LAZ_REV)
# This snapshot has an unconditional Windows define in the portable Process unit.
process = fpc / 'packages/fcl-process/src/process.pp'
process.write_text(process.read_text().replace('{$define windows}\n', ''))
compiler = TOOLS / 'ppca64-stage2'
if not compiler.exists():
    run('make', '-j8', 'all', f'FPC={shutil.which("ppca64")}',
        f'OPT=-O2 -XR{SDK}', f'FPCMAKEOPT=-XR{SDK}', cwd=fpc, log='bootstrap-fpc.log')
    shutil.copy2(fpc / 'compiler/ppca64', compiler)
wrapper = TOOLS / 'fpc-dev'
wrapper.write_text(f'''#!/bin/bash
unitargs=()
for unitdir in "{fpc}"/packages/*/units/aarch64-darwin; do
  unitargs+=("-Fu$unitdir")
done
exec "{compiler}" -n -Fu"{fpc}/rtl/units/aarch64-darwin" -XR"{SDK}" "$@" "${{unitargs[@]}}"
''')
wrapper.chmod(0o755)
output = fpc / 'packages/fcl-process/units/aarch64-darwin'
output.mkdir(parents=True, exist_ok=True)
run(wrapper, '-Mobjfpc', '-S2h', f'-Fu{fpc}/packages/fcl-process/src',
    f'-Fi{fpc}/packages/fcl-process/src/unix', f'-FU{output}', process, log='bootstrap-process.log')
if not (lazarus / 'lazbuild').exists():
    run('make', 'lazbuild', 'LCL_PLATFORM=cocoa', cwd=lazarus, log='bootstrap-lazarus.log')
bass = ROOT / 'out/bass'
if not (bass / 'libbass.dylib').exists():
    archive = ROOT / 'out/bass24-osx.zip'
    urllib.request.urlretrieve('https://www.un4seen.com/files/bass24-osx.zip', archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != BASS_SHA256:
        raise SystemExit('BASS SDK checksum changed; verify the new SDK before updating BASS_SHA256.')
    with zipfile.ZipFile(archive) as z:
        for name in ['libbass.dylib', 'bass.txt']:
            z.extract(name, bass)
print(f'Ready: {TOOLS}')
