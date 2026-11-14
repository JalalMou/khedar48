# Khedar48 · خضار 48

L'app dial l'livraison dial khodra w fawakih f Wjda. Fiha:

- **Boutique** dial zboun (b l3arbiya). Zboun kaytlb bla compte.
- **Suivi** dial talab.
- **Espace Admin** (b lfrançais).
- **App livreur.**
- Kattnstalla f tilifoun b7al app (PWA).

Kolchi mbni 3la jouj:

- **Supabase:** database, login w tsawer.
- **Vercel:** bach l'app tban f internet.

> Ila ma 3mmrtich `supabase-config.js`, l'app kakhdem f **mode démo**: kolchi kaybqa ghi f navigateur.

---

## A) Supabase (database)

**1. Dir projet**
- Sir l **supabase.com** w dkhl, w mn ba3d **New project**.
- Name: `khedar48`.
- Database Password: ktb wa7d w **7ddo 3ndk**.
- Region: **West EU (Paris)** wla **Frankfurt**.
- Klik **Create new project** w tsenna 2 d9aye9.

**2. Dir tables w l'aman**
- Mn lisr: **SQL Editor** (icône `>_`), w mn ba3d **New query**.
- 7el fichier `supabase.sql` b TextEdit, w nskh **kolchi** (Cmd+A, Cmd+C).
- Lss9o f Supabase w klik **Run**.
- Khass ytla3 lik **"Success. No rows returned"**.

**3. Ch3el login**
- Mn lisr: **Authentication**, w mn ba3d **Sign In / Providers** (wla **Providers**).
- Ch3el **"Allow anonymous sign-ins"** w dir **Save**. Hadi bach zboun ytlbo bla compte.
- 7el **Email**, w tfeqed bli **Enable Email provider** ch3ail.
- **Tfi "Confirm email"** w dir **Save**. Hadi bach livreurs ydkhlo direct.

**4. Dir compte dial l'admin**
- **Authentication → Users → Add user → Create new user**.
- Dkhl email dialk w mot de passe.
- Ch3el **"Auto Confirm User"** w klik **Create user**.

**5. Rdd had l'compte admin**
- Rje3 l **SQL Editor → New query**.
- Lss9 had star, w bddel `TON_EMAIL` b email dialk:
  ```sql
  insert into public.staff (user_id, role, name, email)
  select id, 'admin', 'Admin', email from auth.users where email = 'TON_EMAIL'
  on conflict (user_id) do update set role = 'admin';
  ```
- Klik **Run**. Khass ytla3 **"Success. 1 row"**.

**6. Jib l'mafatih**
- Mn lisr: **Project Settings** (⚙️), w mn ba3d **API** (wla **Data API / API Keys**).
- Nskh jouj 7wayj:
  - **Project URL**, b7al `https://abcd.supabase.co`
  - **anon public** key, wla **Publishable key** (`sb_publishable_...`)
- 7ethom f fichier **`supabase-config.js`** f blast `COLLE_ICI`.
- ⚠️ **Ma t7ttch** l'key dial `service_role` wla `secret`.

---

## B) GitHub (bach Vercel ychouf l'code)

**7. Dir repo**
- Sir l **github.com/new**.
- Name: `khedar48`.
- Khtar **Private**: Vercel kaykhdem 7tta m3a private.
- Klik **Create repository**.

**8. Rfe3 l'fichiers**
- Klik **"uploading an existing file"**.
- Jerr had l'fichiers w les dossiers:
  - `index.html`, `supabase-config.js`, `manifest.webmanifest`, `sw.js`, `vercel.json`
  - `icons`, `img`
  - `supabase.sql`, `README.md`
- ⚠️ **Ma tjerrch `khedar48-app.html`**. Hadi nskha 9dima.
- Klik **Commit changes**.

---

## C) Vercel (bach tban l'app)

**9. Lansi l'app**
- Sir l **vercel.com** w mn ba3d **Add New… → Project**.
- **Import Git Repository**: rbt GitHub ila tlab mnk, w khtar `khedar48` w klik **Import**.
- Framework Preset: **Other**. Ma tbdl walou akhor.
- Klik **Deploy**.
- Mn ba3d d9i9a, l'app katban f `https://khedar48.vercel.app` (wla smiya 9riba).

**10. Domain dialk (optionnel)**
- F Vercel: **Project → Settings → Domains**, zid `app.khedar48.com`.
- Vercel ghadi y3tik record dial DNS, ghaliban:
  - Type: `CNAME`
  - Name: `app`
  - Value: `cname.vercel-dns.com`
- Zido 3nd fin chriti domain.
- ⚠️ Ma tbdlch DNS dial `khedar48.com` kaml, wla site li kayn daba ghadi y7bs.

---

## D) Jrreb

**11. Dkhl l'admin**
- 7el l'app, w lta7t f boutique klik **"دخول الفريق"**.
- Dkhl b email w mot de passe dial l'admin.
- L'awel mra, l'catalogue kayt3mer bo7do: 40 produit, codes promo w bannières.

**12. Jrreb talab**
- Mn tilifoun akhor, dir talab.
- Ghadi ywslek f l'admin b sout.
- F **Paramètres → Activer**, ch3el l'notifications.

**13. Livreurs**
- F **Livreurs**, zid smiya, tilifoun, email w mot de passe.
- 3tihom l'email w mot de passe.
- Kaydkhlo mn "دخول الفريق" w kaychoufo ghi talabathom.

---

## Kol merra tbdl chi 7aja

1. F GitHub, klik **Add file → Upload files**.
2. Jerr l'fichier li tbdl, w klik **Commit**.

Vercel kay3awd ylansi l'app bo7do f d9i9a.

## Fichiers

| Fichier | Chnou fih |
|---|---|
| `index.html` | L'app kamla: boutique, suivi, admin w livreur |
| `supabase-config.js` | URL w key dial Supabase (khassek t3mmrhom) |
| `supabase.sql` | Tables, l'aman w stockage dial tsawer |
| `vercel.json` | Réglages sghar dial Vercel |
| `manifest.webmanifest`, `sw.js`, `icons/` | Bach l'app ttnstalla f tilifoun |

**Mola7aza:** l'prix dial talab kayt7seb f tilifoun dial zboun. Tfeqed dima l'articles w l'total f l'admin 9bel ma tsifet talab (lkhlass kaykoun 3nd l'istilam).
