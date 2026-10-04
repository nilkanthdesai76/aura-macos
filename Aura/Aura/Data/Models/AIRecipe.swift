//
//  AIRecipe.swift
//  Granola
//

import Foundation

public struct AIRecipe: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var icon: String
    public var description: String
    public var promptDirective: String
    
    public init(
        id: String,
        name: String,
        icon: String,
        description: String,
        promptDirective: String
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.promptDirective = promptDirective
    }
    
    public static let standard = AIRecipe(
        id: "general",
        name: "General Meeting",
        icon: "doc.text",
        description: "Balanced synthesis with summary, decisions, action items, and quotes.",
        promptDirective: "Focus on summarizing the core discussions, explicit decisions, and clear action items with assigned owners."
    )
    
    public static let engineering = AIRecipe(
        id: "engineering",
        name: "Engineering Sync",
        icon: "gearshape.2",
        description: "Emphasizes architecture decisions, technical risks, API changes, and blockers.",
        promptDirective: "Focus heavily on technical details, architectural decisions, API schema changes, performance risks, and engineering blockers."
    )
    
    public static let sales = AIRecipe(
        id: "sales",
        name: "Sales Discovery",
        icon: "briefcase",
        description: "Extracts customer pain points, budget, decision makers, and objections.",
        promptDirective: "Structure findings around customer pain points, current tool stack, budget, timeline, decision criteria (MEDDPICC), and explicit next steps."
    )
    
    public static let oneOnOne = AIRecipe(
        id: "1on1",
        name: "1-on-1 Catchup",
        icon: "person.2",
        description: "Tracks feedback, career goals, personal updates, and blockers to resolve.",
        promptDirective: "Focus on interpersonal updates, feedback exchanged, personal blockers, alignment on goals, and commitments made for the next 1-on-1."
    )
    
    public static let allDefaultRecipes: [AIRecipe] = [
        .standard,
        .engineering,
        .sales,
        .oneOnOne
    ]
}
