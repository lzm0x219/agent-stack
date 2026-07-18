#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readme="$repo_root/README.md"
skills_snapshot="$repo_root/snapshot/skills.json"
hermes_skills_snapshot="$repo_root/snapshot/hermes-skills.json"
environment_snapshot="$repo_root/snapshot/environment.json"
catalog_snapshot="$repo_root/snapshot/catalog.json"
skills_lock="$HOME/.agents/.skill-lock.json"
agents_skills="$HOME/.agents/skills"
codex_skills="$HOME/.codex/skills"
hermes_skills="$HOME/.hermes/skills"
plugin_cache="$HOME/.codex/plugins/cache"
codex_config="$HOME/.codex/config.toml"
global_agents="$HOME/.codex/AGENTS.md"
local_skill_names=(
  generate-agent-stack-readme
  hatch-pet
  playwright
)

for command_name in awk cmp find hermes jq mktemp shasum sort tr wc; do
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
  "$hermes_skills_snapshot" \
  "$environment_snapshot" \
  "$catalog_snapshot" \
  "$skills_lock" \
  "$agents_skills" \
  "$codex_skills" \
  "$hermes_skills" \
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

if ! jq -e '
  . as $root
  | .schemaVersion == 1
    and (.snapshotDate | test("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$"))
    and .timezone == "Asia/Shanghai"
    and (.counts.codexPersonalSkills | type == "number")
    and (.counts.hermesSkills | type == "number")
    and (.counts.pluginPackages | type == "number")
    and (.counts.enabledPlugins | type == "number")
    and (.counts.mcpServices | type == "number")
    and .hermesAgent.command == "hermes"
    and (.hermesAgent.version | type == "string")
    and (.hermesAgent.build | type == "string")
    and (.hermesAgent.upstreamRevision | test("^[0-9a-f]+$"))
    and .hermesAgent.installDirectory == "~/.hermes/hermes-agent"
    and (.hermesAgent.installMethod | type == "string")
    and .hermesAgent.skillsRoot == "~/.hermes/skills"
    and .hermesAgent.skillsSnapshot == "snapshot/hermes-skills.json"
    and (.plugins | type == "array")
    and (.plugins | length == $root.counts.pluginPackages)
    and (([.plugins[].name] | unique | length) == (.plugins | length))
    and (all(.plugins[];
      (.name | test("^[A-Za-z0-9._-]+$"))
      and (.version | type == "string")
      and (.source | test("^[A-Za-z0-9._-]+$"))
      and (.cached | type == "boolean")
      and (.configured | type == "boolean")
      and (.enabled | type == "boolean")))
    and ([.plugins[] | select(.enabled)] | length == $root.counts.enabledPlugins)
    and (.mcpServers | type == "array")
    and (.mcpServers | length == $root.counts.mcpServices)
    and (([.mcpServers[].name] | unique | length) == (.mcpServers | length))
    and (all(.mcpServers[];
      (.name | test("^[A-Za-z0-9._-]+$"))
      and (.configured == true)
      and ((.enabled == null) or (.enabled | type == "boolean"))
      and (.purpose | type == "string")))
    and (.tools | type == "array")
    and (([.tools[].command] | unique | length) == (.tools | length))
    and (all(.tools[];
      (.command | test("^[A-Za-z0-9._-]+$"))
      and (.status == "ok" or .status == "version-read-failed")
      and ((.version == null) or (.version | type == "string"))))
    and ([.tools[] | select(.command == "hermes")][0].version == .hermesAgent.version)
    and .globalAgents.source == "~/.codex/AGENTS.md"
    and (.globalAgents.sha256 | test("^[0-9a-f]{64}$"))
' "$environment_snapshot" >/dev/null; then
  printf 'environment snapshot contains invalid or incomplete public fields\n' >&2
  exit 1
fi

if ! jq -e --slurpfile environment "$environment_snapshot" '
  . as $root
  | .schemaVersion == 1
    and .generatedFrom == ["hermes --version", "~/.hermes/skills"]
    and .runtime.command == $environment[0].hermesAgent.command
    and .runtime.version == $environment[0].hermesAgent.version
    and .runtime.build == $environment[0].hermesAgent.build
    and .runtime.upstreamRevision == $environment[0].hermesAgent.upstreamRevision
    and .runtime.installDirectory == $environment[0].hermesAgent.installDirectory
    and .runtime.installMethod == $environment[0].hermesAgent.installMethod
    and .runtime.skillsRoot == $environment[0].hermesAgent.skillsRoot
    and (.hashSemantics | type == "string")
    and (.skills | type == "array")
    and (.skills | length == $environment[0].counts.hermesSkills)
    and (([.skills[].name] | unique | length) == (.skills | length))
    and (all(.skills[];
      (.name | test("^[A-Za-z0-9._-]+$"))
      and (.category | test("^[A-Za-z0-9._-]+$"))
      and (.skillPath | test("^~/.hermes/skills/[A-Za-z0-9._/-]+/SKILL\\.md$"))
      and (.contentHash | test("^[0-9a-f]{64}$"))
      and .hashSource == "local-tree-sha256"))
