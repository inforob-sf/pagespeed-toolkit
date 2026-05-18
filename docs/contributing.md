# Contributing

## Adding a new framework integration

1. Create a folder: `integrations/<framework>/`
2. Add the audit command/script that generates `pagespeed-report.json`
3. Write a `README.md` with installation and usage instructions
4. Update the fix guide table in `.claude/commands/pagespeed-fix.md` with framework-specific audit IDs and file paths

### Report format

All audit integrations must produce a JSON file in this format:

```json
{
  "/path": {
    "mobile": {
      "url": "https://example.com/path",
      "scores": {
        "performance": 72,
        "seo": 91,
        "accessibility": 88,
        "best-practices": 95
      },
      "failing": [
        {
          "id": "largest-contentful-paint",
          "title": "Largest Contentful Paint",
          "score": 42,
          "displayValue": "4.2 s"
        }
      ],
      "timestamp": "2025-01-15T10:30:00Z"
    },
    "desktop": { ... }
  }
}
```

This schema is what `.claude/commands/pagespeed-fix.md` reads. As long as your integration produces this format, Claude Code's `/pagespeed-fix` command will work with it automatically.

## Extending the fix guide

The fix guide in `.claude/commands/pagespeed-fix.md` maps Lighthouse audit IDs to framework-specific fixes. To add entries:

1. Find the audit ID from the Lighthouse documentation or from a failing audit in the report
2. Identify the correct file to edit for each framework
3. Add a row to the fix guide table following the existing pattern

## Testing

Test your changes by:
1. Running the audit script against a real or staging URL
2. Running `/pagespeed-fix` in Claude Code on the generated report
3. Verifying Claude reads the report correctly and suggests appropriate fixes
