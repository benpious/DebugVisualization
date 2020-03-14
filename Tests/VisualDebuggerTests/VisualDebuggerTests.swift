import XCTest
@testable import VisualDebugger

final class VisualDebuggerTests: XCTestCase {
    
    func test_demangling() {
        let mangledName = "$s10TestTarget4DataV"
        XCTAssertEqual(try! mangledName.basicDemangle(),
                       MangledName(runtimeUsableName: "10TestTarget4DataV",
                                   moduleName: "TestTarget",
                                   typeName: "Data"))
    }
        
}
