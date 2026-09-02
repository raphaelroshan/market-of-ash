# MA-I1 — Shell and Performance Completion

**Completed:** 2026-09-02  
**Build:** `v0.14.0-early-access-rc1` plus MA-I1 source changes  
**Player behavior:** A fresh player can advance Main Menu → all three Introduction cards → the first Ashgate Bazaar at minimum width, 1280×720, 1600×900, and Large Text without losing a required action. Mouse/keyboard and controller focus enter the same ordinary-trade path.

## Acceptance record

- The opening uses the stacked composition at 960 and 1280 pixels wide and the intended split composition at 1600 pixels. Native capture validation asserts every required opening and Bazaar control is visible, has rendered bounds, and remains inside its active panel.
- The minimum-width Large Text capture keeps the Introduction primary/back/skip actions and the Bazaar buy/sell/departure actions reachable. Long market detail remains intentionally scrollable.
- The controller smoke traverses New Game, all Introduction pages, the first Bazaar purchase, Departure, road continuation, an event response, and arrival without mouse input.
- Public runtime-content APIs still return isolated copies. Internal record lookup now reads the already validated cache and copies only the requested record instead of cloning the complete 83 KB content document for every validation lookup.
- The deterministic benchmark reports its exact duration. On the local Apple M1 Pro with Godot 4.7.2, 25 fresh-world serialize/load cycles completed in **41.62 ms**, below the **5,000 ms** release limit and far below the audited approximately **5,161.91 ms** result.

## Evidence

| State | Evidence |
|---|---|
| Minimum-width opening | [Introduction at 960×540](visual_evidence/v0.14.0-ma-i1-shell-performance-2026-09-02/introduction-basin-960x540.png) |
| Minimum-width Large Text | [Introduction 3 at 960×540](visual_evidence/v0.14.0-ma-i1-shell-performance-2026-09-02/introduction-road-large-text-960x540.png) |
| Minimum-width first Bazaar | [Large Text Bazaar at 960×540](visual_evidence/v0.14.0-ma-i1-shell-performance-2026-09-02/settlement-shop-large-text-960x540.png) |
| Baseline opening | [Introduction at 1280×720](visual_evidence/v0.14.0-ma-i1-shell-performance-2026-09-02/introduction-basin-1280x720.png) |
| Baseline first Bazaar | [Bazaar at 1280×720](visual_evidence/v0.14.0-ma-i1-shell-performance-2026-09-02/settlement-shop-1280x720.png) |
| Preferred desktop opening | [Introduction at 1600×900](visual_evidence/v0.14.0-ma-i1-shell-performance-2026-09-02/introduction-basin-1600x900.png) |

## Verification

```text
Godot 4.7.2
Release budget: 25 deterministic world/save round trips in 41.62 ms (limit: <5000.00 ms)
Early Access release readiness: PASS
Map UI smoke: PASS
Tutorial flow: PASS
Controller input smoke: PASS
Native UI captures: PASS (960x540)
Native UI captures: PASS (1280x720)
Native UI captures: PASS (1600x900)
Native UI render validation: PASS
```

The repository-wide verification entrypoint remains the final integration gate. CI uses the pinned Godot 4.4.1 target and therefore supplies the authoritative cross-version result after the pull request is pushed.

## Known limitation

The screenshots are deterministic code-native capture evidence, not moderated readability or physical-controller evidence. Those remain external evaluation tasks and do not block the next implementation gate.

## Next gate

**MA-I2 — Trade fantasy:** make the first five minutes explicitly teach purchase, demand, capacity, route cost, provisions, sale, and changed return-market conditions through one normal-flow journey and receipt.
