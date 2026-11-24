import Foundation

public struct CleanResult: Identifiable {
    public let id = UUID()
    public var filesRemoved: Int = 0
    public var bytesFreed: Int64 = 0
    public var targetName: String = ""
    public var timestamp: Date = Date()
    public var removedFiles: [String] = []

    public var formattedBytes: String {
        ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file)
    }

    public var summary: String {
        if filesRemoved == 0 {
            return "No metadata files found on \(targetName). It is already clean!"
        }
        return "Cleaned \(filesRemoved) file\(filesRemoved == 1 ? "" : "s") on \(targetName) (\(formattedBytes) freed)"
    }
}
