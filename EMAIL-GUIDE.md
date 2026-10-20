# EMAIL SETUP — step by step

**Time: about 8 minutes.** Free. No card.

After this, your clients automatically receive emails when they register, apply, are
approved or declined, pay, and when you confirm their payment — **without anyone tapping
send**.

| # | Email | Sent when | Comes from |
|---|-------|-----------|------------|
| 1 | Your CHILESHE INNOVATIONS account is ready | Client registers | the client's phone |
| 2 | Application received — APP-… | Client submits an application | the client's phone |
| 3 | Loan approved — LN-… | You approve | your phone |
| 4 | Application update (declined) | You decline | your phone |
| 5 | Payment received — K500.00 | Client records a payment | the client's phone |
| 6 | Payment confirmed — K500.00 | You confirm that payment | your phone |

> **Important — why there is a "publish" step.** Emails 1, 2 and 5 are sent by the
> **client's own phone**. So the email settings cannot live only on your phone. When you save
> them once in **Settings → Email confirmations**, the app publishes them to your Supabase
> database, and every phone — clients included — picks them up on its next sync. You do this
> **once**, not per phone.

---

# PART 1 — Create the free EmailJS account (3 min)

## 1.1 Sign up

1. Go to **https://www.emailjs.com**
2. Click **Sign Up** (top right). Google sign-in is fine.
3. Confirm your email address if they ask.

You land on the dashboard. Free plan: **200 emails/month**, 2 templates. That covers roughly
150–200 client actions — enough for a small lender, and the app keeps working (queued, not
lost) if you ever hit the cap.

## 1.2 Connect the Gmail you want to send *from*

1. Left menu → **Email Services** → **Add New Service**.
2. Choose **Gmail**.
3. Click **Connect account**, sign in with the address you want clients to see as the sender
   (e.g. `chilesheinnovations@gmail.com`), and allow access.
   *Use a business address, not a personal one — clients trust it more and replies land in
   the right inbox.*
4. **Name:** `chileshe`
5. Click **Create Service**.
6. Copy the **Service ID** — looks like `service_ab12cd3`. Paste it somewhere safe.

## 1.3 Create the message template

1. Left menu → **Email Templates** → **Create New Template**.
2. **Name:** `chileshe-confirmation`
3. Fill the fields exactly like this:

| Field | Value |
|---|---|
| **To email** | `{{to_email}}` |
| **To name** | `{{to_name}}` |
| **From name** | `{{from_name}}` |
| **Reply to** | `{{reply_to}}` |
| **Subject** | `{{subject}}` |
| **Body** | `{{message}}` |

The body is just that one token: delete whatever text is already in the editor and type
`{{message}}`. The app writes the whole letter (greeting, amounts, balance, phone number), so
the template only has to deliver it.

4. Click **Save**.
5. Copy the **Template ID** — looks like `template_xy98zw7`.

> If EmailJS shows a *Test* button asking for values, give it anything (e.g. `to_email` =
> your own address) — you will test from the app instead.

## 1.4 Copy your public key

1. Click your account name (top right) → **Account**.
2. **General** tab → **Public Key** — looks like `Zk3nAbCdEfGhIjKlM`.
3. Copy it.

## 1.5 Lock the key to your app (30 seconds — do not skip)

This is what stops a stranger from using your key to send their own mail.

1. **Account → Security** (or **Account → General → Allowed origins**, depending on the
   version of the dashboard).
2. Under **Allowed origins / websites**, add your app's address **without a trailing slash**:

```
https://YOUR-GITHUB-USERNAME.github.io
```

3. Add a second entry for your own preview URL if you use one.
4. **Save**.

> Your GitHub Pages address is in `SETUP-STEP-BY-STEP.md` step 2.7. If you later move the app
> to a custom domain, add that too — until you do, sending will fail with an origin error.

---

# PART 2 — Put the three values into the app (2 min)

Do this on **one** phone or computer — ideally the one you use as the office phone.

1. Open your app → footer → **Staff login** → password → sign in.
2. **Settings** → scroll to the **Email confirmations** card.
3. Fill in:

| Field | Paste |
|---|---|
| **Service** | EmailJS (recommended) — already selected |
| **EmailJS Service ID** | `service_ab12cd3` |
| **EmailJS Template ID** | `template_xy98zw7` |
| **EmailJS Public key** | `Zk3nAbCdEfGhIjKlM` |
| **Reply-to address** | your business email (optional but recommended) |
| **Office copy (optional)** | leave blank, or your own email if you want a copy of every client mail |

4. Tap **Save**.

**You should see:** *"Email saved and sent to every phone."*

If you see *"Saved on this phone, but could not reach the other phones"* — the phone had no
internet or is not signed in to the database. The settings are still on that phone; tap
**Save** again when you are back online.

> The card should now read **● Email is on — confirmations are being sent.**
> If it still says *off*, a field is missing — the three IDs are all required for EmailJS.

