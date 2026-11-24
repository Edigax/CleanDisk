<p align="center">
  <img src="assets/logo.png" width="128" height="128" alt="CleanDisk Logo" />
</p>

<h1 align="center">CleanDisk</h1>

<p align="center">
  <b>A native macOS Menu Bar application that automatically purges hidden metadata files (.DS_Store, ._* AppleDouble, and system indexing files) from USB keys, SD cards, MP3 players, and external drives.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple" alt="macOS 13+" />
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift 6.0" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20arm64-black" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## 📌 Overview

Whenever macOS interacts with non-Mac filesystems (FAT32, exFAT, NTFS, or network SMB shares), Finder silently creates hidden metadata files:
- **`.DS_Store`**: Stores window positions, icon view settings, and folder layouts.
- **`._*` (AppleDouble files)**: Stores resource forks and extended file attributes.
- **System Folders**: `.Spotlight-V100`, `.Trashes`, `.fseventsd`, and `.TemporaryItems`.

While invisible on a Mac, these files clutter digital cameras, car infotainment audio systems, smart TVs, and Windows/Linux machines. **CleanDisk** runs as a discreet Menu Bar Extra to eliminate these files on demand with **1-click** and watches external volumes in real-time to remove them **automatically as they appear**.

---

## ✨ Features

- **Menu Bar Utility (`LSUIElement`)**: Runs quietly in your macOS top menu bar as a status item without cluttering the Dock.
- **Real-Time Kernel Watcher (`FSEvents`)**: Watches mounted external volumes with near-zero CPU overhead, deleting `.DS_Store` and `._*` files the moment Finder or an app creates them.
- **Auto-Mount Detection (`NSWorkspace`)**: Detects newly inserted flash drives or SD cards and automatically cleans them on connection.
- **1-Click Clean & Eject**: Sanitizes all hidden files and safely unmounts the disk so you can unplug it immediately without Finder warnings.
- **Drag-and-Drop Sanitizer**: Drop any folder or external disk onto the popup (or click *Browse Folder...*) to clean custom directories.
- **Custom Vector Icon**: Includes a standalone SVG vector asset and multi-resolution Apple Icon bundle (`.icns`).

---

## 🚀 Quick Start

### Running CleanDisk
Clone this repository and run the startup script:

```bash
git clone https://github.com/your-username/CleanDisk.git
cd CleanDisk
./run.sh
```

*(You can also double-click `CleanDisk.app` directly from Finder)*

Look at your top macOS Menu Bar for the **✨ sparkles** icon to open the CleanDisk control pane.

---

## 🔨 Building from Source

CleanDisk is built using **Swift 6** and **SwiftUI** with no third-party dependencies.

To compile and produce a signed local `.app` bundle:

```bash
./build.sh
```

The script compiles all source files, generates the `Info.plist` accessory configuration, attaches the vector `AppIcon.icns`, and signs the bundle for Apple Silicon execution.

---

## 📂 Project Structure

```text
CleanDisk/
├── assets/
│   └── logo.png                # High-res icon asset for repository display
├── Resources/
│   ├── AppIcon.svg             # Standalone scalable SVG vector graphic
│   ├── AppIcon.icns            # Multi-resolution macOS Apple Icon Image bundle
│   └── generate_icon.swift     # CoreGraphics script that renders the icon bundle
├── Sources/
│   ├── CleanDiskApp.swift      # Application entry point using MenuBarExtra
│   ├── Models/
│   │   ├── VolumeItem.swift    # Represents mounted disks and storage metrics
│   │   └── CleanResult.swift   # Metrics for cleaned files and bytes freed
│   ├── Services/
│   │   ├── CleanerEngine.swift # POSIX filesystem scanner & purger
│   │   ├── VolumeMonitor.swift # NSWorkspace disk mount/unmount and eject handler
│   │   └── FileSystemWatcher.swift # Real-time FSEventStream monitor
│   ├── ViewModels/
│   │   └── CleanDiskViewModel.swift # Central ObservableObject state coordinator
│   └── Views/
│       ├── CleanDiskMainView.swift  # Main popover interface
│       ├── VolumeCardView.swift     # Connected disk card with capacity bar & buttons
│       └── DropZoneView.swift       # Drag-and-drop target and folder picker
├── Package.swift               # Swift Package Manager manifest
├── build.sh                    # Automated compilation and packaging script
├── run.sh                      # Launch script
└── LICENSE                     # MIT License
```

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
