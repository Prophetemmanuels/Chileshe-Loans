# CHILESHE INNOVATIONS MONEY LENDERS — Loan App

A complete, professional, **installable loan app** for **CHILESHE INNOVATIONS MONEY LENDERS (Zambia)**.
It has a **client app** (apply online, upload NRC, track repayments, get reminders) and a
**PIN-protected owner dashboard** (review applications, disburse loans, record payments,
watch every due date, run reports).

- 📞 **0772742481**
- 📍 Lusaka, Lusaka Province, Zambia
- 💰 **15% — 1 week · 20% — 2 weeks · 25% — 3 weeks · 30% — 4 weeks** (flat interest)
- 🌐 Pure HTML/CSS/JavaScript — no build step, no server needed. Host free on **GitHub Pages**.

---

## 📸 Screens (see the `extras/screenshots/` folder)

| Client app | Owner dashboard |
|---|---|
| ![Home](extras/screenshots/01-home-desktop.png) | ![Owner overview](extras/screenshots/10-owner-overview.png) |
| ![Apply](extras/screenshots/03-apply-desktop.png) | ![Application review](extras/screenshots/11-application-review.png) |
| ![Dashboard](extras/screenshots/06-client-dashboard.png) | ![Loan book](extras/screenshots/12-loan-book-mobile.png) |
| ![Loan agreement](extras/screenshots/09-agreement-pdf.png) | ![Rates in dark mode](extras/screenshots/05-rates-dark.png) |

---

## ✨ What the app does

### For clients
| Feature | Details |
|---|---|
| Installable app (PWA) | “Add to Home Screen” on Android and iPhone; works offline |
| Online application | Amount, 1–4 week term, purpose, employment/income, next of kin |
| Full KYC | NRC number, DOB, address + **uploads**: NRC front, NRC back, selfie with NRC, proof of income |
| Live quote | Interest, total repayable, weekly instalment and due date update as you type |
| Accounts | Phone + PIN (PINs are hashed, never stored in plain text) |
| Tracking code | e.g. `CH-4K7P-9QXM` — track an application without signing in |
| Dashboard | Outstanding balance, days-remaining countdown, progress bar, repayment schedule |
| Reminders | In-app notifications 7, 3 and 1 day before the due date + on the due date |
| Payments & receipts | Record repayments (mobile money/cash/bank), printable receipts |
| Documents | Printable loan agreement, receipts and customer statement |
| **Email confirmations** | Automatic email when the account is created, when an application is received, when a loan is approved/declined, when a payment is recorded and when it is confirmed — see **[EMAIL-GUIDE.md](EMAIL-GUIDE.md)** |
| Privacy | Data stays on the device; consent screens; privacy policy page |

### For the owner / staff
| Feature | Details |
|---|---|
| Admin login | First visit creates an admin PIN (4–6 digits) |
| Overview | Outstanding balance, collections, interest booked, overdue, charts |
| Applications | Review NRC documents, approve (creates loan + agreement) or decline with reason |
| Loan book | Every loan with principal, interest, paid, balance, due date, countdown, status |
| Clients | **Every client, every transaction, on any phone** — sign in with the staff password and the full book appears; profiles, documents, contact buttons (call / WhatsApp), per-client statement |
| **Emails** | Log of every confirmation email (sent / queued / failed + reason), resend, and a one-tap test |
| **Digital list** | A spreadsheet tab, **pre-filled with the office's 22-entry list**: No · Names · Amount · Interest · Numbers · Collateral · Date · Due Date. Add or remove **rows and columns**, paste a whole list from Excel/WhatsApp, auto money totals (K21,650 + K10,725 = K32,375), print, CSV and WhatsApp — all staff phones share it |
| Payments | Confirm client-declared payments, record office payments, receipts, delete mistakes |
| Reminders | Overdue / due-today / due-this-week lists with one-tap WhatsApp reminders |
| Reports | Monthly disbursements, collections, interest, loan book, CSV + JSON backup |
| Settings | Business phone, WhatsApp, rates, admin PIN, cloud sync, backup/restore |