---

# PART 3 — Test it for real (2 min)

## 3.1 Send a test from Settings

1. Still in **Settings → Email confirmations**, tap **Send test**.
2. Type an address you can open.
3. Check that inbox — and the **Spam** folder.

Nothing arrived? **Settings → Emails** shows the exact reason. The three common ones:

| Row says | Meaning | Fix |
|---|---|---|
| `no-address` | No email typed | Type one and retry |
| `failed` — *The service ID is invalid* | Wrong Service ID | Re-copy from Email Services |
| `failed` — *The template ID is invalid* | Wrong Template ID | Re-copy from Email Templates |
| `failed` — *The public key is invalid* | Wrong key | Account → General → Public Key |
| `failed` — *origin* / *403* | Allowed origins does not include your site | Redo 1.5 |
| `queued` | Phone offline at that moment | It sends on the next sync |

## 3.2 Test the real flow on a **second** phone

This is the important one — it proves client phones can send.

1. On another phone (or a private/incognito browser window), open the app.
2. Register a new client with an email address you can open.
3. You should receive **"Your CHILESHE INNOVATIONS account is ready"** within ~10 seconds.
4. Apply for a small loan → **"Application received"** arrives.
5. On the office phone: **Clients** → the new client is there → **Approve** →
   **"Loan approved"** arrives.
6. On the client phone: record a payment → **"Payment received"** (says *waiting for office
   confirmation*).
7. On the office phone: **Payments** → **Confirm** → **"Payment confirmed"** with the new
   balance.

If those five arrive, email is fully working on both sides.

> A brand-new phone needs to open the app once with internet so it picks up the settings.
> It does that automatically on first sync — nothing to configure.

---

# PART 4 — Understand what the client sees

Every message is written for a borrower, not a developer:

- full business name, phone **0772 742 481** and Lusaka address at the bottom;
- the reference numbers (APP-…, LN-…, RCPT-…) so a phone call starts with the right record;
- amounts in Kwacha, the balance remaining, and what happens next;
- **never** the NRC number or the uploaded documents — those stay behind the staff login.

The **Emails** screen belongs to staff. Clients do not see a mail log — they see their
receipts, balance and statement in **My loan**.

---

# PART 5 — Running it month to month

| Situation | What to do |
|---|---|
| Client says "I never got the email" | Check the address on their profile (Clients → client → Edit), then **Settings → Emails** for the row |
| You change your Gmail password | EmailJS keeps working — the connection is a token, not your password. If you revoke access, reconnect the service in EmailJS |
| You want a new sender address | Add a second Email Service in EmailJS, paste the new Service ID in Settings, Save |
| You hit 200 emails/month | Upgrade EmailJS (~US$9/month) — no app change needed |
| You change the password or business phone | Nothing to redo; templates read the business details from the app |
| A staff phone shows email as **off** | It has not synced since you saved. Open the app with internet, or **Settings → Online sync → Sync now** |
| You want to switch email off temporarily | Settings → Service → **Off** → Save. Messages are still recorded in **Emails** as `queued` |

---

# PART 6 — If you would rather not use EmailJS

In **Settings → Email confirmations**, choose **Custom webhook / Apps Script** and paste any
URL that accepts a JSON POST. The app sends exactly this:

```json
{
  "to": "client@example.com",
  "name": "Grace Tembo",
  "subject": "Loan approved — LN-2026-0001-Q3E9",
  "message": "the full letter text…",
  "from": "CHILESHE INNOVATIONS MONEY LENDERS",
  "replyTo": "office@yourbusiness.zm",
  "staffEmail": ""
}
```

Your endpoint should reply `200`. Options: a Google Apps Script web app (free, uses your
Gmail), Make.com, Zapier, Formspree, or your own server.

> Whatever you choose, **save it in Settings once** — the app publishes it to Supabase, and
> every phone uses it from then on.

---

# TROUBLESHOOTING — one table

| What you see | Cause | Fix |
|---|---|---|
| Card shows **● Email is off** | Missing one of the three IDs | Fill all three, Save |
| `Send test` says *Choose EmailJS and fill the three IDs first* | Same | Same |
| Nothing arrives, log says `queued` | No internet, or email not configured on that phone yet | Connect, open the app, **Sync now** |
| Nothing arrives, log says `sent` | Client's spam folder, or a typo in their address | Ask them to check Spam and mark *not spam* |
| Works on your phone, not the client's | Client phone has not synced since you saved | Open the app on that phone with internet |
| `403` / *origin not allowed* | Allowed origins missing your site | Part 1.5 |
| Emails arrive blank | Template body is not exactly `{{message}}` | Fix the template |
| Duplicate emails | You set an **Office copy** to the same address as the client | Leave Office copy blank, or use a different address |

---

*Verified on 19 October 2026: settings saved on a staff device appear on a device that has
never been configured, and that device then sends a real formatted email; a wrong staff
password cannot overwrite the published settings.*
