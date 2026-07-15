# NautaConnect for macOS — agent rules

- All code, comments, and commit messages are written in English.
- User-facing UI strings are bilingual (Spanish and English) via `L10n`; never hardcode UI text.
- Commits follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `test:`, `ci:`). Subject ≤ 50 chars.
- Do not add `Co-Authored-By` trailers or any AI attribution to commits.
- Zero third-party dependencies. AppKit + Foundation + Security only. Keep the app tiny.
- The ETECSA portal protocol is documented in [SPECS.md](SPECS.md); any change to endpoints or parsing must update it.
- Never commit real Nauta credentials, tokens, or captures containing them. Test fixtures must be anonymized.
- Passwords go to the macOS Keychain only — never UserDefaults, never logs.
