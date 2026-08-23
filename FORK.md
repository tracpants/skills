# This is a fork

Upstream: **[homeassistant-ai/skills](https://github.com/homeassistant-ai/skills)**.

It exists to carry fixes that are in use locally before (or instead of) upstream
taking them. Everything here is meant to be upstreamable — nothing is deliberately
divergent except the version scheme below.

## Local patches on top of upstream

From the audit of 2026-08-23 (skill version 17, now 18 upstream). Each was verified against
`home-assistant/core` at the 2026.8.3 tag, or rendered on a live 2026.8 template
engine, rather than reasoned about:

| Where | Patch |
|---|---|
| `template-guidelines.md` | `kelvin:` → `color_temp_kelvin:` — the mireds API is gone from `light/services.yaml` |
| `template-guidelines.md` | Loop accumulator → `namespace()`. `{% set x = x + ... %}` inside `{% for %}` is loop-scoped; the example rendered `0` for every input |
| `template-guidelines.md` | `state_attr(...) \| default(0)` → `default(0, true)` (×2). `default` fires on *undefined*; `state_attr` returns `None` |
| `template-guidelines.md` | `states(...) \| default('Unknown', true)` → `has_value()` test. `states()` returns the truthy string `unknown` |
| `safe-refactoring.md` | Device-sibling discovery pointed at `GET /api/states/<entity_id>`, which carries no registry data. Now the WebSocket registries |
| `safe-refactoring.md` + `SKILL.md` | **New `#voice-assistant-exposure` section.** Alexa/Google key on `entity_id`, so a rename orphans the old name in the assistant's app and breaks assistant-side routines invisibly from HA |
| `safe-refactoring.md` | Step 2 gained energy dashboard prefs, recorder globs, and Node-RED as its own row — all silent-failure consumers |
| `device-control.md` | Prefer the Z2M device trigger over the raw `mqtt:` topic (the topic embeds the friendly name); `sensor.*_action` is deprecated |
| `dashboard-guide.md` | Dropped a non-existent npm package name for a browser MCP server, per the repo's own "no tool names" rule |
| `helper-selection.md` | Note that its `- platform:` blocks show config shape, not a file to hand-edit |

## Versioning

Upstream's CI sets the plugin version to `0.<max skill metadata.version>.0`.
**This fork bumps the patch instead** — `0.18.1`, `0.18.2`, … — so that:

- fork-only changes get a new version, which is what makes `/plugin update` in
  Claude Code actually pick up content instead of silently no-op'ing; and
- the fork never claims a version number upstream is about to mint.

Skill `metadata.version` is left alone; upstream owns it.

When an upstream sync conflicts on a version field, **keep the higher of each**,
then bump the patch again.

## Staying in sync

Upstream changes are **reviewed, never auto-merged** — a clean merge only means no
textual conflict, not that upstream left the patched sections alone.

```bash
scripts/sync-upstream.sh          # park upstream on sync/upstream, show what changed
scripts/sync-upstream.sh --pr     # ...and open a PR against this fork's main
```

`.github/workflows/sync-upstream.yml` does the same on a weekly schedule: a PR on a
clean merge, an issue on a conflict. **It only runs once Actions are enabled on this
fork** — a one-time click under the repo's Actions tab, which GitHub requires on every
fork and which no API can do for you.

The inherited `auto-bump-version.yml` is also dormant until then; that is fine, since
this fork bumps its patch version by hand.

## Sending a patch upstream

```bash
git checkout -b fix/<thing> upstream/main
git cherry-pick <sha>
gh pr create -R homeassistant-ai/skills
```

Upstream's review bar (their `CLAUDE.md`): claims about HA behaviour are verified
against source at the release tag, e.g.
`gh api repos/home-assistant/core/contents/<path>?ref=2026.8.3 --jq .content | base64 -d`.
