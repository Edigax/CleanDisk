import Foundation
import Darwin

public final class CleanerEngine {
    public static let shared = CleanerEngine()

    private init() {}

    public static func isTargetMetadata(name: String) -> (isTarget: Bool, isDirectoryTarget: Bool) {
        if name == ".DS_Store" {
            return (true, false)
        }
        if name.hasPrefix("._") {
            return (true, false)
        }
        if [".Spotlight-V100", ".Trashes", ".fseventsd", ".TemporaryItems"].contains(name) {
            return (true, true)
        }
        return (false, false)
    }

    /// Recursively counts how many metadata files/directories exist without removing them
    public func scan(at path: String) -> Int {
        var count = 0
        guard let dir = opendir(path) else { return 0 }
        defer { closedir(dir) }

        var subdirectories: [String] = []

        while let entry = readdir(dir) {
            let name = withUnsafePointer(to: &entry.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen)) {
                    String(cString: $0)
                }
            }

            if name == "." || name == ".." { continue }

            let fullPath = (path as NSString).appendingPathComponent(name)
            let (isTarget, isDirTarget) = CleanerEngine.isTargetMetadata(name: name)

            if isTarget {
                count += 1
                if isDirTarget {
                    continue
                }
            }

            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                subdirectories.append(fullPath)
            }
        }

        for sub in subdirectories {
            count += scan(at: sub)
        }

        return count
    }

    /// Recursively cleans all .DS_Store, ._ AppleDouble, and system metadata files
    public func clean(at path: String, targetName: String = "") -> CleanResult {
        var result = CleanResult()
        result.targetName = targetName.isEmpty ? (path as NSString).lastPathComponent : targetName

        guard let dir = opendir(path) else { return result }
        defer { closedir(dir) }

        var subdirectories: [String] = []

        while let entry = readdir(dir) {
            let name = withUnsafePointer(to: &entry.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen)) {
                    String(cString: $0)
                }
            }

            if name == "." || name == ".." { continue }

            let fullPath = (path as NSString).appendingPathComponent(name)
            let (isTarget, isDirTarget) = CleanerEngine.isTargetMetadata(name: name)

            if isTarget {
                var fileSize: Int64 = 0
                if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
                   let size = attrs[.size] as? Int64 {
                    fileSize = size
                }

                do {
                    try FileManager.default.removeItem(atPath: fullPath)
                    result.filesRemoved += 1
                    result.bytesFreed += fileSize
                    result.removedFiles.append(name)
                } catch {
                    // Try POSIX unlink if standard removeItem encounters permissions
                    if unlink(fullPath) == 0 {
                        result.filesRemoved += 1
                        result.bytesFreed += fileSize
                        result.removedFiles.append(name)
                    }
                }

                if isDirTarget {
                    continue
                }
            }

            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                subdirectories.append(fullPath)
            }
        }

        for sub in subdirectories {
            let subResult = clean(at: sub, targetName: result.targetName)
            result.filesRemoved += subResult.filesRemoved
            result.bytesFreed += subResult.bytesFreed
            result.removedFiles.append(contentsOf: subResult.removedFiles)
        }

        return result
    }
}
