import Foundation
import ServiceManagement
import os.log

/// User-facing preferences, persisted in UserDefaults and (where relevant)
/// reflected into system services like SMAppService.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private nonisolated static let log = Logger(subsystem: "com.bitmoor.whatcable", category: "settings")

    private enum Keys {
        static let notifyOnChanges = "notifyOnChanges"
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            applyLaunchAtLogin(launchAtLogin)
        }
    }

    @Published var notifyOnChanges: Bool {
        didSet {
            guard notifyOnChanges != oldValue else { return }
            UserDefaults.standard.set(notifyOnChanges, forKey: Keys.notifyOnChanges)
            if notifyOnChanges {
                NotificationManager.shared.requestAuthorizationIfNeeded()
            }
        }
    }

    private init() {
        // Launch at Login is owned by the system; read its current state.
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        // Notifications default off — opt in to avoid noise.
        self.notifyOnChanges = UserDefaults.standard.bool(forKey: Keys.notifyOnChanges)
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Self.log.error("Failed to update launch at login: \(error.localizedDescription, privacy: .public)")
            // Roll the published value back so the UI matches reality.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let actual = SMAppService.mainApp.status == .enabled
                if self.launchAtLogin != actual {
                    self.launchAtLogin = actual
                }
            }
        }
    }
}
