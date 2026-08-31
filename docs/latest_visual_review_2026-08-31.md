# Market of Ash — Current Presentation Visual Review

**Build:** `v0.13.5-alpha-basin-vertical-slice`

**Engine:** Godot 4.4.1

**Capture:** Local macOS OpenGL real renderer at 960×540, 1280×720, 1600×900, and 1920×1080.

## Current finding

The 1280×720 opening still used the split desktop composition. Large Text left the Introduction primary action with almost no horizontal safety margin, while the bounds harness proved only that the outer card and a small subset of controls remained on-screen.

## Current resolution

Main Menu and Introduction now switch to the stacked composition at 1280 pixels and below. The compact Main Menu shortens its illustrated header, both cards add horizontal safety gutters, and Introduction actions wrap instead of clipping. At 1600×900 and larger, the Introduction gives the action rail more width while retaining the split scene. Capture evidence now checks every required opening heading, explanation, status, and action against both its containing card and the active viewport.

## Current evidence

![Main Menu at 1280×720](visual_evidence/v0.13.5-alpha-basin-vertical-slice/main-menu-1280x720.png)

![Introduction with Large Text at 1280×720](visual_evidence/v0.13.5-alpha-basin-vertical-slice/introduction-road-large-text-1280x720.png)

![Introduction with Large Text at 1600×900](visual_evidence/v0.13.5-alpha-basin-vertical-slice/introduction-road-large-text-1600x900.png)

The complete 25-state journey matrix passed viewport, required-control, card-containment, focus, and state-transition validation at all four requested sizes.

## Previous correction

The 0.13.4 roadside dossier separated threat, exposed cargo, route, dilemma, event basis, and rules while preserving complete response costs and outcomes. The 0.13.3 Bazaar trade ticket remains unchanged.

## Remaining visual limitation

The procedural settlement and road illustrations establish identity and navigation but are not final commercial art. Further art-direction work should be driven by player evidence rather than unvalidated ornament.
