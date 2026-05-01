Usage: bitbaby [option]

Options:
         --main         Open a PR from the current branch to main
         --stage        Open a PR from the current branch to stage
         --branch       Open current branch in bitbucket
         --selfish      Open the pull requests page filtered with just your user
         --prs          Open the pull repquests page
         --pipelines    Open pipelines page
         -h, --help     Show this help message

Examples:
         bitbaby --main
         bitbaby --branch

---

### To Do Ideas
* [ ] Figure out how to dynamically get the user id so no config needed either?
* [ ] --selfish --stage OR --selfish --main opens the prs filtered to your user with at=stage or at=main added to the url
* [ ] Same as above but with --prs --stage or --prs --main (Would probably have to update the current --main and --stage flags to be --prmain and --prstage)
