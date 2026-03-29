// FirebasePerformanceTraceExtension.swift
// TraceKitDemo
//
// Created by jimmy on 2026-01-22.

import Foundation
import TraceKit
import FirebasePerformance

/// Firebase Performance와 TraceKit 통합
///
/// TraceKit의 PerformanceTracer를 Firebase Performance Monitoring과 연동합니다.
/// TraceSpan을 Firebase Trace로 변환하여 성능 데이터를 Firebase Console에서 확인할 수 있습니다.
///
/// ## 주요 기능
/// - TraceSpan → Firebase Trace 자동 변환
/// - 커스텀 메트릭 전송 (duration, memory, custom attributes)
/// - 네트워크 요청 추적과 연계
///
/// ## 사용 예시
/// ```swift
/// let span = await TraceKit.async.span(operation: "fetchUserData")
/// try await performNetworkRequest()
/// await span.end()
/// await span.sendToFirebasePerformance()
/// ```
extension TraceSpan {
    /// TraceSpan을 Firebase Performance Trace로 전송
    ///
    /// 완료된 span의 성능 데이터를 Firebase Performance에 기록합니다.
    /// span이 아직 진행 중이면 자동으로 종료합니다.
    func sendToFirebasePerformance() async {
        guard await FirebaseIntegrationRuntime.shared.isPerformanceEnabled() else {
            return
        }

        guard let trace = Performance.startTrace(name: sanitizeTraceName(name)) else {
            return
        }
        
        addMetrics(to: trace)
        addAttributes(to: trace)
        
        trace.stop()
    }
    
    /// Firebase Performance Trace 이름 규칙에 맞게 정제
    ///
    /// Firebase Performance Trace 이름 규칙:
    /// - 100자 이내
    /// - 알파벳으로 시작
    /// - 언더스코어로 단어 구분
    private func sanitizeTraceName(_ name: String) -> String {
        let sanitized = name
            .prefix(100)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "", options: .regularExpression)
        
        if sanitized.first?.isLetter == false {
            return "trace_\(sanitized)"
        }
        
        return String(sanitized)
    }
    
    /// TraceSpan의 메트릭을 Firebase Trace에 추가
    private func addMetrics(to trace: Trace) {
        if let durationMs = durationMs {
            let durationMsInt = Int64(durationMs)
            trace.setValue(durationMsInt, forMetric: "duration_ms")
        }
        
        for (key, value) in metadata {
            if let numericValue = extractNumericValue(value) {
                trace.setValue(numericValue, forMetric: sanitizeMetricName(key))
            }
        }
    }
    
    /// TraceSpan의 속성을 Firebase Trace에 추가
    private func addAttributes(to trace: Trace) {
        for (key, value) in metadata {
            let stringValue = String(describing: value)
            trace.setValue(
                String(stringValue.prefix(100)),
                forAttribute: sanitizeAttributeName(key)
            )
        }
    }
    
    /// 메트릭 이름 정제
    private func sanitizeMetricName(_ name: String) -> String {
        let sanitized = name
            .prefix(100)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "", options: .regularExpression)
        
        return String(sanitized)
    }
    
    /// 속성 이름 정제
    private func sanitizeAttributeName(_ name: String) -> String {
        let sanitized = name
            .prefix(40)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "", options: .regularExpression)
        
        return String(sanitized)
    }
    
    /// AnyCodable 값에서 숫자 추출
    private func extractNumericValue(_ value: AnyCodable) -> Int64? {
        if let intValue = value.value as? Int {
            return Int64(intValue)
        }
        
        if let doubleValue = value.value as? Double {
            return Int64(doubleValue)
        }
        
        return nil
    }
}

/// Firebase Performance를 활용한 성능 추적 헬퍼
///
/// TraceKit과 Firebase Performance를 함께 사용하는 편의 메서드를 제공합니다.
enum FirebasePerformanceHelper {
    /// 성능 추적과 함께 비동기 작업 실행
    ///
    /// TraceKit span과 Firebase Performance trace를 동시에 생성하고,
    /// 작업 완료 후 두 시스템에 모두 기록합니다.
    ///
    /// - Parameters:
    ///   - name: 추적 이름
    ///   - operation: 실행할 비동기 작업
    /// - Returns: 작업 결과
    static func trace<T>(
        name: String,
        operation: () async throws -> T
    ) async throws -> T {
        let spanId = await TraceKit.async.startSpan(name: name)

        guard await FirebaseIntegrationRuntime.shared.isPerformanceEnabled() else {
            do {
                let result = try await operation()
                await TraceKit.async.endSpan(id: spanId)
                return result
            } catch {
                await TraceKit.async.endSpan(
                    id: spanId,
                    metadata: ["error": AnyCodable(error.localizedDescription)]
                )
                throw error
            }
        }

        guard let firebaseTrace = Performance.startTrace(name: name) else {
            // Firebase trace 생성 실패 시에도 TraceKit span은 계속 진행
            defer {
                Task {
                    await TraceKit.async.endSpan(id: spanId)
                }
            }
            return try await operation()
        }
        
        do {
            let result = try await operation()
            if let completedSpan = await TraceKit.async.tracer.endSpan(id: spanId) {
                firebaseTrace.stop()
                await completedSpan.sendToFirebasePerformance()
            }
            return result
        } catch {
            await TraceKit.async.endSpan(id: spanId)
            firebaseTrace.stop()
            throw error
        }
    }
}

actor FirebaseIntegrationRuntime {
    static let shared = FirebaseIntegrationRuntime()

    private var performanceEnabled: Bool = true

    func setPerformanceEnabled(_ enabled: Bool) {
        performanceEnabled = enabled
    }

    func isPerformanceEnabled() -> Bool {
        performanceEnabled
    }
}
