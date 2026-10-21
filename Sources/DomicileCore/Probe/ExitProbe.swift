import Foundation

public struct ProbeResult: Sendable {
    public var byIP: TraceResponse?
    public var byName: TraceResponse?
}

public enum ExitProbe {
    public static func probe() async -> ProbeResult {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 6
        config.waitsForConnectivity = false
        let session = URLSession(configuration: config)
        async let byIP = fetch(session, "https://1.1.1.1/cdn-cgi/trace")
        async let byName = fetch(session, "https://cloudflare.com/cdn-cgi/trace")
        return await ProbeResult(byIP: byIP, byName: byName)
    }

    private static func fetch(_ session: URLSession, _ urlString: String) async -> TraceResponse? {
        guard let url = URL(string: urlString) else { return nil }
        guard let (data, response) = try? await session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return TraceResponse(parsing: text)
    }
}
