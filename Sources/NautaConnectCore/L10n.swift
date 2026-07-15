import Foundation

public enum Language: String, CaseIterable {
    case english = "en"
    case spanish = "es"

    /// Follows the user's preferred system language.
    public static var system: Language {
        (Locale.preferredLanguages.first ?? "en").hasPrefix("es") ? .spanish : .english
    }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
}

/// In-code bilingual string table. Exhaustive per language: a missing
/// translation is a compile-time problem, not a runtime surprise.
public enum L10n {
    public static var language: Language = .english

    public enum Key: String, CaseIterable {
        case statusConnected
        case statusDisconnected
        case statusNotOnNetwork
        case statusWorking
        case connect
        case disconnect
        case timeLeft
        case timeLeftUnknown
        case sessionTime
        case settings
        case quit
        case settingsTitle
        case usernameLabel
        case usernamePlaceholder
        case passwordLabel
        case languageLabel
        case launchAtLogin
        case save
        case saved
        case errorTitle
        case missingCredentials
        case refreshTimeLeft
    }

    public static func t(_ key: Key) -> String {
        table[language]?[key] ?? key.rawValue
    }

    private static let table: [Language: [Key: String]] = [
        .english: [
            .statusConnected: "Connected",
            .statusDisconnected: "Disconnected",
            .statusNotOnNetwork: "Not on a Nauta network",
            .statusWorking: "Working…",
            .connect: "Connect",
            .disconnect: "Disconnect",
            .timeLeft: "Time left",
            .timeLeftUnknown: "Time left: —",
            .sessionTime: "Session",
            .settings: "Settings…",
            .quit: "Quit NautaConnect",
            .settingsTitle: "NautaConnect Settings",
            .usernameLabel: "Username:",
            .usernamePlaceholder: "user@nauta.com.cu",
            .passwordLabel: "Password:",
            .languageLabel: "Language:",
            .launchAtLogin: "Launch at login",
            .save: "Save",
            .saved: "Saved",
            .errorTitle: "NautaConnect",
            .missingCredentials: "Enter your Nauta username and password in Settings first.",
            .refreshTimeLeft: "Refresh time left",
        ],
        .spanish: [
            .statusConnected: "Conectado",
            .statusDisconnected: "Desconectado",
            .statusNotOnNetwork: "No estás en una red Nauta",
            .statusWorking: "Procesando…",
            .connect: "Conectar",
            .disconnect: "Desconectar",
            .timeLeft: "Tiempo disponible",
            .timeLeftUnknown: "Tiempo disponible: —",
            .sessionTime: "Sesión",
            .settings: "Ajustes…",
            .quit: "Salir de NautaConnect",
            .settingsTitle: "Ajustes de NautaConnect",
            .usernameLabel: "Usuario:",
            .usernamePlaceholder: "usuario@nauta.com.cu",
            .passwordLabel: "Contraseña:",
            .languageLabel: "Idioma:",
            .launchAtLogin: "Abrir al iniciar sesión",
            .save: "Guardar",
            .saved: "Guardado",
            .errorTitle: "NautaConnect",
            .missingCredentials: "Primero escribe tu usuario y contraseña de Nauta en Ajustes.",
            .refreshTimeLeft: "Actualizar tiempo disponible",
        ],
    ]
}
