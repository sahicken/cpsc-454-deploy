Submodule workflow and helper script

Local update workflow:

```bash
# update remote tracking for submodules
git submodule update --init --remote --recursive
# stage and commit submodule updates
git add frontend backend
git commit -m "Update submodules to latest"
git push origin HEAD
```

Helper script: `scripts/update-submodules.sh` — run locally or from CI with a bot account.

CI idea:
- Add a Cloud Build trigger or GitHub Action that runs on a schedule or when upstream releases change; it updates submodules and opens a PR with the changes.

Notes:
- Keep submodules locked to specific commits in `frontend` and `backend` to guarantee reproducible builds.
- Update process should run in a feature branch and require tests to pass before merging into `staging`.
