// Vercel function for /cuisine and /cuisine/<slug>: sends the normal app (index.html) with the right
// SEO title, description, social sharing image and Product data for that page, so Google, Facebook and
// WhatsApp previews show the kitchen product. If anything fails, the plain app is sent and still works.
// It only reads public data (the catalog table is public); no secret is used here.
const esc = (s) => String(s ?? "").replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const pick = (o, l) => (o && typeof o === "object" ? (o[l] || o.fr || o.ar || "") : String(o || ""));

module.exports = async (req, res) => {
  const host = String(req.headers["x-forwarded-host"] || req.headers.host || "www.khedar48.com").replace(/[^\w.:-]/g, "");
  const origin = "https://" + host;
  const slug = String((req.query && req.query.slug) || "").toLowerCase().replace(/[^a-z0-9-]/g, "").slice(0, 80);
  let html = "";
  try {
    html = await (await fetch(origin + "/index.html", { headers: { "cache-control": "no-cache" } })).text();
  } catch (e) {
    res.statusCode = 302; res.setHeader("Location", "/"); return res.end();
  }
  const url = origin + "/cuisine" + (slug ? "/" + slug : "");
  let meta = {
    t: "Accessoires de cuisine à Oujda · KHEDAR48 CUISINE",
    d: "Accessoires de cuisine pratiques livrés à Oujda. Paiement à la livraison.",
    img: origin + "/img/hero.jpg", type: "website", ld: null, found: !slug,
  };
  try {
    const cfg = await (await fetch(origin + "/supabase-config.js")).text();
    const U = (/SUPABASE_URL\s*=\s*"([^"]+)"/.exec(cfg) || [])[1], K = (/SUPABASE_KEY\s*=\s*"([^"]+)"/.exec(cfg) || [])[1];
    if (slug && U && K && K !== "COLLE_ICI") {
      const r = await fetch(U + "/rest/v1/catalog?id=eq.products&select=data", { headers: { apikey: K } });
      const items = ((await r.json())[0] || {}).data?.items || [];
      const p = items.find((x) => x && x.c === "cuisine" && !x.par && x.slug === slug && x.on !== false);
      if (p) {
        const name = p.fr || p.n || "Produit", seo = p.seo || {};
        const imgs = [p.img, ...(Array.isArray(p.gal) ? p.gal : [])].filter((u) => typeof u === "string" && u)
          .map((u) => (/^https:\/\//.test(u) ? u : origin + "/" + u.replace(/^\/+/, "")));
        const shareImg = typeof seo.img === "string" && /^https:\/\//.test(seo.img) ? seo.img : imgs[0];
        const desc = seo.d || pick(p.sh, "fr") || pick(p.sh, "ar") || name;
        const inStock = !(typeof p.stock === "number" && p.stock <= 0) && Number(p.p) > 0;
        meta = {
          t: seo.t || `${name} · KHEDAR48 CUISINE`, d: desc, img: shareImg || meta.img, type: "product", found: true,
          ld: { "@context": "https://schema.org", "@type": "Product", name, image: imgs, description: desc, sku: p.id,
            brand: { "@type": "Brand", name: "Khedar48" },
            offers: { "@type": "Offer", url, priceCurrency: "MAD", price: Number(p.p) || 0,
              availability: inStock ? "https://schema.org/InStock" : "https://schema.org/OutOfStock" } },
          price: Number(p.p) || 0,
        };
      }
    }
  } catch (e) { /* keep the default tags */ }

  const tags = [
    `<base href="/">`,
    `<title>${esc(meta.t)}</title>`,
    `<meta name="description" content="${esc(meta.d)}">`,
    `<link rel="canonical" href="${esc(url)}">`,
    `<meta property="og:type" content="${meta.type}">`,
    `<meta property="og:url" content="${esc(url)}">`,
    `<meta property="og:title" content="${esc(meta.t)}">`,
    `<meta property="og:description" content="${esc(meta.d)}">`,
    `<meta property="og:image" content="${esc(meta.img)}">`,
    `<meta name="twitter:card" content="summary_large_image">`,
    meta.price ? `<meta property="product:price:amount" content="${meta.price}"><meta property="product:price:currency" content="MAD">` : "",
    meta.ld ? `<script type="application/ld+json" id="kLd">${JSON.stringify(meta.ld).replace(/</g, "\\u003c")}</script>` : "",
  ].filter(Boolean).join("\n");
  html = html
    .replace(/<title>[\s\S]*?<\/title>/i, "")
    .replace(/<meta\s+name="description"[^>]*>/i, "")
    .replace(/<meta\s+property="og:(title|description|image|type|url)"[^>]*>/gi, "")
    .replace(/<head([^>]*)>/i, `<head$1>\n${tags}`);
  res.statusCode = meta.found ? 200 : 404;
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.setHeader("Cache-Control", "public, max-age=0, s-maxage=300, stale-while-revalidate=600");
  res.end(html);
};
