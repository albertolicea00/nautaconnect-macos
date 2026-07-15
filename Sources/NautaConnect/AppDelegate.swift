import AppKit
import NautaConnectCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        L10n.language = SessionStore.shared.language
        statusController = StatusItemController()
    }
}
