
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
     local proj dest branch base_url out url
     proj=$(git -C . remote get-url origin 2>/dev/null \
        | sed -E 's#(git@|https://)bitbucket\.org[:/]##' \
        | sed -E 's#\.git$##')
    
    case "${1-}" in
        --stage|--main)
          dest="${1#--}"
          branch="$(_bitchild_branch)" || return 1
          base_url="$(_bitchild_base_url)" || return 1
    
          xdg-open "$base_url/pull-requests/new?source=$branch&dest=$dest"
          return
          ;;

        --branch)
          branch="$(_bitchild_branch)" || return 1
          base_url="$(_bitchild_base_url)" || return 1

          xdg-open "$base_url/branch/$branch"
          return
          ;;

       --pipelines)
         base_url="$(_bitchild_base_url)" || return 1

         xdg-open "$base_url/pipelines"
         return
         ;;

       --prs)
         base_url="$(_bitchild_base_url)" || return 1

         xdg-open "$base_url/pull-requests"
         return
         ;;

       --selfish)
          base_url="$(_bitchild_base_url)" || return 1
          uuid="$(_bitchild_user_uuid)" || return 1
          uuid_encoded="${uuid//\{/%7B}"
          uuid_encoded="${uuid_encoded//\}/%7D}"

          xdg-open "$base_url/pull-requests?state=OPEN%2BDRAFT&author=$uuid_encoded"
         return
         ;;

       --help|-h|"")
         cat <<'EOF'
Usage: bitbaby [option]

Options:
 --main         Open a PR from the current branch to main
 --stage        Open a PR from the current branch to stage
 --branch       Open current branch in bitbucket
 --prs          Open the pull requests page
 --selfish      Open the pull requests page filtered with just your user
 --pipelines    Open pipelines page
 -h, --help     Show this help message

Examples:
 bitbaby --main
 bitbaby --branch
EOF
         return
         ;;
    esac
       
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

