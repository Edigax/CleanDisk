import Foundation
import SwiftUI
import AppKit

public final class CleanDiskViewModel: ObservableObject {
    @Published public var volumes: [VolumeItem] = []
    @Published public var autoCleanEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(autoCleanEnabled, forKey: "autoCleanEnabled")
            updateWatchers()
        }
    }
    @Published public var statusMessage: String = "Watching external drives"
    @Published public var recentResults: [CleanResult] = []
    @Published public var isProcessing: Bool = false
    @Published public var isDropTargeted: Bool = false

    private let monitor = VolumeMonitor.shared
    private let watcher = FileSystemWatcher.shared
    private let engine = CleanerEngine.shared

    public init() {
        if UserDefaults.standard.object(forKey: "autoCleanEnabled") != nil {
            self.autoCleanEnabled = UserDefaults.standard.bool(forKey: "autoCleanEnabled")
        }

        setupHooks()
        refresh()
    }

    private func setupHooks() {
        monitor.onVolumesChanged = { [weak self] items in
            DispatchQueue.main.async {
                self?.volumes = items
                self?.updateWatchers()
                self?.scanAllVolumesMetadata()
            }
        }

        monitor.onVolumeMounted = { [weak self] newDrive in
            DispatchQueue.main.async {
                self?.statusMessage = "Mounted: \(newDrive.name)"
                if self?.autoCleanEnabled == true {
                    self?.cleanVolume(newDrive)
                }
            }
        }

        watcher.onVolumeChanged = { [weak self] eventPath in
            guard let self = self, self.autoCleanEnabled else { return }
            // Identify which volume this event belongs to
            if let volume = self.volumes.first(where: { eventPath.hasPrefix($0.path) }) {
                self.cleanVolume(volume, isAutoEvent: true)
            }
        }
    }

    public func refresh() {
        let items = monitor.refreshVolumes()
        self.volumes = items
        updateWatchers()
        scanAllVolumesMetadata()
    }

    private func updateWatchers() {
        watcher.stopAll()
        guard autoCleanEnabled else { return }

        for v in volumes {
            watcher.startWatching(path: v.path)
        }
    }

    public func scanAllVolumesMetadata() {
        for v in volumes {
            let path = v.path
            DispatchQueue.global(qos: .utility).async { [weak self] in
                let count = self?.engine.scan(at: path) ?? 0
                DispatchQueue.main.async {
                    if let index = self?.volumes.firstIndex(where: { $0.path == path }) {
                        self?.volumes[index].pendingMetadataCount = count
                    }
                }
            }
        }
    }

    public func cleanVolume(_ item: VolumeItem, isAutoEvent: Bool = false) {
        guard !item.isCleaning else { return }

        if let index = volumes.firstIndex(where: { $0.id == item.id }) {
            volumes[index].isCleaning = true
        }

        let path = item.path
        let name = item.name

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.engine.clean(at: path, targetName: name)

            DispatchQueue.main.async {
                if let index = self.volumes.firstIndex(where: { $0.path == path }) {
                    self.volumes[index].isCleaning = false
                    self.volumes[index].pendingMetadataCount = 0
                }

                if result.filesRemoved > 0 || !isAutoEvent {
                    self.recentResults.insert(result, at: 0)
                    if self.recentResults.count > 10 {
                        self.recentResults.removeLast()
                    }
                    self.statusMessage = result.summary
                    NSSound(named: "Glass")?.play()
                } else if isAutoEvent {
                    self.statusMessage = "\(name) is clean"
                }
            }
        }
    }

    public func cleanAndEject(_ item: VolumeItem) {
        cleanVolume(item)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.statusMessage = "Ejecting \(item.name)..."
            self?.monitor.ejectVolume(at: item.url) { success, error in
                if success {
                    self?.statusMessage = "Safely ejected \(item.name)"
                    NSSound(named: "Pop")?.play()
                } else {
                    self?.statusMessage = "Could not eject \(item.name): \(error ?? "In use")"
                }
            }
        }
    }

    public func cleanCustomPath(_ url: URL) {
        isProcessing = true
        let path = url.path
        let name = url.lastPathComponent

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.engine.clean(at: path, targetName: name)

            DispatchQueue.main.async {
                self.isProcessing = false
                self.recentResults.insert(result, at: 0)
                if self.recentResults.count > 10 {
                    self.recentResults.removeLast()
                }
                self.statusMessage = result.summary
                NSSound(named: "Glass")?.play()
            }
        }
    }
}
