// TraceKitIntegrationTests.swift
// TraceKitTests
//
// Created by jimmy on 2026-03-29.

import Foundation
import Testing
@testable import TraceKit

struct TraceKitIntegrationTests {
    // MARK: - PerformanceTracer Integration Tests

    @Test("TraceKit 빌더로 생성 시 PerformanceTracer가 로그 파이프라인에 연결됨")
    @TraceKitActor
    func performanceTracerConnectedToLogPipeline() async {
        let destination = InMemoryTestDestination()

        let traceKit = await TraceKitBuilder()
            .addDestination(destination)
            .with(configuration: .debug)
            .build()

        TraceKit.setShared(traceKit)
        await traceKit.connectTracerToLogging()

        let spanId = await traceKit.tracer.startSpan(name: "test_operation")
        try? await Task.sleep(nanoseconds: 10_000_000)
        _ = await traceKit.tracer.endSpan(id: spanId)
        await traceKit.flush()

        let messages = await destination.getMessages()
        let loggedMessages = messages.map { $0.message }
        #expect(loggedMessages.count > 0)
        #expect(loggedMessages.contains { $0.contains("test_operation") && $0.contains("completed") })
    }

    @Test("buildAsShared()로 생성 시 자동으로 tracer 연결됨")
    @TraceKitActor
    func buildAsSharedAutoConnectsTracer() async {
        let destination = InMemoryTestDestination()

        let traceKit = await TraceKitBuilder()
            .addDestination(destination)
            .with(configuration: .debug)
            .buildAsShared()

        let spanId = await traceKit.tracer.startSpan(name: "auto_connected_span")
        try? await Task.sleep(nanoseconds: 10_000_000)
        _ = await traceKit.tracer.endSpan(id: spanId)
        await traceKit.flush()

        let messages = await destination.getMessages()
        let loggedMessages = messages.map { $0.message }
        #expect(loggedMessages.count > 0)
        #expect(loggedMessages.contains { $0.contains("auto_connected_span") && $0.contains("completed") })
    }

    @Test("measure() 메서드도 로그 파이프라인으로 전송됨")
    @TraceKitActor
    func measureSendsToLogPipeline() async {
        let destination = InMemoryTestDestination()

        let traceKit = await TraceKitBuilder()
            .addDestination(destination)
            .with(configuration: .debug)
            .buildAsShared()

        let result = await traceKit.measure(name: "compute_task") {
            try? await Task.sleep(nanoseconds: 5_000_000)
            return 42
        }
        await traceKit.flush()

        let messages = await destination.getMessages()
        let loggedMessages = messages.map { $0.message }
        #expect(result == 42)
        #expect(loggedMessages.count > 0)
        #expect(loggedMessages.contains { $0.contains("compute_task") && $0.contains("completed") })
    }

    @Test("카테고리가 Performance로 설정됨")
    @TraceKitActor
    func tracerLogsHavePerformanceCategory() async {
        let destination = InMemoryTestDestination()

        let traceKit = await TraceKitBuilder()
            .addDestination(destination)
            .with(configuration: .debug)
            .buildAsShared()

        let spanId = await traceKit.tracer.startSpan(name: "test")
        _ = await traceKit.tracer.endSpan(id: spanId)
        await traceKit.flush()

        let messages = await destination.getMessages()
        let loggedCategories = messages.map { $0.category }
        #expect(loggedCategories.contains("Performance"))
    }

    @Test("부모-자식 span의 들여쓰기가 올바르게 표시됨")
    @TraceKitActor
    func parentChildSpanIndentation() async {
        let destination = InMemoryTestDestination()

        let traceKit = await TraceKitBuilder()
            .addDestination(destination)
            .with(configuration: .debug)
            .buildAsShared()

        let parentId = await traceKit.tracer.startSpan(name: "parent_operation")
        let childId = await traceKit.tracer.startSpan(name: "child_operation", parentId: parentId)

        _ = await traceKit.tracer.endSpan(id: childId)
        _ = await traceKit.tracer.endSpan(id: parentId)
        await traceKit.flush()

        let messages = await destination.getMessages()
        let loggedMessages = messages.map { $0.message }
        #expect(loggedMessages.count == 2)

        let childMessage = loggedMessages.first { $0.contains("child_operation") }
        #expect(childMessage?.contains("└") == true)

        let parentMessage = loggedMessages.first { $0.contains("parent_operation") }
        #expect(parentMessage?.hasPrefix("▶ ") == true)
    }

