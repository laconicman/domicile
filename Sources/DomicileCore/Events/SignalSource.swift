import Foundation

public final class SignalSource: @unchecked Sendable {
    private let sources: [DispatchSourceSignal]

    public init(signals: [Int32] = [SIGINT, SIGTERM, SIGHUP], hub: EventHub) {
        let queue = DispatchQueue(label: "com.learnable.domicile.signals")
        sources = signals.map { sig in
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: queue)
            source.setEventHandler { hub.yield(.signal(sig)) }
            source.resume()
            return source
        }
    }

    deinit {
        for source in sources { source.cancel() }
    }
}
