import Foundation

public enum Paths {
    public static let stateDirectory = URL(
        fileURLWithPath: "/Library/Application Support/Domicile",
        isDirectory: true
    )
    public static let snapshotURL = stateDirectory.appendingPathComponent("nat-snapshot.plist")
    public static let runStateURL = stateDirectory.appendingPathComponent("run.json")
}
