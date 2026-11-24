import SwiftUI

@main
struct CleanDiskApp: App {
    @StateObject private var viewModel = CleanDiskViewModel()

    var body: some Scene {
        MenuBarExtra {
            CleanDiskMainView(viewModel: viewModel)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "sparkles")
                if viewModel.isProcessing {
                    Text("•")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
