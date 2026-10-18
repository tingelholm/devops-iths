# CI pipeline

## What the scripts do

### build.sh

Starts with `set -euo pipefail`, which sets up error handling:

- `-e` stops the build at the first error
- `-u` reacts to variables that don't exist, e.g. a typo in a variable name
- `-o pipefail` catches errors earlier in a `|` chain, not just the last step

It then checks whether ShellCheck is installed, dumping the extra output to `/dev/null` since only the exit code matters. If it is installed, ShellCheck runs on every script in `scripts/`. If not, the script prints a message and skips the step, since the pipeline runs it anyway.

Finally it loops over README.md and .gitignore in the loop variable `file` and checks that each one exists. If one is missing it prints Missing and exits with code 1. Otherwise it ends with Build OK.

### test.sh

Same error handling as build.sh, but without `-e`. That is on purpose, so all four checks get to run. With `-e` the script would stop at the first error and only report one problem per run.

It runs four checks against the repo:

- README.md exists
- .gitignore exists
- build.sh is executable
- README.md has a heading

The checks are run by the function `check()`, which takes two things: a label and a command. It runs the command, prints ok or FAIL with the label, and sets `fail=1` if it went badly. The variable is never set back to 0, so a single failure fails the whole run.

At the end `exit "$fail"` hands a single number to the pipeline: 0 if everything passed, 1 if not. That number is what the pipeline reads.

## The failure the pipeline caught

https://github.com/tingelholm/devops-iths/actions/runs/39117307800

I removed .gitignore on purpose, which made test.sh fail with `Error: Process completed with exit code 1`. In the run, the step **Run the Test Script** is the one that went red, and the log shows `FAIL  .gitignore exists` while the other three checks still say ok. That is `-e` being left out working as intended: one run gives the full list instead of just the first problem.

The pull request then could not be merged, because Require status checks to pass is set in the repo's ruleset. Without that rule GitHub would have shown the red check but let the merge through anyway. That is the difference between information and a gate.

### Is the gate worth its cost?

This one runs in about seven seconds, so it is close to free and clearly worth keeping. The question is not always that easy. A gate that takes 40 minutes and catches one error a month slows down roughly 30 successful merges for every error it finds. The question to ask about any gate: how often does it catch something, and what does it cost when it doesn't.

## AI review

Prompt to Gemini, no context given: "Give me a GitHub Actions workflow that builds and tests a repo with a bash script in scripts/"

```yaml
name: Build and Test

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Install ShellCheck
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck

      - name: Make scripts executable
        run: chmod +x scripts/*.sh

      - name: Lint bash scripts
        run: shellcheck scripts/*.sh

      - name: Run script
        run: ./scripts/your-script.sh
```

What I reacted to:

- **Install ShellCheck** is not needed, it is already on GitHub's runner. Two apt runs per pipeline run for nothing.
- **Make scripts executable** is unnecessary. It sets the permission on the runner every run instead of fixing it in the repo. Anyone cloning the repo gets the wrong permissions, and the pipeline still goes green, so the problem is never discovered.
- **ShellCheck runs as its own step in YAML** instead of inside build.sh. That means the same check cannot be run locally, only by pushing. The logic belongs in the scripts, the pipeline should just call them.

My general thoughts: the suggestion was well-formatted valid YAML that tested nothing and masked a real error, since the chmod step would have hidden a missing permission in the repo. It looks very correct, which is exactly why it has to be run and reviewed before it is trusted.
