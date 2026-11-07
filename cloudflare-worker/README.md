# Question assistant backend

The website is static, so the AI key and the email sending live here, in a small Cloudflare Worker.

What it does for every visitor question:
1. Checks the request comes from the allowed website and is not too frequent.
2. Asks Claude for a reply limited to estate planning in Malaysia (rules are in `SYSTEM_PROMPT` in `worker.js`).
3. Returns the reply to the page.
4. Emails the question and the reply to `chokkc.m100@gmail.com` (also if the AI call fails).

## One-time setup (about 15 minutes)

You need three free or pay-as-you-go accounts. Keys must be entered by you, not pasted into chat or the website.

1. **Anthropic API key**: create one at console.anthropic.com and set a monthly spend limit.
2. **Resend** (sends the email copy): sign up at resend.com **using chokkc.m100@gmail.com**, then create an API key. Resend's shared test sender can only deliver to the address the account was created with, which is exactly what we need. (To send from your own domain later, verify the domain in Resend and change `RECORD_FROM`.)
3. **Cloudflare**: create a free account at cloudflare.com.

**Shortcut:** in PowerShell, in this folder, run `.\deploy.ps1`. It does everything below and updates `index.html` for you.

Or by hand, in a terminal in this `cloudflare-worker` folder:

```bash
npx wrangler login
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put RESEND_API_KEY
npx wrangler deploy
```

`wrangler deploy` prints a URL like `https://effecto-wills-chat.<your-subdomain>.workers.dev`.

Last step: open `index.html`, set `CHAT_API_URL` to that URL, and push to GitHub. Until you do this, the chat shows a polite "not switched on yet, message us on WhatsApp" reply.

## Good practice

- In the Cloudflare dashboard, add a rate-limiting rule for the Worker. The built-in limit in `worker.js` is only best effort.
- Visitors are told before chatting that conversations are recorded and emailed to Effecto. Because questions can contain personal details, keep that notice, handle the inbox in line with Malaysia's Personal Data Protection Act 2010, and delete records you no longer need.
- The assistant is told to give general information only. Have a Malaysian advocate and solicitor read `SYSTEM_PROMPT` and sample answers before you rely on it. An AI cannot guarantee that every answer is legally correct or current, so spot-check the emailed records regularly.
- If your lawyers want different rules, edit `SYSTEM_PROMPT` and run `npx wrangler deploy` again.
