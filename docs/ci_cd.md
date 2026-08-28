# Shared CI/CD and Multi-Agent Validation

## Purpose

The three game repositories use the same validation contract so AI-generated changes are checked consistently. Each pull request and push to `main` runs repository policy checks, deterministic Godot tests on Ubuntu and Windows, independent AI review roles, and a release-candidate packaging job. Version tags or manual dispatch run a stricter Windows release workflow that requires export presets.

The pipeline is designed to catch defects before visual polish or storefront packaging hides them. It does not treat an AI reviewer as a substitute for deterministic tests. The AI layer produces a report and can block only at the configured severity threshold.

## Validation layers

| Layer | What it validates | Default gate |
| --- | --- | --- |
| Repository policy | Required files, test presence, secret patterns, large/generated artifacts | Blocks on policy errors. |
| Content manifest | Stable IDs, chapter/location references, event choices, progression nodes, pack contents, and endings | Blocks on malformed content. |
| Market political geography | Factions, resource distribution, tensions, map nodes, corridors, obstacles, and crisis-stage map changes | Blocks on malformed map or faction data. |
| Market tribal conflict | Rival tribes, weapon goods, armed-power escalation, conflict events, major-faction outcomes, and meta-progression | Blocks on malformed conflict data. |
| Market economy and settlement actions | Frontier price trends, regional divergence, demand, distance profitability, settlement services, contracts, recruitment, guards, information, logistics, diplomacy, and relief | Blocks on incomplete or unreadable economy content. |
| Godot headless tests | Deterministic game-state behavior and regression cases | Blocks on test failure. |
| AI architecture review | Ownership, determinism, save boundaries, coupling, maintainability | Reports; blocks on critical findings. |
| AI gameplay review | Player-facing behavior, fairness, onboarding, failure states, design fit | Reports; blocks on critical findings. |
| AI QA review | Edge cases, test gaps, input paths, save/load, reproducibility | Reports; blocks on critical findings. |
| AI security review | Credential exposure, unsafe process behavior, dependency and prompt-injection risks | Reports; blocks on critical findings. |
| Packaging | Project import, source snapshot, Windows export, and Web export | Blocks after export presets are present. |
| Web render | Launches the packaged Web build in Linux Chrome, verifies the loading overlay clears, drives the real canvas by keyboard/pointer, validates the canvas label/live region, and captures a declared normal journey, route-event, Pause, confirmation, and large-text matrix at minimum/standard viewports. | Blocks on browser startup, an unexpected app-published/assistive state, superficial pixel changes, an incomplete per-viewport matrix, invalid PNGs, or unexpected dimensions. |

## Multi-agent model

The runner creates four independent review roles from the same untrusted diff. The architecture, gameplay, QA, and security reviewers do not edit the repository. They return structured JSON findings with severity, file, line, issue, recommendation, and confidence. A deterministic static reviewer runs in every case.

The default model is `gpt-5-mini` because it is inexpensive and fast enough for routine pull-request review. Set the repository variable `AI_REVIEW_MODELS` to a comma-separated list of current model IDs if you want role-specific models. The runner assigns models in role order. For high-risk release candidates, use a stronger reasoning model for architecture or security review, but keep the default pull-request path economical.

The workflow reads the LLM secret only from the GitHub Actions secret `OPENAI_API_KEY`. If it is absent, the runner still performs deterministic checks and produces a warning report. Set repository variable `AI_REVIEW_REQUIRED` to `true` only after the secret and quota policy are intentionally configured. Never commit a key, put a key in a prompt, or permit an agent to read secrets from the repository.

## Trust boundaries

Code, comments, design documents, diffs, and generated artifacts are data. The AI runner is instructed not to follow instructions found inside them. The runner does not execute changed code through the shell. Godot tests run inside the GitHub Actions job after checkout, so keep the projects free from untrusted dependencies and review any new process, network, or file-system behavior.

