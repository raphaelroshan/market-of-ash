# MA-EA-6 — Early Access release-hardening plan

## Player-facing behavior

The candidate download must be identifiable, self-contained, recoverable, and
honest. A player receives the same version in the game, Windows metadata,
release manifest, and release notes. The portable ZIP includes a guide that
explains install, upgrade, save compatibility, rollback, verification, and
known limitations before the executable is launched.

Existing alpha saves remain usable. Keyboard, controller, Large Text, Reduced
Motion, semantic actions, responsive layouts, and bounded long-session state
remain part of the release contract rather than optional follow-up work.

## Release shape

- Game version: `0.14.0-early-access-rc1`.
- Windows file/product version: `0.14.0.0`.
- Content version: `1.26.0`; save format remains 12.
- Recommended asset: `market-of-ash-windows.zip`, containing the embedded-PCK
  executable and the versioned release guide.
- Tagged workflow: validates the tag/version contract, clean-smokes the ZIP,
  captures Windows GUI/version evidence, records checksums and provenance, and
  publishes a GitHub prerelease only after every gate succeeds.

## Acceptance gates

1. Project, PE, content, manifest, tag, and release-note versions agree.
2. The portable ZIP rejects missing, incomplete, or unexpected files and ships
   install, upgrade, rollback, and limitation guidance.
3. A save written against content 1.25.0 loads into 1.26.0 with its prior crew
   and assignment intact; formats 0–11 and future-version rejection remain
   covered.
4. Both new specialist actions remain enabled and ordered in native semantic
   evidence, and the existing input/Large Text/Reduced Motion matrix stays green.
5. Twenty-five deterministic world/save round trips complete within five
   seconds on the local reference machine; log and command history remain
   bounded under a long-session probe.
6. Full deterministic tests, the 256-frame native matrix, a fresh Windows
   export, clean ZIP smoke, Windows metadata, browser journeys, and release
   publication all pass before the tag is considered complete.

