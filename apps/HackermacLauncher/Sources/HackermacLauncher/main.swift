import AppKit
import Carbon.HIToolbox
import SwiftUI

@main
struct HackermacLauncherMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: LauncherController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = LauncherController()
        controller?.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.unregisterHotKey()
    }
}

@MainActor
final class LauncherController: ObservableObject {
    @Published var searchText = ""
    @Published var menuStack: [LauncherMenu]
    @Published var currentItems: [LauncherItem]
    @Published var statusText = ""
    @Published var selectedIndex = 0
    @Published var navigationID = UUID()

    let repoPath: String
    let theme: LauncherTheme
    private let rootMenu: LauncherMenu
    private let runner: ActionRunner
    private var panel: LauncherPanel?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init() {
        repoPath = RepoLocator.findRepoPath()
        rootMenu = ConfigLoader.loadMenu(repoPath: repoPath)
        theme = ConfigLoader.loadTheme(repoPath: repoPath)
        menuStack = [rootMenu]
        currentItems = rootMenu.items
        runner = ActionRunner(repoPath: repoPath)
        installHotKey()
    }

    var currentMenu: LauncherMenu { menuStack.last ?? rootMenu }

    var filteredItems: [LauncherItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return currentItems }
        return currentItems
            .map { ($0, Fuzzy.score(query: query, item: $0)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    var breadcrumb: String {
        menuStack.map(\.title).joined(separator: " / ")
    }

    func show() {
        if panel == nil {
            panel = LauncherPanel(theme: theme)
            let view = LauncherView(controller: self)
            panel?.contentView = TransparentHostingView(rootView: view)
        }

        menuStack = [rootMenu]
        setCurrentItems(rootMenu.items)
        NSApp.activate(ignoringOtherApps: true)
        panel?.centerOnActiveScreen()
        panel?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func open(_ item: LauncherItem) {
        if let children = item.items, !children.isEmpty {
            menuStack.append(LauncherMenu(title: item.title, items: children))
            setCurrentItems(children)
            return
        }

        guard let action = item.action else {
            statusText = "No action for \(item.title)"
            return
        }

        if item.confirm == true {
            let alert = NSAlert()
            alert.messageText = "Run \(item.title)?"
            alert.informativeText = item.subtitle ?? "This action may modify your system."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Run")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }

        Task {
            do {
                try await runner.run(action)
                statusText = "Ran \(item.title)"
                hide()
            } catch {
                statusText = error.localizedDescription
            }
        }
    }

    func openSelected() {
        let items = filteredItems
        guard items.indices.contains(selectedIndex) else { return }
        open(items[selectedIndex])
    }

    func moveSelection(_ delta: Int) {
        let count = filteredItems.count
        guard count > 0 else { return }
        selectedIndex = min(max(selectedIndex + delta, 0), count - 1)
    }

    func back() {
        if menuStack.count > 1 {
            menuStack.removeLast()
            setCurrentItems(currentMenu.items)
        } else {
            hide()
        }
    }

    private func setCurrentItems(_ items: [LauncherItem]) {
        currentItems = items
        searchText = ""
        selectedIndex = 0
        navigationID = UUID()
    }

    func resetSelection() {
        selectedIndex = 0
    }

    func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func installHotKey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData else { return noErr }
            let controller = Unmanaged<LauncherController>.fromOpaque(userData).takeUnretainedValue()
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            if hotKeyID.id == 1 {
                Task { @MainActor in controller.toggle() }
            }
            return noErr
        }, 1, &eventType, selfPointer, &eventHandlerRef)

        let hotKeyID = EventHotKeyID(signature: OSType(0x484d4c48), id: 1) // HMLH
        RegisterEventHotKey(
            theme.hotKey.keyCode,
            theme.hotKey.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}

final class LauncherPanel: NSPanel {
    init(theme: LauncherTheme) {
        let size = NSSize(width: theme.width, height: 560)
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func centerOnActiveScreen() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else { return }
        setFrameOrigin(NSPoint(x: frame.midX - frame.width * 0.25, y: frame.midY + frame.height * 0.08))
        center()
    }
}

final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    required init(rootView: Content) {
        super.init(rootView: rootView)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init(rootView: Content, ignoreSafeArea: Bool) {
        fatalError("init(rootView:ignoreSafeArea:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct LauncherView: View {
    @ObservedObject var controller: LauncherController
    @FocusState private var searchFocused: Bool

    var body: some View {
        VisualEffect(
            material: controller.theme.material.nsMaterial,
            cornerRadius: controller.theme.cornerRadius
        )
            .overlay(content)
            .clipShape(RoundedRectangle(cornerRadius: controller.theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.36), radius: 34, y: 22)
            .frame(width: controller.theme.width, height: 560)
            .onAppear { searchFocused = true }
            .onChange(of: controller.searchText) { _, _ in controller.resetSelection() }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.22)
            results
                .id(controller.navigationID)
            footer
        }
        .onKeyPress(.downArrow) {
            controller.moveSelection(1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            controller.moveSelection(-1)
            return .handled
        }
        .onKeyPress(.return) {
            controller.openSelected()
            return .handled
        }
        .onKeyPress(.escape) {
            controller.back()
            return .handled
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.orange)
                Text(controller.breadcrumb)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(controller.theme.hotKey.displayName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.16), in: Capsule())
            }

            TextField("Search commands...", text: $controller.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .focused($searchFocused)
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 18)
    }

    private var results: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(Array(controller.filteredItems.enumerated()), id: \.offset) { index, item in
                        LauncherRow(item: item, selected: index == controller.selectedIndex)
                            .id(index)
                            .onTapGesture { controller.open(item) }
                    }
                }
                .padding(14)
            }
            .onChange(of: controller.selectedIndex) { _, newValue in
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(controller.statusText.isEmpty ? "Enter runs. Esc goes back. Arrow keys move." : controller.statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text("HackermacLauncher")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.orange.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct LauncherRow: View {
    let item: LauncherItem
    let selected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.icon ?? "command")
                .font(.system(size: 20, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(selected ? .orange : .primary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if item.items?.isEmpty == false {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            } else if item.action != nil {
                Image(systemName: item.confirm == true ? "exclamationmark.triangle" : "return")
                    .foregroundStyle(item.confirm == true ? .orange : .secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(selected ? .orange.opacity(0.18) : .white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(selected ? .orange.opacity(0.45) : .white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct VisualEffect: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.layer?.cornerRadius = cornerRadius
        nsView.layer?.masksToBounds = true
    }
}

struct LauncherMenu: Decodable, Identifiable {
    var id: String { title }
    let title: String
    let items: [LauncherItem]
}

struct LauncherItem: Decodable, Identifiable {
    var id: String { title + (subtitle ?? "") }
    let title: String
    let subtitle: String?
    let icon: String?
    let confirm: Bool?
    let items: [LauncherItem]?
    let action: LauncherAction?
}

indirect enum LauncherAction: Decodable {
    case submenu
    case openApp(name: String)
    case openPath(path: String)
    case openURL(url: String)
    case ghostty(command: String, cwd: String?)
    case aerospace(args: [String])
    case run(command: String, args: [String]?, cwd: String?)
    case appleScript(script: String)
    case sequence(actions: [LauncherAction])

    enum CodingKeys: String, CodingKey {
        case type, name, path, url, command, args, cwd, script, actions
    }

    enum ActionType: String, Decodable {
        case submenu, openApp, openPath, openURL, ghostty, aerospace, run, appleScript, sequence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionType.self, forKey: .type)
        switch type {
        case .submenu:
            self = .submenu
        case .openApp:
            self = .openApp(name: try container.decode(String.self, forKey: .name))
        case .openPath:
            self = .openPath(path: try container.decode(String.self, forKey: .path))
        case .openURL:
            self = .openURL(url: try container.decode(String.self, forKey: .url))
        case .ghostty:
            self = .ghostty(
                command: try container.decode(String.self, forKey: .command),
                cwd: try container.decodeIfPresent(String.self, forKey: .cwd)
            )
        case .aerospace:
            self = .aerospace(args: try container.decode([String].self, forKey: .args))
        case .run:
            self = .run(
                command: try container.decode(String.self, forKey: .command),
                args: try container.decodeIfPresent([String].self, forKey: .args),
                cwd: try container.decodeIfPresent(String.self, forKey: .cwd)
            )
        case .appleScript:
            self = .appleScript(script: try container.decode(String.self, forKey: .script))
        case .sequence:
            self = .sequence(actions: try container.decode([LauncherAction].self, forKey: .actions))
        }
    }
}

struct LauncherTheme: Decodable {
    let material: String
    let cornerRadius: CGFloat
    let accentColor: String
    let width: CGFloat
    let maxRows: Int
    let hotKey: LauncherHotKey

    static let fallback = LauncherTheme(
        material: "hudWindow",
        cornerRadius: 28,
        accentColor: "orange",
        width: 720,
        maxRows: 8,
        hotKey: .fallback
    )

    enum CodingKeys: String, CodingKey {
        case material, cornerRadius, accentColor, width, maxRows, hotKey
    }

    init(material: String, cornerRadius: CGFloat, accentColor: String, width: CGFloat, maxRows: Int, hotKey: LauncherHotKey) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
        self.width = width
        self.maxRows = maxRows
        self.hotKey = hotKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        material = try container.decode(String.self, forKey: .material)
        cornerRadius = try container.decode(CGFloat.self, forKey: .cornerRadius)
        accentColor = try container.decode(String.self, forKey: .accentColor)
        width = try container.decode(CGFloat.self, forKey: .width)
        maxRows = try container.decode(Int.self, forKey: .maxRows)
        hotKey = try container.decodeIfPresent(LauncherHotKey.self, forKey: .hotKey) ?? .fallback
    }
}

struct LauncherHotKey: Decodable {
    let key: String
    let modifiers: [String]

    static let fallback = LauncherHotKey(key: "space", modifiers: ["option"])

    var displayName: String {
        let names = modifiers.map { modifier in
            switch modifier.lowercased() {
            case "option", "alt": "Option"
            case "control", "ctrl": "Control"
            case "shift": "Shift"
            case "command", "cmd", "super": "Command"
            default: modifier.capitalized
            }
        }
        return (names + [keyDisplayName]).joined(separator: " ")
    }

    var keyCode: UInt32 {
        switch key.lowercased() {
        case "space": UInt32(kVK_Space)
        case "a": UInt32(kVK_ANSI_A)
        case "b": UInt32(kVK_ANSI_B)
        case "c": UInt32(kVK_ANSI_C)
        case "d": UInt32(kVK_ANSI_D)
        case "e": UInt32(kVK_ANSI_E)
        case "f": UInt32(kVK_ANSI_F)
        case "g": UInt32(kVK_ANSI_G)
        case "h": UInt32(kVK_ANSI_H)
        case "i": UInt32(kVK_ANSI_I)
        case "j": UInt32(kVK_ANSI_J)
        case "k": UInt32(kVK_ANSI_K)
        case "l": UInt32(kVK_ANSI_L)
        case "m": UInt32(kVK_ANSI_M)
        case "n": UInt32(kVK_ANSI_N)
        case "o": UInt32(kVK_ANSI_O)
        case "p": UInt32(kVK_ANSI_P)
        case "q": UInt32(kVK_ANSI_Q)
        case "r": UInt32(kVK_ANSI_R)
        case "s": UInt32(kVK_ANSI_S)
        case "t": UInt32(kVK_ANSI_T)
        case "u": UInt32(kVK_ANSI_U)
        case "v": UInt32(kVK_ANSI_V)
        case "w": UInt32(kVK_ANSI_W)
        case "x": UInt32(kVK_ANSI_X)
        case "y": UInt32(kVK_ANSI_Y)
        case "z": UInt32(kVK_ANSI_Z)
        default: UInt32(kVK_Space)
        }
    }

    var carbonModifiers: UInt32 {
        modifiers.reduce(UInt32(0)) { result, modifier in
            switch modifier.lowercased() {
            case "option", "alt": result | UInt32(optionKey)
            case "control", "ctrl": result | UInt32(controlKey)
            case "shift": result | UInt32(shiftKey)
            case "command", "cmd", "super": result | UInt32(cmdKey)
            default: result
            }
        }
    }

    private var keyDisplayName: String {
        key.lowercased() == "space" ? "Space" : key.uppercased()
    }
}

extension String {
    var nsMaterial: NSVisualEffectView.Material {
        switch self {
        case "popover": .popover
        case "sidebar": .sidebar
        case "underWindowBackground": .underWindowBackground
        default: .hudWindow
        }
    }
}

enum RepoLocator {
    static func findRepoPath() -> String {
        if let explicit = ProcessInfo.processInfo.environment["HACKERMACUI_REPO"], !explicit.isEmpty {
            return explicit
        }

        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var current: URL? = cwd
        while let url = current {
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("configs/launcher/menu.json").path) {
                return url.path
            }
            current = url.path == "/" ? nil : url.deletingLastPathComponent()
        }

        return NSHomeDirectory() + "/HackermacUI"
    }
}

enum ConfigLoader {
    static func loadMenu(repoPath: String) -> LauncherMenu {
        let path = URL(fileURLWithPath: repoPath).appendingPathComponent("configs/launcher/menu.json")
        do {
            let data = try Data(contentsOf: path)
            return try JSONDecoder().decode(LauncherMenu.self, from: data)
        } catch {
            return LauncherMenu(title: "HackermacUI", items: [
                LauncherItem(
                    title: "Menu load failed",
                    subtitle: error.localizedDescription,
                    icon: "exclamationmark.triangle",
                    confirm: nil,
                    items: nil,
                    action: nil
                )
            ])
        }
    }

    static func loadTheme(repoPath: String) -> LauncherTheme {
        let path = URL(fileURLWithPath: repoPath).appendingPathComponent("configs/launcher/theme.json")
        do {
            let data = try Data(contentsOf: path)
            return try JSONDecoder().decode(LauncherTheme.self, from: data)
        } catch {
            return .fallback
        }
    }
}

struct ActionRunner {
    let repoPath: String

    func run(_ action: LauncherAction) async throws {
        switch action {
        case .submenu:
            return
        case let .openApp(name):
            try runProcess("/usr/bin/open", ["-na", name], cwd: nil)
        case let .openPath(path):
            try runProcess("/usr/bin/open", [resolve(path)], cwd: nil)
        case let .openURL(url):
            try runProcess("/usr/bin/open", [resolve(url)], cwd: nil)
        case let .ghostty(command, cwd):
            let resolvedCwd = cwd.map(resolve)
            let shell = [resolvedCwd.map { "cd \(shellQuote($0))" }, resolve(command)]
                .compactMap { $0 }
                .joined(separator: " && ")
            try runProcess("/bin/bash", ["-lc", "open -na Ghostty --args -e /bin/zsh -lc \(shellQuote(shell))"], cwd: nil)
        case let .aerospace(args):
            try runProcess("/opt/homebrew/bin/aerospace", args.map(resolve), cwd: nil)
        case let .run(command, args, cwd):
            let resolvedCommand = resolve(command)
            try runProcess(resolvedCommand, (args ?? []).map(resolve), cwd: cwd.map(resolve))
        case let .appleScript(script):
            try runProcess("/usr/bin/osascript", ["-e", resolve(script)], cwd: nil)
        case let .sequence(actions):
            for action in actions {
                try await run(action)
            }
        }
    }

    private func resolve(_ value: String) -> String {
        value.replacingOccurrences(of: "${repo}", with: repoPath)
    }

    private func runProcess(_ launchPath: String, _ arguments: [String], cwd: String?) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        if let cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        }
        try process.run()
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

enum Fuzzy {
    static func score(query: String, item: LauncherItem) -> Int {
        let haystack = [item.title, item.subtitle ?? ""].joined(separator: " ").lowercased()
        let needle = query.lowercased()
        if haystack.contains(needle) { return 100 + needle.count }

        var score = 0
        var index = haystack.startIndex
        for character in needle {
            guard let found = haystack[index...].firstIndex(of: character) else { return 0 }
            score += found == index ? 8 : 3
            index = haystack.index(after: found)
        }
        return score
    }
}
