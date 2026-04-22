import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct HangulFixerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = Shared.appState

    var body: some Scene {
        WindowGroup("HangulFixer", id: "main") {
            ContentView()
                .environmentObject(state)
                .frame(width: 500, height: 360)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra("HangulFixer", systemImage: "character.textbox.ko") {
            MenuBarContentView()
                .environmentObject(state)
                .frame(width: 340)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let argumentPaths = Array(CommandLine.arguments.dropFirst())
        guard !argumentPaths.isEmpty else { return }
        let urls = argumentPaths.map { URL(fileURLWithPath: $0) }
        Shared.appState.process(urls: urls, sourceDescription: "명령줄에서 전달된 항목")
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Shared.appState.process(urls: urls, sourceDescription: "Finder에서 전달된 항목")
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        Shared.appState.process(urls: urls, sourceDescription: "Finder에서 전달된 항목")
        sender.reply(toOpenOrPrint: .success)
    }
}

enum Shared {
    static let appState = AppState()
}

final class AppState: ObservableObject {
    @Published var isTargeted = false
    @Published var statusMessage = "파일이나 폴더를 드롭하면 Windows용 ZIP으로 저장합니다."
    @Published var isProcessing = false

    @AppStorage("outputDirectoryPath") var outputDirectoryPath = defaultDownloadsPath()
    @AppStorage("openOutputFolderAfterProcessing") var openOutputFolderAfterProcessing = false

    var outputDirectoryURL: URL {
        URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
    }

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.prompt = "저장 경로 선택"
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.directoryURL = outputDirectoryURL
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.outputDirectoryPath = url.path
            self?.statusMessage = "저장 경로를 변경했습니다: \(url.path)"
        }
    }

    func revealOutputDirectory() {
        NSWorkspace.shared.activateFileViewerSelecting([outputDirectoryURL])
    }

    func process(urls: [URL], sourceDescription: String) {
        let validURLs = urls.filter { $0.isFileURL }
        guard !validURLs.isEmpty else {
            statusMessage = "처리할 파일을 읽지 못했습니다."
            return
        }

        isProcessing = true
        statusMessage = "\(sourceDescription) 처리 중..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            do {
                let result = try FilenameNormalizer.process(
                    inputURLs: validURLs,
                    outputDirectory: self.outputDirectoryURL
                )

                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.statusMessage = result.summaryMessage
                    if self.openOutputFolderAfterProcessing {
                        self.revealOutputDirectory()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.statusMessage = "실패: \(error.localizedDescription)"
                }
            }
        }
    }

}

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 14) {
            header
            optionsCard
            actionButtons
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color.accentColor.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onDrop(of: [UTType.fileURL.identifier as NSString as String], isTargeted: $state.isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            AppIconView()
                .frame(width: 92, height: 92)
                .overlay {
                    if state.isTargeted {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.accentColor, lineWidth: 3)
                    }
                }

            Text("HangulFixer")
                .font(.system(size: 24, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("저장 설정")
                .font(.headline)

            HStack {
                Text("저장 위치")
                    .frame(width: 62, alignment: .leading)
                Text(state.outputDirectoryPath)
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("변경") {
                    state.chooseOutputDirectory()
                }
                Button("열기") {
                    state.revealOutputDirectory()
                }
            }

            Toggle("완료 후 저장 폴더 자동 열기", isOn: $state.openOutputFolderAfterProcessing)

        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button("파일 선택") {
                    openInputPanel()
                }
                .controlSize(.large)

                if state.isProcessing {
                    ProgressView()
                        .controlSize(.large)
                }

                Spacer()
            }

            Text(state.statusMessage)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()
        }
    }

    private func openInputPanel() {
        let panel = NSOpenPanel()
        panel.prompt = "가져오기"
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.begin { response in
            guard response == .OK else { return }
            state.process(urls: panel.urls, sourceDescription: "선택한 항목")
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        let lock = NSLock()
        var urls: [URL] = []

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }

                let resolvedURL: URL?
                if let data = item as? Data {
                    resolvedURL = URL(dataRepresentation: data, relativeTo: nil)
                } else if let nsData = item as? NSData {
                    resolvedURL = URL(dataRepresentation: nsData as Data, relativeTo: nil)
                } else if let str = item as? String {
                    resolvedURL = URL(string: str)
                } else if let url = item as? URL {
                    resolvedURL = url
                } else {
                    resolvedURL = nil
                }

                if let resolvedURL {
                    lock.lock()
                    urls.append(resolvedURL)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            state.process(urls: urls, sourceDescription: "드롭한 항목")
        }
        return true
    }
}

