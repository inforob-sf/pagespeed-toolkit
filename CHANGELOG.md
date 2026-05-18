# Changelog

## [0.1.0] — 2026-05-18

### Added
- `pagespeed-optimizer` Claude Code subagent — deep analysis of PageSpeed issues with framework-aware recommendations (Symfony, Laravel, Next.js, WordPress)
- `/pagespeed-fix` slash command — interactive fixer that reads audit reports and applies minimum-necessary changes with user confirmation
- Symfony integration: `PageSpeedService` and `PageSpeedAuditCommand` — generalized from project-specific code, configurable via `PAGESPEED_URLS` and `SITE_URL` env vars
- Shell script `integrations/shell/pagespeed-audit.sh` — framework-agnostic auditor via Google PageSpeed Insights API, requires only `curl` and `jq`
- Contributing guide and report JSON schema documentation
