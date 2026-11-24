import SwiftUI
import UniformTypeIdentifiers
import AppKit

public struct DropZoneView: View {
    @Binding public var isTargeted: Bool
    public let onSelectURL: (URL) -> Void

    public init(isTargeted: Binding<Bool>, onSelectURL: @escaping (URL) -> Void) {
        self._isTargeted = isTargeted
        self.onSelectURL = onSelectURL
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 24))
                .foregroundStyle(isTargeted ? .blue : .secondary)

            Text("Drop a folder or USB drive here")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)

            Button("or Browse Folder...") {
                openFolderPicker()
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.blue : Color.primary.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                )
                .background(isTargeted ? Color.blue.opacity(0.05) : Color.clear)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        onSelectURL(url)
                    }
                }
            }
            return true
        }
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Clean Folder"

        if panel.runModal() == .OK, let url = panel.url {
            onSelectURL(url)
        }
    }
}