> **Interest is flat:** `interest = principal × rate%`, `total repayable = principal + interest`.
> Example: K1,000 over 2 weeks at 20% → K200 interest → **K1,200 due** on the due date.

---

## 📁 Files in this folder (upload all of them)

```
single-file/index.html      ← ⭐ COMPLETE APP IN ONE FILE (easiest upload)
index.html                  ← the app (multi-file version)
manifest.json               ← PWA manifest (name, icons, shortcuts)
sw.js                       ← service worker (install + offline)
404.html                    ← friendly fallback page
.nojekyll                   ← tells GitHub Pages not to run Jekyll
LICENSE                     ← copyright notice
README.md                   ← this file
SYNC-GUIDE.md               ← how phones & computers stay in step
EMAIL-GUIDE.md              ← 5-minute email setup + troubleshooting
css/styles.css              ← design system (emerald & gold, dark mode)
js/config.js                ← BUSINESS SETTINGS (phone, limits, default rates)
js/storage.js               ← on-device database (localStorage)
js/utils.js                 ← dates, money, validation, hashing
js/calc.js                  ← interest engine, schedules, reminders, stats
js/backend.js               ← online sync (Supabase; Apps Script still supported)
js/records.js               ← applications, approvals, payments, receipts
js/ui.js                    ← icons, modals, toasts, navigation, install
js/client.js                ← auth, shared components, printable documents
js/pages.js                 ← home, rates, calculator, apply, track, auth, legal
js/account.js               ← dashboard, loan details, payments, profile
js/mail.js                  ← automatic confirmation emails (EmailJS / webhook)
js/grid.js                  ← staff digital list (spreadsheet tab)
js/admin.js                 ← owner dashboard
js/onboarding.js            ← first-run welcome
js/app.js                   ← router + bootstrap
icons/                      ← app icons (192, 512, maskable, Apple)
backend/supabase/           ← ⭐ OPTIONAL online database (schema.sql + README)
backend/google-apps-script/ ← legacy online database (Code.gs + README)
extras/make_icons.py        ← script that generated the icons (optional)
```

Everything is static — you can upload this folder exactly as it is.

---

## ⭐ Ready-to-deploy package: `github/`

The **`github/`** folder (and **`chileshe-GITHUB-UPLOAD.zip`**) contains exactly the files
GitHub Pages needs for the app to **work and install itself on phones**:

`index.html` · `manifest.json` · `sw.js` · `icons/` (192, 512, maskable, Apple) · `404.html` · `.nojekyll`

**→ Full instructions: [GITHUB-SETUP.md](GITHUB-SETUP.md)** — upload the *contents* of
`github/` to your repo root, enable Pages, and Android/Chrome users get an automatic
**“Install Chileshe Loans”** banner; iPhone users get Share → Add to Home Screen guidance.

> ### ⚠️ Getting “page isn’t working right now” or “There isn’t a GitHub Pages site here”?
> GitHub’s uploader struggles with multi-folder uploads. Use the **single-file build**
> (`single-file/index.html`) and follow **[UPLOAD-GUIDE.md](UPLOAD-GUIDE.md)** — one file,
> four clicks, done.

## 📱 One app, many devices

**Staff sign in with one password on any phone** (the staff password you set in Supabase) and immediately see every client,
application, NRC photo and payment — then approve, record payments and follow up from wherever
they are. Balances deduct automatically as clients pay, other phones refresh within ~20
seconds, and every receipt or application can be sent straight to WhatsApp.

## 📱 The detail

Clients on their phones and the owner on a phone, laptop or tablet **all work from the same
records** once the free **Supabase** backend is connected (about 10 minutes, no monthly cost):

- applications submitted on a client phone appear on the owner's device;
- approvals, balances and renewals flow back to the client automatically;
- the owner can use a second phone or the office computer with the same admin key;
- each client only ever sees their own records.

Every device keeps a full offline copy and syncs in the background.
**→ Read [SYNC-GUIDE.md](SYNC-GUIDE.md)** for setup, the one-tap client link, and what each
device can see.

## ⚡ First 10 minutes, after the app is online

