# MA-EA-4 completion — faction agency and adaptive endings

## Delivered slice

- The Causeway Bellkeepers are the fourth standing faction. Their bounded trust state changes the Salt Causeway fee at a visible threshold and leaves unrelated roads untouched.
- Whiteout guide payment and Mothlight bell-chart work build Bellkeeper standing; rejecting the guide line reduces it while preserving arrival.
- The Night Market now supports cooperation, opposition, and reconciliation through three authored Mirror Wells services without closing ordinary trade.
- `ending_night_market_network` is the sixth ending. It requires failed or expired official beacon support, positive Night Market support, two Mirror Wells resilience, four post-activation ordinary saltglass sales, bounded Consortium standing, and low arms pressure.
- Both replacement endings use one generic adaptive-ending evaluator and data contract.

## Verification

- Runtime content version `1.25.0` validates four standing factions, two replacement actors, and six endings.
- `tests/test_ma_ea_4.gd` proves Bellkeeper gain/loss, the route-specific discount, save/load, Night Market support/opposition/reconciliation, the alternate ending, debrief output, and rejection of pre-activation or non-ordinary transfers.
- The full repository/Godot suite passes with the new MA-EA-4 test included.
- Native evidence renders 58 player-facing states at every supported viewport and checks the one-ashmark trusted Causeway fee, each Night Market support state, and the complete alternate-ending debrief.
- A fresh Windows export validates as a 98,158,256-byte x86-64 GUI executable with a 638,116-byte embedded PCK. The expected local macOS `rcedit` warning remains non-blocking; Windows CI performs authoritative resource and package checks.

## Remaining boundary

The game now meets its faction, replacement-actor, and ending breadth floors. It still needs two or three decision-changing crew members, two to four event families, replay-focused map/event refinement, and the MA-EA-6 release-hardening gate.
