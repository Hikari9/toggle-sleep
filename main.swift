import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var onMenuItem: NSMenuItem!
    private var offMenuItem: NSMenuItem!
    private var openAtLoginItem: NSMenuItem!
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        updateState()

        // Poll every 2.5 seconds to reflect external changes (e.g. terminal runs)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.updateState()
        }
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let coffeeImage = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Coffee")
        let moonImage = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Moon")

        let menu = NSMenu()
        menu.delegate = self

        onMenuItem = NSMenuItem(
            title: "ON: Don't sleep, even with the laptop closed",
            action: #selector(handleSelectOn),
            keyEquivalent: ""
        )
        onMenuItem.image = coffeeImage
        onMenuItem.target = self
        menu.addItem(onMenuItem)

        offMenuItem = NSMenuItem(
            title: "OFF: Sleep normally, following the laptop's settings",
            action: #selector(handleSelectOff),
            keyEquivalent: ""
        )
        offMenuItem.image = moonImage
        offMenuItem.target = self
        menu.addItem(offMenuItem)

        menu.addItem(NSMenuItem.separator())

        openAtLoginItem = NSMenuItem(
            title: "Open at Login",
            action: #selector(toggleOpenAtLogin),
            keyEquivalent: ""
        )
        openAtLoginItem.target = self
        menu.addItem(openAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit Sleep Toggle",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateState()
    }

    // MARK: - State Management

    private func isSleepDisabled() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("SleepDisabled") {
                        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
                        if parts.count >= 2, parts[1] == "1" {
                            return true
                        }
                    }
                }
            }
        } catch {
            NSLog("Sleep Toggle: Error checking pmset: \(error)")
        }
        return false
    }

    private func updateState() {
        let disabled = isSleepDisabled()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let button = self.statusItem.button {
                let symbolName = disabled ? "cup.and.saucer.fill" : "moon.fill"
                let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: disabled ? "Sleep Off (Coffee)" : "Sleep Enabled (Moon)")
                image?.isTemplate = true
                button.image = image
                button.title = ""
                button.toolTip = disabled ? "Sleep Off: Won't sleep even if laptop is closed" : "Sleep Enabled: Sleeps normally"
            }
            self.onMenuItem.state = disabled ? .on : .off
            self.offMenuItem.state = disabled ? .off : .on

            if #available(macOS 13.0, *) {
                self.openAtLoginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
            }
        }
    }

    // MARK: - Actions

    @objc private func handleSelectOn() {
        runToggleSleep(disableSleep: true)
    }

    @objc private func handleSelectOff() {
        runToggleSleep(disableSleep: false)
    }

    private func runToggleSleep(disableSleep: Bool) {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let scriptPath = "\(home)/.local/bin/toggle-sleep"

        // In toggle-sleep:
        // argument "0" -> force disable sleep (SleepDisabled=1, ON)
        // argument "1" -> force enable sleep (SleepDisabled=0, OFF)
        let scriptArg = disableSleep ? "0" : "1"

        let task = Process()
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\(home)/.local/bin"
        task.environment = env

        if FileManager.default.fileExists(atPath: scriptPath) {
            task.launchPath = scriptPath
            task.arguments = [scriptArg]
        } else {
            // Direct fallback to sudo pmset
            task.launchPath = "/usr/bin/sudo"
            task.arguments = ["/usr/bin/pmset", "disablesleep", disableSleep ? "1" : "0"]
        }

        let errPipe = Pipe()
        task.standardError = errPipe

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus != 0 {
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let errString = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                NSLog("Sleep Toggle: toggle-sleep failed with code \(task.terminationStatus): \(errString)")
                showSudoErrorAlert(detail: errString)
            }
        } catch {
            NSLog("Sleep Toggle: Failed to run process: \(error)")
            showSudoErrorAlert(detail: error.localizedDescription)
        }

        updateState()
    }

    private func showSudoErrorAlert(detail: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Permission Required for Sleep Toggle"
            alert.informativeText = "Sleep Toggle needs passwordless sudo permission to run pmset.\n\nError: \(detail.isEmpty ? "Process exited with non-zero status" : detail)\n\nPlease ensure passwordless sudo is configured in /etc/sudoers.d/toggle_sleep."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc private func toggleOpenAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                NSLog("Sleep Toggle: Failed to change open at login status: \(error)")
                let alert = NSAlert()
                alert.messageText = "Open at Login Error"
                alert.informativeText = "Could not update login item: \(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            updateState()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
