# EMAIL-GUIDE.md — automatic confirmation emails

CHILESHE INNOVATIONS sends these emails automatically, from the app, with no tapping:

| # | When | Subject the customer sees |
|---|------|---------------------------|
| 1 | Client registers on their own phone | Your CHILESHE INNOVATIONS account is ready |
| 2 | Client submits a loan application | Application received — APP-2026-0001-XXXX |
| 3 | Office approves the loan | Loan approved — LN-2026-0001-XXXX |
| 4 | Office declines the loan | Application update — APP-… |
| 5 | Client records a payment | Payment received — K500.00 (RCPT-…) — *says "Awaiting office confirmation"* |
| 6 | Office confirms the payment | Payment confirmed — K500.00 (RCPT-…) — *shows new balance* |

Every attempt is listed in **Emails** on the staff phone (sent, queued or failed, with the reason). Nothing is lost silently.

You need one free account: **EmailJS** (emailjs.com). It gives 200 emails/month free — enough for a few hundred client actions. You can upgrade later without changing the app.

---

## Step 1 — Create the EmailJS account (2 minutes)

1. Go to **https://www.emailjs.com** → **Sign Up** (Google sign-in is fine).
2. Verify your email address.
3. You land on the **Email Services** page.

## Step 2 — Add your email service (1 minute)

1. **Email Services → Add New Service**.
2. Choose **Gmail** (or Outlook / your own SMTP — Gmail is simplest).
3. Click **Connect account**, sign in with the address you want to send **from** (e.g. `chilesheinnovations@gmail.com`), allow access.
4. Name it `chileshe` → **Create Service**.
5. Copy the **Service ID** — looks like `service_ab12cd3`.

## Step 3 — Create the message template (2 minutes)

1. **Email Templates → Create New Template**.
2. Name it `chileshe-confirmation`.
3. In the template editor set:

   **To email:** `{{to_email}}`
   **To name:** `{{to_name}}`
   **From name:** `{{from_name}}`
   **Reply to:** `{{reply_to}}`
   **Subject:** `{{subject}}`

   **Body** — delete everything and paste exactly this:

```
{{message}}
```

   (The app composes a full, professional message — the template just delivers it.)

4. Open the **Settings** tab of the template: tick **"Use variables in the message"** if shown.
5. **Save**, then copy the **Template ID** — looks like `template_xy98zw7`.

## Step 4 — Get your public key (30 seconds)

1. Click your account name (top right) → **Account**.
2. Copy the **Public Key** — looks like `Zk3nAbCdEfGhIjKlM`.

## Step 5 — Paste the three values into the app

You can do this from your **phone** — no computer needed.

1. Open the app → **Settings** (staff side).
2. Find the **Email confirmations** card. Fill:

| Field | What to paste |
|-------|---------------|
| Provider | `EmailJS` (already selected) |
| Service ID | `service_ab12cd3` (from Step 2) |
| Template ID | `template_xy98zw7` (from Step 3) |
| Public key | `Zk3nAbCdEfGhIjKlM` (from Step 4) |
| Reply-to | your business email (optional) |
| Office copy *(optional)* | leave blank, or your own email to receive a copy of every client mail |

3. Tap **Save**. The card should read **Connected**.

That is the whole setup. Values are stored in the app and applied to every phone that syncs.

> Prefer to edit the file? Put the same values in `js/config.js` → `mail: { provider: "emailjs", serviceId: "...", templateId: "...", publicKey: "..." }` before uploading to GitHub.

---

## Step 6 — Test it properly (2 minutes)

1. On a **second phone or a browser in private mode**, register a new client with an email address you can open.
2. Check the inbox (and the **Spam** folder) for *"Your CHILESHE INNOVATIONS account is ready"*.
3. On the staff phone open **Emails** — the row should say **sent**.
   - `queued` or `failed` → read the red reason on that row. The three usual causes:
     - *Email is not configured* → Step 5 values missing on this device.
     - *EmailJS: The service ID is invalid* → wrong Service ID.
     - *EmailJS: The template ID is invalid* → wrong Template ID.
4. Apply for a small loan and approve it: the customer should receive the application and approval mails too.

---

## If you would rather not use EmailJS

Any service that accepts a JSON POST works. In **Settings → Email confirmations** choose **Webhook** and paste a URL. The app sends:

```json
{ "to": "client@example.com", "name": "Grace Tembo", "subject": "Loan approved — LN-…",
  "message": "full text…", "from": "CHILESHE INNOVATIONS", "replyTo": "", "staffEmail": "" }
```

Your endpoint should reply `200`. Good options: your own server, Make.com, Zapier, or Formspree.

---

## Costs, limits and good practice

- **Free tier:** 200 emails/month, 2 templates. Paid plans start around US$9/month.
- **Free Gmail accounts** can send ~500 messages/day — far above what this app needs.
- Emails go only to the address the client typed. If they mistype it, the app shows it on their profile and the staff can correct it (Clients → client → Edit).
- Registration **requires** a valid email now, so every client is reachable.
- The app never puts the NRC number or uploaded documents in an email — only the reference, amounts and balance. Documents stay behind the staff login.
- Turn on **2-step verification** on the EmailJS/Gmail account; if a phone is lost, change the Gmail password — that cuts off sending until you reconnect.

---

## Quick troubleshooting table

| What you see | Cause | Fix |
|---|---|---|
| Emails card says **Off** | No provider/settings saved | Steps 1–5 |
| Row says `no-address` | Client has no email on file | Clients → client → Edit → add email |
| Row says `failed` with "The service ID is invalid" | Typo in Service ID | Re-copy from EmailJS → Email Services |
| Row says `failed` with "The template ID is invalid" | Typo in Template ID | Re-copy from EmailJS → Email Templates |
| Row says `failed` with "The public key is invalid" | Typo in Public key | Account → General → Public Key |
| Emails arrive but are blank | Template body is not `{{message}}` | Edit template in EmailJS |
| Customer says nothing arrived | Check Spam; check the address on their profile | Ask them to mark "not spam" |
| `queued` on a phone with no signal | No internet at that moment | It sends on the next sync — no action needed |

---

*Tested end-to-end on 19 October 2026 in a two-phone rehearsal — register → apply → approve → pay → confirm — with all five emails of that path arriving and the staff **Emails** screen showing each one as sent.*
