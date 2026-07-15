# NautaConnect for macOS — Technical Specifications

Native menu bar client for the ETECSA Nauta captive portal (`https://secure.etecsa.net:8443/`). This document is the engineering reference: architecture, portal protocol, build, storage, i18n and testing.

## 1. Requirements

- macOS 12.0+ (Monterey). Launch-at-login uses `SMAppService` and is only offered on macOS 13+.
- Build: Swift 5.7+ toolchain (Xcode 14+ or Command Line Tools).
- Runtime dependencies: none. AppKit + Foundation + Security only.

## 2. Architecture

SwiftPM package with three targets:

| Target | Kind | Contents |
|---|---|---|
| `NautaConnectCore` | library | Portal protocol client, HTML parsing, session persistence, Keychain, localization table. No AppKit. |
| `NautaConnect` | executable | AppKit UI: `NSStatusItem`, menu, settings window, menu bar icon drawing. |
| `NautaConnectCoreTests` | tests | Parser unit tests against anonymized portal HTML fixtures. |

```
Sources/
  NautaConnectCore/     PortalParser, PortalClient, SessionStore, KeychainHelper, L10n
  NautaConnect/         main, AppDelegate, StatusItemController, MenuBarIcon, SettingsWindowController
Tests/
  NautaConnectCoreTests/  PortalParserTests + Fixtures/
scripts/                build-app.sh (bundles .app), make-icons.sh (SVG → .icns)
assets/                 icon.svg, app-icon-macos.svg, AppIcon.icns
```

The app is an `LSUIElement` (no Dock icon). All UI hangs off an `NSStatusItem`; when connected, the item title shows the elapsed session time (`H:MM:SS`) updated every second.

## 3. ETECSA portal protocol

Reverse-engineered from the official portal pages. **It can only be exercised on a real ETECSA network (Nauta WiFi / Nauta Hogar); there is no public sandbox.** Everything below must be re-verified on-network before a release.

Base URL: `https://secure.etecsa.net:8443`

### 3.1 Fetch login page

```
GET /
```

- Captures the `JSESSIONID` cookie (handled by `URLSession`).
- Parses from the HTML (see `PortalParser`):
  - `CSRFHW` — anti-CSRF token, hidden input, regex `name=["']CSRFHW["'][^>]*?value=["']([^"']*)["']`
  - `wlanuserip` — client IP as seen by the AC, same hidden-input pattern
  - `loggerId` — request logger id, same hidden-input pattern

### 3.2 Login

```
POST //LoginServlet          ← the double slash is intentional; it is what the portal form uses
Content-Type: application/x-www-form-urlencoded
```

| Field | Value |
|---|---|
| `wlanuserip` | from login page |
| `wlanacname` | `""` |
| `wlanmac` | `""` |
| `firsturl` | `notFound.jsp` |
| `ssid` | `""` |
| `usertype` | `""` |
| `gotopage` | `/nauta_etecsa/LoginURL/pc_login.jsp` |
| `successpage` | `/nauta_etecsa/OnlineURL/pc_index.jsp` |
| `loggerId` | `<loggerId>+<username>` (portal appends the username with a `+`) |
| `lang` | `es_ES` |
| `username` | full account, e.g. `user@nauta.com.cu` |
| `password` | account password |
| `CSRFHW` | from login page |

**Success**: response body contains `ATTRIBUTE_UUID=<hex>` → captured with regex `ATTRIBUTE_UUID=([A-Fa-f0-9]+)`. This UUID is the session handle required to log out.

**Failure**: response body contains a JavaScript `alert("...")` with the reason (wrong credentials, no time left, user already connected…) → captured with regex `alert\s*\(\s*["']([^"']+)["']` and surfaced verbatim in the UI.

### 3.3 Logout

```
GET /LogoutServlet?ATTRIBUTE_UUID=<uuid>&CSRFHW=<token>&wlanuserip=<ip>&username=<user>&remove=1
```

Success ⇔ response body contains `SUCCESS` (the portal answers `logoutcallback('SUCCESS')`). Anything else keeps the session marked as active so the user can retry — silently dropping the state would leak paid time.

### 3.4 Remaining time

```
POST /EtecsaQueryServlet
op=getLeftTime&ATTRIBUTE_UUID=<uuid>&CSRFHW=<token>&wlanuserip=<ip>&username=<user>
```

Response body is (or contains) the remaining time as `HH:MM:SS` (hours may exceed 2 digits) → regex `(\d{1,3}:\d{2}:\d{2})`.

### 3.5 Session persistence

`{username, CSRFHW, wlanuserip, ATTRIBUTE_UUID, loginDate}` is persisted (UserDefaults, JSON-encoded) immediately after a successful login, so **logout survives app restarts and crashes** — the core promise of the app.

### 3.6 Network detection

Before connecting, the client probes `GET /` with a short timeout. Unreachable portal ⇒ "Not on a Nauta network" state; connect is disabled.

## 4. Storage & security

| Data | Where |
|---|---|
| Password | macOS Keychain, service `com.nautaconnect.macos`, account = username |
| Username, language, session tokens | UserDefaults (`com.nautaconnect.macos` domain) |

TLS certificate validation is never disabled. See [SECURITY.md](SECURITY.md).

## 5. Localization

UI is bilingual Spanish/English via the in-code `L10n` table (`NautaConnectCore/L10n.swift`). Default language follows the system (`es*` → Spanish, otherwise English) and can be overridden in Settings. Adding a string = adding a `Key` case + both translations; missing translations are a compile-time non-option since the table is exhaustive per language.

## 6. Build & run

```sh
swift build                 # debug build
swift test                  # parser unit tests
./scripts/build-app.sh      # release build → dist/NautaConnect.app (ad-hoc signed)
```

Icons are pre-generated and committed. To regenerate from the SVG sources (requires `librsvg`: `brew install librsvg`):

```sh
./scripts/make-icons.sh
```

## 7. Testing

- `swift test` runs `PortalParserTests` against anonymized HTML fixtures captured from the real portal (login page, online page, failed login). Tokens/IPs in fixtures are synthetic.
- The full login/logout flow **cannot be tested off-network**. On-network release checklist:
  1. Connect with a valid account → menu shows Connected + timer starts.
  2. Quit and relaunch the app → session restored, Disconnect still works.
  3. Disconnect → portal confirms `SUCCESS`, timer stops.
  4. Wrong password → the portal's alert message is shown, no session stored.
  5. Remaining time matches the value shown by the portal's own online page.

## 8. Roadmap

- **[nauta.cu](https://www.nauta.cu/) user portal integration**: authenticated scraping/API of the user portal for account balance, expiry date, recharge and transfers. Kept out of v1 — it is a separate host, separate auth (captcha involved) and can rot independently of the captive portal protocol.
- Low-time notifications (`UserNotifications`) fed by §3.4 polling.
- Nauta network auto-detection via `NWPathMonitor` + captive-portal probe.
