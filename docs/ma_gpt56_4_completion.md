# MA-GPT56-4 — Early Access Private-Alpha Package

**Status:** Complete

**Candidate:** `0.16.0-early-access-rc2`

**Content:** `1.28.0`

**Next packet:** Publish and collect private-alpha calibration

## Player result

The complete GPT-5.6 investment campaign is available as a portable, offline Windows candidate for a 30–90 minute session. The package includes a versioned tester guide covering install, upgrade, backup recovery, migration, rollback, the intended test path, known limitations, and artifact provenance. The same candidate can be tested with mouse, keyboard, controller, Large Text, Reduced Travel Motion, and four supported window sizes.

## Package result

The local acceptance gate produced and validated:

- `market-of-ash.exe`, a 94 MB Windows PE with an embedded Godot pack;
- `market-of-ash-windows.zip`, a clean 32 MB portable distribution containing the executable and tester guide;
- `market-of-ash-1600-capture.zip`, the complete 86-state 1600×900 journey evidence;
- `release_manifest.json`, binding repository, versions, commit, ref, run, release notes, and private-alpha contract;
- `SHA256SUMS.txt`, covering every tester-facing artifact.

Tagged builds repeat the Windows export, clean extraction, offline headless launch, packaged GUI capture, full journey capture, manifest generation, and checksum generation before GitHub can publish the prerelease.

## Deterministic acceptance

```bash
MARKET_GODOT_BIN=/tmp/godot-4.4.1/Godot.app/Contents/MacOS/Godot \
  scripts/verify_gpt56_private_alpha.sh /tmp/market-of-ash-0.16.0-private-alpha
```

Result: `MA-GPT56-4 private-alpha acceptance: PASS`. The nested repository gate passed all validators and Godot suites; the native capture validator accepted all 86 required states at 1600×900; the Windows PE/PCK, clean ZIP, guide, manifest, capture archive, and checksums all passed their validators.

The durable review subset and complete capture manifest are in `docs/visual_evidence/v0.16.0-private-alpha-2026-09-03/`. Tagged CI publishes the full capture archive next to the executable.

## Authority and save boundary

Packaging does not create a second game path. It exports the same project, runtime content, command processor, save version 12, migration rules, and one-generation `.bak` recovery used by local and CI tests. Release metadata is read from the authoritative project, runtime-world, and CI manifest files; the UI and release scripts do not calculate market outcomes.

## Known deficiencies

- The executable is unsigned and may trigger Windows reputation warnings.
- Physical controller, assistive-technology, antivirus-vendor, storefront, and moderated comprehension testing require external testers or services.
- Settlement and route illustrations are original code-native production scaffolding; temporary CC0 interface audio and departure dust remain explicitly attributed and replaceable.
- The Ash Sifters have one cooperation action rather than the broader political depth of the older replacement actors.
