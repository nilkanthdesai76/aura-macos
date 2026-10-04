//
//  DependencyContainer.swift
//  Granola
//

import Foundation

public final class DependencyContainer: @unchecked Sendable {
    public static let shared = DependencyContainer()
    
    public let audioCaptureManager: AudioCaptureManager
    public let streamingTranscriber: StreamingTranscriber
    public let aiService: AIService
    public let meetingRepository: LocalMeetingRepository
    public let searchService: SearchService
    
    public init(
        audioCaptureManager: AudioCaptureManager = AudioCaptureManager(),
        streamingTranscriber: StreamingTranscriber = StreamingTranscriber(),
        aiService: AIService = AIService(),
        meetingRepository: LocalMeetingRepository = LocalMeetingRepository.shared,
        searchService: SearchService = SearchService()
    ) {
        self.audioCaptureManager = audioCaptureManager
        self.streamingTranscriber = streamingTranscriber
        self.aiService = aiService
        self.meetingRepository = meetingRepository
        self.searchService = searchService
    }
}
