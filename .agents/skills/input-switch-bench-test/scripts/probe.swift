// Drives input-source switches the way a user would (via TIS, which fires the
// same distributed notification InputSwitch listens to) and observes the HUD
// window from outside the process via CGWindowList. No Accessibility or Screen
// Recording permission needed: window bounds/alpha/layer are public.
//
// Build once (timings are skewed when run through the `swift` interpreter):
//   swiftc -O scripts/probe.swift -o build/bench/probe
//
// Usage:
//   probe list                         enabled, selectable input sources (id<TAB>name)
//   probe current                      current input source id
//   probe select <id>                  select a source and confirm it took effect
//   probe windows --pid <pid>          on-screen windows of <pid> (layer, alpha, bounds)
//   probe cycle --pid <pid> [--ids a,b,...] [--count N] [--interval-ms MS] [--timeout-ms MS]
//       Switches through the sources N times, one every MS. Per switch prints a CSV row:
//       i,target_id,selected_ok,appear_ms,gone_ms,width,height,x,y,screen,focus_stolen
//       appear_ms  switch → HUD window on screen with alpha > 0 (-1 = never appeared)
//       gone_ms    switch → HUD window off screen (-1 = still visible when the next switch fired)
//       focus_stolen  1 if the frontmost app became <pid>
//   The original input source is restored on exit (also on Ctrl-C).

import AppKit
import Carbon

// MARK: - TIS

func enabledSources() -> [TISInputSource] {
    let filter: [String: Any] = [
        kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
        kTISPropertyInputSourceIsSelectCapable as String: true,
    ]
    return TISCreateInputSourceList(filter as CFDictionary, false)?
        .takeRetainedValue() as? [TISInputSource] ?? []
}

func string(_ source: TISInputSource, _ key: CFString) -> String {
    guard let pointer = TISGetInputSourceProperty(source, key) else { return "" }
    return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
}

func currentID() -> String {
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return "" }
    return string(source, kTISPropertyInputSourceID)
}

/// Selects `id` and waits up to 300 ms for TIS to report it as current.
@discardableResult
func select(_ id: String) -> Bool {
    guard let source = enabledSources().first(where: { string($0, kTISPropertyInputSourceID) == id }) else {
        return false
    }
    TISSelectInputSource(source)
    let deadline = Date().addingTimeInterval(0.3)
    while Date() < deadline {
        if currentID() == id { return true }
        RunLoop.current.run(until: Date().addingTimeInterval(0.005))
    }
    return currentID() == id
}

// MARK: - Windows

struct WindowInfo {
    let layer: Int
    let alpha: Double
    let bounds: CGRect
}

func windows(of pid: pid_t) -> [WindowInfo] {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
        return []
    }
    return list.compactMap { info in
        guard (info[kCGWindowOwnerPID as String] as? Int).map(pid_t.init) == pid else { return nil }
        let boundsDict = info[kCGWindowBounds as String] as! CFDictionary
        return WindowInfo(
            layer: info[kCGWindowLayer as String] as? Int ?? 0,
            alpha: info[kCGWindowAlpha as String] as? Double ?? 0,
            bounds: CGRect(dictionaryRepresentation: boundsDict) ?? .zero
        )
    }
}

/// The HUD panel sits at utility-window level + 1000, far above the status
/// item (layer 25) and the Settings window (layer 0).
func hudWindow(of pid: pid_t) -> WindowInfo? {
    windows(of: pid).first { $0.layer > 1000 && $0.alpha > 0 }
}

/// Index of the NSScreen containing the window's center (CG coords are top-left origin).
func screenIndex(for bounds: CGRect) -> Int {
    guard let primaryHeight = NSScreen.screens.first?.frame.height else { return -1 }
    let center = CGPoint(x: bounds.midX, y: primaryHeight - bounds.midY)
    return NSScreen.screens.firstIndex { NSMouseInRect(center, $0.frame, false) } ?? -1
}

// MARK: - Restore on exit

nonisolated(unsafe) var originalSourceID = ""

func installRestoreHandler() {
    originalSourceID = currentID()
    signal(SIGINT) { _ in
        _ = select(originalSourceID)
        exit(130)
    }
}

// MARK: - Commands

func argument(_ name: String, in args: [String]) -> String? {
    guard let index = args.firstIndex(of: name), index + 1 < args.count else { return nil }
    return args[index + 1]
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(2)
}

func cycle(args: [String]) {
    guard let pid = argument("--pid", in: args).flatMap(pid_t.init) else { fail("cycle needs --pid") }
    let ids = argument("--ids", in: args)?.split(separator: ",").map(String.init)
        ?? enabledSources().map { string($0, kTISPropertyInputSourceID) }
    guard ids.count >= 2 else { fail("need at least 2 input sources to switch between") }
    let count = argument("--count", in: args).flatMap(Int.init) ?? 20
    let interval = (argument("--interval-ms", in: args).flatMap(Double.init) ?? 1500) / 1000
    let timeout = (argument("--timeout-ms", in: args).flatMap(Double.init) ?? 1000) / 1000

    installRestoreHandler()
    defer { select(originalSourceID) }

    // Start from a source that is not the first target, so switch 0 is a real change.
    if currentID() == ids[0] { select(ids[1]); RunLoop.current.run(until: Date().addingTimeInterval(interval)) }

    print("i,target_id,selected_ok,appear_ms,gone_ms,width,height,x,y,screen,focus_stolen")
    for i in 0..<count {
        let id = ids[i % ids.count]
        let start = Date()
        let ok = select(id)

        var appear = -1.0, gone = -1.0
        var seen: WindowInfo?
        var focusStolen = false
        let deadline = start.addingTimeInterval(interval)
        while Date() < deadline {
            let elapsed = Date().timeIntervalSince(start) * 1000
            if let hud = hudWindow(of: pid) {
                if appear < 0 { appear = elapsed }
                seen = hud
            } else if appear >= 0 && gone < 0 {
                gone = elapsed
            }
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == pid { focusStolen = true }
            if appear < 0 && elapsed > timeout * 1000 { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.002))
        }
        RunLoop.current.run(until: deadline)

        let b = seen?.bounds ?? .zero
        print([
            "\(i)", id, ok ? "1" : "0",
            String(format: "%.1f", appear), String(format: "%.1f", gone),
            "\(Int(b.width))", "\(Int(b.height))", "\(Int(b.minX))", "\(Int(b.minY))",
            "\(seen.map { screenIndex(for: $0.bounds) } ?? -1)", focusStolen ? "1" : "0",
        ].joined(separator: ","))
        fflush(stdout)
    }
}

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "list":
    for source in enabledSources() {
        print(string(source, kTISPropertyInputSourceID) + "\t" + string(source, kTISPropertyLocalizedName))
    }
case "current":
    print(currentID())
case "select":
    guard args.count > 1 else { fail("select needs an id") }
    exit(select(args[1]) ? 0 : 1)
case "windows":
    guard let pid = argument("--pid", in: args).flatMap(pid_t.init) else { fail("windows needs --pid") }
    for w in windows(of: pid) {
        print("layer=\(w.layer) alpha=\(w.alpha) bounds=\(w.bounds) screen=\(screenIndex(for: w.bounds))")
    }
case "cycle":
    cycle(args: args)
default:
    fail("usage: probe list | current | select <id> | windows --pid <pid> | cycle --pid <pid> [...]")
}
