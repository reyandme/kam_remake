# Native macOS build (Apple Silicon)

This is an experimental Cocoa/ARM64 port. It uses the existing OpenGL renderer,
BASS for music, and OpenAL Soft for sound. Wine and Rosetta are not required.

## Requirements

- An Apple Silicon Mac with Xcode Command Line Tools and Homebrew.
- Python 3.9 or newer, Git and network access to fetch build dependencies.
- A copy of the original game and a full KaM Remake installation. Game assets
  are not included in this repository and must not be added to the PR.

The current bundle targets macOS 27 because the Homebrew audio libraries used
for testing require it. Supporting earlier macOS releases requires dependencies
built for those releases and a matching deployment target in `build.py`.

## Build

From the repository root:

```sh
git submodule update --init src/ext/pascalscript_submodule
python3 macos/bootstrap.py
python3 macos/prepare_assets.py --original "/path/to/GOG-installer.exe" \
  --remake "/path/to/KaM-Remake-Beta-r16397.exe"
python3 macos/build.py --test
```

The bootstrap keeps its compiler and Lazarus sources in `../kam-tools`.
Set `KAM_TOOLS` to use another directory. It pins FPC to
`ef2a6d6bbd23f3db160c2e93c800b7d1b342af03` and Lazarus 4.4 to
`98f9c7a7a102139e43b39050ebbb5c48d805f59f`. FPC 3.3.1 is needed for
anonymous procedure references; the stable 3.2.2 compiler bootstraps it.

The BASS SDK download is checked against its recorded SHA-256. See
[bass/README.md](bass/README.md) for its source and license information.
The bundle includes the libraries' license files.

`prepare_assets.py` extracts the supplied installers into `out/`, then overlays
original game data, Remake assets and repository data in that order, following
the project's compilation guide. It does not modify the installers.

The game is not launched by the build script. To run it yourself:

```sh
open "out/KaM Remake.app"
```

## Tests without game assets

```sh
python3 macos/build.py --test-only
```

The smoke program checks collection serialization, worker execution, file
copying, XML persistence, PNG RGBA round trips, and PascalScript calls into
native ARM64 code. The native calls cover signed integers, floating point,
Unicode strings, packed records, dynamic/open arrays, `var` parameters and
object methods.

To compile the game and run the smoke tests without replacing the app bundle:

```sh
python3 macos/build.py --test --compile-only
```

The build prepares patched PascalScript sources in `out/pascalscript/` from the
submodule's committed files. It does not edit the submodule. The project files
and the patch therefore travel together in this repository; no unpublished
submodule commit is required.

## Writable data

On first launch, the app copies its resources to:

```text
~/Library/Application Support/KaM Remake/
```

Settings, saves, downloaded maps and logs stay there, outside the signed bundle.
APFS clones avoid duplicating resource storage when available. `KAM_DATA_DIR`
selects a separate writable directory. The bundle's `assets-version.txt` controls
resource refreshes; files present only in the writable directory are retained.

## Scope and testing

The public-source target defines `DBG_SKIP_SECURE_AUTH`, as described in the
upstream compilation guide. The private authentication unit is not available,
so official authenticated multiplayer is unsupported. Native video playback
is not enabled.

The ARM64 PascalScript bridge uses libffi. Its record handling covers the
integer-field records exported by the game; arbitrary homogeneous
floating-point records are not supported.

Checked on an Apple M5 Max running macOS 27.0.1:

- Cocoa window, Apple OpenGL renderer and audio initialization.
- Town Tutorial startup, script messages, selection and menu input.
- Manual save followed by loading it back into gameplay.
- 25 smoke checks and strict/deep ad-hoc signature verification.

The pinned compiler and Lazarus were also bootstrapped in a new tools directory.
Windows and Linux builds, full campaigns, long sessions, network play and replay
determinism across platforms have not been verified. The LCL developer panel
has compatibility containers for the shared form code; it is not a complete
port of the VCL debugging tools.
