# Invenzo AI Solutions - website + admin panel

```
index.html            public website (3D chapters, projects ring, products deck)
admin/index.html      admin console  ->  https://invenzoai.in/admin
config.js             your Supabase URL + anon key (2 lines to fill in)
supabase-setup.sql    database + security rules (run once)
favicon.png
```

Upload this whole folder to your hosting (Netlify, Vercel, Cloudflare Pages,
GitHub Pages, cPanel - anything that serves static files). Because the admin page is
the file `admin/index.html`, the address `https://invenzoai.in/admin` works with no
extra server setup.

## Why a database is needed

A website made of plain HTML files cannot safely check passwords or let several
people change what every visitor sees - anything written inside the page can be read by
anyone. So the login and the saved projects/products live in **Supabase** (free plan is
enough; Postgres + login + image storage). The page only talks to it.

## One-time setup (about 10 minutes)

1. Create a free project at https://supabase.com .
2. **SQL Editor -> New query**, paste all of `supabase-setup.sql`, press **Run**.
   This creates the tables, the image bucket, and the rule that only the three admin
   emails can add / edit / delete.
3. **Authentication -> Users -> Add user -> Create new user**. For each admin enter
   their email and a password, and tick **Auto Confirm User**:
   - mithinkrishnanns@invenzoai.in
   - mukeshpandi@invenzoai.in
   - maheshwaran@invenzoai.in
   (Authentication -> Sign In / Providers: you can switch **Allow new users to sign up**
   OFF so nobody else can create an account.)
4. **Project Settings -> API**: copy the **Project URL** and the **anon public** key
   into `config.js`. Never use the `service_role` key anywhere in these files.
5. Upload the folder. Open `https://invenzoai.in/admin`, sign in, add a project.
   Refresh the main site - it appears on the Projects ring.

## Using the admin

- **Projects**: name, client, short description, client website link, cover image
  (upload or link), tags, order, show/hide.
- **Products**: name, tagline, description, product link, image, status
  (Live / Beta / In development / Coming soon), order, show/hide.
- Arrows on each card change the order. "Hidden" items stay saved but are not shown.
- Sessions end when the tab closes and after 30 minutes idle.

## Security notes

- Passwords are never stored in these files. They live (hashed) inside Supabase.
- The `anon` key in `config.js` is meant to be public. The rules in
  `supabase-setup.sql` (row-level security) are what stop strangers from editing.
- Choose strong, unique passwords (a long random one per admin) rather than a pattern
  based on name + company domain, and change any password that was shared in a chat.
- To add or remove an admin later: add/remove the email in the `admins` table
  and create/delete the user under Authentication.
- Before Supabase is configured, `/admin` runs in **preview mode** (data only in your own
  browser) so you can try the screens.
