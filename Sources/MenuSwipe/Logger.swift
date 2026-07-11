import Foundation

/// Dead-simple append logger for debugging. Writes to /tmp/menuswipe.log.
enum Log {
    private static let url = URL(fileURLWithPath: "/tmp/menuswipe.log")
    private static let q = DispatchQueue(label: "menuswipe.log")

    static func write(_ s: String) {
        q.async {
            let line = "\(Date()) \(s)\n"
            let data = Data(line.utf8)
            if FileManager.default.fileExists(atPath: url.path),
               let h = try? FileHandle(forWritingTo: url) {
                h.seekToEndOfFile()
                h.write(data)
                try? h.close()
            } else {
                try? data.write(to: url)
            }
        }
    }
}
