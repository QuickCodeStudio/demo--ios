import SwiftUI
import UIKit
import Pulse
import PulseUI
import QuickCodeHTTP
#if DEBUG
import PulseProxy
#endif

/// Starts network capture. DEBUG uses PulseProxy (covers leftovers); Release/TestFlight
/// rely on ``GatewayHTTP/session`` (URLSessionProxy) only — no private-API swizzle.
enum PortalPulse {
    private static var didStart = false

    static func start() {
        guard !didStart else { return }
        didStart = true
        #if DEBUG
        NetworkLogger.enableProxy()
        #endif
        // Touch the shared logged session so OpenAPI / ad-hoc calls are wired early.
        _ = GatewayHTTP.session
    }
}

/// Shake → Pulse network console + error dump (available in Debug and Release/TestFlight).
struct PortalShakeReportModifier: ViewModifier {
    @State private var open = false

    func body(content: Content) -> some View {
        content
            .onAppear { PortalPulse.start() }
            .onReceive(NotificationCenter.default.publisher(for: .portalDeviceDidShake)) { _ in
                open = true
            }
            .sheet(isPresented: $open) {
                PortalDebugConsoleSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    func portalShakeToReport() -> some View {
        modifier(PortalShakeReportModifier())
    }
}

private struct PortalDebugConsoleSheet: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case network
        case errors
        var id: String { rawValue }
        var title: String {
            switch self {
            case .network: return "Network"
            case .errors: return "Errors"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .network

    var body: some View {
        NavigationStack {
            Group {
                switch tab {
                case .network:
                    ConsoleView(mode: .network)
                case .errors:
                    PortalShakeReportList()
                }
            }
            .navigationTitle(tab == .network ? "Pulse" : "Error report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Tab", selection: $tab) {
                        ForEach(Tab.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }
            }
        }
    }
}

private struct PortalShakeReportList: View {
    @State private var entries = PortalErrors.recent

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No recent errors",
                    systemImage: "checkmark.seal",
                    description: Text("Shake again after something fails to capture details.")
                )
            } else {
                List {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.userMessage)
                                .font(.subheadline.weight(.semibold))
                            Text(entry.date.formatted(date: .abbreviated, time: .standard))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(entry.technical)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !entries.isEmpty {
                    ShareLink(item: reportText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Clear log", role: .destructive) {
                    PortalErrors.clear()
                    entries = []
                }
                .disabled(entries.isEmpty)
            }
        }
        .onAppear { entries = PortalErrors.recent }
    }

    private var reportText: String {
        entries.map { entry in
            """
            [\(entry.date.formatted())] \(entry.userMessage)
            \(entry.technical)
            """
        }
        .joined(separator: "\n\n———\n\n")
    }
}
