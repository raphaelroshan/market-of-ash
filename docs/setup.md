# Market of Ash — Development Environment Setup

## Recommended local machine

Use a Windows development machine as the primary target because the commercial release is intended for Steam and Epic Games Store. Keep the repository in Git and make the project folder available to the coding agent through the agent’s folder-binding mechanism. The sandbox used to generate this package does not include Godot, so the project has been scaffolded and statically reviewed but not launched here.

Install Godot 4.x from the official Godot website, Git, and a code editor that can search the repository and display GDScript diagnostics. Use a stable Godot release for the project and pin that choice in the first decision-log entry. Do not change engine minor versions during a milestone unless a compatibility issue is documented.

## First local commands

From the repository root:

```powershell
godot --editor project.godot
godot --headless --path . --script res://tests/test_economy.gd
git status
git add .
git commit -m "Initialize Market of Ash agent-first prototype"
```

If the `godot` command is not available, launch Godot from its installation directory or add it to PATH. The repository verification script will report the same limitation rather than hiding it.

## Agent access

Bind the local project folder to the coding agent before asking it to modify files. Provide the persistent context prompt from `docs/agent_feeding_guide.md`, then give one narrow task. The agent should be able to inspect files, edit scripts, run the headless test command, launch the project, and report the result. Do not provide storefront credentials or SDK secrets in chat or repository files.

## Platform integration staging

Do not install Steamworks or Epic Online Services dependencies into the first simulation milestone. First stabilize the offline game and its save model. Then add a small platform abstraction with no-op offline behavior. Add Steam integration and Steam Cloud first, using the maintained GodotSteam source or an internally controlled GDExtension adapter. Add Epic Online Services through a separate adapter after the offline and Steam paths are stable. Keep achievements, cloud saves, rich presence, and account identity out of the economy classes.

## Build channels

Maintain three build channels:

| Channel | Purpose |
| --- | --- |
| Local debug | Fast agent iteration with verbose logs, seeded test worlds, and developer controls. |
| Demo/review | Clean player-facing build with the vertical slice, safe save migration, no debug shortcuts, and a resettable profile. |
| Release candidate | Windows storefront build with platform services, crash logging, controller and scaling checks, and final content lock. |

The agent must never submit a release candidate directly from an uncommitted working tree. Create a tagged commit, record the Godot version, record the test result, and archive the exact build artifact.

## Art pipeline

Start with a small set of intentional 2D references: map background, settlement icons, route states, goods icons, three crew portraits, and event illustrations. Use stable filenames and data references. The art style should be illustrated and readable at desktop scale, with a restrained ashland palette and strong color coding for market states and route risk. Replace placeholders incrementally; do not wait until the end to discover that the interface cannot support the intended art.

## Local checklist before agent work

Confirm that the folder is bound, Git is initialized, Godot opens `project.godot`, the main scene launches, the headless economy test command is known, and the agent has read `AGENTS.md`. If any of these are false, fix the environment before asking for new gameplay.