    // MARK: - Runtime Wiring Integration Tests

    @Test("removeDestination 호출 후 해당 destination으로는 더 이상 전달되지 않음")
    func removeDestinationDisablesDelivery() async {
        let logger = await makeLogger(configuration: .debug)
        let keepDestination = TestTraceDestination(identifier: "keep")
        let removedDestination = TestTraceDestination(identifier: "removed")

        await logger.addDestination(keepDestination)
        await logger.addDestination(removedDestination)
        await logger.removeDestination(identifier: "removed")
        await logger.info("hello")

        #expect(await keepDestination.messages().count == 1)
        #expect(await removedDestination.messages().isEmpty)
    }

    @Test("disabledDestinations 설정은 fan-out에서 즉시 반영됨")
    func disabledDestinationsAreRespected() async {
        let logger = await makeLogger(
            configuration: TraceKitConfiguration(disabledDestinations: ["disabled"])
        )
        let enabledDestination = TestTraceDestination(identifier: "enabled")
        let disabledDestination = TestTraceDestination(identifier: "disabled")

        await logger.addDestination(enabledDestination)
        await logger.addDestination(disabledDestination)
        await logger.info("hello")

        #expect(await enabledDestination.messages().count == 1)
        #expect(await disabledDestination.messages().isEmpty)
    }

    @Test("configure 호출 후 destination 비활성화가 즉시 반영됨")
    func configureUpdatesDisabledDestinationsImmediately() async {
        let logger = await makeLogger(configuration: .debug)
        let destination = TestTraceDestination(identifier: "toggle")

        await logger.addDestination(destination)
        await logger.info("before")

        await logger.configure(
            TraceKitConfiguration(disabledDestinations: ["toggle"])
        )
        await logger.info("after")

        let messages = await destination.messages()
        #expect(messages.count == 1)
        #expect(messages.first?.message == "before")
    }

    @Test("주입한 CrashTracePreserver를 통해 로그가 기록되고 복구 가능함")
    @TraceKitActor
    func builderUsesInjectedCrashPreserver() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tracekit-preserver-\(UUID().uuidString).json")
        let preserver = CrashTracePreserver(
            preserveCount: 10,
            storageURL: tempURL
        )
        let logger = await TraceKitBuilder()
            .withCrashPreserver(preserver)
            .build()

        await logger.error("builder wired preserver", category: "Integration")

        #expect(await preserver.count == 1)

        let recovered = try await preserver.recover()
        #expect(recovered?.count == 1)
        #expect(recovered?.first?.message == "builder wired preserver")

        await preserver.cleanup()
        try? FileManager.default.removeItem(at: tempURL)
        try? FileManager.default.removeItem(
            at: tempURL.deletingPathExtension().appendingPathExtension("mmap")
        )
    }
}

@TraceKitActor
private func makeLogger(configuration: TraceKitConfiguration) -> TraceKit {
    TraceKit(configuration: configuration)
}

private actor TestTraceDestination: TraceDestination {
    let identifier: String
    var minLevel: TraceLevel = .verbose
    var isEnabled: Bool = true

    private var storedMessages: [TraceMessage] = []

    init(identifier: String) {
        self.identifier = identifier
    }

    func log(_ message: TraceMessage) async {
        guard shouldLog(message) else { return }
        storedMessages.append(message)
    }

    func messages() -> [TraceMessage] {
        storedMessages
    }
}

private actor InMemoryTestDestination: TraceDestination {
    let identifier: String = "InMemoryTestDestination"
    var minLevel: TraceLevel = .verbose
    var isEnabled: Bool = true
    private var messages: [TraceMessage] = []

    func log(_ message: TraceMessage) async {
        messages.append(message)
    }

    func flush(_ messages: [TraceMessage]) async {
        self.messages.append(contentsOf: messages)
    }

    func getMessages() -> [TraceMessage] {
        messages
    }

    func clearMessages() {
        messages.removeAll()
    }
}
