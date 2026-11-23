import Foundation
#if canImport(zlib)
import zlib
#endif

enum ReferenceLoader {
    static func rows(named fileName: String) throws -> [[String]] {
        guard let root = Bundle.module.resourceURL else {
            throw NSError(domain: "ReferenceLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing Bundle.module resourceURL"])
        }
        let url = root.appendingPathComponent("Fixtures").appendingPathComponent(fileName)
        let text: String
        if fileName.hasSuffix(".gz") {
            text = try readGzip(url: url)
        } else {
            text = try String(contentsOf: url, encoding: .utf8)
        }
        var result: [[String]] = []
        var first = true
        text.enumerateLines { line, _ in
            if first {
                first = false
                return
            }
            if line.isEmpty { return }
            result.append(line.split(separator: ",", omittingEmptySubsequences: false).map(String.init))
        }
        return result
    }

    private static func readGzip(url: URL) throws -> String {
        #if canImport(zlib)
        guard let file = gzopen(url.path, "rb") else {
            throw NSError(domain: "ReferenceLoader", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to open gzip file \(url.path)"])
        }
        defer { gzclose(file) }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 65_536)
        while true {
            let count = buffer.withUnsafeMutableBytes { raw -> Int32 in
                gzread(file, raw.baseAddress, UInt32(raw.count))
            }
            if count > 0 {
                data.append(buffer, count: Int(count))
            } else {
                break
            }
        }
        guard let decoded = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ReferenceLoader", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 in \(url.lastPathComponent)"])
        }
        return decoded
        #else
        throw NSError(domain: "ReferenceLoader", code: 4, userInfo: [NSLocalizedDescriptionKey: "zlib unavailable"])
        #endif
    }
}
