// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MyMacroLibraryMacros", type: "StringifyMacro")

@freestanding(expression)
public macro BinaryString(_ value: Int) -> String = #externalMacro(module: "MyMacroLibraryMacros", type: "BinaryStringMacro")

@freestanding(declaration, names: arbitrary)
public macro Constant(_ value: String) = #externalMacro(module: "MyMacroLibraryMacros", type: "ConstantMacro")

@attached(peer, names: arbitrary)
public macro Interface() = #externalMacro(module: "MyMacroLibraryMacros", type: "InterfaceMacro")

@attached(accessor) 
public macro UserDefault() = #externalMacro(module: "MyMacroLibraryMacros", type: "UserDefaultMacro")

@attached(member, names: named(description))
public macro Desccription() = #externalMacro(module: "MyMacroLibraryMacros", type: "DesccriptionMacro")

//@attached(extension, conformances: Equatable)
//public macro Equatable() = #externalMacro(module: "MyMacroLibraryMacros", type: "EquatableMacro")
