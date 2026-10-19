# Multiple phones & computers — how they stay in step

**Short answer:** yes, once the app is connected to a Supabase project. A client applying on
their phone, the owner approving on a laptop, and a second owner phone all work from the same
records.

Out of the box each phone is a separate private notebook — the app works perfectly offline,
but the owner's phone will **not** see a client's application. Connecting Supabase is what
makes the devices correspond.

**→ Setup instructions: [SUPABASE-GUIDE.md](SUPABASE-GUIDE.md)** (about 10 minutes, free).

---

## 1. The picture

```
   Client phone  ─┐
   Client phone  ─┼──►  Supabase project  ◄──┬──  Owner laptop
   Client phone  ─┘      (your account)      ├──  Owner phone
                                             └──  Office tablet
```

- Each device keeps a **full local copy** and works offline.
- It uploads what it changed and downloads what others changed, automatically.
- The **admin key** is what makes a device an *owner* device. It is stored only on owner
  devices and is never put in a client link.
- The **client link** carries only the public key, so a client can fetch only their own
  records.

### Who sees what

| Device | Sees | Can change |
|---|---|---|
| Client phone | Only its own application, loan, payments, documents | Own application, own payment claims |
| Owner phone / laptop / tablet | **Every** client, application, loan, payment | Everything, including approvals and confirmations |

A client can never see another client's records, even if they copy the link.

---

## 2. Connecting devices (summary)

| Device | How |
|---|---|
| **Any staff phone / tablet / computer** | Open the app → **Staff** → enter the **staff password** → everything downloads. No setup, no link, nothing to configure. |
| **First device that sets up the office** | Only needed once, by whoever deploys: Settings → Online sync → Staff password → Save. |
| **Client phone** | Install the app. It connects to the office by itself. (An optional client link exists for older installs.) |

Full detail, with what each screen looks like: [SUPABASE-GUIDE.md](SUPABASE-GUIDE.md).

---

## 3. What happens when someone acts

1. Client submits an application → saved on the phone and uploaded with the NRC photos.
2. Owner syncs → application appears with **document details and links**. Tapping **Open**
   downloads the photo from the cloud on demand.
3. Owner approves → loan + agreement created and uploaded.
4. Client's phone syncs (automatically, or on opening the app) → loan, balance, due date and
   reminders appear.
5. Client claims a payment → the balance drops **immediately** on the client's phone and
   shows *K500 paid, awaiting office confirmation*.
6. The staff phone picks it up on its own within ~20 seconds; the staff balance has already
   dropped by the same amount. Staff taps **Confirm** to mark the money verified.
7. Staff records cash received at the office → the client sees the confirmed payment and the
   reduced balance.

**Balances are automatic everywhere.** `outstanding = total repayable − everything paid`, so
no one has to recalculate anything. Unconfirmed claims still reduce the balance but are shown
in gold as *awaiting confirmation*; a fake claim can be deleted by staff with one tap.

Every record keeps its own update time, so the **newest version of each record wins**.
Two people working on different loans never clash, and receipts are unique per device
(`RCPT-2026-0002-JXWY`).

---

## 4. How often it syncs

| Situation | Staff devices | Client devices |
|---|---|---|
| App opened / brought to the foreground | immediately | immediately |
| While the app stays open | checks every **20 seconds**, downloads only if something changed | same |
| After applying / approving / recording a payment | pushed immediately | pushed immediately |
| Other people's changes | appear within ~20 seconds without touching anything | same |
| Manual | **Settings → Sync now** | **Profile → Sync now** |
| Offline | queued, sent when the connection returns | same |

The 20-second check asks the database for a fingerprint of the records (a hash — no personal
data travels); the full records are only downloaded when the fingerprint changes.

The **Profile** screen (clients) and the **Settings** card (owner) show the last successful
sync and how many items are waiting to upload.

---

## 5. Documents

- NRC photos, selfies and payslips are compressed on the phone (900 px, JPEG) and uploaded
  once to your Supabase `documents` table.
