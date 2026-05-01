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

---

### To Do Ideas
* [x] Figure out how to dynamically get the user id so no config needed either?
* [ ] --selfish --stage OR --selfish --main opens the prs filtered to your user with at=stage or at=main added to the url
* [ ] Same as above but with --prs --stage or --prs --main (Would probably have to update the current --main and --stage flags to be --prmain and --prstage)
