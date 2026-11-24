import Foundation
import CoreServices

public final class FileSystemWatcher {
    public static let shared = FileSystemWatcher()

    private var streams: [String: FSEventStreamRef] = [:]
    public var onVolumeChanged: ((String) -> Void)?

    private init() {}

    deinit {
        stopAll()
    }

    public func startWatching(path: String) {
        // If already watching, do not duplicate
        if streams[path] != nil { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let pathsToWatch = [path] as CFArray
        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        let callback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            guard let clientCallBackInfo = clientCallBackInfo else { return }
            let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(clientCallBackInfo).takeUnretainedValue()

            if let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] {
                for p in paths {
                    let filename = (p as NSString).lastPathComponent
                    let (isTarget, _) = CleanerEngine.isTargetMetadata(name: filename)
                    if isTarget {
                        watcher.onVolumeChanged?(p)
                        return
                    }
                }
            }
            // General directory modification fallback
            if let first = (unsafeBitCast(eventPaths, to: NSArray.self) as? [String])?.first {
                watcher.onVolumeChanged?(first)
            }
        }

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0, // 1-second latency window
            flags
        ) else { return }

        streams[path] = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    public func stopWatching(path: String) {
        guard let stream = streams.removeValue(forKey: path) else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
    }

    public func stopAll() {
        for (path, _) in streams {
            stopWatching(path: path)
        }
    }
}
