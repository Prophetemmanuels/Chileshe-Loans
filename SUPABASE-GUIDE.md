# Supabase setup — make every phone see the same records

This guide connects the app to **Supabase** (a free Postgres database). After it, an
application submitted on a client's phone appears on the owner's phone and computer,
and approvals, balances and receipts flow back to the client automatically.

- **Time:** about 10 minutes, once.
- **Cost:** free. No card required.
- **You need:** an email address and a browser.
- **What you get:** one database in *your* account, holding loans, payments and NRC photos.

---

## 🟢 This build is already connected

The app you have is compiled against project **`vvrffehhofnvypujtyhn`**
(`https://vvrffehhofnvypujtyhn.supabase.co`) and the schema is installed and verified:

- a phone that installs the app is **connected automatically** — no link, no settings;
- **owner devices only need the admin key** (Settings → Online sync → Admin key → Save);
- clients can never read the office records even with the app installed.

### 🔴 Do these two things once (3 minutes)

**1. Update the database** — Supabase → **SQL Editor → New query** → paste the whole (updated)
file **`supabase-schema.sql`** → **Run**. Re-running is safe: it updates the functions and
leaves all data alone. It adds the lockout below and refuses the public template key.

**2. Set the staff password** — same SQL Editor, paste and **Run**, replacing `YOUR-STAFF-PASSWORD` with the password you want:

```sql
insert into private.app_config (key, value, updated_at)
values ('admin_key_hash', extensions.crypt('YOUR-STAFF-PASSWORD', extensions.gen_salt('bf', 10)), now())
on conflict (key) do update set value = excluded.value, updated_at = now();
```

Then confirm it took effect — this must return **`false`**:

```sql
select extensions.crypt('CHANGE_ME_ADMIN_KEY', value) = value as still_template
from private.app_config where key = 'admin_key_hash';
```

That value is now the **staff password** — the same one on every phone, tablet and computer.
Type it on any device: the app checks it against the database and that device becomes a staff
device. It is never put in a client link or in the app's code. (The SQL file keeps the
placeholder `CHANGE_ME_ADMIN_KEY` on purpose, because your GitHub repo is public.)

> **Seeing “The database still uses the template admin key” on a phone?** That message means
> step 2 has not been run yet (or was run on a different project). The app now shows the exact
> SQL with a **Copy this SQL** button under **Settings → Online sync** — paste, **Run**, tap
> **Test**, and it clears immediately. No reinstall, no new link.

**3. Remove the stray table** you created in the dashboard (the app does not use it, and it is
currently readable by anyone). SQL Editor:

```sql
drop table if exists public."Chileshe-Loans";
```

Prefer to keep it? Turn protection on instead:
`alter table public."Chileshe-Loans" enable row level security;`

> **About the password.** Six digits give 1,000,000 combinations. The database locks
> an address out after **15 wrong tries in 15 minutes**, and 100 wrong tries in total pause
> everyone for 15 minutes — so guessing is impractical. Every successful staff sign-in resets
> the counter. Change it any time by re-running the `update` line with a new value, then
> signing in again on each staff phone.

---

> ℹ️  The old Google Apps Script option still works (Settings → *Google Apps Script* tab), but
> Supabase is faster and far more reliable, so it is now the recommended path.

---

## Contents

