# MA-I6 completion — 0.15.0 investment release candidate

## Candidate contract

- Game version: `0.15.0-early-access-rc1`.
- Windows file/product version: `0.15.0.0`.
- Runtime content version: `1.27.0`; save format remains 12.
- Versioned install, upgrade, rollback, test, limitation, and verification guidance ships inside the portable Windows ZIP.
- The deterministic simulation remains offline and contains no live storefront credentials or service dependency.

## Automated acceptance

- Full repository verification covers economy, UI, presenters, tutorial, controller, complete campaigns, three regions, factions/endings, five specialists, the creative vertical, release readiness, and static/package contracts.
- The 100-seed investment economy matrix reports completion, profitability, bankruptcy, cargo loss, cargo utilization, arrival timing, route use, route net, goods, and event distribution.
- Save tests cover migrations from formats 0–11, current-content normalization, backup recovery, pending journeys/events, changed markets, recruited crew, route conditions, replacement actors, and terminal state.
- Native capture validates the complete flow and responsive shell; Linux/Windows and packaged-browser CI remain required before merge.
- Tagged release CI builds the Windows executable and portable ZIP, validates the embedded PCK and PE metadata, clean-launches the extracted build, captures its UI, and publishes checksums plus provenance.

Local Godot 4.4.1 acceptance produced and structurally validated a 98,177,424-byte x86-64 Windows executable with a 657,284-byte embedded PCK and a 33,634,342-byte portable ZIP. Native bounds and distinct-state validation passed at 960×540, 1280×720, 1600×900, and 1920×1080. Windows CI remains authoritative for PE resource stamping and visible packaged launch because local macOS export cannot run `rcedit`.

## External gates

Code cannot certify physical-controller feel, assistive-technology behavior, antivirus reputation, Steam/Epic review, or moderated 30–90 minute player sessions. These are named release limitations rather than hidden completion claims.
