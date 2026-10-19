# 🌐 GitHub setup + automatic “Install app”

Everything needed for the app to **work on GitHub Pages** and be **installable as an app**
on phones is already built for you in the **`github/` folder**.

---

## ✅ The 6 files that make install work

Browsers will only offer “Install app” when **all** of these are true. The `github/`
folder already satisfies every one:

| # | Requirement | Where it is | Notes |
|---|---|---|---|
| 1 | **HTTPS** | GitHub Pages gives this free | Installing is **blocked** on `http://` and on files opened from storage |
| 2 | **`index.html`** at the site root | `github/index.html` | Contains the whole app (CSS + JS inlined) |
| 3 | **`manifest.json`** linked in the page | `github/manifest.json` | `display: standalone`, `start_url`, `scope`, name, colours |
| 4 | **192 px + 512 px icons** (PNG) | `github/icons/icon-192.png`, `icon-512.png` | Plus a **maskable** 512 icon for Android |
| 5 | **Service worker with a `fetch` handler** | `github/sw.js` | Registers automatically; makes the app work offline |
| 6 | **Apple touch icon** | `github/icons/apple-touch-icon.png` | iPhone/iPad home-screen icon |

```
github/
├── index.html                    ← the app (everything inlined)
├── manifest.json                 ← app name, icons, standalone display
├── sw.js                         ← service worker (offline + installability)
├── icons/
│   ├── icon-192.png              ← required
│   ├── icon-512.png              ← required
│   ├── icon-maskable-512.png     ← Android adaptive icon
│   ├── apple-touch-icon.png      ← iPhone/iPad
│   └── favicon-32.png            ← browser tab
├── 404.html                      ← friendly "page not found" → sends to app
└── .nojekyll                     ← stops GitHub's Jekyll from processing files
```

> ⚠️ **Upload the contents of `github/` — not the folder itself.** After uploading, your
> repo homepage must show `index.html`, `manifest.json`, `sw.js` and an `icons` folder
> at the top level. If you see a single folder, open it and move the files up.

---

## 🚀 Step-by-step (5 minutes)

### 1. Create the repository
- github.com → **+ → New repository**
- Name: `chileshe-loans`
- **Public** (free accounts need Public for Pages)
- Don't add a README → **Create repository**

### 2. Upload the files
Easiest: extract `chileshe-GITHUB-UPLOAD.zip`, select **everything inside** it
(`index.html`, `manifest.json`, `sw.js`, `icons`, `404.html`, `.nojekyll`) and drag it
onto **Add file → Upload files** → **Commit changes**.

> If uploading multiple files keeps failing, upload in two steps: first `index.html`
> alone, then a second upload with `manifest.json` + `sw.js` + the `icons` folder.

### 3. Turn on Pages
- **Settings → Pages**
- Source: **Deploy from a branch**
- Branch: **main** · folder **/ (root)** → **Save**
- Wait 1–2 minutes → banner shows your URL → **Visit site**

### 4. Open the live app
```
https://YOUR-USERNAME.github.io/chileshe-loans/
```
That is the app. (`github.com/…` is just the code view.)

---

## 📲 How the automatic install works

The app **asks to install itself** — you don't need to tell clients anything.

### Android / Chrome / Edge / Samsung Internet
1. Chrome checks the 6 requirements above and fires the `beforeinstallprompt` event.
2. The app shows a **“Install Chileshe Loans”** banner at the bottom of the screen
   (a few seconds after the page loads) with an **Install** button.
3. Tapping **Install** opens Chrome's native install dialog → the icon is added to the
   home screen and the app opens full-screen without browser bars.
4. After installing (or tapping ✕), the banner **doesn't nag again for 14 days**.

If the banner is missed, the **download icon in the top bar** and
**Profile → Install app** do the same thing.

### iPhone / iPad (Safari)
Apple does **not** allow websites to trigger an install prompt — this is an iOS rule,
not an app limitation. The app therefore:
1. Detects iPhone/iPad and shows the **“Tap Share → Add to Home Screen”** banner automatically.
2. If tapped, it opens **step-by-step instructions with pictures/icons**.
   *(Share button → Add to Home Screen → Add.)*

