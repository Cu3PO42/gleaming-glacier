import SwiftUI
import KeybindHelperCore

/// SwiftUI view for displaying keybinding overlays with modern styling
struct KeybindingOverlayView: View {
    let keymap: Keymap
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if !keymap.name.isEmpty {
                Text(keymap.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 12)
            }
            
            // Keybinding list
            ScrollView(.vertical, showsIndicators: true) {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                    ForEach(Array(keymap.binds.enumerated()), id: \.offset) { _, binding in
                        GridRow(alignment: .top) {
                            // Key combination column
                            Text(formatKeyCombination(binding.key))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .gridColumnAlignment(.trailing)
                                .fixedSize()
                            
                            // Command name column
                            Text(binding.name)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .gridColumnAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 400)
        }
        .padding(20)
        .frame(minWidth: 320, maxWidth: 600, minHeight: 100, maxHeight: 500)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.9))
        )
    }
    
    private func formatKeyCombination(_ combination: KeyCombination) -> String {
        return combination.displayString
    }
}


/// Window controller for SwiftUI overlay
public class SwiftUIOverlayWindowController: NSWindowController {
    private var hostingView: NSHostingView<KeybindingOverlayView>?
    
    public convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        setupWindow()
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.center()
    }
    
    public func updateKeymap(_ keymap: Keymap) {
        let overlayView = KeybindingOverlayView(keymap: keymap)
        
        if hostingView == nil {
            hostingView = NSHostingView(rootView: overlayView)
            window?.contentView = hostingView
        } else {
            hostingView?.rootView = overlayView
        }
        
        // Let SwiftUI calculate the ideal size
        DispatchQueue.main.async {
            guard let hostingView = self.hostingView else { return }
            let idealSize = hostingView.fittingSize
            self.window?.setContentSize(idealSize)
            self.centerWindow()
        }
    }
    
    private func centerWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        let x = screenFrame.origin.x + (screenFrame.width - windowFrame.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - windowFrame.height) / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    public func showWithAnimation() {
        window?.alphaValue = 0
        window?.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window?.animator().alphaValue = 1.0
        }
    }
    
    public func hideWithAnimation() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            window?.animator().alphaValue = 0.0
        } completionHandler: {
            self.window?.orderOut(nil)
            self.window?.alphaValue = 1.0
        }
    }
}