| Order | What | Guide | Time |
|---|---|---|---|
| 1 | Sign in as staff with your **staff password** — set it in Supabase (step 2 of the Supabase guide) | in-app | 1 min |
| 2 | Connect **Supabase** so every phone shares one book | [SUPABASE-GUIDE.md](SUPABASE-GUIDE.md) | 10 min |
| 3 | Switch on **email confirmations** (free EmailJS account) | [EMAIL-GUIDE.md](EMAIL-GUIDE.md) | 5 min |
| 4 | Send the **client phone link** to clients, or just share the GitHub Pages link | in-app | 1 min |

> The app is fully usable on one device without steps 2–3, but clients will not receive
> emails and other phones will not see new records until each is done.

## 🚀 Put it on GitHub Pages (step by step)

1. Go to <https://github.com> → **New repository**.
   - Name: `chileshe-loans`
   - Visibility: **Public** (required for free GitHub Pages) or Private (paid plans).
   - Do **not** add a README (you already have one).
2. On the new repo page click **uploading an existing file**.
3. Drag in **all files and folders** from this folder
   (`index.html`, `manifest.json`, `sw.js`, `css/`, `js/`, `icons/`, etc.) and click
   **Commit changes**.
4. Go to **Settings → Pages**.
   - *Source*: **Deploy from a branch**
   - *Branch*: `main` · folder `/ (root)` → **Save**.
5. Wait 1–2 minutes. Your app is live at:

   ```
   https://YOUR-USERNAME.github.io/chileshe-loans/
   ```

6. Share that link (or a QR code of it) with clients on WhatsApp.

> **Important:** install/PWA features require **https://**. GitHub Pages provides HTTPS
> automatically. Opening `index.html` directly from a file on a phone will work, but
> “Install app” will not.

### Updating the app later
Edit a file on GitHub (or upload a new version) → commit. Pages updates in ~1 minute.
Bump `VERSION` at the top of `sw.js` (e.g. `chileshe-v1.4.0`) so phones fetch the new
version instead of using the cached one. The current build is **1.4.0**.

---

## 📲 How clients install the app

**Android (Chrome / Edge)**
1. Open the GitHub Pages link.
2. Tap the **Install app** button in the app header, **or** the browser menu **⋮ → Install app / Add to Home screen**.

**iPhone / iPad (Safari)**
1. Open the link in **Safari**.
2. Tap **Share** → **Add to Home Screen** → **Add**.

The app then opens full-screen, with its own icon, and works offline.

---

## 🏢 First-time setup for the owner (2 minutes)

1. Open the app → footer **Staff login** (or add `#/admin` to the URL).
2. Create the **admin PIN** — this protects the owner dashboard on that device.
   *Optional:* tap **Explore with sample data** to see the dashboard populated
   (demo client PIN `1234`). Remove it later in **Settings → Data**.
3. In **Settings**:
   - set/confirm the business phone & WhatsApp (default **0772742481**)
   - adjust the interest rates if they ever change
   - change the admin PIN to something only you know
4. **Add the owner dashboard to your own phone’s home screen** too
   (`#/admin` → install app), so you can approve loans from anywhere.

### Daily workflow
1. Client applies in the app → appears in **Applications** (pending).
2. Open the application → check the NRC documents match → **Approve & disburse**
   (choose the disbursement date) or **Decline** with a reason.
3. When the client pays → open the loan → **Record payment** (or confirm the
   client-declared payment in **Payments**) → give/print the receipt.
4. Watch **Reminders** for overdue / due-today lists and tap **Remind** to send
   a pre-written WhatsApp message.

---

## 🌍 Online applications from any phone (recommended)

By default, records are stored **on the device where the app is used** (private, works
offline, no data cost). That means a client applying on **their own phone** stays on their
phone unless the online database is turned on.

Turning it on makes **all phones and computers share the same records**: client applies →
the office sees it → approve → the client sees the loan → payment → the office confirms.
It is free and takes about 10 minutes.

1. Create a free project at <https://supabase.com> (region: Europe/Frankfurt or London).
2. Paste **`backend/supabase/schema.sql`** into the SQL Editor — **after changing the admin
   key** in the last section — and click **Run**.
