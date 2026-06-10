#!/bin/sh
# Renders the job matrix for a tool-update workflow. Given a YAML list of tools and
# a YAML registry of version sources, it validates the list and resolves each
# entry's version_source (inline when present, otherwise from the registry by tool
# name), then writes the matrix as compact JSON for a downstream matrix job. The
# consumer supplies the tools and registry; this script only validates and renders.
set -euf

die() {
  printf '%s\n' "render-github-workflow-matrix: $1" >&2
  exit 1
}

: "${INPUT_TOOLS:?tools input is required}"
: "${INPUT_REGISTRY:?registry input is required}"

command -v yq >/dev/null 2>&1 || die "yq not found"
command -v jq >/dev/null 2>&1 || die "jq not found"

main() {
  tools="$(printf '%s\n' "${INPUT_TOOLS}" | yq -o=json '.')"
  registry="$(printf '%s\n' "${INPUT_REGISTRY}" | yq -o=json '.')"

  printf '%s\n' "${tools}" |
    jq -e 'type == "array" and length > 0 and all(.tool | type == "string")' >/dev/null ||
    die "tools input must be a non-empty YAML list of entries naming a tool"

  printf '%s\n' "${tools}" |
    jq -e 'all(.files | 0 < length and length <= 2)' >/dev/null ||
    die "each tools entry requires one or two files"

  # Resolve each entry's version_source, preferring an inline value over the registry.
  json="$(
    printf '%s\n' "${tools}" |
      jq -c --argjson registry "${registry}" \
        'map(.version_source //= $registry[.tool])'
  )"

  # An entry with no inline value and no registry match has nothing to resolve.
  unknown="$(
    printf '%s\n' "${json}" |
      jq -r 'map(select(.version_source == null) | .tool) | join(", ")'
  )"
  if [ -n "${unknown}" ]; then
    supported="$(printf '%s\n' "${registry}" | jq -r 'keys | join(", ")')"
    die "unsupported tool(s): ${unknown} (supported: ${supported})"
  fi

  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf 'json=%s\n' "${json}" >>"${GITHUB_OUTPUT}"
  fi
}

main "$@"
