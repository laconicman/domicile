import Foundation
import os.log

public enum Console {
    private static let logger = Logger(subsystem: "com.learnable.domicile", category: "cli")

    public static func step(_ message: String) {
        emit("step: \(message)", error: false)
    }

    public static func ok(_ message: String) {
        emit("ok: \(message)", error: false)
    }

    public static func info(_ message: String) {
        emit(message, error: false)
    }

    public static func warn(_ message: String) {
        emit("warning: \(message)", error: true)
    }

    public static func fail(_ message: String) {
        emit("error: \(message)", error: true)
    }

    private static func emit(_ line: String, error: Bool) {
        // TODO(TD-2): route output behind a reporter seam for the XPC helper
        if error {
            FileHandle.standardError.write(Data((line + "\n").utf8))
        } else {
            FileHandle.standardOutput.write(Data((line + "\n").utf8))
        }
        logger.log("\(line, privacy: .public)")
    }
}
