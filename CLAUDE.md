# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Parking Jam — a single-file vanilla-JS sliding-block puzzle PWA. No build step, no dependencies, no test suite. The entire game (markup, styles, logic, level data) lives in `index.html`. `sw.js` and `manifest.json` make it installable and offline-capable.

## Common commands

All ops go through the `Makefile`:

| Command | What it does |
|---|---|
| `make serve` | Foreground `python3 -m http.server` on `PORT` (default 8000) |
| `make start` / `make stop` / `make restart` | Background server, PID tracked in `.server.pid` |
| `make open` | Open `http://localhost:$(PORT)/` in default browser |
| `make lan` | Print the LAN URL (for testing on a phone on the same Wi-Fi) |
| `make bump` | Increment the SW cache version in `sw.js` (e.g. `parking-jam-v2` → `v3`) |
| `make docker-build` / `make docker-run` / `make docker-stop` | Build and run the nginx static-server image |

Override defaults: `make start PORT=8080`, `make docker-run IMAGE=me/parking-jam TAG=v1 DOCKER_PORT=9000`.

## Architecture

### Single-file game (`index.html`)

Lines ~234–833 hold the entire game logic. Key globals and functions worth knowing before editing:

- **Grid model.** `COLS = ROWS = 6`, `EXIT_ROW = 2`. The target car (red, `id:0`) is always horizontal and exits to the right at row 2. `CELL` is `let`, not `const` — `computeCellSize()` recalculates it from viewport width on every `buildBoard()` call and on window resize, clamped to `[36, 72]` px.
- **Cars and levels.** `LEVELS` is an array of `{ cars, solution }`. Each car: `{ id, col, row, len, horiz, color, target? }`. `solution` is an array of `{ id, dir, steps }` steps that drive both the **Hint** button (which simulates the solution against the current state to find the first divergent move) and the **Solution** auto-play. **If you edit `cars`, you must update `solution` to match** — there is no solver.
- **Movement validation.** `getOccupied(excludeId)` builds a Set of occupied cells; `canMove(car, dir, steps)` checks bounds + collisions step-by-step. `attachDrag()` uses pointer events with `setPointerCapture` and clamps drags to legal positions cell-by-cell during the gesture, not just on release.
- **Touch on iOS.** The `.car` and `#board` rules use `touch-action: none` — without this Safari hijacks the gesture as a scroll/zoom and drags break. Don't remove.
- **Rendering.** `buildBoard()` recomputes `CELL` then lays out background cells absolutely; `renderCars()` re-creates car DOM nodes and re-attaches drag handlers. Resize handler (line ~840) debounces 100 ms, then calls both.
- **Audio.** `getAudioCtx()` lazy-creates a single `AudioContext` (required for autoplay policies). `playMove`/`playWin`/`playApplause`/`playClick` build oscillators inline.

### Service worker (`sw.js`)

Cache-first strategy with a single named cache (`parking-jam-vN`). On `activate` it deletes any other caches. **The cache name is the version key** — to ship a code change to already-installed PWAs, run `make bump` to increment `vN`. Bumping invalidates the old cache and forces a re-fetch on next launch.

### Docker image

`Dockerfile` is `nginx:1.27-alpine` serving the static files. `nginx.conf` is intentional:

- `index.html` and `sw.js` get `Cache-Control: no-cache, no-store, must-revalidate` so updates roll out immediately even without `make bump`.
- Icons get a 30-day immutable cache.
- Manifest is served as `application/manifest+json`.
- `try_files $uri $uri/ /index.html` for SPA-style fallback.

If you change cache headers, keep `index.html` and `sw.js` no-cache — otherwise nothing else can update.

## When making changes

- **Adding/editing a level:** edit the `LEVELS` array in `index.html` *and* its matching `solution`. Verify by clicking **Solution** in the browser; it should reach the win state.
- **Changing visuals or interactions:** test on a real iPhone via `make lan`. Bump the SW (`make bump`) before testing or the phone will keep loading the cached old HTML.
- **Editing icons:** the `<link rel="apple-touch-icon">` in `index.html` and the `icons` array in `manifest.json` both reference the same PNGs. iOS uses the link tag; Android uses the manifest. See README's "Install on Android" notes for the maskable-icon caveat.
