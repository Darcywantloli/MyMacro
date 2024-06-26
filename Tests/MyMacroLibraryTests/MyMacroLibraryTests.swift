import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MyMacroLibraryMacros)
import MyMacroLibraryMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "BinaryString": BinaryStringMacro.self,
    "Constant": ConstantMacro.self,
    "Interface": InterfaceMacro.self,
    "UserDefault": UserDefaultMacro.self,
    "Desccription": DesccriptionMacro.self,
//    "Equatable": EquatableMacro.self
]
#endif

final class MyMacroLibraryTests: XCTestCase {
    func testMacro() throws {
        #if canImport(MyMacroLibraryMacros)
        assertMacroExpansion(
            """
            let b = #BinaryString(1000)
            """,
            expandedSource: """
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(MyMacroLibraryMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
