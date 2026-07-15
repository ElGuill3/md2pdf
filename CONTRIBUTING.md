# Contribute one verifiable outcome

Keep each contribution focused on one behavior, its tests, and the documentation
users need for that behavior. Do not split implementation, tests, and docs into
unrelated review units.

## Before Changing Code

1. State the user-visible outcome and rollback boundary.
2. Identify the launcher, Lua policy, Typst presentation, or packaging layer that
   owns the behavior.
3. Add or update the smallest real-tool test that proves the outcome.

## Verify The Work Unit

Install the external development tools listed in
[Compatibility](docs/compatibility.md), then run:

```sh
./tests/run.sh
sh -n md2pdf install.sh uninstall.sh tests/run.sh
git diff --check
```

The suite must remain usable outside a Git worktree. Installation tests must use
temporary HOME, XDG, or prefix paths and must never write to the real user
account. Remote tests must use the provided mock rather than a live service.

## Keep Reviews Focused

- Keep tests with the behavior they verify.
- Keep public docs with user-visible changes.
- Preserve executable modes for launchers and test runners.
- Record exact commands and results.
- Name the files and behavior that can be reverted independently.
- Do not commit generated PDFs unless they are intentional review fixtures.

By contributing, you agree that your contribution is licensed under the
[MIT License](LICENSE).
