This is the Pascal header from the BASS 2.4 macOS SDK, copyright Un4seen
Developments. The local addition enables `MACOS` and links `bass` when compiling
for Darwin. The existing Windows header in `src/ext` is unchanged.

SDK: <https://www.un4seen.com/files/bass24-osx.zip>

SHA-256: `dfadd6238896b02b144b2870655fb9ee2445fc84d5c00f7e1c56faf9343ce59c`

BASS has its own license; see the `Licence` section in the SDK's `bass.txt`.
The bootstrap downloads the runtime library and that file, and the bundler
includes the full file in the application. No BASS binary is committed here.
