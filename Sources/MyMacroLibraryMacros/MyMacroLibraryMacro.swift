import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        
        return "(\(argument), \(literal: argument.description))"
    }
}

// MARK: - ExpressionMacro

public struct BinaryStringMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("the macro does not have any arguments")
        }
        
//        let binaryString = String(Int("\(argument)")!, radix: 2)
        
        return ExprSyntax(literal: "binaryString")
    }
}

// MARK: - DeclarationMacro

public struct ConstantMacro: DeclarationMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let name = node.argumentList.first?.expression
            .as(StringLiteralExprSyntax.self)?.segments.first?
            .as(StringSegmentSyntax.self)?.content.text
        else {
            fatalError("invalid arguments")
        }
        
        return ["public static var \(raw: name) = \(literal: name)"]
    }
}

// MARK: - PeerMarco

public struct InterfaceMacro: PeerMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax,
                                                       providingPeersOf declaration: Declaration,
                                                       in context: Context) throws -> [DeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            fatalError("compiler bug: invalid declaration")
        }
        
        let className = classDecl.name.text
        
        let variables = classDecl.memberBlock.members
            .compactMap { member -> PatternBindingListSyntax? in
                member.decl.as(VariableDeclSyntax.self)?.bindings
            }.compactMap { bindings -> (String, String)? in
                guard let variable = bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                      let type = bindings.first?.typeAnnotation?.type.description
                else {
                    return nil
                }
                return (variable, type)
            }.map { "    var \($0.0): \($0.1)" }.joined(separator: "\n")
        
        let functions = classDecl.memberBlock.members
            .compactMap { member -> FunctionDeclSyntax? in
                member.decl.as(FunctionDeclSyntax.self)
            }.compactMap { funcDecl in
                var new = funcDecl
                new.body = nil 
                return new.description
            }.map { "    \($0.trimmingCharacters(in: .whitespacesAndNewlines))" }.joined(separator: "\n")
        
        return ["""
                class \(raw: className)Interface {
                \(raw: variables)
                
                \(raw: functions) {}
                }
                """
        ]
    }
}

// MARK: - AccessorMacro

public struct UserDefaultMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax,
                                                       providingAccessorsOf declaration: Declaration,
                                                       in context: Context) throws -> [AccessorDeclSyntax] where Context: MacroExpansionContext, Declaration: DeclSyntaxProtocol {
        guard let binding = declaration.as(VariableDeclSyntax.self)?.bindings.first,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let type = binding.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type.as(OptionalTypeSyntax.self)?.wrappedType.description
        else {
            fatalError("compiler bug: unknown error")
        }
        
        let getter = AccessorDeclSyntax.init(accessorSpecifier: .keyword(.get)) {
            DeclSyntax(stringLiteral: """
                                      UserDefaults.standard.value(forKey: \"\(name)\") as? \(type)
                                      """)
        }
        
        let setter = AccessorDeclSyntax.init(accessorSpecifier: .keyword(.set)) {
            DeclSyntax(stringLiteral: """
                                      UserDefaults.standard.setValue(newValue, forKey: \"\(name)\")
                                      """)
        }
        
        return [getter, setter]
    }
}

// MARK: - MemberAttributeMacro

extension UserDefaultMacro: MemberAttributeMacro {
    public static func expansion<Declaration, MemberDeclaration, Context>(of node: AttributeSyntax,
                                                                          attachedTo declaration: Declaration,
                                                                          providingAttributesFor member: MemberDeclaration,
                                                                          in context: Context) throws -> [AttributeSyntax] where Declaration : DeclGroupSyntax, MemberDeclaration : DeclSyntaxProtocol, Context : MacroExpansionContext {
        return [.init(stringLiteral: "@UserDefault")]
    }
}

// MARK: - MemberMacro

public struct DesccriptionMacro: MemberMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax,
                                                       providingMembersOf declaration: Declaration,
                                                       in context: Context) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            fatalError("compiler bug: unknown error")
        }
        
        let className = classDecl.name.text
        let variables = classDecl.memberBlock.members.compactMap { member -> PatternBindingListSyntax? in
            member.decl.as(VariableDeclSyntax.self)?.bindings
        }.compactMap { bindings -> String? in
            bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }.map({ "\($0): \\(\($0))" }).joined(separator: ", ")
        
        return ["""
                var description: String {
                    "\(raw: className)(\(raw: variables))"
                }
                """
        ]
    }
}
//
//public struct EquatableMacro: ExtensionMacro {
//    public static func expansion(of node: AttributeSyntax,
//                                 attachedTo declaration: some DeclGroupSyntax,
//                                 providingExtensionsOf type: some TypeSyntaxProtocol,
//                                 conformingTo protocols: [TypeSyntax],
//                                 in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
//        let encodableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): Encodable {}")
//        return [encodableExtension]
//    }
//}

@main
struct MyMacroLibraryPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        BinaryStringMacro.self,
        ConstantMacro.self,
        InterfaceMacro.self,
        UserDefaultMacro.self,
        DesccriptionMacro.self,
//        EquatableMacro.self
    ]
}
