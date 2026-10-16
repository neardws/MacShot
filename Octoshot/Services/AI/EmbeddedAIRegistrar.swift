import OctoshotCore

enum EmbeddedAIRegistrar {
    @MainActor
    static func install() {
        EmbeddedAIProvider.vision = LocalVLMService.shared
        EmbeddedAIProvider.latex = Pix2TexService.shared
    }
}
