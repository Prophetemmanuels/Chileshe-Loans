# 🚑 UPLOAD GUIDE — fix “page isn’t working” on GitHub

GitHub’s web uploader often fails when you drag a **folder with many sub-folders**
(`css/`, `js/`, `icons/`…). When that happens, files land in the wrong place or not
at all — and GitHub Pages then shows **“There isn’t a GitHub Pages site here”**
or the browser says **“This site can’t be reached / page isn’t working right now.”**

**Do this instead — upload ONE file.** 👇

---

## ✅ Fastest, most reliable way (recommended)

Everything is packed into a **single `index.html`** (378 KB). No folders, no paths —
nothing can go missing.

### Step 1 — Create the repository
1. Go to <https://github.com> and sign in.
2. Top-right **+** → **New repository**.
3. Repository name: `chileshe-loans`
4. Choose **Public** (free accounts need Public for Pages).
5. **Do NOT** tick “Add a README”.
6. Click **Create repository**.

### Step 2 — Upload the single file
1. On the empty repo page click **uploading an existing file**
   *(or: Add file → Upload files)*.
2. Drag in **`single-file/index.html`** from this folder — **just that one file**.
   - ⚠️ Upload the **file**, not the `single-file` folder.
   - ⚠️ The file must be named exactly `index.html`.
3. Wait for the file name to appear in the list, then click **Commit changes**.

✅ Your repo homepage must now show `index.html` **immediately** (not inside any folder).

### Step 3 — Turn on GitHub Pages
1. Repo → **Settings** (top tab).
2. Left sidebar → **Pages**.
3. Under *Build and deployment*:
   - **Source:** `Deploy from a branch`
   - **Branch:** `main` — folder **`/ (root)`** → **Save**
   *(if your repo uses `master`, pick `master`)*
4. Wait **1–3 minutes**. Refresh the page — a green banner appears:
   *“Your site is live at …”* → click **Visit site**.

### Step 4 — Open the right URL
The app lives at **`https://YOUR-USERNAME.github.io/chileshe-loans/`**

| ❌ Not the app | ✅ This is the app |
|---|---|
| `github.com/you/chileshe-loans` | `yourname.github.io/chileshe-loans` |
| `…/blob/main/index.html` | `…github.io/chileshe-loans/index.html` |

> Bookmark that URL. On a phone: open it → menu **⋮ → Install app / Add to Home screen**.
> On iPhone: Safari → **Share → Add to Home Screen**.

---

## 🧯 If the upload still fails

Try these in order:

1. **Refresh and sign in again.** An expired session makes GitHub’s uploader throw a
   generic “Something went really wrong”.
2. **Use a computer, not the phone.** The GitHub website is much more reliable on a
   desktop browser. If you must use a phone, switch the browser to **Desktop site**.
3. **Drag the file onto the page** (not into the little box) — or click
   *choose your files* and pick `index.html` from your Downloads/File manager.
4. **Create the file inside GitHub instead** (works even if uploading is blocked):
   - Repo → **Add file → Create new file**
   - Name it `index.html`
   - Open `single-file/index.html` on your device, **select all**, copy, paste into
     the editor, then **Commit changes**.
   *(Pasting 378 KB is slow but works. If the browser struggles, use option 5.)*
5. **Use GitHub Desktop** (free app): *File → Add local repository* → choose the
   folders on your computer → **Publish repository**. Then enable Pages as in Step 3.

---

## 🔍 Diagnose what you see

| What you see | What it means | Fix |
|---|---|---|
| **“There isn’t a GitHub Pages site here”** / 404 page | Pages not enabled, or wrong branch/folder | Step 3 — branch `main`, folder `/ (root)`, Save, wait 2 min |
| **“This site can’t be reached” / DNS error** | Site not published yet, or URL typo | Check the exact URL in **Settings → Pages** banner; wait a few minutes |
| **Page loads but is blank/unstyled** | You uploaded the folder version and `css/` or `js/` is missing | Use the **single-file** version — it cannot break this way |
| **Repo page shows code** | You are on `github.com/...`, not the Pages URL | Open `https://USERNAME.github.io/REPO/` |
| **“Yowza, that file is too big”** | Uploading the screenshots/zip (large) | Upload only `index.html` |
| **Actions tab shows a red ❌** | Build error | Delete the workflow run or tell me what the log says — with plain HTML it is almost always a path issue |
| **Private repo, Pages unavailable** | Free plan needs Public repos for Pages | Settings → General → scroll down → **Change visibility → Public** |

---

## ✅ 60-second test after the site is live

1. Open your `…github.io/chileshe-loans/` link → you see the green **CHILESHE
   INNOVATIONS** home page. ✅
2. Footer → **Staff login** → create your **admin PIN**.
3. Tap **“Explore with sample data”** → you’ll see loans, payments and reminders
   (demo client PIN `1234`). Remove it later in **Settings → Data**.
4. Apply for a test loan from the client side, then approve it in the owner
   dashboard to confirm the full flow works.
5. Install the app on your own phone (menu → *Install app*) — this only works on the
   `https://` GitHub Pages link, not on a file opened from storage.

---

## 📦 What is in this folder

| File / folder | Upload? | Purpose |
|---|---|---|
| **`single-file/index.html`** | ✅ **Yes — this one file only** | Complete app in one file |
| `index.html`, `css/`, `js/`, `icons/`, `sw.js`, `manifest.json`, `404.html` | Optional | Full multi-file version (better offline support via service worker) |
| `backend/` | Optional | Google Sheet sync (only if you want online applications) |
| `extras/` | No | Screenshots + build script |

> **Single file vs full version:** the single file is the easiest to upload and does
> everything (applications, uploads, approvals, payments, reminders, receipts, PDFs,
> install to home screen). The multi-file version additionally caches the app for
> **offline** use through a service worker. Start with the single file; you can
> upgrade later by uploading the full folder on top.

---

## 🌐 Plan B if GitHub still refuses (works in 30 seconds)

1. Go to <https://app.netlify.com/drop>
2. Drag the `single-file` folder onto the page.
3. You instantly get a live `https://….netlify.app` address (free, HTTPS, installable).
   You can rename it in *Site settings → Change site name*.
4. Later, point it at GitHub or keep using Netlify — same app either way.

---

Still stuck? Tell me **exactly**:
1. the link you open,
2. the exact message on screen (or a screenshot),
3. whether the repo shows `index.html` at the top level,
4. the **Settings → Pages** screenshot.

…and I’ll pinpoint it.
