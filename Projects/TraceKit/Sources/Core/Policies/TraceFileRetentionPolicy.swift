// TraceFileRetentionPolicy.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 파일 보관 정책
/// - Note: 파일 보관 기간, 최대 크기 등을 정의
public struct TraceFileRetentionPolicy: Sendable, Equatable {
    /// 보관 일수
    public let retentionDays: Int

    /// 전체 로그 파일 최대 크기 (바이트)
    public let maxTotalSize: Int?

    /// 개별 파일 최대 크기 (바이트)
    public let maxFileSize: Int

    /// 자동 정리 간격 (초)
    public let cleanupInterval: TimeInterval

    /// 로그 파일 확장자
    public let fileExtension: String

    /// 로그 파일 이름 날짜 포맷
    public let dateFormat: String

    public init(
        retentionDays: Int = 7,
        maxTotalSize: Int? = 100 * 1024 * 1024, // 100MB
        maxFileSize: Int = 10 * 1024 * 1024, // 10MB
        cleanupInterval: TimeInterval = 3600, // 1시간
        fileExtension: String = "log",
        dateFormat: String = "yyyy-MM-dd"
    ) {
        self.retentionDays = retentionDays
        self.maxTotalSize = maxTotalSize
        self.maxFileSize = maxFileSize
        self.cleanupInterval = cleanupInterval
        self.fileExtension = fileExtension
        self.dateFormat = dateFormat
    }

    /// 기본 정책 (7일 보관)
    public static let `default` = TraceFileRetentionPolicy()

    /// 디버그용 정책 (1일 보관, 작은 크기)
    public static let debug = TraceFileRetentionPolicy(
        retentionDays: 1,
        maxTotalSize: 10 * 1024 * 1024,
        maxFileSize: 1 * 1024 * 1024
    )

    /// 장기 보관 정책 (30일)
    public static let longTerm = TraceFileRetentionPolicy(
        retentionDays: 30,
        maxTotalSize: 500 * 1024 * 1024,
        maxFileSize: 50 * 1024 * 1024
    )
}
