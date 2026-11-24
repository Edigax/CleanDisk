import SwiftUI
import AppKit

public struct CleanDiskMainView: View {
    @ObservedObject public var viewModel: CleanDiskViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.blue)

                    Text("CleanDisk")
                        .font(.system(size: 15, weight: .bold))
                }

                Spacer()

                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Refresh Connected Disks")

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Quit CleanDisk")
            }

            Divider()

            // Auto-clean toggle
            Toggle(isOn: $viewModel.autoCleanEnabled) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Auto-Clean External Disks")
                        .font(.system(size: 12, weight: .medium))
                    Text("Removes .DS_Store & ._* automatically on mount & write")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Divider()

            // Connected Drives Section
            VStack(alignment: .leading, spacing: 8) {
                Text("EXTERNAL DISKS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)

                if viewModel.volumes.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "externaldrive.badge.questionmark")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("No External Disks Detected")
                                .font(.system(size: 12, weight: .medium))
                            Text("Plug in a USB key, SD card, or clean a folder below.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    ForEach(viewModel.volumes) { item in
                        VolumeCardView(
                            item: item,
                            onClean: { viewModel.cleanVolume(item) },
                            onCleanAndEject: { viewModel.cleanAndEject(item) }
                        )
                    }
                }
            }

            // Quick drop zone
            VStack(alignment: .leading, spacing: 6) {
                Text("MANUAL CLEAN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)

                DropZoneView(isTargeted: $viewModel.isDropTargeted) { url in
                    viewModel.cleanCustomPath(url)
                }
            }

            // Status & Recent Results
            if let latest = viewModel.recentResults.first {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)

                    Text(latest.summary)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.autoCleanEnabled ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)

                    Text(viewModel.statusMessage)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(width: 360)
    }
}
