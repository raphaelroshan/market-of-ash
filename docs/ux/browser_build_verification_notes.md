# Browser Build Verification Notes

The Godot Web export completed successfully after the shop/departure flow refactor. The temporary public proxy that previously served the build became unavailable during the refreshed visual check, and direct localhost navigation from the isolated browser returned an empty response. The headless Godot UI smoke test is the authoritative automated verification for the new flow until a refreshed proxy session is available.

The next manual browser check should confirm the following rendered states: main menu; Settlement Shop after Start Game; Departure Desk after Plan Departure; unchanged resources after Return to Shop; arrival report after Commit Departure; and destination shop after Enter Settlement.
