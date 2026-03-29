// TraceKitIntegrationTests.swift
// TraceKitTests
//
// Created by jimmy on 2026-03-29.

import Foundation
import Testing
@testable import TraceKit

struct TraceKitIntegrationTests {
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