3. In the app: **Owner → Settings → Online sync** (Supabase tab) → paste the **Project URL**,
   the **publishable key** and your **admin key** → **Save → Test**.
4. Tap **Client phone link → Copy** and send it once to each client's phone.

**→ Full walkthrough: [SUPABASE-GUIDE.md](SUPABASE-GUIDE.md)** ·
**How syncing behaves: [SYNC-GUIDE.md](SYNC-GUIDE.md)**

The older Google Apps Script backend (`backend/google-apps-script/`) still works and is
selectable in Settings, but Supabase is faster and does not run into Apps Script quotas.

---

## 🎨 Customising

| What | Where |
|---|---|
| Phone, WhatsApp, email, address, limits, default rates | `js/config.js` (or in-app **Settings**) |
| Colours / fonts | `css/styles.css` — variables at the top (`--emerald`, `--gold`, …) |
| App name / icons | `manifest.json`, `icons/`, `index.html` |
| Loan purposes list | `js/config.js` → `CI.LoanPurposes` |
| Reminder days | `js/config.js` → `reminders.daysBefore` (default 7, 3, 1, 0) |
| Required documents | `js/config.js` → `CI.Docs` |

---

## 🔐 Security & privacy notes (please read)

- **PINs** are hashed before storage; they are never written in plain text.
- This is a **local-first app**: records live in the browser’s storage (`localStorage`).
  Clearing browser data deletes the records — **use Settings → Download backup** regularly,
  and/or connect Supabase so the cloud keeps a copy.
- The **admin PIN protects the dashboard on that device**. Anyone who has an
  unlocked phone with the app can open the client side; the owner dashboard stays locked.
  For staff phones, set a device screen lock as well.
- Do **not** commit your **admin key** to a public GitHub repo. It is entered in the app’s
  Settings (stored only as a bcrypt hash in the database), never in the code.
- NRC photos are personal data. Zambia’s **Data Protection Act No. 3 of 2021** applies —
  collect only what you need, keep it secure, and delete it when no longer required.
- The Terms & Privacy pages are practical templates, **not legal advice** — have a Zambian
  lawyer review them before going live.

---

## 🧪 Test checklist before going live

- [ ] Open the live GitHub Pages URL on a phone → **Install app** works
- [ ] Register a client account → apply for K1,000 / 2 weeks → total shows **K1,200**
- [ ] Upload NRC front, back and selfie (photos from a phone camera)
- [ ] On the owner side, application appears → approve → loan created with correct due date
- [ ] Make a part payment → balance reduces, receipt prints
- [ ] Check the countdown changes colour when ≤3 days / overdue
- [ ] Generate reminders → WhatsApp button opens with a prefilled message
- [ ] **Settings → Download backup** saves a JSON file (keep it somewhere safe)
- [ ] Print/preview a **loan agreement** and a **receipt** (Print → Save as PDF)

---

## 🆘 Troubleshooting

| Problem | Fix |
|---|---|
| “Install app” button does nothing | Use Chrome/Edge on Android or Safari on iPhone; must be **https://**. On iPhone the button shows manual instructions. |
| App looks old after update | Close all tabs, reopen; or bump `VERSION` in `sw.js` and refresh twice. |
| Blank page after uploading | Make sure folders `css/`, `js/`, `icons/` were uploaded (they must sit next to `index.html`). |
| Records disappeared | Browser data was cleared, or a different browser/device is being used. Restore from **Settings → Restore backup**, or switch to the Google Sheet sync. |
| “Storage is full” | Download a backup, then remove old applications/documents (Settings → Reset) and re-import without documents, or enable cloud sync and keep the phone data lean. |
| Forgot admin PIN | On the admin login → **Forgot the PIN?** → reset. Records are kept. Only do this on a device you own. |
| Client can’t find their tracking code | Sign in as the client, or search the application in the owner dashboard. |

---

## 🧾 Licence

© 2026 **CHILESHE INNOVATIONS MONEY LENDERS**. All rights reserved.
Built for the exclusive use of the business. See `LICENSE`.

**Borrow responsibly.** Interest is charged per the agreed term. Only lend to clients
who can repay, and only borrow what you can repay.
