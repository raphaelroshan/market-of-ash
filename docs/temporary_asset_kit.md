# Market of Ash — Temporary Asset Kit

**Status:** Testing-only breadth kit  
**Build target:** Current private alpha branch  
**Purpose:** Give AI agents usable art, audio, VFX, and animation ingredients while the final frontier-trade visual identity is still being authored.

## Included sources

| Source | Repository path | License | Intended use | Deficiency note |
|---|---|---|---|---|
| Kenney Tiny Town | `assets/temporary/kenney/tiny-town/` | CC0; proof in `assets/temporary/kenney/LICENSE-tiny-town.txt` | Temporary settlement plates, map tiles, route backgrounds, and travel filler | The bright, cute 16×16 language does not match the dusty frontier tone. Use as blockout/travel filler, not final key art. |
| Kenney Interface Sounds | `assets/temporary/kenney/interface-sounds/` | CC0; proof in `assets/temporary/kenney/LICENSE-interface-sounds.txt` | Button, selection, confirmation, cancel, error, open, close, and receipt feedback | Generic UI clicks are useful for usability but do not express market, caravan, or frontier identity. |
| Kenney RPG Audio | `assets/temporary/kenney/rpg-audio/` | CC0; proof in `assets/temporary/kenney/LICENSE-rpg-audio.txt` | Footsteps, cloth, doors, books, weapon/foley, and material cues | RPG fantasy foley is serviceable for testing but lacks dusty-road, wagon, coin, crowd, and faction-specific character. |
| Kenney Particle Pack | `assets/temporary/kenney/particle-pack/` | CC0; proof in `assets/temporary/kenney/LICENSE-particle-pack.txt` | Dust, smoke, sparks, impact flashes, and route/event emphasis | Generic white particle shapes need palette tinting and scale discipline before they resemble ash, dust, or fire. |

## Safe usage pattern in Godot

Load imported resources through `ResourceLoader` or `load`, not editor-only file paths. For example:

```gdscript
var town_texture: Texture2D = load("res://assets/temporary/kenney/tiny-town/tilemap.png")
var click_sound: AudioStream = load("res://assets/temporary/kenney/interface-sounds/click_001.ogg")
var dust_texture: Texture2D = load("res://assets/temporary/kenney/particle-pack/smoke_01.png")
```

Use `Sprite2D` or `TextureRect` for a static preview. For temporary animation, create an `AnimatedSprite2D` or `SpriteFrames` resource from several related particle frames, then tint the result with the current game palette. The Tiny Town package is primarily a tileset, not a character-animation set; do not imply that its static tiles are finished animated actors.

For audio, route temporary sounds to the project’s existing UI, world, or ambience bus. Use short sounds for confirmation, selection, and receipt events. Do not play a raw preview or long loop on every state refresh. A useful first mapping is `click_001` for hover/selection, `confirmation_001` for completed purchase/sale, `error_001` for invalid cargo action, `bookFlip1` or `bookOpen` for information panels, and a quiet `footstep` or `creak` cue for travel transition tests.

## Market-specific application

Use Tiny Town as a temporary background behind the route map, settlement arrival, or travel transition if the current procedural view is too empty. Keep the market data, prices, local need, and route risk in the authored UI; the pack must not replace the authoritative trade presentation.

Use interface sounds to make ordinary buying and selling feel responsive before custom market audio exists. A successful purchase should have a clear but restrained confirmation, an unaffordable purchase should use the error cue, and a completed route/departure should receive a distinct confirmation or close sound.

Current integration uses `confirmation_001.ogg` for successful commands, `error_001.ogg` for blocked commands, and `creak1.ogg` for committed travel. Export-safe `.oggstr` copies live under `assets/temporary/selected-audio/`; their README preserves the original source paths and hashes. They play at a restrained shared level, remain controlled by the existing Interface Sounds setting, and never replace visible result text.

Use particle textures sparingly for dust on departure, a short spark on a route consequence, and a small smoke layer for an event or damaged wagon. Do not use magical-looking particles for economic state; color and timing should suggest dust, ash, paper, metal, or fire.

Current integration uses `particle-pack/smoke_03.png` as three small, palette-tinted puffs behind the caravan during only the opening portion of an animated departure. An export-safe byte copy lives at `assets/temporary/selected-vfx/departure-dust.pngdata`; its README preserves the source path and hash. The effect is presentation-only, fades before the mandatory road stop, and is fully suppressed by Reduce Travel Motion. Release presets exclude the unused raw Kenney source directories and include only explicitly selected runtime assets.

## Animation recipes for the agent

The temporary kit does not contain a bespoke Market of Ash animation set. Agents should create motion from existing textures and deterministic state:

1. Use a two- or three-frame smoke sequence for a short departure dust puff.
2. Use a one-shot scale/fade animation for a coin or trade confirmation accent.
3. Use a slow parallax or offset animation on the Tiny Town travel layer while the authoritative route state remains unchanged.
4. Use a palette-tinted spark or scorch frame for a disclosed risk/consequence receipt, never as a hidden simulation signal.

Every animation must be presentation-only. It must not consume random streams, alter prices, change route outcomes, or make a trade appear successful before the command is accepted.

## Replacement priority

Replace the Tiny Town settlement and map art first when the team is ready for a stronger frontier identity. Replace generic interface sounds only after the ordinary trade loop has stable event names and timing. Commission or author a small portrait/sigil family and a market/frontier musical motif before commissioning dozens of individual event illustrations.

## Provenance

The upstream pages are [Tiny Town](https://kenney.nl/assets/tiny-town), [Interface Sounds](https://kenney.nl/assets/interface-sounds), [RPG Audio](https://kenney.nl/assets/rpg-audio), and [Particle Pack](https://kenney.nl/assets/particle-pack). The local license files are the authoritative copies used for this temporary kit. Keep this document with the assets and do not redistribute the raw source packages as a standalone asset bundle.