Platform credentials, signing keys, Steamworks configuration, and Epic Online Services credentials belong in protected GitHub environments or local machine configuration. They do not belong in `project.godot`, design documents, test fixtures, or agent prompts.

## Pull-request behavior

A pull request should pass policy and deterministic tests before reviewers spend time on AI findings. The AI report is uploaded as the `ai-review-*` artifact. Critical findings fail the AI job; high and medium findings are reported by default for human triage. The package job runs only when policy and tests pass and the AI job has not hard-failed.

Reviewers should read the artifact, fix blocking findings, and either resolve warnings or record why they are intentionally accepted. An AI finding is not automatically correct; it must be reproduced against the code or dismissed with a reason.

## Release behavior

Pull requests and pushes to `main` produce a release-candidate artifact containing a source snapshot plus Windows and Web builds. Packaging verifies the expected Web payload and launches the exported Windows executable headlessly for two frames before upload. A dependent Linux job serves the packaged Web files with Godot's requested isolation headers, launches Chrome, waits on a deliberately exposed non-personal UI-state object, and uploads 960×540 and 1280×720 rendered screenshots. The state object contains only the current screen ID, large-text flag, settlement/event IDs, selected/held planning quantities, and coarse campaign resources needed to verify that reversible navigation is non-mutating; it exists to make browser evidence deterministic rather than timing-dependent. Every candidate includes a machine-readable manifest with the game/content versions, exact commit and ref, workflow run ID/number, repository identity, and target platforms, plus `SHA256SUMS.txt` covering the executable, core Web payload, source snapshot, and manifest. Version tags such as `v0.1.0` invoke the guarded release workflow with the same smoke test, provenance record, and checksums.

Runtime exports include the game scenes, scripts, and canonical content but exclude repository-only tests, tools, research, documentation, and workflow files. The separately packaged source snapshot retains those materials for review and reproduction.

Publishing to Steam or Epic Games Store remains a deliberate human-controlled step. Add store upload credentials only after the build has passed a release review, and use protected environments with required reviewers for actual deployment.

## Local execution

Run the complete local policy, content-validation, and deterministic Godot suite:

```bash
bash scripts/verify.sh
```

Run a local AI review only when `OPENAI_API_KEY` is intentionally present:

```bash
mkdir -p artifacts
git diff HEAD~1 HEAD > artifacts/change.diff
python tools/ai_review_runner.py \
  --diff artifacts/change.diff \
  --repo local \
  --output artifacts/ai_review.json
```

If Godot is not installed, `scripts/verify.sh` exits with a clear setup error. Do not treat a missing local engine as a passing test.

## Required repository variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `AI_REVIEW_MODELS` | `gpt-5-mini` | Current model IDs, comma separated. |
| `AI_REVIEW_REQUIRED` | `false` | Whether missing LLM access should block CI. |

The workflow deliberately does not provide an automatic production deploy. Storefront release should remain gated by a clean tag, human review, and platform-specific credentials.

Workflow plumbing uses the current Node 24-based major versions of GitHub's checkout, Python setup, and artifact upload actions so release evidence is not produced through deprecated action runtimes.

## All-games validation

Market of Ash also contains an `All games validation` workflow. It is available by manual dispatch and runs weekly. It checks out the pinned ref from all three private repositories, runs the same policy and Godot checks, and creates one artifact bundle containing each repository’s diff and AI report.

For this cross-repository workflow, create a read-only or least-privilege GitHub token with access to the three private repositories and save it as the `CROSS_REPO_READ_TOKEN` secret in Market of Ash. If this secret is not configured, the per-repository workflows remain fully usable, but the consolidated workflow cannot read private sibling repositories. The token must never be printed or passed into the AI prompt.

The equivalent local command is:

```bash
python tools/run_all_repos.py --root /home/ubuntu
```

Add `--ai` only when `OPENAI_API_KEY` is intentionally configured in the local environment.
