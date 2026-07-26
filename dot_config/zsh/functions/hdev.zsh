function hdev() {
  local agent_command
  case ${1:-} in
    claude)
      agent_command=claude
      ;;
    codex)
      agent_command=codex
      ;;
    *)
      print -u2 -- "使い方: hdev <claude|codex>"
      return 2
      ;;
  esac

  local required_command
  for required_command in herdr hunk jq "$agent_command"; do
    if (( ! $+commands[$required_command] )) && (( ! $+functions[$required_command] )); then
      print -u2 -- "必要なコマンドが見つかりません: $required_command"
      return 1
    fi
  done

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 -- "Gitリポジトリ内で実行してください"
    return 1
  }

  local server_status
  server_status=$(herdr status server 2>/dev/null)
  if [[ $server_status != *"status: running"* ]]; then
    herdr server >/dev/null 2>&1 &!

    local attempt
    for attempt in {1..50}; do
      server_status=$(herdr status server 2>/dev/null)
      [[ $server_status == *"status: running"* ]] && break
      sleep 0.1
    done

    if [[ $server_status != *"status: running"* ]]; then
      print -u2 -- "Herdrサーバーを起動できませんでした"
      return 1
    fi
  fi

  local workspace_id="" root_pane_id pane_list
  local workspace_list workspace_json tab_json workspace_label

  if [[ ${HERDR_ENV:-0} == 1 ]]; then
    if [[ -z ${HERDR_WORKSPACE_ID:-} || -z ${HERDR_TAB_ID:-} || -z ${HERDR_PANE_ID:-} ]]; then
      print -u2 -- "現在のHerdrペインを特定できません"
      return 1
    fi

    workspace_id=$HERDR_WORKSPACE_ID
    root_pane_id=$HERDR_PANE_ID
    pane_list=$(herdr pane list --workspace "$workspace_id") || return 1

    if ! jq -e \
      --arg tab "$HERDR_TAB_ID" \
      --arg pane "$root_pane_id" \
      '[.result.panes[]? | select(.tab_id == $tab)] as $panes
       | ($panes | length) == 1 and $panes[0].pane_id == $pane' \
      >/dev/null <<< "$pane_list"; then
      print -u2 -- "新規の空Tabで実行してください"
      return 1
    fi
  else
    workspace_list=$(herdr workspace list) || return 1

    local candidate_workspace_id
    for candidate_workspace_id in ${(f)"$(jq -r '.result.workspaces[]?.workspace_id' <<< "$workspace_list")"}; do
      pane_list=$(herdr pane list --workspace "$candidate_workspace_id") || continue
      if jq -e --arg cwd "$repo_root" \
        '.result.panes[]? | select(.cwd == $cwd)' \
        >/dev/null <<< "$pane_list"; then
        workspace_id=$candidate_workspace_id
        break
      fi
    done

    if [[ -n $workspace_id ]]; then
      tab_json=$(herdr tab create \
        --workspace "$workspace_id" \
        --cwd "$repo_root" \
        --label "$agent_command" \
        --focus) || return 1
      root_pane_id=$(jq -er '.result.root_pane.pane_id' <<< "$tab_json") || return 1
    else
      workspace_label=${repo_root:t}
      workspace_json=$(herdr workspace create \
        --cwd "$repo_root" \
        --label "$workspace_label" \
        --focus) || return 1
      workspace_id=$(jq -er '.result.workspace.workspace_id' <<< "$workspace_json") || return 1
      root_pane_id=$(jq -er '.result.root_pane.pane_id' <<< "$workspace_json") || return 1
    fi
  fi

  local bottom_pane_json hunk_pane_json bottom_pane_id hunk_pane_id

  bottom_pane_json=$(herdr pane split "$root_pane_id" \
    --direction down \
    --ratio 0.7) || return 1
  bottom_pane_id=$(jq -er '.result.pane.pane_id' <<< "$bottom_pane_json") || return 1

  hunk_pane_json=$(herdr pane split "$root_pane_id" \
    --direction right \
    --ratio 0.5) || return 1
  hunk_pane_id=$(jq -er '.result.pane.pane_id' <<< "$hunk_pane_json") || return 1

  herdr pane rename "$root_pane_id" "$agent_command" >/dev/null || return 1
  herdr pane rename "$hunk_pane_id" review >/dev/null || return 1
  herdr pane rename "$bottom_pane_id" shell >/dev/null || return 1

  herdr pane run "$hunk_pane_id" "hunk diff --watch" >/dev/null || return 1
  herdr pane run "$root_pane_id" "$agent_command" >/dev/null || return 1

  [[ ${HERDR_ENV:-0} == 1 ]] && return 0
  herdr
}