' "$hermes_skills_snapshot" >/dev/null; then
  printf 'Hermes Skills snapshot contains invalid or incomplete public fields\n' >&2
  exit 1
fi

if ! jq -e --slurpfile environment "$environment_snapshot" '
  ([.toolGroups[].commands[]] == [$environment[0].tools[].command])
  and (.agentRuntimes | type == "array")
  and (all(.agentRuntimes[];
    . as $runtime
    | (.name | type == "string")
      and (.command | test("^[A-Za-z0-9._-]+$"))
      and ([ $environment[0].tools[].command ] | index($runtime.command) != null)
      and ((has("skillsRoots") | not) or (.skillsRoots | type == "array"))
      and ((has("skillsSnapshot") | not) or (.skillsSnapshot | type == "string"))))
  and ([.agentRuntimes[] | select(.command == "hermes")][0].skillsRoots == ["~/.hermes/skills"])
  and ([.agentRuntimes[] | select(.command == "hermes")][0].skillsSnapshot == "snapshot/hermes-skills.json")
' "$catalog_snapshot" >/dev/null; then
  printf 'environment runtime or tool list does not match catalog\n' >&2
  exit 1
fi

environment_counts="$(jq -r '
  [.snapshotDate, .counts.codexPersonalSkills, .counts.hermesSkills, .counts.pluginPackages, .counts.enabledPlugins, .counts.mcpServices]
  | @tsv
' "$environment_snapshot")"

set -- $environment_counts
if [ "$#" -ne 6 ]; then
  printf 'could not parse counts from snapshot/environment.json\n' >&2
  exit 1
fi

snapshot_date="$1"
expected_skills="$2"
expected_hermes_skills="$3"
expected_plugin_packages="$4"
expected_enabled_plugins="$5"
expected_mcp_services="$6"

readme_counts="$(awk -F '|' '
  /^\| 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {
    for (field = 2; field <= 7; field++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $field)
    }
    print $2, $3, $4, $5, $6, $7
    exit
  }
' "$readme")"

set -- $readme_counts
if [ "$#" -ne 6 ]; then
  printf 'could not parse snapshot summary from README.md\n' >&2
  exit 1
fi

readme_snapshot_date="$1"
readme_skills="$2"
readme_hermes_skills="$3"
readme_plugin_packages="$4"
readme_enabled_plugins="$5"
readme_mcp_services="$6"

actual_skills="$(
  find -L "$agents_skills" "$codex_skills" \
    -name SKILL.md -type f ! -path "$codex_skills/.system/*" -print |
    awk -F '/' '{print $(NF - 1)}' |
    LC_ALL=C sort -u |
    wc -l |
    tr -d ' '
)"

actual_hermes_skills="$(
  find -L "$hermes_skills" -name SKILL.md -type f -print |
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
check_equal 'README snapshot date' "$snapshot_date" "$readme_snapshot_date"
check_equal 'README personal Skills' "$expected_skills" "$readme_skills"
check_equal 'README Hermes Skills' "$expected_hermes_skills" "$readme_hermes_skills"
check_equal 'README plugin packages' "$expected_plugin_packages" "$readme_plugin_packages"
check_equal 'README enabled plugins' "$expected_enabled_plugins" "$readme_enabled_plugins"
check_equal 'README MCP services' "$expected_mcp_services" "$readme_mcp_services"
check_equal 'personal Skills' "$expected_skills" "$actual_skills"
check_equal 'Hermes Skills' "$expected_hermes_skills" "$actual_hermes_skills"
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

