import Foundation
import AppKit

public final class VolumeMonitor {
    public static let shared = VolumeMonitor()

    public var onVolumesChanged: (([VolumeItem]) -> Void)?
    public var onVolumeMounted: ((VolumeItem) -> Void)?

    private var observers: [NSObjectProtocol] = []

    private init() {
        setupNotifications()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func setupNotifications() {
        let center = NSWorkspace.shared.notificationCenter

        let mountObserver = center.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            let updated = self.refreshVolumes()
            if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL,
               let newDrive = updated.first(where: { $0.url == volumeURL }) {
                self.onVolumeMounted?(newDrive)
            }
        }

        let unmountObserver = center.addObserver(
            forName: NSWorkspace.didUnmountNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshVolumes()
        }

        let renameObserver = center.addObserver(
            forName: NSWorkspace.didRenameVolumeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshVolumes()
        }

        observers = [mountObserver, unmountObserver, renameObserver]
    }

    @discardableResult
    public func refreshVolumes() -> [VolumeItem] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeIsInternalKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeLocalizedFormatDescriptionKey
        ]

        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else {
            onVolumesChanged?([])
            return []
        }

        var items: [VolumeItem] = []

        for url in urls {
            // Never treat the boot drive / system volume as a removable external drive
            if url.path == "/" { continue }

            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }

            let isRemovable = values.volumeIsRemovable ?? false
            let isEjectable = values.volumeIsEjectable ?? false
            let isInternal = values.volumeIsInternal ?? true

            // Only include external, removable, or ejectable disks (USB, SD, Network, DMG)
            if isRemovable || isEjectable || !isInternal || url.path.hasPrefix("/Volumes/") {
                let name = values.volumeName ?? url.lastPathComponent
                let total = Int64(values.volumeTotalCapacity ?? 0)
                let available = Int64(values.volumeAvailableCapacity ?? 0)
                let format = values.volumeLocalizedFormatDescription ?? "External Disk"

                let item = VolumeItem(
                    name: name,
                    url: url,
                    path: url.path,
                    isRemovable: isRemovable,
                    isEjectable: isEjectable,
                    isInternal: isInternal,
                    fileSystem: format,
                    totalCapacity: total,
                    availableCapacity: available,
                    pendingMetadataCount: 0,
                    isCleaning: false
                )
                items.append(item)
            }
        }

        onVolumesChanged?(items)
        return items
    }

    public func ejectVolume(at url: URL, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: url)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
}
