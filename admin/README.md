# AgentPost — admin dashboard

The owner's web dashboard (Next.js). Plain-language setup instructions live
in the [repository README](../README.md).

Quick version (developers):

```bash
cd admin
cp .env.example .env.local   # then fill in your Supabase values
npm install
npm run dev                  # open http://localhost:3000
```

Only accounts listed in the `admin_users` table can log in — see the
repository README for how to make yourself an admin.

Check the code:

```bash
npm run lint
npm run build
```
