# MA-EA-6 completion — versioned Early Access candidate

## Delivered hardening

- Project, Windows resource, content, manifest, and release-note versions are
  bound by a dependency-free release-contract validator.
- The Windows portable package now includes a release guide and rejects a
  missing guide, incomplete guidance, path surprises, or extra files.
- Tagged release jobs require the matching version, impose a 30-second clean
  launch timeout, generate checksums/provenance, and publish the executable,
  portable ZIP, metadata, screenshot, source snapshot, and manifest as a GitHub
  prerelease only after validation.
- Content-1.25 save compatibility, all historical migrations, semantic access
  to both new crew responses, and bounded runtime/history performance are
  explicit regression gates.

## Automated evidence

- `tools/validate_release_contract.py` and its fixture test enforce release
  version/document alignment.
- `tests/test_windows_export_validation.py` enforces the two-file portable ZIP
  contract and required in-package guidance.
- `tests/test_release_readiness.gd` enforces every numeric content floor,
  twenty-five deterministic world/save round trips within five seconds, and
  bounded long-session logs.
- `scripts/verify_ma_ea_6.sh` runs the repository suite, four-resolution native
  matrix, release contract, fresh Windows export, and local portable-package
  validation. Tagged CI supplies authoritative Windows resource, clean-launch,
  packaged-browser, and publication evidence.
- The local candidate export validates as a 98,169,824-byte x86-64 GUI
  executable with a 649,684-byte embedded PCK; its two-file portable ZIP is
  33,624,350 bytes and includes the 3,294-byte release guide.

## Honest remaining limits

The candidate completes the agent-implementable roadmap, not final commercial
certification. The executable remains unsigned; temporary CC0 audio and
code-native production art remain visible; and physical-device,
assistive-technology, antivirus-vendor, Steam, Epic Games Store, localization,
and moderated human-playtest gates remain external work.
