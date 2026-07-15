import AppKit
import NautaConnectCore

/// Owns the NSStatusItem: icon, elapsed-time title, and the dropdown menu
/// with connect/disconnect actions.
final class StatusItemController: NSObject, NSMenuDelegate {
    private enum State {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let client = PortalClient()
    private let store = SessionStore.shared
    private var settingsController: SettingsWindowController?

    private var state: State = .disconnected
    private var timeLeft: String?
    private var timer: Timer?

    override init() {
        super.init()

        statusItem.button?.image = MenuBarIcon.image()
        statusItem.button?.imagePosition = .imageLeading

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        // Restore a session persisted by a previous run: logout must survive restarts.
        if store.session != nil {
            state = .connected
            startElapsedTimer()
            refreshTimeLeft()
        }
        updateButton()
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(disabledItem(statusLine()))
        if state == .connected {
            menu.addItem(disabledItem("\(L10n.t(.timeLeft)): \(timeLeft ?? "—")"))
            menu.addItem(makeItem(L10n.t(.refreshTimeLeft), action: #selector(refreshTimeLeftAction)))
        }
        menu.addItem(.separator())

        switch state {
        case .disconnected:
            menu.addItem(makeItem(L10n.t(.connect), action: #selector(connectAction), key: "c"))
        case .connected:
            menu.addItem(makeItem(L10n.t(.disconnect), action: #selector(disconnectAction), key: "d"))
        case .connecting, .disconnecting:
            menu.addItem(disabledItem(L10n.t(.statusWorking)))
        }

        menu.addItem(.separator())
        menu.addItem(makeItem(L10n.t(.settings), action: #selector(openSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(makeItem(L10n.t(.quit), action: #selector(quit), key: "q"))
    }

    private func statusLine() -> String {
        switch state {
        case .connected:
            return "\(L10n.t(.statusConnected)) — \(formattedElapsed())"
        case .disconnected:
            return L10n.t(.statusDisconnected)
        case .connecting, .disconnecting:
            return L10n.t(.statusWorking)
        }
    }

    private func makeItem(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - Actions

    @objc private func connectAction() {
        let username = store.username
        guard !username.isEmpty,
              let password = KeychainHelper.loadPassword(account: username), !password.isEmpty else {
            showError(L10n.t(.missingCredentials))
            openSettings()
            return
        }

        state = .connecting
        updateButton()
        Task { @MainActor in
            do {
                let session = try await client.login(username: username, password: password)
                store.session = session
                state = .connected
                startElapsedTimer()
                refreshTimeLeft()
            } catch {
                state = .disconnected
                showError(error.localizedDescription)
            }
            updateButton()
        }
    }

    @objc private func disconnectAction() {
        guard let session = store.session else {
            state = .disconnected
            updateButton()
            return
        }
        state = .disconnecting
        updateButton()
        Task { @MainActor in
            do {
                try await client.logout(session)
                store.session = nil
                state = .disconnected
                stopElapsedTimer()
                timeLeft = nil
            } catch {
                // Keep the session: dropping it would strand the user logged in.
                state = .connected
                showError(error.localizedDescription)
            }
            updateButton()
        }
    }

    @objc private func refreshTimeLeftAction() {
        refreshTimeLeft()
    }

    @objc private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController()
        }
        settingsController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Time left

    private func refreshTimeLeft() {
        guard let session = store.session else { return }
        Task { @MainActor in
            timeLeft = try? await client.remainingTime(for: session)
        }
    }

    // MARK: - Elapsed timer

    private func startElapsedTimer() {
        stopElapsedTimer()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateButton()
        }
        // .common so the title keeps ticking while the menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopElapsedTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formattedElapsed() -> String {
        guard let session = store.session else { return "0:00:00" }
        let total = Int(session.elapsed)
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    private func updateButton() {
        statusItem.button?.title = state == .connected ? " " + formattedElapsed() : ""
    }

    // MARK: - Errors

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.t(.errorTitle)
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
