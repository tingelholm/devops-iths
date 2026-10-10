# Branching strategy

## Chosen strategy
I will use short-lived branches as a solo developer, without long gaps between PRs. The pipeline runs on every change to main, so main has to be updated often.
## Branch protection
Restrict deletions, especially  the main branch.  require pull requests before merging, nothing gets added into main without review. and block force pushes that overwrites branch history. 
## Tagging and versioning 
v0.1.0 is the first tagged version. The repo has a branching strategy and a pull request template, but no application yet. The 0 in front means everything can still change. The next version follows from the commit messages: fix: v.0.1.1, feat: v0.2.0, docs: changes will not affect the number.
