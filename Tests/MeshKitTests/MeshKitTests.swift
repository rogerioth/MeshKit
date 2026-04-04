import XCTest
@testable import MeshKit

final class MeshKitTests: XCTestCase {

    func testGenerateReturnsRequestedGridSize() {
        let mesh = MeshKit.generate(palette: .purple, size: .init(width: 4, height: 4))

        XCTAssertEqual(mesh.width, 4)
        XCTAssertEqual(mesh.height, 4)
    }

    func testMeshColorCodableRoundTripPreservesValues() throws {
        let original = MeshColor(
            startLocation: .init(x: 0.0, y: 1.0),
            location: .init(x: 0.2, y: 0.8),
            color: SystemColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 1.0),
            tangent: .init(
                u: .init(x: 0.1, y: 0.0),
                v: .init(x: 0.0, y: -0.1)
            )
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MeshColor.self, from: data)

        XCTAssertEqual(decoded.startLocation, original.startLocation)
        XCTAssertEqual(decoded.location, original.location)
        XCTAssertEqual(decoded.tangent, original.tangent)
        XCTAssertEqual(decoded.color.asSimd(), original.color.asSimd())
    }
}