struct AppIconView: View {
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "AppIconPreview", withExtension: "png"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
            }
        }
    }
}

struct MenuBarContentView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HangulFixer")
                .font(.headline)

            Text(state.statusMessage)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Button("메인 창 열기") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
            Button("파일 선택") {
                NSApp.activate(ignoringOtherApps: true)
                let panel = NSOpenPanel()
                panel.prompt = "가져오기"
                panel.allowsMultipleSelection = true
                panel.canChooseFiles = true
                panel.canChooseDirectories = true
                panel.canCreateDirectories = false
                panel.begin { response in
                    guard response == .OK else { return }
                    state.process(urls: panel.urls, sourceDescription: "선택한 항목")
                }
            }
            Button("저장 위치 변경") {
                state.chooseOutputDirectory()
            }
            Button("저장 폴더 열기") {
                state.revealOutputDirectory()
            }
            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
    }
}

struct ProcessingResult {
    let savedURLs: [URL]
    let summaryMessage: String
}

enum FilenameNormalizer {
    static func process(inputURLs: [URL], outputDirectory: URL) throws -> ProcessingResult {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let batchName = batchBaseName(for: inputURLs)
        let stagingRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stagingDirectory = stagingRoot.appendingPathComponent(batchName, isDirectory: true)
        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: stagingRoot) }

        let stagedURLs = try inputURLs.map { try copyItemRecursively($0, to: stagingDirectory) }
        let zipSourceURL: URL
        if stagedURLs.count == 1 {
            zipSourceURL = stagedURLs[0]
        } else {
            zipSourceURL = stagingDirectory
        }

        let zipName = zipSourceURL.lastPathComponent.precomposedStringWithCanonicalMapping
        let zipDestination = uniqueDestination(
            for: outputDirectory.appendingPathComponent(zipName).deletingPathExtension().appendingPathExtension("zip")
        )
        try createZipArchive(from: zipSourceURL, to: zipDestination)

        return ProcessingResult(
            savedURLs: [zipDestination],
            summaryMessage: "ZIP 생성을 완료했습니다: \(zipDestination.lastPathComponent)"
        )
    }

    private static func batchBaseName(for inputURLs: [URL]) -> String {
        if inputURLs.count == 1 {
            return inputURLs[0].deletingPathExtension().lastPathComponent.precomposedStringWithCanonicalMapping
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "normalized_batch_\(formatter.string(from: Date()))"
    }

    private static func createZipArchive(from sourceURL: URL, to destinationURL: URL) throws {
        guard let scriptURL = Bundle.main.url(forResource: "zip_utf8", withExtension: "py") else {
            throw NSError(domain: "HangulFixer", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "ZIP 스크립트를 찾지 못했습니다."
            ])
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptURL.path, sourceURL.path, destinationURL.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8) ?? "ZIP 생성에 실패했습니다."
            throw NSError(domain: "HangulFixer", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message.trimmingCharacters(in: .whitespacesAndNewlines)
            ])
        }
    }

    private static func copyItemRecursively(_ sourceURL: URL, to destinationDirectory: URL) throws -> URL {
        let fileManager = FileManager.default
        let normalizedName = sourceURL.lastPathComponent.precomposedStringWithCanonicalMapping
        let destinationURL = uniqueDestination(for: destinationDirectory.appendingPathComponent(normalizedName))

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory) else {
            throw NSError(domain: "HangulFixer", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "원본 항목을 찾을 수 없습니다: \(sourceURL.path)"
            ])
        }

        if isDirectory.boolValue {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            let children = try fileManager.contentsOfDirectory(
                at: sourceURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            for child in children {
                _ = try copyItemRecursively(child, to: destinationURL)
            }
        } else {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

        return destinationURL
    }

    private static func uniqueDestination(for url: URL) -> URL {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: url.path) else {
            let ext = url.pathExtension
            let baseName = url.deletingPathExtension().lastPathComponent
            let directory = url.deletingLastPathComponent()
            var index = 1

            while true {
                let candidateName: String
                if ext.isEmpty {
                    candidateName = "\(baseName) (\(index))"
                } else {
                    candidateName = "\(baseName) (\(index)).\(ext)"
                }

                let candidate = directory.appendingPathComponent(candidateName)
                if !fileManager.fileExists(atPath: candidate.path) {
                    return candidate
                }
                index += 1
            }
        }

        return url
    }
}

private func defaultDownloadsPath() -> String {
    FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path
        ?? NSString(string: "~/Downloads").expandingTildeInPath
}
