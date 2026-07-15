# Security Policy

## Supported versions

Only the latest release receives security fixes.

## How credentials are handled

- Your Nauta password is stored exclusively in the **macOS Keychain** (service `com.nautaconnect.macos`). It never touches UserDefaults, log files, or disk in plain text.
- The username, session tokens (`CSRFHW`, `ATTRIBUTE_UUID`), and login timestamp are stored in UserDefaults. These tokens are only valid for a single portal session.
- All portal traffic goes over HTTPS to `secure.etecsa.net:8443` using the system TLS stack. Certificate validation is **never** disabled.
- The app talks only to the ETECSA portal. No telemetry, no analytics, no third-party servers.

## Reporting a vulnerability

Please report vulnerabilities privately via GitHub Security Advisories ("Report a vulnerability" on the repository's Security tab). Do not open public issues for security problems. You should get a response within a week.

## Scope notes

- This is an unofficial client. The portal itself (`secure.etecsa.net`) is operated by ETECSA; vulnerabilities in the portal should be reported to ETECSA, not here.
- Anything that could leak Nauta credentials or session tokens (logs, crash reports, pasteboard) is considered a vulnerability in scope.