- Owner screens receive **document details, not image files**, so a phone never downloads
  megabytes of photos — tapping **Open** fetches just that one image.
- Images already on a phone are **never deleted** by a sync; the local copy is kept.
- If a photo fails to upload (phone lost signal mid-application), it is retried from the
  **offline queue**; the owner can also re-capture the NRC in the office.

---

## 5b. WhatsApp

Every important document can leave the app through WhatsApp, prefilled with the details:

| Where | Button | Goes to |
|---|---|---|
| After a client applies | **Send to office on WhatsApp** | the office number **0772 742 481** |
| Client → loan page | **Send payment proof** | the office number, with loan, total, paid and balance |
| Client / staff → any receipt | **WhatsApp** in the receipt window | the client's number (staff) or the office (client) |
| Staff → Payments row | WA icon | the client's number, with the full receipt |
| Staff → Application | **Send to office** | the office number, with NRC, amount, term and document count |
| Staff → client profile / reminders | WhatsApp / Remind | that client's number |

Nothing is sent automatically — the button opens WhatsApp with the message ready, and you tap
send. That keeps the business number's normal WhatsApp history intact.

## 6. Rules of thumb

- **One staff password**. Give it only to staff, never to clients. Change it in
  Supabase (one SQL line in SUPABASE-GUIDE) if a phone is lost, then sign in again on the
  staff phones.
- **Do not delete the Supabase project** — if you must start over, export a backup first.
- **New phone for the owner?** Open the owner link, sign in, **Sync now** — everything
  downloads.
- **New phone for a client?** Send the client link again. Their history lives in the cloud,
  but sign-in details (phone + PIN) are stored on their old phone — they can use the
  **tracking code** (`CH-XXXX-XXXX`) on the **Track** page from any device.
- **Changing phones entirely?** Export a backup first: **Settings → Download backup**.

---

## 7. Troubleshooting

| What you see | Cause | Fix |
|---|---|---|
| “Office sync is off” on a phone | No backend configured on that device | Send the client link again, or paste URL + key in Settings |
| “Invalid API key” | Wrong publishable key | Re-copy from Supabase → Project Settings → API Keys |
| “That staff password is not correct.” | Password ≠ the one stored in the database | Re-run the `update private.app_config …` line with the password you want |
| “Too many wrong admin-key attempts” | 15 wrong passwords from that network | Wait 15 minutes, then enter the right password |
| “Failed to fetch” / requests hang | Free project paused (7 days idle), or firewall | Resume it in the dashboard; see SUPABASE-GUIDE §10 |
| Client applied but owner never sees it | Owner device not connected, or phone offline | Check the status line in Settings → **Sync now**; the phone uploads when back online |
| Payment missing on the other device | Still queued, or awaiting confirmation | Client **Profile → Sync now**; owner confirms under **Payments** |
| Two devices show different balances | One has been offline for days | **Sync now** on both; newest record wins |
| Photos won't open | Upload was interrupted, or project paused | Owner: retry after resuming; re-capture if needed |

---

## 8. Is the data private?

- Records sit in **your own** Supabase project (free plan, no third party between you and
  Google/GitHub hosting).
- Tables are in a `private` schema with row-level security and **no public grants** — the
  key shipped in the app cannot read rows directly; it can only call the functions.
- Client functions require the client's **tracking code**; owner functions require the
  **admin key**, stored only as a bcrypt hash.
- The app rejects a client trying to approve a loan or confirm a payment, even if the app
  itself were tampered with.
- Use **2-step verification** on your Supabase account and keep the secret key
  (`sb_secret_…`) out of the app entirely.

---

**Files involved:** `backend/supabase/schema.sql` (database + security) · `js/backend.js`
(sync engine, queue, throttles) · `js/storage.js` (per-record merge, unique references) ·
`js/app.js` (auto-sync timers, setup links) · `js/admin.js` (settings, document viewer) ·
`js/account.js` (client sync status).
