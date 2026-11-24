import SwiftUI

public struct VolumeCardView: View {
    public let item: VolumeItem
    public let onClean: () -> Void
    public let onCleanAndEject: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: item.systemIcon)
                    .font(.system(size: 26))
                    .foregroundStyle(.blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text(item.fileSystem)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(4)
                    }

                    Text(item.formattedFreeSpace)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            // Capacity bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(item.usedFraction > 0.9 ? Color.red : Color.blue)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(item.usedFraction))), height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                if item.pendingMetadataCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text("\(item.pendingMetadataCount) junk items")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Metadata Clean")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if item.isCleaning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: onClean) {
                        Label("Clean", systemImage: "sparkles")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: onCleanAndEject) {
                        Label("Clean & Eject", systemImage: "eject.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
