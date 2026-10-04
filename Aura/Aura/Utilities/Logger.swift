//
//  Logger.swift
//  Granola
//

import Foundation
import OSLog

public enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.nilkanth.Granola"
    
    public static let general = Logger(subsystem: subsystem, category: "general")
    public static let audio = Logger(subsystem: subsystem, category: "audio")
    public static let transcription = Logger(subsystem: subsystem, category: "transcription")
    public static let ai = Logger(subsystem: subsystem, category: "ai")
    public static let data = Logger(subsystem: subsystem, category: "data")
    public static let search = Logger(subsystem: subsystem, category: "search")
    public static let security = Logger(subsystem: subsystem, category: "security")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
}
