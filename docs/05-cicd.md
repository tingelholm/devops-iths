# Automated deployment

## The chain

A push to `main` runs four scripts in order: `build.sh`, `test.sh`,
`deploy-app-service.sh`, `health-check.sh`. A step that fails stops the ones after it, which
is why the tests come before the deployment.

The build and the tests live in one file only. The deploy pipeline calls
`build-test-pipeline.yml` with `uses:`, so a pull request builds and tests without deploying.

Login to Azure uses OIDC. Instead of a password in the repo, GitHub presents a certificate
valid for a few minutes, and Azure checks it comes from my repo and the `main` branch.

A `paths-ignore` filter skips the deployment when a push only changes `.md` files or `docs/`.
It sits only on the deploy pipeline: a check skipped in a pull request would leave that pull
request waiting forever.

## The rollback I tried

I broke `/health` on purpose, making it answer `503` when `WEBSITE_SITE_NAME` exists. Azure
always sets that variable and the tests do not, so the tests passed while the app was broken.

The smoke test caught it:

```
Attempt 1 of 30: status 200, but without the expected text. Waiting 5 s...
Attempt 9 of 30: status 503. Waiting 5 s...
```

The first attempts got `200` from the old version, still running while the new one started.
Checking only for `200` would have gone green against a version I had not deployed.

Red run: https://github.com/tingelholm/devops-iths/actions/runs/41820828502

Then two fixes, in order. **Rollback:** `gh run rerun` on the last green run, and the app
answered again with the previous commit. Nothing in the code changed. **Revert:**
`git revert --no-edit HEAD`, because the broken commit was still on `main` and the next push
would have deployed it again.

Re-run: https://github.com/tingelholm/devops-iths/actions/runs/41812825554

A rollback and a revert solve different problems. The rollback gets users a working app in
minutes but leaves the bug in the repo. The revert removes the bug but has to go through the
whole pipeline. Operations first, then the code.