1. [How it works](#1-how-it-works)
2. [Create the project](#2-create-the-project)
3. [Create the tables (paste one file)](#3-create-the-tables-paste-one-file)
4. [Copy your two keys](#4-copy-your-two-keys)
5. [Connect the owner's device](#5-connect-the-owners-device)
6. [Connect other owner devices](#6-connect-other-owner-devices)
7. [Connect a client's phone](#7-connect-a-clients-phone)
8. [Test it end-to-end](#8-test-it-end-to-end)
9. [How syncing behaves](#9-how-syncing-behaves)
10. [Free plan limits (read this)](#10-free-plan-limits-read-this)
11. [Security & keys](#11-security--keys)
12. [Backups](#12-backups)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. How it works

```
 Client phone ─┐
 Client phone ─┼──►  Supabase project  ◄──┬──  Owner phone
 Client phone ─┘     (your account)       ├──  Owner laptop
                                          └──  Office computer
```

- Every device keeps a **full copy** and works offline.
- It uploads what changed and downloads what others changed, automatically.
- The **admin key** (which you invent) is what makes a device an *owner* device. It never
  goes into a link you send to clients.
- A client's phone can only ever fetch records matching **its own tracking code**.

---

## 2. Create the project

1. Go to **<https://supabase.com>** → **Start your project** (sign in with Google or email).
2. Click **New project**.
3. Fill in:

   | Field | What to enter |
   |---|---|
   | **Name** | `chileshe-loans` |
   | **Database password** | A long password. **Save it** somewhere safe (you rarely need it, but you cannot see it again). |
   | **Region** | **Europe (Frankfurt)** or **Europe (London)** — the closest to Zambia (Supabase has no African region yet). |
   | **Plan** | **Free** |

4. Click **Create new project** and wait ~2 minutes while it builds.

> If you already have another Supabase project you no longer use, free accounts allow two
> active projects at a time.

---

## 3. Create the tables (paste one file)

1. In the left sidebar click **SQL Editor** → **New query**.
2. Open **`supabase-schema.sql`** in any text editor (Notepad, TextEdit, VS Code).
   It is included with the files you uploaded to GitHub, next to `index.html`; the master
   copy lives in `backend/supabase/schema.sql` inside the project folder.
3. **Change your admin key first.** Find this line near the bottom:

   ```sql
   values ('admin_key_hash', extensions.crypt('CHANGE_ME_ADMIN_KEY', extensions.gen_salt('bf', 10)))
   ```

   Replace `CHANGE_ME_ADMIN_KEY` with your own secret, for example:

   ```sql
   values ('admin_key_hash', extensions.crypt('chileshe-2026-7Qm4XzD9pLw2', extensions.gen_salt('bf', 10)))
   ```

   - Use **at least 20 characters**; mix words and numbers.
   - **Write it down** — you will paste it into the app in step 5.
   - It is stored only as a bcrypt hash, so even someone reading your database cannot see it.

4. Copy the **whole file** and paste it into the SQL editor.
5. Click **Run** (or press `Ctrl/⌘ + Enter`). You should see **“Success. No rows returned”**.

What this created, inside a schema called `private` (invisible to the public API):

| Name | What it holds |
|---|---|
| `private.applications` | one row per loan application |
| `private.loans` | approved loans |
| `private.payments` | every receipt, with a `confirmed` flag |
| `private.documents` | NRC / selfie photos (compressed JPEGs) |
| `private.app_config` | the bcrypt hash of your admin key |

and these functions in `public`, which are the only ways in:

`backend_info` · `client_pull` · `client_push` · `client_push_document` · `client_document`
· `owner_ping` · `owner_pull` · `owner_push` · `owner_delete_payment` · `owner_document`

> ✅ Re-running the script later is safe — it updates the functions and leaves your data alone.
> To change the admin key later, run only the `update private.app_config …` line at the bottom
> of the file.

---

## 4. Copy your two keys

In the left sidebar open **Project Settings** (gear icon) → **API Keys**.

| Key | Looks like | Where it goes | Safe to share? |
|---|---|---|---|
| **Project URL** | `https://abcdefghijklm.supabase.co` | Settings in the app | Yes — it is public |
| **Publishable key** | `sb_publishable_…` | Settings in the app | Yes — it identifies the project, nothing more |
| ~~Secret key~~ | `sb_secret_…` | **Nowhere. Never paste it in the app.** | **No** |

- On older projects the publishable key is under **Legacy API keys** and is called
  **`anon` `public`** — it starts with `eyJ…`. Either one works; the app accepts both.
- The **Project URL** is also shown under *Project Settings → Data API*.

> ⚠️ The secret key (`sb_secret_…` / `service_role`) bypasses all security. The app never needs
> it. If you ever paste it into a website, treat it as leaked and roll it immediately.

---

## 5. Connect the owner's device

> ✅ **In this build** the Project URL and publishable key are already inside the app. The
> only thing to do is **sign in with the staff password**. Client phones need no setup at all.

Do this on the phone or computer the owner uses.

1. Open the app → **Owner** (bottom bar or menu).
2. Sign in / create the admin PIN.
3. Go to **Settings → Online sync** and make sure the **Supabase** tab is selected.
4. Paste:

   | Field | Value |
   |---|---|
   | **Project URL** | `https://abcdefghijklm.supabase.co` (no trailing `/`) |
   | **API key (publishable)** | `sb_publishable_…` |
   | **Admin key** | the secret you typed into the SQL file |

5. Tap **Save**, then **Test**.
   You should see **“✓ Connection successful. Online sync is working.”**
   - *Unauthorized: wrong admin key* → the admin key does not match the SQL file.
   - *Invalid API key* → the publishable key is wrong or from another project.
6. Tap **Sync now** → **Push all** (uploads any records already on this device).

✅ The owner's device is now the office master.

---

## 6. Connect other owner devices

For a second owner phone, laptop or the office computer:

1. On the **already-connected** device go to **Settings → Online sync**.
2. Under **Your other phones / computers** tap **Copy** (this link contains the admin key).
3. Open it once on the new device. The app connects itself, then cleans the address bar.
4. Sign in to **Owner** with the PIN and tap **Sync now** — every client, loan and payment
   downloads.

> 🔒 That link is powerful. Send it to yourself only (WhatsApp "message yourself", email,
> or a password manager). Never post it in a group.

---

## 7. Connect a client's phone

1. **Settings → Online sync → Client phone link → Copy** (or **Share**).
   It looks like:
   `https://your-name.github.io/chileshe-loans/?supabase=https%3A%2F%2Fabcdefghijklm.supabase.co&anon=sb_publishable_…`
2. Send it to the client by WhatsApp or SMS. They tap it **once**.
3. The app opens connected to your office; they install it (Chrome: *Install app*;
   iPhone: Share → *Add to Home Screen*).

The link contains **only** the public key — no admin key. It can fetch only that client's
own records.

> A client who ignores the link can still use the app; it simply stays on their phone until
> the link is opened.

---

## 8. Test it end-to-end

1. **Client phone:** apply for e.g. K2,000 over 2 weeks. Upload the NRC photos.
2. **Owner device:** tap **Sync now** → the application appears with **Documents** marked
   *Open* (tap to fetch the photo from the cloud).
3. Approve it → the client's phone shows the loan (within ~1 minute, or immediately when
   they open the app).
4. **Client phone:** record a payment → it shows *pending* on their side.
5. **Owner device:** **Sync now** → **Payments** shows the pending item → **Confirm**.
6. **Client phone:** open the app → the payment is confirmed and the balance is lower.

If all six steps work, every phone will stay in step.

---

## 9. How syncing behaves

| Situation | What happens |
|---|---|
| App opened / brought to the foreground | syncs immediately |
| App left open (owner) | every 2 minutes |
| App left open (client) | every 1 minute |
| After applying / approving / recording a payment | pushed immediately |
| Phone offline | saved in a queue, sent automatically when the signal returns |
| Two devices edit the same record | the **newest** version wins (per record, so different loans never clash) |
| Duplicate receipt numbers | impossible — each device adds a 4-letter suffix (`RCPT-2026-0002-JXWY`) |
| Client's photo | uploaded once, fetched by the owner on demand (never downloaded to every phone) |

**Manual sync:** Owner → *Settings → Sync now*; Client → *Profile → Sync now*.

---

## 10. Free plan limits (read this)

| Limit | Free plan | What it means here |
|---|---|---|
| Database | 500 MB | ~4 compressed photos per client ≈ 0.3–0.5 MB → roughly **1,000+ clients** |
| Egress | 5 GB / month | receipts and records are tiny; photos load only when opened |
| Active projects | 2 | enough |
| **Pausing** | **after 7 days of no database activity** | see below |

**Project pausing.** If nothing touches the database for a week, Supabase pauses the project
(your data is kept). The app then shows sync errors until you resume it:

> Supabase dashboard → select the project → **Resume project** (takes a minute; data intact).

In normal use the office opens the app most days, which keeps it awake. If the business will
be closed for a long holiday, either resume it when you return, or stay on a paid plan
($25/month) where projects are never paused. Restoring is possible for up to a year.

**Automatic backups are not included on the free plan** — see [Backups](#12-backups).

---

## 11. Security & keys

- All tables live in the `private` schema with **row-level security on** and **no grants** to
  the public API. The anon/publishable key cannot read a single row directly.
- Every function checks something before returning data:
  - owner functions require the **admin key** (checked against the bcrypt hash);
  - client functions require the **tracking code** of that client's own records.
- A client cannot approve themselves, cannot mark a payment confirmed, and cannot touch
  another client's loan — the database rejects it even if someone tampers with the app.
- **Change the admin key** any time: run the `update private.app_config …` line from the bottom
  of `schema.sql`, then re-paste the new key on each owner device.
- **If an owner link leaks:** change the admin key, then reconnect your own devices.
  Client links stay valid (they hold no secret).
- Turn on **2-step verification** for your Supabase login.

---

## 12. Backups

The free plan has no automatic backups, so do both of these:

1. **In the app:** Owner → *Settings → Download backup* — a JSON file with every record.
   Keep a copy weekly (email it to yourself, or a USB stick).
2. **In Supabase:** *Table Editor* → open `applications` / `loans` / `payments` →
   **Export → CSV** for a spreadsheet copy.

Photos are in the `documents` table; open one to download the image if you need a hard copy.

---

## 13. Troubleshooting

| What you see | Cause | Fix |
|---|---|---|
| `Invalid API key` | Publishable key wrong, or from another project | Re-copy it from *Project Settings → API Keys* |
| `Unauthorized: wrong admin key` | Admin key ≠ the key hashed in the database | Re-run the `update private.app_config …` line with the key you want, or retype it on the owner device |
| `The database still uses the template admin key CHANGE_ME_ADMIN_KEY` | The database is still using the key published in the SQL file — anyone who can read your repo could sign in as staff | Run the `insert … on conflict … 'YOUR-STAFF-PASSWORD' …` block at the top of this guide, then tap **Test** in Settings. The same SQL is inside the app: **Settings → Online sync → “Database says template admin key?”** with a **Copy this SQL** button and a direct link to the SQL Editor |
| `Too many wrong admin-key attempts. Wait 15 minutes and try again.` | Lockout after repeated wrong passwords from that address | Wait 15 minutes (or use another network), then enter the correct password |
| `That staff password is not correct.` | Password ≠ the one stored in the database | Re-run the `update …` line with the password you want |
| `Could not find the function public.owner_pull` | SQL file not run (or run in a different project) | Run `schema.sql` in **this** project's SQL Editor |
| `Project is paused` / 402 / requests hang | Free project paused after a week idle | Dashboard → **Resume project** |
| `Failed to fetch` on the office Wi-Fi | DNS / firewall blocking `*.supabase.co` | Try mobile data; allow the domain on the router |
| Application never appears on the owner device | Owner device not connected, or key saved but not **Save**d | Settings → check the green status line → **Sync now** |
| Client's phone shows nothing after approval | Client link not opened on that phone, or app not reopened | Send the client link again; ask them to reopen the app |
| Documents say *Open* but fail | Photo upload interrupted (phone offline mid-upload) | Owner: ask the client to reopen **Profile → Sync now**; or capture the NRC in the office |
| Balance differs between two devices | One device was offline for days | **Sync now** on both — newest record wins |
| Everything works but the old phone does not | That phone still uses Google Apps Script settings | Settings → Supabase tab → paste URL + keys → Save → Push all |

---

## What changed in the app

### v1.2.0 — Supabase sync

- New **Supabase** engine in `js/backend.js` (REST/RPC, publishable keys, offline queue).
- Owner **Settings → Online sync** now has Supabase / Google Apps Script tabs, a **Test**
  button, **Client phone link** and **Your other phones / computers** (owner) link.
- Client **Profile → Sync now** shows connection status and queued uploads.
- Owner can open NRC photos **straight from the cloud** when they were not previously
  downloaded to that device.
- Payments: client claims arrive **pending** and only the owner can confirm them; office
  payments keep their confirmed status.
- Fixed: two phones could generate the same receipt number and overwrite each other.
- Fixed: an install banner could cover buttons when a side panel opened.

**Files involved:** `backend/supabase/schema.sql` · `js/backend.js` · `js/app.js` ·
`js/admin.js` · `js/account.js` · `js/storage.js`

---

### v1.4.2 — packaged and ready to hand over

- **`START-HERE.md`** — the two remaining actions, with nothing else to read.
- **`PASTE-IN-SUPABASE.sql`** — one file to paste into the Supabase SQL Editor: sets the staff
  password, protects the stray dashboard table, and prints a `true/false` check. Verified
  against the real schema (installs clean, idempotent, `still_template = false`,
  `password_works = true`).
- **Security fix:** the in-app “copy this SQL” helper no longer contains a real password. The
  app is served publicly from GitHub Pages, so a literal password in the bundle would have
  handed the staff console to anyone who viewed the source. The helper now shows
  `YOUR-STAFF-PASSWORD` and tells the user what to replace; the filled-in version lives only
  in the private paste file.
- The public guides no longer name the password either (they say “the staff password you set”).
- The build now copies the guides into `github/` automatically, so the published repo and the
  workspace can no longer drift apart.

### v1.4.1 — the “template admin key” blocker, fixed in one tap

- The app now shows the **exact SQL** wherever that error can appear — **staff sign-in**,
  **Settings → Online sync**, and the **Sync now** toast — with a **Copy this SQL** button and
  a direct link to your project's SQL Editor. No hunting through this guide.
- Sync now sends a staff device straight to that box instead of a dead-end error.
- The SQL is idempotent (`insert … on conflict … do update`), so it works whether or not the
  key row already exists, and re-running it is harmless.
- **Fixed a serious cache bug:** the generated `sw.js` had its cache version hard-coded at
  `v1.1.0` since 1.1.0, so installed phones could keep serving an old copy of the app after an
  update. The build now takes the version from `js/config.js`, so every release actually
  reaches installed phones.
- Small robustness fixes: `matchMedia` guard, and the copy button falls back to a hidden
  textarea where the clipboard API is unavailable.

### v1.4.0 — email confirmations and the all-clients view

- **Email confirmations** (`js/mail.js`): the client is emailed when the account is
  created, when an application is received, when a loan is approved or declined, when a
  payment is recorded and when the office confirms it. Configure in
  **Settings → Email confirmations**; full walkthrough in **[EMAIL-GUIDE.md](EMAIL-GUIDE.md)**.
- Registration now **requires a unique, valid email address**, so every client is reachable.
- **All clients screen** for staff (`allClients`): a staff phone that signs in with the
  staff password sees every client, their email, their documents and every transaction —
  even for clients who registered on a different phone and were never opened on that device.
- **Clients → client panel** now carries the full transaction list, an email composer and a
  printable **customer statement** (same document the client sees).
- **Emails** screen in the staff section: every attempt (sent / queued / failed + reason),
  including rows derived from a client phone's own registration, with the exact message.
- Optional **office copy** of every client email.
- Fixed: a missing template argument made `Mail.notify` throw for templates that take no
  arguments (welcome/reminder) — registration emails now send.
- Fixed: `Calc` was not imported in `mail.js`, so every **payment** email failed with
  "Calc is not defined"; payments and confirmations now send with the correct balance.
- Payment mails are split: **Payment received** (awaiting confirmation) and
  **Payment confirmed** (with the new balance), so the client can tell them apart.

**Files involved:** `js/mail.js` (new) · `js/records.js` · `js/client.js` · `js/admin.js` ·
`js/storage.js` · `js/pages.js` · `js/ui.js` · `js/app.js` · `index.html` · `js/config.js`
