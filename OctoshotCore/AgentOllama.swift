import Foundation

public enum AgentOllama {
    public static func isReachable(baseURL: URL = AgentConfiguration.aiBaseURL) async -> Bool {
        let host = ollamaHost(from: baseURL)
        let endpoint = host.appendingPathComponent("api/tags")
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 4
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return http.statusCode == 200
        } catch {
            return false
        }
    }

    private static func ollamaHost(from settingsBase: URL) -> URL {
        guard var components = URLComponents(url: settingsBase, resolvingAgainstBaseURL: false) else {
            return URL(string: "http://127.0.0.1:11434")!
        }
        if components.path.hasSuffix("/v1") {
            components.path = String(components.path.dropLast(2))
        }
        if components.path == "/" || components.path.isEmpty {
            components.path = ""
        }
        return components.url ?? URL(string: "http://127.0.0.1:11434")!
    }
}
