# Parking Jam

A small browser-based sliding-block puzzle. Move cars on a 6×6 grid to clear a path for the red car to exit. Single-file vanilla JS — no build step, no dependencies.

## Features

- 10 hand-crafted levels with built-in solutions
- Hint button (highlights the next correct move) and full auto-solve playback
- Reset, level picker dots, move counter
- Web Audio sound effects (toggleable)
- Installable as a PWA (manifest + service worker, works offline)
- Touch-friendly drag controls, scales to phone screens

## Layout

```
.
├── index.html      # game (HTML + CSS + JS in one file)
├── manifest.json   # PWA manifest
├── sw.js           # service worker (offline cache)
├── icon-192.png    # PWA icon
├── icon-512.png    # PWA icon
├── nginx.conf      # nginx config used inside the Docker image
├── Dockerfile      # nginx:alpine static-server image
├── Makefile        # common ops
└── .dockerignore
```

## Run locally

```sh
make serve              # foreground, Ctrl+C to stop
make start              # background, writes .server.pid
make stop
make open               # open in default browser
make lan                # print LAN URL for testing on a phone
```

Override the port with `make serve PORT=8080`.

## Install on iPhone / iPad

The game is a PWA, so once installed it launches full-screen from the home screen with no Safari chrome and works offline.

### 1. Serve the files

Pick one of:

- **Local network (quickest):** on your Mac run `make start`, then `make lan` to print the LAN URL (e.g. `http://192.168.4.125:8000/`). Phone and Mac must be on the same Wi-Fi.
- **Docker:** `make docker-run` then use the same `make lan` URL with `:8080`.
- **Public URL:** deploy the static files anywhere (GitHub Pages, Netlify, Cloudflare Pages, S3+CloudFront, your own nginx). PWA install **requires HTTPS** for non-localhost origins, so a public deploy must serve over `https://`.

### 2. Open in Safari

Open the URL **in Safari** (not Chrome — only Safari can install PWAs to the iOS home screen). If you used a LAN URL, accept any "not secure" warning — `http://` is allowed for private LAN addresses.

### 3. Add to Home Screen

1. Tap the **Share** button (the square with the up-arrow) at the bottom of Safari (or top-right on iPad).
2. Scroll down and tap **Add to Home Screen**.
3. Confirm the name **Parking Jam** and tap **Add**.

A new icon appears on your home screen. Launching it opens the game full-screen, in landscape or portrait, with the status bar styled to match the game background.

### 4. Offline use

After the first launch the service worker caches everything. You can put the phone in airplane mode and the game will still load from the home-screen icon.

### Updating an installed copy

If you change the code, the phone may keep showing the old version. To force an update:

```sh
make bump      # bumps parking-jam-vN -> v(N+1) in sw.js
```

Then on the phone: open the home-screen icon, pull down to refresh in Safari, or — if it still won't budge — delete the icon (long-press → Remove App → Delete from Home Screen) and re-add it.

### Troubleshooting

- **"Add to Home Screen" missing** — you're not in Safari. Open the URL in Safari specifically.
- **LAN URL won't load** — check the Mac's firewall (System Settings → Network → Firewall) and confirm both devices are on the same network (no "client isolation" on the Wi-Fi).
- **Cars won't drag on touch** — make sure you're on the latest `index.html`; the touch fix needs `touch-action: none`. Bump the SW cache and reload.

## Install on Android

The same overall flow as iOS, but through Chrome's menu instead of a Share sheet, and the result is a real installed app (WebAPK) with its own launcher entry — not just a bookmark.

1. Serve the files (same as iOS — `make start` + `make lan`, Docker, or a public HTTPS URL).
2. Open the URL in **Chrome** (Edge, Samsung Internet, and Firefox also work).
3. Either:
   - Wait a few seconds for Chrome's automatic **"Install app"** banner and tap it, or
   - Tap **⋮ menu → Install app** (older versions: **Add to Home screen**).
4. Confirm and the app appears in your launcher and app drawer.

Updates and offline behavior are the same as iOS. To force-refresh after a code change, run `make bump` on your Mac, then reopen the app — Chrome picks up the new service worker on next launch.

## Docker

```sh
make docker-build                       # build parking-jam:latest
make docker-run                         # run on host port 8080
make docker-stop
make docker-run IMAGE=me/parking-jam TAG=v1 DOCKER_PORT=9000
make docker-push IMAGE=me/parking-jam TAG=v1
```

The image is `nginx:1.27-alpine` serving the static files. `index.html` and `sw.js` are sent with `no-cache` so updates roll out immediately; icons get a 30-day cache.

## Editing levels

Levels are defined inline in `index.html` as the `LEVELS` array. Each entry:

```js
{
  cars: [
    { id:0, col:0, row:2, len:2, horiz:true, color:'#e74c3c', target:true },
    ...
  ],
  solution: [{id:1, dir:1, steps:2}, {id:0, dir:1, steps:4}],
}
```

- `id:0` is the target (red) car. It must be horizontal and exits to the right at `EXIT_ROW` (row 2).
- `dir` is `+1` (right/down) or `-1` (left/up); `steps` is how many cells.
- The `solution` powers both the **Hint** and **Solution** buttons — keep it in sync if you edit `cars`.
