#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readme="$repo_root/README.md"
skills_snapshot="$repo_root/snapshot/skills.json"
skills_lock="$HOME/.agents/.skill-lock.json"
agents_skills="$HOME/.agents/skills"
codex_skills="$HOME/.codex/skills"
plugin_cache="$HOME/.codex/plugins/cache"
codex_config="$HOME/.codex/config.toml"
global_agents="$HOME/.codex/AGENTS.md"
local_skill_names=(
  generate-agent-stack-readme
  hatch-pet
  playwright
)

for command_name in awk cmp find jq mktemp shasum sort tr wc; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$command_name" >&2
    exit 1
  fi
done

if ! jq -e '
  .skills
  | to_entries
  | all(.[];
      (.key | test("^[A-Za-z0-9._-]+$"))
      and (.value.source | test("^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$"))
      and (.value.skillPath | test("^[A-Za-z0-9._/-]+$"))
      and (.value.skillFolderHash | test("^[0-9a-f]{40,64}$"))
    )
' "$skills_lock" >/dev/null; then
  printf 'skill lock contains fields outside the public manifest allowlist\n' >&2
  exit 1
fi

required_paths=(
  "$readme" \
  "$skills_snapshot" \
  "$skills_lock" \
  "$agents_skills" \
  "$codex_skills" \
  "$plugin_cache" \
  "$codex_config" \
  "$global_agents"
)

for skill_name in "${local_skill_names[@]}"; do
  required_paths+=("$codex_skills/$skill_name")
done

for required_path in "${required_paths[@]}"; do
  if [ ! -e "$required_path" ]; then
    printf 'missing required path: %s\n' "$required_path" >&2
    exit 1
  fi
done

expected_counts="$(awk -F '|' '
  /^\| 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {
    for (field = 2; field <= 6; field++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $field)
    }
    print $2, $3, $4, $5, $6
    exit
  }
' "$readme")"

set -- $expected_counts
if [ "$#" -ne 5 ]; then
  printf 'could not parse snapshot summary from README.md\n' >&2
  exit 1
fi

snapshot_date="$1"
expected_skills="$2"
expected_plugin_packages="$3"
expected_enabled_plugins="$4"
expected_mcp_services="$5"

actual_skills="$(
  find -L "$agents_skills" "$codex_skills" \
    -name SKILL.md -type f ! -path "$codex_skills/.system/*" -print |
    awk -F '/' '{print $(NF - 1)}' |
    LC_ALL=C sort -u |
    wc -l |
    tr -d ' '
)"

actual_plugin_packages="$(
  find "$plugin_cache" -path '*/.codex-plugin/plugin.json' -type f -print |
    wc -l |
    tr -d ' '
)"

actual_enabled_plugins="$(awk '
  /^[[:space:]]*\[/ {
    in_plugin = ($0 ~ /^[[:space:]]*\[plugins\."[^"]+"\][[:space:]]*(#.*)?$/ || $0 ~ /^[[:space:]]*\[plugins\.[A-Za-z0-9_-]+\][[:space:]]*(#.*)?$/)
    next
  }
  in_plugin && /^[[:space:]]*enabled[[:space:]]*=[[:space:]]*true[[:space:]]*(#.*)?$/ { count++ }
  END { print count + 0 }
' "$codex_config")"

actual_mcp_services="$(awk '
  /^[[:space:]]*\[mcp_servers\."[^"]+"\][[:space:]]*(#.*)?$/ { count++; next }
  /^[[:space:]]*\[mcp_servers\.[A-Za-z0-9_-]+\][[:space:]]*(#.*)?$/ { count++ }
  END { print count + 0 }
' "$codex_config")"

failures=0

check_equal() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  if [ "$expected" = "$actual" ]; then
    printf '[ok] %s: %s\n' "$label" "$actual"
  else
    printf '[drift] %s: expected %s, found %s\n' "$label" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

printf 'Snapshot date: %s\n' "$snapshot_date"
check_equal 'personal Skills' "$expected_skills" "$actual_skills"
check_equal 'plugin packages' "$expected_plugin_packages" "$actual_plugin_packages"
check_equal 'enabled plugins' "$expected_enabled_plugins" "$actual_enabled_plugins"
check_equal 'MCP services' "$expected_mcp_services" "$actual_mcp_services"

hash_local_tree() {
  local directory="$1"

  find -L "$directory" -type f -print |
    LC_ALL=C sort |
    while IFS= read -r file; do
      file_hash="$(shasum -a 256 "$file" | awk '{print $1}')"
      relative_path="${file#"$directory"/}"
      printf '%s  %s\n' "$file_hash" "$relative_path"
    done |
    shasum -a 256 |
    awk '{print $1}'
}

render_skills_snapshot() {
  local local_skills_json skill_directory skill_hash skill_name
  local_skills_json="$({
    for skill_name in "${local_skill_names[@]}"; do
      skill_directory="$codex_skills/$skill_name"
      skill_hash="$(hash_local_tree "$skill_directory")"
      jq -cn \
        --arg name "$skill_name" \
        --arg path "~/.codex/skills/$skill_name" \
        --arg hash "$skill_hash" \
        '{
          name: $name,
          source: "local",
          skillPath: $path,
          contentHash: $hash,
          hashSource: "local-tree-sha256"
        }'
    done
  } | jq -s '.')"

  jq --argjson local_skills "$local_skills_json" '{
    schemaVersion: 1,
    lockVersion: .version,
    generatedFrom: (["~/.agents/.skill-lock.json"] + ($local_skills | map(.skillPath))),
    hashSemantics: {
      managed: "skillFolderHash copied from the lock file; it is not an upstream commit",
      local: "SHA-256 of sorted lines containing each relative path and file SHA-256"
    },
    skills: (
      (.skills | to_entries | map({
        name: .key,
        source: .value.source,
        skillPath: .value.skillPath,
        contentHash: .value.skillFolderHash,
        hashSource: "skillFolderHash"
      }))
      + $local_skills
      | sort_by(.name)
    )
  }' "$skills_lock"
}

temporary_snapshot="$(mktemp "${TMPDIR:-/tmp}/agent-stack-skills.XXXXXX")"
trap 'rm -f "$temporary_snapshot"' EXIT
render_skills_snapshot > "$temporary_snapshot"

if cmp -s "$skills_snapshot" "$temporary_snapshot"; then
  printf '[ok] Skills manifest matches lock metadata and local skill trees\n'
else
  printf '[drift] Skills manifest differs from lock metadata or local skill trees\n' >&2
  failures=$((failures + 1))
fi

expected_agents_hash="$(awk -F '`' '/源文件 SHA-256/ {print $2; exit}' "$readme")"
actual_agents_hash="$(shasum -a 256 "$global_agents" | awk '{print $1}')"

if [ -z "$expected_agents_hash" ]; then
  printf '[drift] README does not record the global AGENTS.md SHA-256\n' >&2
  failures=$((failures + 1))
else
  check_equal 'global AGENTS.md SHA-256' "$expected_agents_hash" "$actual_agents_hash"
fi

if [ "$failures" -ne 0 ]; then
  printf 'Snapshot consistency check failed with %s issue(s).\n' "$failures" >&2
  exit 1
fi

printf 'Snapshot consistency check passed.\n'
