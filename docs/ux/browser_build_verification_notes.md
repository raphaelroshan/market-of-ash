# Browser Build Verification Notes

CI run 36 completed successfully and its uploaded release candidate was inspected directly. It contains the Windows executable and the complete Godot Web payload: `index.html`, JavaScript loaders/worklets, PCK data, icons, and WASM. The temporary public proxy that previously served the build became unavailable during the refreshed visual check, and direct localhost navigation from the isolated browser returned an empty response. The headless Godot UI smoke test remains the authoritative automated verification until a refreshed browser session is available.

The next manual browser check should confirm the following rendered states: main menu; Settlement Shop after Start Game; Departure Desk after Plan Departure; unchanged resources after Return to Shop; arrival report after Commit Departure; and destination shop after Enter Settlement.
