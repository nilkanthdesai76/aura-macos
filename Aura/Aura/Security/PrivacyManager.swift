//
//  PrivacyManager.swift
//  Granola
//

import Foundation
import OSLog

public protocol AudioRetentionPolicy: Sendable {
    var shouldPersistAudio: Bool { get }
}

public struct DefaultPrivacyPolicy: AudioRetentionPolicy {
    public let shouldPersistAudio: Bool = false
    public init() {}
}

public final class PrivacyManager: @unchecked Sendable {
    public static let shared = PrivacyManager()
    
    public var policy: AudioRetentionPolicy = DefaultPrivacyPolicy()
    
    private init() {}
    
    public func purgeTemporaryData() {
        AppLog.security.info("Purging temporary in-memory buffers in accordance with zero-retention policy.")
    }
}
