# Shell Script Integration (Universal)

Works with any framework or stack. The only dependencies are `curl` and `jq`.

## Requirements

- `curl`
- `jq` — install with `apt install jq` / `brew install jq`
- A [Google PageSpeed Insights API key](https://developers.google.com/speed/docs/insights/v5/get-started)

## Usage

```bash
chmod +x pagespeed-audit.sh

# Audit home page only
PAGESPEED_API_KEY=your_key ./pagespeed-audit.sh https://your-site.com

# Audit multiple pages
PAGESPEED_API_KEY=your_key ./pagespeed-audit.sh https://your-site.com \
  --urls /,/blog,/about,/contact

# Desktop only, custom output path
PAGESPEED_API_KEY=your_key ./pagespeed-audit.sh https://your-site.com \
  --strategy desktop \
  --output var/pagespeed-report.json

# Pass API key as flag instead of env var
./pagespeed-audit.sh https://your-site.com --key your_key
```

## Options

| Flag | Default | Description |
|---|---|---|
| `--strategy` | `both` | `mobile`, `desktop`, or `both` |
| `--output` | `pagespeed-report.json` | Output path for the JSON report |
| `--key` | `$PAGESPEED_API_KEY` | Google API key |
| `--urls` | `/` | Comma-separated list of paths to audit |

## Output

The script creates a `pagespeed-report.json` file in the standard format that `/pagespeed-fix` expects. Once the report exists, open Claude Code and run `/pagespeed-fix`.

## Rate limits

The free Google PageSpeed API tier allows ~25,000 requests/day. The script adds a 500ms delay between requests to stay well within limits. For large audits (many pages × 2 strategies), consider using an API key to avoid anonymous rate limiting.
