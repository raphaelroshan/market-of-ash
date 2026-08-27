# Browser Build Verification Notes

CI run 73 completed successfully with the current Node 24-based GitHub actions. Its package job imported the project, exported Windows and Web targets, verified the complete Web payload, launched the packaged Windows executable headlessly for two frames, and uploaded `release-candidate-73` with a source snapshot and provenance manifest. Direct interactive browser rendering remains a manual gate; the deterministic Godot UI smoke test is the authoritative automated interaction check until that session is recorded.

The next manual browser check should confirm the following rendered states: main menu; Settlement Shop after Start Game; Departure Desk after Plan Departure; unchanged resources after Return to Shop; arrival report after Commit Departure; and destination shop after Enter Settlement.
