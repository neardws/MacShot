import AppKit
import Foundation

enum AIClientError: LocalizedError {
    case invalidEndpoint
    case emptyResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "Invalid AI endpoint URL."
        case .emptyResponse: return "Empty response from local model."
        case .server(let message): return message
        }
    }
}

struct OpenAICompatibleClient {
    var baseURL: URL
    var model: String
    var apiKey: String?

    func streamVisionChat(prompt: String, image: NSImage) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await chunk in try await requestStream(prompt: prompt, image: image) {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func completeVisionChat(prompt: String, image: NSImage) async throws -> String {
        var text = ""
        for try await chunk in try await requestStream(prompt: prompt, image: image) {
            text += chunk
        }
        guard !text.isEmpty else { throw AIClientError.emptyResponse }
        return text
    }

    private func requestStream(prompt: String, image: NSImage) async throws -> AsyncThrowingStream<String, Error> {
        guard let jpeg = ImageFormats.jpegData(from: image, quality: 0.85) else {
            throw AIClientError.emptyResponse
        }
        let b64 = jpeg.base64EncodedString()
        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]]
                    ]
                ]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                        continuation.finish(throwing: AIClientError.server("HTTP \(http.statusCode)"))
                        return
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String,
                              !content.isEmpty else { continue }
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    @MainActor
    static func fromSettings() -> OpenAICompatibleClient {
        let settings = AppSettings.shared
        return OpenAICompatibleClient(
            baseURL: settings.aiBaseURL,
            model: settings.aiVisionModel,
            apiKey: settings.aiAPIKey.isEmpty ? nil : settings.aiAPIKey
        )
    }
}
