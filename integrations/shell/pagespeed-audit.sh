#!/usr/bin/env bash
# pagespeed-audit.sh — Framework-agnostic PageSpeed audit via Google API
#
# Usage:
#   ./pagespeed-audit.sh <site-url> [options]
#
# Options:
#   --strategy   mobile|desktop|both  (default: both)
#   --output     path to JSON report  (default: pagespeed-report.json)
#   --key        Google API key       (or set PAGESPEED_API_KEY env var)
#   --urls       comma-separated list of paths to audit (default: /)
#
# Example:
#   PAGESPEED_API_KEY=AIzaSy... ./pagespeed-audit.sh https://example.com \
#     --urls /,/blog,/about --strategy both --output var/pagespeed-report.json

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
SITE_URL=""
STRATEGY="both"
OUTPUT="pagespeed-report.json"
API_KEY="${PAGESPEED_API_KEY:-}"
URLS_ARG="/"
API_ENDPOINT="https://www.googleapis.com/pagespeedonline/v5/runPagespeed"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Argument parsing ──────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo -e "${BOLD}Usage:${RESET} $0 <site-url> [--strategy mobile|desktop|both] [--output path] [--key API_KEY] [--urls /,/blog,/about]"
  exit 1
fi

SITE_URL="${1%/}"  # strip trailing slash
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strategy) STRATEGY="$2"; shift 2 ;;
    --output)   OUTPUT="$2";   shift 2 ;;
    --key)      API_KEY="$2";  shift 2 ;;
    --urls)     URLS_ARG="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Validate dependencies ─────────────────────────────────────────────────────
for cmd in curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}Error:${RESET} '$cmd' is required but not installed."
    exit 1
  fi
done

# ── Build strategy list ───────────────────────────────────────────────────────
case "$STRATEGY" in
  mobile)  STRATEGIES=("mobile") ;;
  desktop) STRATEGIES=("desktop") ;;
  both)    STRATEGIES=("mobile" "desktop") ;;
  *) echo "Invalid strategy: $STRATEGY. Use mobile, desktop, or both."; exit 1 ;;
esac

# ── Build URL list ────────────────────────────────────────────────────────────
IFS=',' read -ra URL_PATHS <<< "$URLS_ARG"

# ── Audit function ────────────────────────────────────────────────────────────
audit_url() {
  local path="$1" strategy="$2"
  local full_url="${SITE_URL}${path}"

  local query="url=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$full_url")&strategy=${strategy^^}&category=performance&category=seo&category=accessibility&category=best-practices"

  if [[ -n "$API_KEY" ]]; then
    query="${query}&key=${API_KEY}"
  fi

  curl -sf --max-time 90 "${API_ENDPOINT}?${query}"
}

score_color() {
  local score=$1
  if   (( score >= 90 )); then echo -e "${GREEN}${score}${RESET}"
  elif (( score >= 50 )); then echo -e "${YELLOW}${score}${RESET}"
  else                         echo -e "${RED}${score}${RESET}"
  fi
}

# ── Main audit loop ───────────────────────────────────────────────────────────
echo -e "\n${BOLD}${CYAN}Google PageSpeed Insights — Full Audit${RESET}"
echo -e "Site: ${BOLD}${SITE_URL}${RESET} · Strategy: ${STRATEGY} · Pages: ${#URL_PATHS[@]}\n"

REPORT="{}"

for path in "${URL_PATHS[@]}"; do
  path="${path// /}"  # trim spaces
  echo -e "${BOLD}── ${path} ──────────────────────────────────────────────${RESET}"

  for strategy in "${STRATEGIES[@]}"; do
    printf "  %-8s → " "$strategy"

    response=$(audit_url "$path" "$strategy" 2>&1) || {
      echo -e "${RED}ERROR${RESET}: $response"
      REPORT=$(echo "$REPORT" | jq --arg p "$path" --arg s "$strategy" --arg e "$response" \
        '.[$p][$s] = {"error": $e}')
      continue
    }

    # Extract scores
    perf=$(echo "$response" | jq -r '.lighthouseResult.categories.performance.score // 0 | . * 100 | round')
    seo=$(echo "$response"  | jq -r '.lighthouseResult.categories.seo.score // 0 | . * 100 | round')
    a11y=$(echo "$response" | jq -r '.lighthouseResult.categories.accessibility.score // 0 | . * 100 | round')
    bp=$(echo "$response"   | jq -r '.lighthouseResult.categories["best-practices"].score // 0 | . * 100 | round')

    echo -e "Perf $(score_color $perf)  SEO $(score_color $seo)  A11y $(score_color $a11y)  BP $(score_color $bp)"

    # Extract failing audits
    failing=$(echo "$response" | jq '[
      .lighthouseResult.audits
      | to_entries[]
      | select(
          .value.score != null
          and (.value.score | type) == "number"
          and .value.score < 1.0
          and (.value.scoreDisplayMode // "" | IN("informative","notApplicable","manual") | not)
        )
      | {
          id: .key,
          title: .value.title,
          score: (.value.score * 100 | round),
          displayValue: (.value.displayValue // null)
        }
      | select(.score != null)
    ] | sort_by(.score)')

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    REPORT=$(echo "$REPORT" | jq \
      --arg p "$path" \
      --arg s "$strategy" \
      --argjson perf "$perf" \
      --argjson seo "$seo" \
      --argjson a11y "$a11y" \
      --argjson bp "$bp" \
      --argjson failing "$failing" \
      --arg ts "$timestamp" \
      --arg url "${SITE_URL}${path}" \
      '.[$p][$s] = {
        "url": $url,
        "scores": {"performance": $perf, "seo": $seo, "accessibility": $a11y, "best-practices": $bp},
        "failing": $failing,
        "timestamp": $ts
      }')

    # Rate limit: respect free API quota
    sleep 0.5
  done
  echo ""
done

# ── Write report ──────────────────────────────────────────────────────────────
echo "$REPORT" | jq '.' > "$OUTPUT"
echo -e "${GREEN}✔${RESET} Report saved to: ${BOLD}${OUTPUT}${RESET}"
echo -e "  Run ${CYAN}/pagespeed-fix${RESET} in Claude Code to analyze and fix the findings.\n"