render_hermes_skills_snapshot() {
  local build first_line install_directory install_method relative_directory
  local skill_category skill_directory skill_hash skill_name skills_json
  local upstream_revision version version_output

  version_output="$(hermes --version)"
  first_line="$(printf '%s\n' "$version_output" | awk 'NR == 1 { print; exit }')"

  if [[ "$first_line" != 'Hermes Agent v'* ]] || [[ "$first_line" != *'upstream '* ]]; then
    printf 'could not parse Hermes version output\n' >&2
    return 1
  fi

  version="${first_line#Hermes Agent v}"
  version="${version%% *}"
  build="${first_line#* (}"
  build="${build%%)*}"
  upstream_revision="${first_line##*upstream }"
  upstream_revision="${upstream_revision%% *}"
  install_directory="$(printf '%s\n' "$version_output" | awk -F ': ' '/^Install directory:/ { print $2; exit }')"
  install_method="$(printf '%s\n' "$version_output" | awk -F ': ' '/^Install method:/ { print $2; exit }')"

  if [ "${install_directory#"$HOME"/}" != "$install_directory" ]; then
    install_directory="~/${install_directory#"$HOME"/}"
  fi

  skills_json="$(
    find -L "$hermes_skills" -name SKILL.md -type f -print |
      LC_ALL=C sort |
      while IFS= read -r skill_file; do
        skill_directory="${skill_file%/SKILL.md}"
        relative_directory="${skill_directory#"$hermes_skills"/}"
        skill_name="${relative_directory##*/}"

        if [[ "$relative_directory" == */* ]]; then
          skill_category="${relative_directory%%/*}"
        else
          skill_category="root"
        fi

        skill_hash="$(hash_local_tree "$skill_directory")"
        jq -cn \
          --arg name "$skill_name" \
          --arg category "$skill_category" \
          --arg path "~/.hermes/skills/$relative_directory/SKILL.md" \
          --arg hash "$skill_hash" \
          '{
            name: $name,
            category: $category,
            skillPath: $path,
            contentHash: $hash,
            hashSource: "local-tree-sha256"
          }'
      done |
      jq -s 'sort_by(.category, .name)'
  )"

  jq -n \
    --arg version "$version" \
    --arg build "$build" \
    --arg upstream_revision "$upstream_revision" \
    --arg install_directory "$install_directory" \
    --arg install_method "$install_method" \
    --argjson skills "$skills_json" \
    '{
      schemaVersion: 1,
      generatedFrom: ["hermes --version", "~/.hermes/skills"],
      runtime: {
        command: "hermes",
        version: $version,
        build: $build,
        upstreamRevision: $upstream_revision,
        installDirectory: $install_directory,
        installMethod: $install_method,
        skillsRoot: "~/.hermes/skills"
      },
      hashSemantics: "SHA-256 of sorted lines containing each relative path and file SHA-256",
      skills: $skills
    }'
}

temporary_snapshot="$(mktemp "${TMPDIR:-/tmp}/agent-stack-skills.XXXXXX")"
temporary_hermes_snapshot="$(mktemp "${TMPDIR:-/tmp}/agent-stack-hermes-skills.XXXXXX")"
actual_plugins_snapshot="$(mktemp "${TMPDIR:-/tmp}/agent-stack-plugins-actual.XXXXXX")"
expected_plugins_snapshot="$(mktemp "${TMPDIR:-/tmp}/agent-stack-plugins-expected.XXXXXX")"
actual_plugin_config="$(mktemp "${TMPDIR:-/tmp}/agent-stack-plugin-config-actual.XXXXXX")"
expected_plugin_config="$(mktemp "${TMPDIR:-/tmp}/agent-stack-plugin-config-expected.XXXXXX")"
actual_mcp_config="$(mktemp "${TMPDIR:-/tmp}/agent-stack-mcp-config-actual.XXXXXX")"
expected_mcp_config="$(mktemp "${TMPDIR:-/tmp}/agent-stack-mcp-config-expected.XXXXXX")"
trap 'rm -f "$temporary_snapshot" "$temporary_hermes_snapshot" "$actual_plugins_snapshot" "$expected_plugins_snapshot" "$actual_plugin_config" "$expected_plugin_config" "$actual_mcp_config" "$expected_mcp_config"' EXIT
render_skills_snapshot > "$temporary_snapshot"
render_hermes_skills_snapshot > "$temporary_hermes_snapshot"

if cmp -s "$skills_snapshot" "$temporary_snapshot"; then
  printf '[ok] Skills manifest matches lock metadata and local skill trees\n'
else
  printf '[drift] Skills manifest differs from lock metadata or local skill trees\n' >&2
  failures=$((failures + 1))
fi

if cmp -s "$hermes_skills_snapshot" "$temporary_hermes_snapshot"; then
  printf '[ok] Hermes Skills manifest matches active skill trees and runtime metadata\n'
else
  printf '[drift] Hermes Skills manifest differs from active skill trees or runtime metadata\n' >&2
  failures=$((failures + 1))
fi

find "$plugin_cache" -path '*/.codex-plugin/plugin.json' -type f -print |
  LC_ALL=C sort |
  while IFS= read -r manifest; do
    relative_path="${manifest#"$plugin_cache"/}"
    plugin_source="${relative_path%%/*}"
    remaining_path="${relative_path#*/}"
    plugin_name="${remaining_path%%/*}"
    remaining_path="${remaining_path#*/}"
    plugin_version="${remaining_path%%/*}"

    jq -c \
      --arg fallback_name "$plugin_name" \
      --arg fallback_version "$plugin_version" \
      --arg source "$plugin_source" \
      '{
        name: (.name // $fallback_name),
        version: (.version // $fallback_version),
        source: $source,
        cached: true
      }' "$manifest"
  done |
  jq -s 'sort_by(.name)' > "$actual_plugins_snapshot"

jq '[.plugins[] | {name, version, source, cached}] | sort_by(.name)' \
  "$environment_snapshot" > "$expected_plugins_snapshot"

if cmp -s "$actual_plugins_snapshot" "$expected_plugins_snapshot"; then
  printf '[ok] Plugin manifest matches cached package metadata\n'
else
  printf '[drift] Plugin manifest differs from cached package metadata\n' >&2
  failures=$((failures + 1))
fi

awk '
  function emit() {
    if (name != "") {
      print name "\t" enabled
    }
  }

  /^[[:space:]]*\[/ {
    emit()
    name = ""
    enabled = "null"

    if ($0 ~ /^[[:space:]]*\[plugins\."[^"]+"\][[:space:]]*(#.*)?$/ ||
        $0 ~ /^[[:space:]]*\[plugins\.[A-Za-z0-9_-]+\][[:space:]]*(#.*)?$/) {
      section = $0
      sub(/[[:space:]]*(#.*)?$/, "", section)
      sub(/^[[:space:]]*\[plugins\./, "", section)
      sub(/\]$/, "", section)
      gsub(/^"|"$/, "", section)
      name = section
    }
    next
  }

  name != "" && /^[[:space:]]*enabled[[:space:]]*=[[:space:]]*(true|false)[[:space:]]*(#.*)?$/ {
    enabled = ($0 ~ /=[[:space:]]*true/) ? "true" : "false"
  }

  END { emit() }
' "$codex_config" | LC_ALL=C sort > "$actual_plugin_config"

jq -r '
  .plugins[]
  | select(.configured)
  | [(.name + "@" + .source), (.enabled | tostring)]
  | @tsv
' "$environment_snapshot" | LC_ALL=C sort > "$expected_plugin_config"

if cmp -s "$actual_plugin_config" "$expected_plugin_config"; then
  printf '[ok] Plugin configuration matches enabled states\n'
else
  printf '[drift] Plugin configuration differs from enabled states\n' >&2
  failures=$((failures + 1))
fi

awk '
  function emit() {
    if (name != "") {
      print name "\t" enabled
    }
  }

  /^[[:space:]]*\[/ {
    emit()
    name = ""
    enabled = "null"

    if ($0 ~ /^[[:space:]]*\[mcp_servers\."[^"]+"\][[:space:]]*(#.*)?$/ ||
        $0 ~ /^[[:space:]]*\[mcp_servers\.[A-Za-z0-9_-]+\][[:space:]]*(#.*)?$/) {
      section = $0
      sub(/[[:space:]]*(#.*)?$/, "", section)
      sub(/^[[:space:]]*\[mcp_servers\./, "", section)
      sub(/\]$/, "", section)
      gsub(/^"|"$/, "", section)
      name = section
    }
    next
  }

  name != "" && /^[[:space:]]*enabled[[:space:]]*=[[:space:]]*(true|false)[[:space:]]*(#.*)?$/ {
    enabled = ($0 ~ /=[[:space:]]*true/) ? "true" : "false"
  }

  END { emit() }
' "$codex_config" | LC_ALL=C sort > "$actual_mcp_config"

jq -r '.mcpServers[] | [.name, (.enabled | tostring)] | @tsv' \
  "$environment_snapshot" | LC_ALL=C sort > "$expected_mcp_config"

if cmp -s "$actual_mcp_config" "$expected_mcp_config"; then
  printf '[ok] MCP configuration matches enabled states\n'
else
  printf '[drift] MCP configuration differs from enabled states\n' >&2
  failures=$((failures + 1))
fi

expected_agents_hash="$(jq -r '.globalAgents.sha256' "$environment_snapshot")"
readme_agents_hash="$(awk -F '`' '/源文件 SHA-256/ {print $2; exit}' "$readme")"
actual_agents_hash="$(shasum -a 256 "$global_agents" | awk '{print $1}')"

if [ -z "$readme_agents_hash" ]; then
  printf '[drift] README does not record the global AGENTS.md SHA-256\n' >&2
  failures=$((failures + 1))
else
  check_equal 'README global AGENTS.md SHA-256' "$expected_agents_hash" "$readme_agents_hash"
fi

check_equal 'global AGENTS.md SHA-256' "$expected_agents_hash" "$actual_agents_hash"

if [ "$failures" -ne 0 ]; then
  printf 'Snapshot consistency check failed with %s issue(s).\n' "$failures" >&2
  exit 1
fi

printf 'Snapshot consistency check passed.\n'
