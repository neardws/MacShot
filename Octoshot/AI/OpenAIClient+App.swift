import OctoshotCore

extension OpenAICompatibleClient {
    @MainActor
    static func fromSettings() -> OpenAICompatibleClient {
        AgentConfiguration.openAIClient()
    }
}
