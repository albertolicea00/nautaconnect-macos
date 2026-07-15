# Contributing to NautaConnect for macOS

Thanks for helping! This is a small, focused project — the bar for a good PR is low, the bar for keeping the app tiny is high.

## Ground rules

- **All code, comments and commit messages are in English.** UI strings are bilingual (ES/EN) through `L10n` — never hardcode user-facing text.
- **Zero dependencies.** AppKit, Foundation and Security only. PRs adding third-party packages will be declined unless there is a truly exceptional reason.
- Target macOS 12+. Gate newer APIs with `if #available`.
- Keep [SPECS.md](SPECS.md) in sync: any change to portal endpoints, parameters or parsing must update it in the same PR.
- Never commit real credentials or raw portal captures — fixtures must be anonymized (synthetic tokens/IPs).

## Dev setup

```sh
git clone <your fork>
cd nautaconnect-macos
swift build          # needs Swift 5.7+ (Xcode 14+ or CLT)
swift test
./scripts/build-app.sh && open dist/NautaConnect.app
```

No Xcode project needed — it is a plain SwiftPM package (you can still `open Package.swift` in Xcode if you prefer).

## Commit style — Conventional Commits

```
<type>: <short imperative summary, ≤ 50 chars>

Optional body explaining *why*, wrapped at 72 chars.
```

Types used here: `feat`, `fix`, `docs`, `test`, `chore`, `ci`, `refactor`.

Examples:

```
feat: show low-time warning at 10 minutes
fix: keep session when logout returns FAILURE
docs: document EtecsaQueryServlet quirks
```

One logical change per commit. No `Co-Authored-By` or tool-attribution trailers.

## Pull requests

1. Fork, branch from `main` (`feat/...`, `fix/...`).
2. Make sure `swift build` and `swift test` pass.
3. If you touched the portal protocol and could verify it on a real ETECSA network, say so in the PR description — it is the only way to truly test it.
4. Fill in the PR template. Small PRs get reviewed fast.

## Reporting bugs

Use the issue templates. For anything involving credentials or session leakage, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.