> On iPhone the link **must be opened in Safari** — Chrome/Facebook/WhatsApp in-app
> browsers cannot add to the home screen.

### Desktop (Chrome / Edge / Brave / Opera)
An **install icon appears in the address bar** (⊕ / monitor icon). The app also shows
its banner. The app then runs in its own window like a desktop program.

### Already installed?
The banner and install buttons disappear automatically (`display-mode: standalone`
detection) — so clients who installed never see install messages again.

---

## 🧪 Verify it yourself after deploying

1. Open your `…github.io/chileshe-loans/` link in **Chrome on Android**.
2. Within a few seconds the **Install Chileshe Loans** banner should slide up. ✅
3. Tap **Install** → confirm → the icon appears on the home screen. ✅
4. Open it from the home screen → it opens **full-screen** (no address bar). ✅
5. Turn on airplane mode and reopen → the app still loads (offline cache). ✅

**Chrome DevTools check (optional, on a computer):**
1. Open the site → press **F12** → **Application** tab
2. **Manifest** → should show the name, icons and `standalone` with no errors
3. **Service Workers** → should show `sw.js` as **activated and running**
4. **Lighthouse → Installability** → green

---

## 🔧 Why install might not appear (and the fix)

| Symptom | Cause | Fix |
|---|---|---|
| No install banner, no address-bar icon | Site is **not HTTPS** | Use the GitHub Pages `https://` link or a Netlify drop; `http://` can't install |
| No banner on Android | `manifest.json` or `sw.js` missing (only `index.html` uploaded) | Upload the whole `github/` content — manifest + sw.js + icons folder |
| No banner on Android | Opened inside **Facebook / WhatsApp / Instagram** browser | Tap ⋮ → **Open in Chrome**, then install |
| Icons look blank / generic | `icons/` folder not uploaded or wrong path | Keep the folder name `icons` next to `index.html` |
| Works on desktop, not on phone | Old Chrome / cached version | Update Chrome, or clear site data and reload twice |
| iPhone shows no prompt | iOS never prompts automatically | Use **Share → Add to Home Screen** (the app's banner explains this) |
| Banner never appears at all | You dismissed it earlier on that device | It returns after 14 days; or use the header download icon / Profile → Install app |

---

## 🔄 Updating the app later

1. Upload the new `index.html` (overwrite) — commit.
2. Open `sw.js` on GitHub → edit the first line, e.g.
   `var VERSION = "chileshe-pwa-v1.2.0";` → commit.
3. Installed phones fetch the new version the next time they open the app with internet.

Bumping the version is what tells the service worker to discard its old cache —
without it, phones may keep showing the old version.

---

## 📁 Which package should I use?

| Folder / zip | Use it for |
|---|---|
| **`github/`** · `chileshe-GITHUB-UPLOAD.zip` | ⭐ **The real deployment.** Installable app + offline support |
| `single-file/index.html` | A quick single-file copy (upload only if you just want the site live fast — no offline, no install prompt) |
| `backend/supabase/` | ⭐ Optional: one SQL file that makes every phone share the same records |
| `backend/google-apps-script/` | Legacy option: applications into a Google Sheet |
| `extras/` | Screenshots and build scripts (don't upload) |

---

## 📱 Several phones and computers

Install is per device — which is exactly what you want. Once the app is on each phone, connect
them so client applications reach the office and approvals reach the client:

**→ [SUPABASE-GUIDE.md](SUPABASE-GUIDE.md)** — create a free Supabase project, run one SQL
file, then paste the Project URL + publishable key + your admin key into *Owner → Settings →
Online sync*. Send each client the one-tap **Client phone link**. Without that step every
device stays a separate private notebook.
**→ [SYNC-GUIDE.md](SYNC-GUIDE.md)** — who sees what, sync timing and troubleshooting.

## 🆘 Plan B — instant HTTPS link

If GitHub's uploader keeps failing you:

1. Go to **<https://app.netlify.com/drop>**
2. Drag the **`github` folder** onto the page.
3. You get a live `https://….netlify.app` link in seconds — HTTPS, installable,
   same app. You can rename it under *Site settings → Change site name*.

The install prompt and everything else behave identically.
