import Foundation
import os

public final class EventHub: Sendable {
    private struct State {
        var timeoutTasks: [UInt64: Task<Void, Never>] = [:]
        var lastTimeoutID: UInt64 = 0
    }

    private let stream: AsyncStream<Event>
    private let continuation: AsyncStream<Event>.Continuation
    private let state = OSAllocatedUnfairLock(initialState: State())

    public init() {
        var captured: AsyncStream<Event>.Continuation!
        stream = AsyncStream(bufferingPolicy: .unbounded) { captured = $0 }
        continuation = captured
    }

    public func yield(_ event: Event) {
        continuation.yield(event)
    }

    public func next() async -> Event? {
        var iterator = stream.makeAsyncIterator()
        return await iterator.next()
    }

    @discardableResult
    public func scheduleTimeout(after duration: Duration) -> UInt64 {
        let id = state.withLock { state -> UInt64 in
            state.lastTimeoutID += 1
            return state.lastTimeoutID
        }
        let task = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            yield(.timeout(id))
            _ = state.withLock { $0.timeoutTasks.removeValue(forKey: id) }
        }
        state.withLock { $0.timeoutTasks[id] = task }
        return id
    }

    public func cancelTimeout(_ id: UInt64) {
        let task = state.withLock { $0.timeoutTasks.removeValue(forKey: id) }
        task?.cancel()
    }
}
