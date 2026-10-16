import XCTest
@testable import OctoshotCore

final class EmbeddedAIModelCatalogTests: XCTestCase {
    func testModelsRootUnderApplicationSupport() {
        let root = EmbeddedAIModelPaths.modelsRoot()
        XCTAssertTrue(root.path.contains("Octoshot/Models"))
    }

    func testSmolVLMManifest() {
        XCTAssertEqual(EmbeddedModelID.smolVLM2_500M_4bit.approximateSizeMB, 292)
        XCTAssertFalse(EmbeddedModelID.smolVLM2_500M_4bit.huggingFaceRepo.isEmpty)
    }
}
