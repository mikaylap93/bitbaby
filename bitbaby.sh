
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "_BCH_UUID=" > "$CONFIG_FILE"
fi

source "$CONFIG_FILE"

_bitchild_base_url() {
    local proj
    
    proj=$(git -C . remote get-url origin 2>/dev/null \
          | sed -E 's#(git@|https://)bitbucket\.org[:/]##' \
          | sed -E 's#\.git$##')

    [ -n "$proj" ] || return 1

    printf 'https://bitbucket.org/%s\n' "$proj"
}

_bitchild_branch() {
  git rev-parse --abbrev-ref HEAD
}

_bitchild_user_uuid() {
    echo "$_BCH_UUID"
}

bitbaby () {
  local proj dest branch base_url out url path="" query="" uuid uuid_encoded page="" used_filter=0 used_main=0 used_stage=0

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "You're not in a repo dumb ass!"
    return 1
  fi

  proj=$(git -C . remote get-url origin 2>/dev/null \
    | sed -E 's#(git@|https://)bitbucket\.org[:/]##' \
    | sed -E 's#\.git$##')

  base_url="$(_bitchild_base_url)" || return 1
  branch="$(_bitchild_branch | sed 's#/#%2F#g')" || return 1

  while [ $# -gt 0 ]; do
    case "$1" in
      #Making PRs
      --prmain|--mainpr)
        page="newPR"
        path="/pull-requests/new"
        query="source=$branch&dest=main"
        ;;

      --prstage|--stagepr)
        page="newPR"
        path="/pull-requests/new"
        query="source=$branch&dest=stage"
        ;;

      #Navigation
      --branch)
        page="branch"
        path="/branch/$branch"
        ;;

      --pipelines)
        page="pipelines"
        path="/pipelines"
        ;;

      --prs)
        page="prs"
        path="/pull-requests"
        ;;

      #Filters
      --selfish)
        used_filter=1
        uuid="$(_bitchild_user_uuid)" || return 1
        uuid_encoded="${uuid//\{/%7B}"
        uuid_encoded="${uuid_encoded//\}/%7D}"

        query="${query:+$query}&author=$uuid_encoded"
        ;;

      --main)
        used_filter=1
        used_main=1
        query="${query:+$query}&at=main"
        ;;

      --stage)
        used_filter=1
        used_stage=1
        query="${query:+$query}&at=stage"
        ;;

      #Help
      --help|-h|"")
        cat <<'EOF'
Usage: bitbaby [option]

Options:
  Navigation:
    --branch       Open current branch in Bitbucket
    --prs          Open the pull requests page
    --pipelines    Open pipelines page

  PR creation:
    --prmain       Open a PR from the current branch to main
    --prstage      Open a PR from the current branch to stage

  Filters (can combine with --prs and eachother or be used individually):
    --selfish      Open the pull requests page filtered with just your user
    --stage        Open the pull requests page filtered by stage as the target branch
    --main         Open the pull requests page filtered by main as the target branch

  Other:
    -h, --help     Show this help message

Examples:
  bitbaby --prmain
  bitbaby --branch
  bitbaby --selfish --stage
EOF
        return
        ;;

      *)
        echo "I have no idea what you mean by $1"
        echo "Maybe try 'bitbaby --help' so you can learn how to talk to me properly"
        return 1
        ;;
    esac
    shift
  done

  #if only filters were given, default to PRs page
  if [ -z "$page" ] && [ "$used_filter" -eq 1 ]; then
    page="prs"
    path="/pull-requests"
  fi

  #block invalid combos
  if [ "$used_filter" -eq 1 ] && [ "$page" != "prs" ]; then
    echo "Wooooooooow... Filters like --selfish can only be used with --prs. The fact you thought those went together is almost comical."
    return 1
  fi

  if [ "$used_filter" -eq 1 ] && [ "$page" == "prs" ]; then
    query="${query:+$query}&state=OPEN%2BDRAFT"
  fi

  #if still nothing, bail
  if [ -z "$path" ]; then
    echo "Bruh. You gotta tell me what to do... Try --help and then maybe you'll figure it out."
    return 1
  fi

  if [ "$used_stage" -eq 1 ] && [ "$used_main" -eq 1 ]; then
    echo "You moron! You can't use --main and --stage together! Tell me how you think I can filter by both main and stage as the target branch. You can't can ya?"
    return 1
  fi

  #build final url
  url="$base_url$path"
  [ -n "$query" ] && url="$url?$query"

  xdg-open "$url"
}

