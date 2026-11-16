# Windows native icon verifier correction

Frozen game source and all four product packages remain at `63584487c1af`.
No executable, asset, PCK or archive was modified. Only the independent verification
script `scripts/check-native-package.py` changed after the initial strict-set failure.

## Actual export observation

The authored ICO contains 16/24/32/48/64/128/256 px entries. Both actual exported
Windows executables contain 16/32/48/64/128/256 px entries. Every exported PNG payload
is byte-for-byte identical to the same-size authored ICO entry; this is neither
resampling nor a remaining default Godot icon. Godot omitted the optional 24 px entry.
Both file and product versions are `0.6.0.429`.

The corrected contract requires all six standard desktop sizes. Every embedded
size still must occur in the source ICO and match its complete PNG bytes and dimensions.
Optional source sizes omitted by the exporter are reported explicitly. No pixel
mismatch, unexpected size, missing standard size or wrong version is accepted.

## Validation

Actual Game and Test EXEs pass with `--version 0.6.0.429`; both report
`omitted_reference_sizes: ["24x24"]`. The negative contract fixtures use detached
copies of the actual parser resource records (not edited executable files).
Removing 64 px, altering one icon byte, and requiring a different native version
all fail for the corresponding reason. Actual original PE files were only read.

```json
{
  "actual_packages": {
    "game": {
      "path": "/Users/yrq/Documents/冯诺伊曼瓶颈/build/vnb-game-v0.6.0-Final20261116Game-63584487c1af/Windows/Von-Neumann-Bottleneck-Game.exe",
      "architecture": "x86_64",
      "sha256": "608c4241a4993f5975071b092a6774b657dd00a873510d2395544c44fcfcc0df",
      "icon_reference": "/Users/yrq/Documents/冯诺伊曼瓶颈/assets/branding/game-icon.ico",
      "icon_group": "",
      "icon_language": 1033,
      "icon_pngs": {
        "16x16": "85ce2d8ae353c01d66c6610e53c49935465e5ca2f167eeaa193c1d734cbf44a8",
        "32x32": "5735b47a72f1eb5e9cd251491dafbed4dc9e30eac1d674942b44b8aee7d29978",
        "48x48": "0848b9fdd93f79e3574e8eee824294a5490f97060f7cef079ae445cfb2957bfd",
        "64x64": "efed9848008fd93ad306300ae9f5a4cc4c8334ebe63d8c6963a97426f96f8e7d",
        "128x128": "27877f8929116d5f35661b5cfee8ee0a0a25d88b1eae4ed48a3130bef6e3cb29",
        "256x256": "38ffe77e41a5f4c4c7e30bc2ba3ca283e2186f8c54fda2b91e5d463d2b862cf2"
      },
      "omitted_reference_sizes": [
        "24x24"
      ],
      "versions": [
        {
          "file_version": "0.6.0.429",
          "product_version": "0.6.0.429",
          "sha256": "d8046c554638087fa7312225aa5c2701b86e158c08e3af05939c581e64311abc"
        }
      ],
      "passed": true
    },
    "test": {
      "path": "/Users/yrq/Documents/冯诺伊曼瓶颈/build/vnb-test-v0.6.0-Final20261116Test-63584487c1af/Windows/Von-Neumann-Bottleneck-Test.exe",
      "architecture": "x86_64",
      "sha256": "ba2c71e08b5c667a8a86c3d68c93a5b8f5bb75f89e4978b6ee031f082467cd09",
      "icon_reference": "/Users/yrq/Documents/冯诺伊曼瓶颈/assets/branding/game-icon.ico",
      "icon_group": "",
      "icon_language": 1033,
      "icon_pngs": {
        "16x16": "85ce2d8ae353c01d66c6610e53c49935465e5ca2f167eeaa193c1d734cbf44a8",
        "32x32": "5735b47a72f1eb5e9cd251491dafbed4dc9e30eac1d674942b44b8aee7d29978",
        "48x48": "0848b9fdd93f79e3574e8eee824294a5490f97060f7cef079ae445cfb2957bfd",
        "64x64": "efed9848008fd93ad306300ae9f5a4cc4c8334ebe63d8c6963a97426f96f8e7d",
        "128x128": "27877f8929116d5f35661b5cfee8ee0a0a25d88b1eae4ed48a3130bef6e3cb29",
        "256x256": "38ffe77e41a5f4c4c7e30bc2ba3ca283e2186f8c54fda2b91e5d463d2b862cf2"
      },
      "omitted_reference_sizes": [
        "24x24"
      ],
      "versions": [
        {
          "file_version": "0.6.0.429",
          "product_version": "0.6.0.429",
          "sha256": "d8046c554638087fa7312225aa5c2701b86e158c08e3af05939c581e64311abc"
        }
      ],
      "passed": true
    }
  },
  "negative_controls": [
    {
      "name": "missing standard 64px entry",
      "passed": true,
      "error": "Windows primary icon lacks a required standard size"
    },
    {
      "name": "wrong embedded icon byte",
      "passed": true,
      "error": "Windows icon 16x16 differs from authored ICO PNG bytes"
    },
    {
      "name": "wrong expected native version",
      "passed": true,
      "error": "Windows native file/product version differs from --version"
    }
  ]
}
```
