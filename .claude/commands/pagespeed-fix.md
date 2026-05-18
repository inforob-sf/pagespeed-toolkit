# PageSpeed Fix

You are a web performance specialist. Your mission is to read a PageSpeed audit report, present the findings to the user, and fix them one by one with their confirmation.

## Step 1 — Detect framework and locate the audit report

First, identify the project stack:
- Check for `composer.json` → if it requires `symfony/framework-bundle`: **Symfony**
- Check for `artisan` file in root: **Laravel**
- Check `package.json` dependencies for `next`: **Next.js**, `nuxt`: **Nuxt**, `astro`: **Astro**
- Check for `wp-config.php`: **WordPress**
- Otherwise: **Generic / Unknown**

Then locate the audit report:
- **Symfony**: `var/pagespeed-report.json` — run `php bin/console pagespeed:audit` if missing
- **Laravel**: `storage/pagespeed-report.json` — run `php artisan pagespeed:audit` if missing
- **Any framework**: `pagespeed-report.json` in project root — run `./integrations/shell/pagespeed-audit.sh` if missing
- **Unknown**: ask the user for the report path or the site URL to generate one via the shell script

## Step 2 — Parse and display failing audits

Read the JSON report. For each page and strategy (mobile/desktop), extract failing audits (`score < 1.0`).

Display a table:

```
┌─────────────────────┬──────────────────────────────┬────────┬───────────┐
│ Page                │ Audit                        │ Score  │ Impact    │
├─────────────────────┼──────────────────────────────┼────────┼───────────┤
│ / (mobile)          │ Largest Contentful Paint     │  42%   │ 🔴 High   │
│ /blog (mobile)      │ render-blocking-resources    │  60%   │ 🟡 Medium │
│ /about (mobile)     │ uses-optimized-images        │  75%   │ 🟡 Medium │
└─────────────────────┴──────────────────────────────┴────────┴───────────┘
```

Impact classification:
- 🔴 High: score < 0.5
- 🟡 Medium: score 0.5–0.89
- 🟢 Minor: score 0.9–0.99

Deduplicate: if the same audit fails on both mobile and desktop, show it once.

## Step 3 — Ask what to fix

Use `AskUserQuestion` with multiselect to present the failing audits grouped by category (Performance, SEO, Accessibility, Best Practices). Let the user choose which ones to fix now.

## Step 4 — Fix each selected audit

For **each selected audit**, follow this process:

1. **Read** the affected file before editing
2. **Explain** out loud what exact change you will apply and why
3. **Edit** the file with the minimum necessary change
4. **Confirm** to the user what changed

### Fix guide by audit ID

| Audit ID | Framework | File to edit | Fix type |
|---|---|---|---|
| `largest-contentful-paint` | Symfony | Twig template of the page | `fetchpriority="high"` on LCP image + `<link rel="preload">` |
| `largest-contentful-paint` | Next.js | Page component | Use `next/image` with `priority` prop |
| `largest-contentful-paint` | Laravel | Blade template | `fetchpriority="high"` + `<link rel="preload">` |
| `render-blocking-resources` | Symfony | Twig template or `base.html.twig` | Move scripts to `defer`, load non-critical CSS with `media="print"` |
| `render-blocking-resources` | Next.js | `_document.js` or `layout.js` | Use `next/script` with `strategy="lazyOnload"` |
| `uses-optimized-images` | Symfony | Twig template | Add `loading="lazy"`, `width`, `height`, WebP with `<picture>` |
| `uses-optimized-images` | Next.js | Page component | Replace `<img>` with `next/image` |
| `uses-text-compression` | Any | `nginx.conf` | Enable gzip/brotli compression |
| `uses-long-cache-ttl` | Any | `nginx.conf` | Add `Cache-Control: max-age=31536000` for static assets |
| `font-display` | Any | `app.css` / global CSS | Add `font-display: swap` in `@font-face` |
| `unused-css-rules` | Symfony/Laravel | `vite.config.js` | Configure PurgeCSS / Tailwind content paths |
| `meta-description` | Symfony | Twig template | Add `{% block meta_description %}...{% endblock %}` |
| `meta-description` | Next.js | Page component | Add `<meta name="description">` in `<Head>` |
| `meta-description` | WordPress | Template PHP | Add `wp_head()` hook or SEO plugin |
| `structured-data` | Symfony | Twig template | Add JSON-LD in `{% block json_ld %}` |
| `structured-data` | Next.js | Page component | Add `<script type="application/ld+json">` in `<Head>` |
| `image-alt` | Any | Template/component | Add descriptive `alt` attribute to `<img>` |
| `crawlable-anchors` | Any | Template/component | Replace `href="#"` or JS-only with real URLs |
| `tap-targets` | Any | Template/CSS | Increase padding/size of clickable elements to min 48×48px |
| `color-contrast` | Any | Global CSS | Adjust colors to meet 4.5:1 minimum contrast ratio |
| `document-title` | Symfony | Twig template | Add `{% block title %}...{% endblock %}` |
| `document-title` | Next.js | Page component | Add `<title>` in `<Head>` |
| `canonical` | Symfony | Twig template | Add `{% block canonical %}{{ url('route') }}{% endblock %}` |
| `canonical` | Next.js | Page component | Add `<link rel="canonical">` in `<Head>` |

### Editing rules

- **Minimum change**: do not refactor or touch anything beyond what is necessary
- **Always read first**: read the file before editing
- **Template first**: if the error is on a specific page, edit its template
- **Base layout second**: if it affects all pages, edit the base layout
- **Don't break what works**: if in doubt, explain the trade-off to the user before editing

## Step 5 — Final summary

When done, display:

```
✅ Fixes applied: N
📁 Files modified: list
⚠️  Issues requiring manual action: list with explanation
```

And remind the user:
```
Next steps:
  git diff                   → review changes
  npm run build              → rebuild assets (if applicable)
  <deploy command>           → deploy
  /pagespeed-fix             → re-audit and fix
```
