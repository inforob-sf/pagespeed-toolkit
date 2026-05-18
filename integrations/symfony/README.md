# Symfony Integration

Adds two Symfony console commands that plug into the Claude Code toolkit.

## Requirements

- PHP 8.1+
- Symfony 6.x or 7.x
- `symfony/http-client` (already included in most Symfony projects)
- A [Google PageSpeed Insights API key](https://developers.google.com/speed/docs/insights/v5/get-started) (free tier allows ~25,000 requests/day)

## Installation

### 1. Copy the source files

```bash
cp src/Service/PageSpeedService.php  your-project/src/Service/
cp src/Command/PageSpeedAuditCommand.php  your-project/src/Command/
```

### 2. Add environment variables

```dotenv
# .env or .env.local
PAGESPEED_API_KEY=your_google_api_key_here
SITE_URL=https://your-site.com

# Optional: comma-separated paths to audit (overrides the default list)
PAGESPEED_URLS=/,/blog,/about,/contact
```

### 3. Register services

Merge the following into your `config/services.yaml`:

```yaml
services:
    App\Service\PageSpeedService:
        arguments:
            $apiKey: '%env(PAGESPEED_API_KEY)%'

    App\Command\PageSpeedAuditCommand:
        arguments:
            $siteUrl: '%env(SITE_URL)%'
            $projectDir: '%kernel.project_dir%'
```

Or copy `config/services.yaml` from this directory and adapt it.

## Usage

### Run an audit

```bash
# Audit all configured pages (mobile + desktop)
php bin/console pagespeed:audit

# Audit a single path
php bin/console pagespeed:audit --url /blog

# Audit specific paths
php bin/console pagespeed:audit --urls /,/blog,/about

# Desktop only
php bin/console pagespeed:audit --strategy desktop

# Custom output path
php bin/console pagespeed:audit --output var/my-report.json
```

The report is saved to `var/pagespeed-report.json` by default.

### Fix with Claude Code

Once the report exists, open Claude Code in your project and run:

```
/pagespeed-fix
```

Claude will read the report, present failing audits grouped by category, and apply fixes interactively with your confirmation.

## How the page list is resolved

Priority order:

1. `--url /path` flag → single page
2. `--urls /,/blog,/about` flag → explicit list
3. `PAGESPEED_URLS` env var → comma-separated list from `.env`
4. Hardcoded fallback: `/`, `/blog`, `/contact`, `/login`

Customize by setting `PAGESPEED_URLS` in your `.env.local`.
