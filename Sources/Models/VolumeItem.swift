import Foundation
import SwiftUI

public struct VolumeItem: Identifiable, Equatable {
    public var id: String { path }
    public let name: String
    public let url: URL
    public let path: String
    public let isRemovable: Bool
    public let isEjectable: Bool
    public let isInternal: Bool
    public let fileSystem: String
    public let totalCapacity: Int64
    public let availableCapacity: Int64
    public var pendingMetadataCount: Int = 0
    public var isCleaning: Bool = false

    public var usedCapacity: Int64 {
        max(0, totalCapacity - availableCapacity)
    }

    public var usedFraction: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedCapacity) / Double(totalCapacity)
    }

    public var formattedFreeSpace: String {
        let free = ByteCountFormatter.string(fromByteCount: availableCapacity, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalCapacity, countStyle: .file)
        return "\(free) free of \(total)"
    }

    public var systemIcon: String {
        let fs = fileSystem.lowercased()
        if fs.contains("smb") || fs.contains("network") {
            return "network"
        } else if name.lowercased().contains("sd") || name.lowercased().contains("card") {
            return "sdcard"
        } else {
            return "externaldrive.fill"
        }
    }

    public static func == (lhs: VolumeItem, rhs: VolumeItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.pendingMetadataCount == rhs.pendingMetadataCount &&
        lhs.isCleaning == rhs.isCleaning
    }
}
