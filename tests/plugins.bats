load helpers

# The repo is a plugin marketplace (.claude-plugin/marketplace.json) for Claude
# Code and Codex. These checks keep the manifests and skill folders in step.

MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

@test "marketplace manifest is valid JSON with a name" {
  run jq -e '.name and (.plugins | length > 0)' "$MARKETPLACE"
  [ "$status" -eq 0 ]
}

@test "every marketplace plugin has a matching plugin.json" {
  local name src
  while IFS=$'\t' read -r name src; do
    [ -f "$REPO_ROOT/$src/.claude-plugin/plugin.json" ]
    [ "$(jq -r .name "$REPO_ROOT/$src/.claude-plugin/plugin.json")" = "$name" ]
  done < <(jq -r '.plugins[] | "\(.name)\t\(.source)"' "$MARKETPLACE")
}

@test "every listed skill has a SKILL.md named after its folder" {
  local src skill dir
  for src in $(jq -r '.plugins[].source' "$MARKETPLACE"); do
    for skill in $(jq -r '.skills[]?' "$REPO_ROOT/$src/.claude-plugin/plugin.json"); do
      dir="$REPO_ROOT/$src/$skill"
      [ -f "$dir/SKILL.md" ]
      grep -qx "name: $(basename "$dir")" "$dir/SKILL.md"
      grep -q '^description: Use when' "$dir/SKILL.md"
    done
  done
}

@test "every skill folder in a plugin is listed in its plugin.json" {
  local src dir
  for src in $(jq -r '.plugins[].source' "$MARKETPLACE"); do
    for dir in "$REPO_ROOT/$src"/skills/*/; do
      [ -d "$dir" ] || continue
      jq -e --arg s "./skills/$(basename "$dir")" '.skills | index($s)' \
        "$REPO_ROOT/$src/.claude-plugin/plugin.json" >/dev/null
    done
  done
}

@test "Claude settings and the Codex reference config enable this marketplace" {
  local mp
  mp="$(jq -r .name "$MARKETPLACE")"
  jq -e --arg m "$mp" '.extraKnownMarketplaces[$m].source.repo == "marlonbarcarol/dotfiles"' \
    "$REPO_ROOT/home/.claude/settings.json" >/dev/null
  for name in $(jq -r '.plugins[].name' "$MARKETPLACE"); do
    jq -e --arg p "$name@$mp" '.enabledPlugins[$p] == true' "$REPO_ROOT/home/.claude/settings.json" >/dev/null
    grep -qF "[plugins.\"$name@$mp\"]" "$REPO_ROOT/codex/config.toml"
  done
  grep -qF "[marketplaces.$mp]" "$REPO_ROOT/codex/config.toml"
}
