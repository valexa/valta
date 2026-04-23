import Sparkle
import SwiftUI
public import Combine

/// Wrapper around Sparkle's SPUStandardUpdaterController
@MainActor
public class SparkleUpdateManager: NSObject, ObservableObject, SPUUpdaterDelegate {
    public static let shared = SparkleUpdateManager()

    // We keep a strong reference to the controller
    private var updaterController: SPUStandardUpdaterController?

    @Published public var canInstallUpdates: Bool = false

    private override init() {
        super.init()
    }

    /// Must be called from applicationDidFinishLaunching
    public func start() {
        if updaterController == nil {
            // Initialize Sparkle
            // SPUStandardUpdaterController must be initialized on the main thread
            self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        }
    }

    /// Trigger a check for updates user action
    public func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }

    public var automaticallyChecksForUpdates: Bool {
        get { return updaterController?.updater.automaticallyChecksForUpdates ?? true }
        set { updaterController?.updater.automaticallyChecksForUpdates = newValue }
    }

    /// Returns true if updates are automatically downloaded
    public var automaticallyDownloadsUpdates: Bool {
        get { return updaterController?.updater.automaticallyDownloadsUpdates ?? true }
        set { updaterController?.updater.automaticallyDownloadsUpdates = newValue }
    }

    // MARK: - SPUUpdaterDelegate

    public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        self.canInstallUpdates = true
    }

    public func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        // Reset state after update cycle if no update was applied or if tailored behavior is needed.
        // For now, we keep it simple: if cycle finishes, we assume the immediate check is done.
        // However, standard behavior is: if found, it stays 'found' until actioned.
        // But if the user cancels, we might want to untint.
        if error != nil {
            self.canInstallUpdates = false
        }
    }
}

