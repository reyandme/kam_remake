#!/usr/bin/env python3
"""Build and bundle the native Cocoa/ARM64 client with local game assets."""
from pathlib import Path
import argparse
import hashlib
import os
import plistlib
import shlex
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
TOOLS = Path(os.environ.get('KAM_TOOLS', ROOT.parent / 'kam-tools'))
os.chdir(ROOT)

def run(*args):
    subprocess.run([str(x) for x in args], check=True)


def prepare_pascalscript():
    submodule = ROOT / 'src/ext/pascalscript_submodule'
    patch = ROOT / 'macos/pascalscript.patch'
    revision = subprocess.check_output(['git', '-C', str(submodule), 'rev-parse', 'HEAD'])
    fingerprint = hashlib.sha256(revision + patch.read_bytes()).hexdigest()
    destination = ROOT / 'out/pascalscript'
    marker = destination / '.kam-patch'
    if marker.exists() and marker.read_text() == fingerprint:
        return
    if destination.exists() and not marker.exists():
        raise SystemExit(f'Refusing to replace an unknown source directory: {destination}')
    with tempfile.TemporaryDirectory(prefix='pascalscript-', dir=ROOT / 'out') as temporary:
        archive = subprocess.check_output(['git', '-C', str(submodule), 'archive', 'HEAD', 'Source'])
        subprocess.run(['tar', '-x', '-C', temporary], input=archive, check=True)
        run('git', 'apply', '--check', '--directory=' + str(Path(temporary).relative_to(ROOT)), patch)
        run('git', 'apply', '--directory=' + str(Path(temporary).relative_to(ROOT)), patch)
        (Path(temporary) / '.kam-patch').write_text(fingerprint)
        if destination.exists():
            shutil.rmtree(destination)
        shutil.copytree(temporary, destination)


def compiler_wrapper():
    prefix = Path(subprocess.check_output(['brew', '--prefix'], text=True).strip())
    arguments = [str(TOOLS / 'fpc-dev'), '-Fl' + str(ROOT / 'out/bass'),
                 '-Fl' + str(prefix / 'lib'), '-Fl' + str(prefix / 'opt/openal-soft/lib')]
    wrapper = ROOT / 'out/macos-fpc'
    wrapper.write_text('#!/bin/sh\nexec ' + shlex.join(arguments) + ' "$@"\n')
    wrapper.chmod(0o755)
    return wrapper

def aliases():
    directory = ROOT / 'out/unit-aliases'
    directory.mkdir(parents=True, exist_ok=True)
    for target in directory.iterdir():
        if not target.is_symlink():
            raise SystemExit(f'Expected a generated unit symlink: {target}')
        target.unlink()
    config = ET.parse(ROOT / 'KaM_Remake_macos.lpi')
    for item in config.find('.//OtherUnitFiles').get('Value').split(';'):
        if item == 'out/unit-aliases' or item.startswith('/'):
            continue
        for source in (ROOT / item).glob('*'):
            if source.suffix.lower() not in ('.pas', '.pp', '.lfm', '.lrs', '.inc', '.dfm'):
                continue
            target = directory / source.name.lower()
            if not target.is_symlink():
                target.symlink_to(source.resolve())

def compile_project(project, log):
    config = ET.parse(ROOT / project)
    output = config.find('.//UnitOutputDirectory').get('Value')
    output = ROOT / output.replace('$(TargetCPU)', 'aarch64').replace('$(TargetOS)', 'darwin')
    if not output.resolve().is_relative_to(ROOT / 'out'):
        raise SystemExit(f'Expected a generated unit directory below out/: {output}')
    if output.exists():
        for item in output.iterdir():
            if item.suffix in ('.ppu', '.o', '.rst', '.rsj'):
                item.unlink()
    if not (TOOLS / 'lazarus/lazbuild').is_file() or not (TOOLS / 'fpc-dev').is_file():
        raise SystemExit('Pascal toolchain missing: run python3 macos/bootstrap.py first.')
    command = [TOOLS / 'lazarus/lazbuild', '-B', f'--compiler={compiler_wrapper()}',
               f'--lazarusdir={TOOLS / "lazarus"}',
               '--pcp=out/lazarus-' + hashlib.sha256(str(TOOLS.resolve()).encode()).hexdigest()[:12],
               '--ws=cocoa', project]
    with open(log, 'w') as output:
        result = subprocess.run([str(x) for x in command], stdout=output, stderr=subprocess.STDOUT)
    if result.returncode:
        print(Path(log).read_text(errors='replace')[-14000:])
        raise SystemExit(result.returncode)

