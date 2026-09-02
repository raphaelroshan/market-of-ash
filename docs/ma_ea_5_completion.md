# MA-EA-5 completion — crew decisions and regional replay depth

## Delivered slice

- Mara Voss is a Blackreed wheelwright whose assigned response to `The Reedline
  Takes a Wheel` consumes one scrap and creates persistent split-axle markers.
- Orin Bell is a Mirror Wells signal reader whose assigned response to `Two
  Beacon Lines` consumes one lamp oil and creates persistent occlusion posts.
- Both new event families retain paid, time-and-provision, and disclosed-risk
  alternatives, so recruitment is useful rather than mandatory.
- The Mirror Run encounter follows the existing Shardwind event on later
  eligible crossings, adding replay depth without hiding or replacing the
  region's established first encounter.
- Event result messages now name every affected standing faction while
  preserving the established Warden phrasing.

## Verification

- Runtime content version `1.26.0` validates five decision-changing crew, eight
  deterministic event families, seven routes, and the existing six endings.
- `tests/test_ma_ea_5.gd` covers recruitment, assignment, all eight new response
  branches, blocked crew/material cases, pending-event deterministic replay,
  persistent route consequences, faction copy, and save/load.
- Native evidence renders 64 player-facing states at every supported viewport
  and asserts both specialist rosters, event identities, assignments, and saved
  route conditions.
- A fresh Windows export validates as a 98,169,776-byte x86-64 GUI executable
  with a 649,636-byte embedded PCK. The expected local macOS `rcedit` warning
  remains non-blocking; Windows CI performs the authoritative resource checks.

## Remaining boundary

The implementation now meets every numeric Early Access content floor. MA-EA-6
still owns packaging, migration, accessibility, performance, versioned release
documentation, and publication of the Early Access candidate. Commercial art,
physical-device, assistive-technology, antivirus/storefront, and moderated
player evidence remain explicitly external gates.
