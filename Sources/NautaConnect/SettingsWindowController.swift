import AppKit
import NautaConnectCore
import ServiceManagement

/// Credentials + language + launch-at-login. Programmatic AppKit, no nibs.
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let usernameField = NSTextField()
    private let passwordField = NSSecureTextField()
    private let languagePopup = NSPopUpButton()
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let store = SessionStore.shared

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 190),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
        window.delegate = self
        buildUI()
        loadValues()
    }

    private func buildUI() {
        guard let window else { return }
        window.title = L10n.t(.settingsTitle)

        let usernameLabel = label(L10n.t(.usernameLabel))
        let passwordLabel = label(L10n.t(.passwordLabel))
        let languageLabel = label(L10n.t(.languageLabel))

        usernameField.placeholderString = L10n.t(.usernamePlaceholder)
        languagePopup.addItems(withTitles: Language.allCases.map(\.displayName))

        launchAtLoginCheckbox.title = L10n.t(.launchAtLogin)
        // SMAppService needs macOS 13+; hide the option on older systems.
        if #unavailable(macOS 13.0) {
            launchAtLoginCheckbox.isHidden = true
        }

        let saveButton = NSButton(title: L10n.t(.save), target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        let grid = NSGridView(views: [
            [usernameLabel, usernameField],
            [passwordLabel, passwordField],
            [languageLabel, languagePopup],
            [NSGridCell.emptyContentView, launchAtLoginCheckbox],
            [NSGridCell.emptyContentView, saveButton],
        ])
        grid.rowSpacing = 10
        grid.columnSpacing = 8
        grid.column(at: 0).xPlacement = .trailing
        grid.translatesAutoresizingMaskIntoConstraints = false

        let content = window.contentView!
        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            grid.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -20),
            usernameField.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
        ])
    }

    private func label(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.alignment = .right
        return field
    }

    private func loadValues() {
        usernameField.stringValue = store.username
        if !store.username.isEmpty,
           let password = KeychainHelper.loadPassword(account: store.username) {
            passwordField.stringValue = password
        }
        languagePopup.selectItem(at: Language.allCases.firstIndex(of: store.language) ?? 0)
        if #available(macOS 13.0, *) {
            launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }

    @objc private func save() {
        let username = usernameField.stringValue.trimmingCharacters(in: .whitespaces)
        store.username = username
        if !username.isEmpty, !passwordField.stringValue.isEmpty {
            KeychainHelper.savePassword(passwordField.stringValue, account: username)
        }

        let language = Language.allCases[languagePopup.indexOfSelectedItem]
        store.language = language
        L10n.language = language

        if #available(macOS 13.0, *) {
            // Best effort: registration fails outside a proper .app bundle (e.g. swift run).
            do {
                if launchAtLoginCheckbox.state == .on {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("Launch at login toggle failed: \(error.localizedDescription)")
            }
        }

        // Language may have changed; rebuild the window next time it opens.
        close()
    }

    func windowWillClose(_ notification: Notification) {
        passwordField.stringValue = ""
    }
}