def bundle():
    source = ROOT / 'out/runtime'
    if not (source / 'data/sprites/GUI.rxx').exists():
        raise SystemExit('Game assets missing: run macos/prepare_assets.py first.')
    app = ROOT / 'out/KaM Remake.app'
    binary_dir = app / 'Contents/MacOS'
    binary_dir.mkdir(parents=True, exist_ok=True)
    asset_dir = app / 'Contents/Resources/game'
    asset_dir.mkdir(parents=True, exist_ok=True)
    for name in ('data', 'Sounds', 'Music', 'Maps', 'MapsMP', 'Campaigns', 'Tutorials'):
        if (source / name).exists():
            run('rsync', '-a', str(source / name) + '/', str(asset_dir / name) + '/')
    asset_version = hashlib.sha256((ROOT / 'out/KaM_Remake').read_bytes()).hexdigest()
    (asset_dir / 'assets-version.txt').write_text(asset_version + '\n')
    shutil.copy2(ROOT / 'out/KaM_Remake', binary_dir / 'KaM_Remake')
    prefix = Path(subprocess.check_output(['brew', '--prefix'], text=True).strip())
    libraries = [ROOT / 'out/bass/libbass.dylib', prefix / 'opt/openal-soft/lib/libopenal.dylib',
                 prefix / 'lib/libogg.0.dylib', prefix / 'lib/libvorbis.0.dylib',
                 prefix / 'lib/libvorbisfile.3.dylib']
    for library in libraries:
        target = binary_dir / library.name
        if target.exists(): target.chmod(0o755)
        shutil.copy2(library, target)
        target.chmod(0o755)
    targets = [binary_dir / 'KaM_Remake'] + [binary_dir / lib.name for lib in libraries]
    names = {lib.name for lib in libraries}
    for target in targets:
        if target.suffix == '.dylib':
            run('install_name_tool', '-id', '@rpath/' + target.name, target)
        dependencies = subprocess.check_output(['otool', '-L', str(target)], text=True)
        for line in dependencies.splitlines()[1:]:
            dependency = line.strip().split(' (')[0]
            name = Path(dependency).name
            if name in names and dependency != '@rpath/' + name:
                run('install_name_tool', '-change', dependency, '@rpath/' + name, target)
        if target.name == 'KaM_Remake':
            run('install_name_tool', '-add_rpath', '@executable_path', target)
        if target.suffix == '.dylib':
            run('codesign', '--force', '--sign', '-', target)
    resources = app / 'Contents/Resources'
    resources.mkdir(exist_ok=True)
    shutil.copy2(ROOT / 'out/bass/bass.txt', resources / 'BASS-license.txt')
    shutil.copy2(ROOT / 'LICENSE.txt', resources / 'KaM-license.txt')
    for package in ('openal-soft', 'libogg', 'libvorbis'):
        shutil.copy2(prefix / 'opt' / package / 'COPYING', resources / (package + '-license.txt'))
    shutil.copy2(prefix / 'opt/openal-soft/LICENSE-pffft', resources / 'pffft-license.txt')
    info = {'CFBundleIdentifier': 'local.kamremake.arm64', 'CFBundleName': 'KaM Remake',
            'CFBundleDisplayName': 'KaM Remake', 'CFBundleExecutable': 'KaM_Remake',
            'CFBundlePackageType': 'APPL', 'CFBundleVersion': '1',
            'CFBundleShortVersionString': 'ARM64 development',
            'LSMinimumSystemVersion': '27.0', 'NSHighResolutionCapable': False,
            'NSPrincipalClass': 'TCocoaApplication'}
    (app / 'Contents/Info.plist').write_bytes(plistlib.dumps(info))
    run('codesign', '--force', '--sign', '-', app)
    run('codesign', '--verify', '--deep', '--strict', app)
    print(app)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--test', action='store_true', help='Run native smoke tests after compilation')
    parser.add_argument('--test-only', action='store_true', help='Build and run smoke tests without bundling the game')
    parser.add_argument('--compile-only', action='store_true', help='Compile without replacing the app bundle')
    options = parser.parse_args()
    (ROOT / 'out').mkdir(exist_ok=True)
    prepare_pascalscript()
    aliases()
    if not options.test_only:
        compile_project('KaM_Remake_macos.lpi', 'out/build-macos.log')
    if options.test or options.test_only:
        compile_project('KaM_Smoke_macos.lpi', 'out/smoke-build.log')
        run(ROOT / 'out/kam-smoke')
    if not options.test_only and not options.compile_only:
        bundle()
