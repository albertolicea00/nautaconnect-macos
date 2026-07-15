<div align="center">

<img src="assets/app-icon-macos.svg" width="96" alt="NautaConnect logo"/>

# NautaConnect for macOS

**Connect, disconnect and track your Nauta session — right from the menu bar.**

![Platform](https://img.shields.io/badge/platform-macOS%2012%2B-000066)
![Swift](https://img.shields.io/badge/Swift-5.7-F05138?logo=swift&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)
![UI](https://img.shields.io/badge/UI-Espa%C3%B1ol%20%7C%20English-00CCFF)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

</div>

---

If you use the internet in Cuba, you know the ritual: open the ETECSA captive portal, log in, browse… and pray you never close that tab. Because if you do, there is no logout button anymore — and your precious hours keep burning.

**NautaConnect fixes that.** It lives quietly in your menu bar and gives you the whole Nauta session lifecycle in one click:

- 🔌 **One-click connect & disconnect** — no browser, no tabs, no portal roulette.
- ⏱ **Live session timer in the menu bar** — always know how long you've been online.
- ⌛ **Remaining time at a glance** — queries your account's leftover hours directly from the portal.
- 🔐 **Your password stays in the macOS Keychain** — never in plain text, never logged, never sent anywhere but ETECSA.
- 🌐 **Español e inglés** — the app speaks both, switch anytime in Settings.
- 🪶 **Truly native, truly tiny** — pure Swift + AppKit. No Electron, no runtime, no 200 MB download. Your 2012 MacBook will not even notice it's running.

> Works with **Nauta Hogar** and **Nauta WiFi** accounts on any ETECSA network that authenticates through [secure.etecsa.net](https://secure.etecsa.net:8443/).

## Install

1. Grab the latest `NautaConnect.app` from [Releases](../../releases) *(or build it yourself in two commands — see [SPECS.md](SPECS.md))*.
2. Drop it into `/Applications`.
3. Click the ⤳ icon in your menu bar, open **Settings…**, enter your `usuario@nauta.com.cu` credentials, done.

Building from source, the portal protocol, architecture and everything technical lives in **[SPECS.md](SPECS.md)**.

## Roadmap

- [x] Connect / disconnect / session timer / remaining time
- [ ] Notifications before your time runs out
- [ ] [nauta.cu](https://www.nauta.cu/) user portal integration — account balance, recharges and transfers without leaving the menu bar
- [ ] Auto-detection of Nauta networks

## Sister projects

NautaConnect is a family of small native apps, one per platform, no shared bloat:

- **[nautaconnect-windows](https://github.com/albertolicea00/nautaconnect-windows)** — native system-tray app for Windows
- **[nautaconnect-extension](https://github.com/albertolicea00/nautaconnect--extension)** — Chrome & Firefox extension

## Contributing

Bugs, ideas and PRs are very welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Disclaimer

NautaConnect is an independent open-source project. It is **not** affiliated with, endorsed by, or supported by ETECSA. It simply automates the same requests your browser makes against the official portal. Use it with your own account, at your own risk.

## License

[MIT](LICENSE) © NautaConnect contributors
