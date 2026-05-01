
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
  local proj dest branch base_url out url path="" query="" uuid uuid_encoded page="" used_filter=0

  proj=$(git -C . remote get-url origin 2>/dev/null \
    | sed -E 's#(git@|https://)bitbucket\.org[:/]##' \
    | sed -E 's#\.git$##')

  base_url="$(_bitchild_base_url)" || return 1
  branch="$(_bitchild_branch | sed 's#/#%2F#g')" || return 1

  while [ $# -gt 0 ]; do
    case "$1" in
      #Making PRs
      --prmain)
        page="newPR"
        path="/pull-requests/new"
        query="source=$branch&dest=main"
        ;;

      --prstage)
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

        query="${query:+$query}&state=OPEN%2BDRAFT&author=$uuid_encoded"
        ;;

      --main)
        used_filter=1
        query="${query:+$query}&at=main"
        ;;

      --stage)
        used_filter=1
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
        echo "Unknown option: $1"
        echo "Run 'bitbaby --help for usage'"
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
    echo "Filters like --selfish can only be used with --prs"
    return 1
  fi

  #if still nothing, bail
  if [ -z "$path" ]; then
    echo "No action specified. Try --help"
    return 1
  fi

  #build final url
  url="$base_url$path"
  [ -n "$query" ] && url="$url?$query"

  xdg-open "$url"
       
    # local out url
  out="$(
    docker run -i --rm \
      -e BROWSER=/bin/true \
      -e NO_COLOR=1 \
      -e TERM=dumb \
      -v "$HOME/.bitbucket-rest-cli-config.json:/root/.bitbucket-rest-cli-config.json" \
      -v "$(pwd):/workdir" -w /workdir \
      ghcr.io/bb-cli/bb-cli \
      ${proj:+--project "$proj"} browse "$@" \
      2>&1
  )"
  # strip ANSI, keep only URLs, print last one
  url="$(printf '%s\n' "$out" \
    | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g' \
    | grep -Eo 'https?://[^[:space:]]+' \
    | tail -1)"
  [ -n "$url" ] && printf '%s\n' "$url" || printf '%s\n' "$out"
}

