#!/usr/bin/env python3
"""Read-only runtime, public version and README checks; never echo CLI output."""

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
HOME = Path.home()
EXCLUDED = {".git", ".system", "hermes-agent", "optional-skills", "node_modules", "venv", ".venv", "plugins"}
VERSION = re.compile(r"(?:^|[^\d])(\d+\.\d+(?:\.[0-9A-Za-z]+)*(?:-[0-9A-Za-z.-]+)?)")


def check(condition, label):
    if not condition:
        raise ValueError(label)


def load(path):
    return json.loads(path.read_text())


def run(args):
    try:
        result = subprocess.run(["rtk", "proxy", *args], cwd=ROOT, capture_output=True, text=True, timeout=20)
        return result.returncode, result.stdout + "\n" + result.stderr
    except subprocess.TimeoutExpired:
        return 124, ""


def tree_hash(directory):
    files = sorted(Path(base) / name for base, _, names in os.walk(directory, followlinks=True) for name in names if (Path(base) / name).is_file())
    lines = "".join(hashlib.sha256(p.read_bytes()).hexdigest() + "  " + p.relative_to(directory).as_posix() + "\n" for p in files)
    return hashlib.sha256(lines.encode()).hexdigest()


def active_skills(roots):
    found = {}
    for display_root in roots:
        base = Path(display_root).expanduser()
        check(base.is_dir(), "missing active Skills root")
        paths = []
        for directory, dirs, names in os.walk(base, followlinks=True):
            dirs[:] = sorted(d for d in dirs if d not in EXCLUDED)
            if "SKILL.md" in names:
                paths.append(Path(directory) / "SKILL.md")
        for p in sorted(paths):
            relative = p.parent.relative_to(base)
            found.setdefault(p.parent.name, {
                "name": p.parent.name,
                "category": relative.parts[0] if len(relative.parts) > 1 else "root",
                "skillPath": "~/" + p.relative_to(HOME).as_posix(),
                "contentHash": tree_hash(p.parent),
                "hashSource": "local-tree-sha256",
            })
    return sorted(found.values(), key=lambda s: s["name"])


def main():
    environment = load(ROOT / "snapshot/environment.json")
    catalog = load(ROOT / "snapshot/catalog.json")
    readme = (ROOT / "README.md").read_text()
    outputs = {}
    for expected in environment["tools"]:
        command = expected["command"]
        check(re.fullmatch(r"[A-Za-z0-9._-]+", command), "invalid command name")
        code, output = run(["zsh", "-lc", "command -v " + command])
        executable = output.strip()
        check(code == 0 and executable.startswith("/") and "\n" not in executable, "missing executable: " + command)
        code, output = run([executable, "--version"])
        match = VERSION.search(output)
        version = match[1] if code == 0 and match else None
        actual = {"command": command, "version": version, "status": "ok" if version else "version-read-failed"}
        if version is None:
            actual["exitCode"] = code
        check(actual == expected, "tool version/status drift: " + command)
        if command in {"grok", "hermes"}:
            outputs[command] = output
    print("[ok] Tool versions and failure states match current login-shell executables")

    for runtime in environment["agentRuntimes"]:
        command = runtime["command"]
        if command == "codex" or "skillsSnapshot" not in runtime:
            continue
        snapshot = load(ROOT / runtime["skillsSnapshot"])
        check(snapshot["schemaVersion"] == 1, "invalid runtime snapshot schema")
        check(snapshot["generatedFrom"] == [command + " --version", *runtime["skillsRoots"]], "runtime provenance drift")
        metadata = {key: runtime[key] for key in ("command", "version", "revision", "installDirectory", "installMethod")}
        metadata["skillsRoot"] = runtime["skillsRoots"][0]
        check(snapshot["runtime"] == metadata, "runtime metadata mismatch: " + command)
        actual = active_skills(runtime["skillsRoots"])
        check(snapshot["skills"] == actual, "active Skills names/paths/hashes drift: " + command)
        check(len(actual) == environment["counts"][command + "Skills"], "active Skills count drift: " + command)
        if command == "hermes":
            match = re.search(r"^Hermes Agent v([0-9.]+) \([0-9.]+\) · upstream ([0-9a-f]+)$", outputs[command], re.M)
            check(match and (match[1], match[2]) == (runtime["version"], runtime["revision"]), "Hermes live revision drift")
            directory = re.search(r"^Install directory: (.+)$", outputs[command], re.M)
            method = re.search(r"^Install method: (.+)$", outputs[command], re.M)
            check(directory and str(Path(runtime["installDirectory"]).expanduser()) == directory[1], "Hermes install directory drift")
            check(method and runtime["installMethod"] == method[1], "Hermes install method drift")
        print("[ok] " + command + " active Skills, exclusions, metadata and tree hashes")

    counts = environment["counts"]
    summary = "| " + " | ".join(str(v) for v in [environment["snapshotDate"], counts["codexPersonalSkills"], counts["grokSkills"], counts["pluginPackages"], counts["enabledPlugins"], counts["mcpServices"], counts["hermesSkills"]]) + " |"
    check(summary in readme, "README summary mismatch")
    versions = {t["command"]: t["version"] if t["version"] is not None else "无法读取（退出码 " + str(t["exitCode"]) + "）" for t in environment["tools"]}
    for group in catalog["toolGroups"]:
        row = "| " + group["category"] + " | " + group["display"] + " | " + " / ".join(versions[c] for c in group["commands"]) + " |"
        check(row in readme, "README tool row mismatch")
    plugin_catalog = {p["name"]: p for p in catalog["plugins"]}
    enabled_section = readme.split("### 配置中显式启用\n", 1)[1].split("### 本机缓存的其他插件\n", 1)[0]
    cached_section = readme.split("### 本机缓存的其他插件\n", 1)[1].split("## MCP 服务\n", 1)[0]
    for plugin in environment["plugins"]:
        entry = plugin_catalog[plugin["name"]]
        row = "| " + entry.get("display", "`" + plugin["name"] + "`") + " | " + plugin["version"] + " | " + entry["capability"] + " |"
        check(row in (enabled_section if plugin["enabled"] else cached_section), "README plugin row mismatch")
    global_text = (HOME / ".codex/AGENTS.md").read_text()
    check("````md\n" + global_text.rstrip() + "\n````" in readme, "README global rules copy mismatch")
    check(hashlib.sha256(global_text.encode()).hexdigest() == environment["globalAgents"]["sha256"], "global rules hash mismatch")
    print("[ok] README counts, tool/plugin rows and complete global rules copy")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError) as error:
        # Exception details may contain local paths; labels above carry no secrets.
        print("[drift] " + (str(error) if isinstance(error, ValueError) else type(error).__name__), file=sys.stderr)
        sys.exit(1)
