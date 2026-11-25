import Foundation
import Pulse

/// Shared HTTP session used by OpenAPI clients and ad-hoc gateway calls.
/// Always uses Pulse ``URLSessionProxy`` (safe for TestFlight / App Store) — not PulseProxy swizzling.
public enum GatewayHTTP {
    public static let session: URLSession = {
        var options = URLSessionProxy.Options()
        #if !DEBUG
        options.isMockingEnabled = false
        #endif
        return URLSessionProxy(configuration: .default, options: options).session
    }()
}
