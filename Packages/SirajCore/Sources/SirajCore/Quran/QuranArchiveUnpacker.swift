import Foundation
import zlib

public enum QuranArchiveError: Error, LocalizedError, Equatable {
    case openSourceFailed
    case createDestinationFailed
    case zlibInitFailed(Int32)
    case zlibInflateFailed(Int32)
    case invalidZipFormat
    case unsupportedCompression(UInt16)
    case unsafeZipPath(String)

    public var errorDescription: String? {
        switch self {
        case .openSourceFailed: return "Could not open archive file."
        case .createDestinationFailed: return "Could not create destination file."
        case .zlibInitFailed(let code): return "Failed to initialize decompression (\(code))."
        case .zlibInflateFailed(let code): return "Decompression failed (\(code))."
        case .invalidZipFormat: return "Archive header is invalid or corrupted."
        case .unsupportedCompression(let method): return "Unsupported zip compression method (\(method))."
        case .unsafeZipPath(let name): return "Blocked unsafe archive path: \(name)"
        }
    }
}

public enum QuranArchiveUnpacker {
    private static let chunkSize = 64 * 1024

    public static func gunzipFile(
        source: URL,
        destination: URL,
        onProgress: ((Double) -> Void)? = nil
    ) throws {
        guard let inHandle = try? FileHandle(forReadingFrom: source) else {
            throw QuranArchiveError.openSourceFailed
        }
        defer { try? inHandle.close() }

        let totalBytes = (try? FileManager.default.attributesOfItem(atPath: source.path)[.size] as? NSNumber)?.doubleValue ?? 0
        let fm = FileManager.default
        try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }
        guard fm.createFile(atPath: destination.path, contents: nil),
              let outHandle = try? FileHandle(forWritingTo: destination) else {
            throw QuranArchiveError.createDestinationFailed
        }
        defer { try? outHandle.close() }

        var stream = z_stream()
        // 15 + 32 instructs zlib to auto-detect and decode the gzip header and trailer.
        let initStatus = inflateInit2_(&stream, 15 + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else {
            throw QuranArchiveError.zlibInitFailed(initStatus)
        }
        defer { inflateEnd(&stream) }

        var outBuffer = [UInt8](repeating: 0, count: chunkSize)
        var bytesReadSoFar: Double = 0
        var reachedEnd = false

        while !reachedEnd {
            let inputData = try inHandle.read(upToCount: chunkSize) ?? Data()
            if inputData.isEmpty { break }
            bytesReadSoFar += Double(inputData.count)

            try inputData.withUnsafeBytes { rawIn in
                guard let inBase = rawIn.bindMemory(to: Bytef.self).baseAddress else { return }
                stream.next_in = UnsafeMutablePointer(mutating: inBase)
                stream.avail_in = uInt(inputData.count)

                while stream.avail_in > 0 {
                    var status: Int32 = Z_OK
                    var produced = 0
                    outBuffer.withUnsafeMutableBytes { rawOut in
                        guard let outBase = rawOut.bindMemory(to: Bytef.self).baseAddress else { return }
                        stream.next_out = outBase
                        stream.avail_out = uInt(chunkSize)
                        status = inflate(&stream, Z_NO_FLUSH)
                        produced = chunkSize - Int(stream.avail_out)
                    }

                    if produced > 0 {
                        try outHandle.write(contentsOf: outBuffer[0..<produced])
                    }

                    if status == Z_STREAM_END {
                        reachedEnd = true
                        break
                    } else if status != Z_OK && status != Z_BUF_ERROR {
                        throw QuranArchiveError.zlibInflateFailed(status)
                    }
                }
            }

            if totalBytes > 0 {
                onProgress?(min(1.0, bytesReadSoFar / totalBytes))
            }
        }

        if !reachedEnd {
            throw QuranArchiveError.zlibInflateFailed(Z_DATA_ERROR)
        }
        onProgress?(1.0)
    }

    public static func gunzipData(_ data: Data) throws -> Data {
        guard !data.isEmpty else { return Data() }
        var stream = z_stream()
        let initStatus = inflateInit2_(&stream, 15 + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else {
            throw QuranArchiveError.zlibInitFailed(initStatus)
        }
        defer { inflateEnd(&stream) }

        var output = Data()
        var outBuffer = [UInt8](repeating: 0, count: chunkSize)

        try data.withUnsafeBytes { rawIn in
            guard let inBase = rawIn.bindMemory(to: Bytef.self).baseAddress else { return }
            stream.next_in = UnsafeMutablePointer(mutating: inBase)
            stream.avail_in = uInt(data.count)

            var status: Int32 = Z_OK
            repeat {
                var produced = 0
                outBuffer.withUnsafeMutableBytes { rawOut in
                    guard let outBase = rawOut.bindMemory(to: Bytef.self).baseAddress else { return }
                    stream.next_out = outBase
                    stream.avail_out = uInt(chunkSize)
                    status = inflate(&stream, Z_NO_FLUSH)
                    produced = chunkSize - Int(stream.avail_out)
                }
                if produced > 0 {
                    output.append(contentsOf: outBuffer[0..<produced])
                }
                if status != Z_OK && status != Z_STREAM_END {
                    throw QuranArchiveError.zlibInflateFailed(status)
                }
            } while status != Z_STREAM_END
        }

        return output
    }

    public static func unzipDirectory(
        source: URL,
        destination: URL,
        flattenBasename: Bool = false,
        onProgress: ((Double) -> Void)? = nil
    ) throws {
        guard let data = try? Data(contentsOf: source, options: .mappedIfSafe) else {
            throw QuranArchiveError.openSourceFailed
        }
        let fm = FileManager.default
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        let canonicalDest = destination.standardizedFileURL.path

        // Locate End of Central Directory (0x06054b50) scanning backward from the end of the archive.
        let count = data.count
        guard count >= 22 else { throw QuranArchiveError.invalidZipFormat }
        let minOffset = max(0, count - 65557)
        var eocdOffset = -1
        for offset in stride(from: count - 22, through: minOffset, by: -1) {
            if readUInt32LE(data, at: offset) == 0x06054b50 {
                eocdOffset = offset
                break
            }
        }
        guard eocdOffset >= 0 else { throw QuranArchiveError.invalidZipFormat }

        let totalEntries = Int(readUInt16LE(data, at: eocdOffset + 10))
        let cdSize = Int(readUInt32LE(data, at: eocdOffset + 12))
        let cdOffset = Int(readUInt32LE(data, at: eocdOffset + 16))
        guard cdOffset >= 0, cdOffset + cdSize <= count else {
            throw QuranArchiveError.invalidZipFormat
        }

        var cursor = cdOffset
        for idx in 0..<totalEntries {
            guard cursor + 46 <= count, readUInt32LE(data, at: cursor) == 0x02014b50 else {
                throw QuranArchiveError.invalidZipFormat
            }
            let method = readUInt16LE(data, at: cursor + 10)
            let compressedSize = Int(readUInt32LE(data, at: cursor + 20))
            let uncompressedSize = Int(readUInt32LE(data, at: cursor + 24))
            let nameLen = Int(readUInt16LE(data, at: cursor + 28))
            let extraLen = Int(readUInt16LE(data, at: cursor + 30))
            let commentLen = Int(readUInt16LE(data, at: cursor + 32))
            let localHeaderOffset = Int(readUInt32LE(data, at: cursor + 42))

            let nameStart = cursor + 46
            guard nameStart + nameLen <= count else { throw QuranArchiveError.invalidZipFormat }
            let rawName = String(data: data[nameStart..<(nameStart + nameLen)], encoding: .utf8) ?? ""
            cursor = nameStart + nameLen + extraLen + commentLen

            if rawName.isEmpty || rawName.hasSuffix("/") {
                continue
            }
            // Reject absolute paths and parent traversal segments before writing anything.
            if rawName.hasPrefix("/") || rawName.hasPrefix("\\") || rawName.split(separator: "/").contains("..") || rawName.split(separator: "\\").contains("..") {
                throw QuranArchiveError.unsafeZipPath(rawName)
            }

            let targetURL: URL
            if flattenBasename {
                let base = (rawName as NSString).lastPathComponent
                if base.isEmpty || base.hasPrefix(".") { continue }
                targetURL = destination.appendingPathComponent(base).standardizedFileURL
            } else {
                targetURL = destination.appendingPathComponent(rawName).standardizedFileURL
            }
            guard targetURL.path == canonicalDest || targetURL.path.hasPrefix(canonicalDest + "/") else {
                throw QuranArchiveError.unsafeZipPath(rawName)
            }

            guard localHeaderOffset + 30 <= count, readUInt32LE(data, at: localHeaderOffset) == 0x04034b50 else {
                throw QuranArchiveError.invalidZipFormat
            }
            let localNameLen = Int(readUInt16LE(data, at: localHeaderOffset + 26))
            let localExtraLen = Int(readUInt16LE(data, at: localHeaderOffset + 28))
            let payloadStart = localHeaderOffset + 30 + localNameLen + localExtraLen
            let payloadEnd = payloadStart + compressedSize
            guard payloadStart >= 0, payloadEnd <= count else {
                throw QuranArchiveError.invalidZipFormat
            }

            try fm.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let payload = data[payloadStart..<payloadEnd]

            switch method {
            case 0:
                try payload.write(to: targetURL, options: .atomic)
            case 8:
                let inflated = try inflateRawDeflate(payload, expectedSize: uncompressedSize)
                try inflated.write(to: targetURL, options: .atomic)
            default:
                throw QuranArchiveError.unsupportedCompression(method)
            }

            if totalEntries > 0 {
                onProgress?(Double(idx + 1) / Double(totalEntries))
            }
        }
        onProgress?(1.0)
    }

    private static func inflateRawDeflate(_ slice: Data, expectedSize: Int) throws -> Data {
        if slice.isEmpty { return Data() }
        var stream = z_stream()
        // Negative windowBits (-15) tells zlib the payload is raw DEFLATE with no zlib/gzip wrapper.
        let initStatus = inflateInit2_(&stream, -15, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else {
            throw QuranArchiveError.zlibInitFailed(initStatus)
        }
        defer { inflateEnd(&stream) }

        var output = Data()
        if expectedSize > 0 && expectedSize < 32 * 1024 * 1024 {
            output.reserveCapacity(expectedSize)
        }
        var outBuffer = [UInt8](repeating: 0, count: chunkSize)

        try slice.withUnsafeBytes { rawIn in
            guard let inBase = rawIn.bindMemory(to: Bytef.self).baseAddress else { return }
            stream.next_in = UnsafeMutablePointer(mutating: inBase)
            stream.avail_in = uInt(slice.count)

            var status: Int32 = Z_OK
            repeat {
                var produced = 0
                outBuffer.withUnsafeMutableBytes { rawOut in
                    guard let outBase = rawOut.bindMemory(to: Bytef.self).baseAddress else { return }
                    stream.next_out = outBase
                    stream.avail_out = uInt(chunkSize)
                    status = inflate(&stream, Z_NO_FLUSH)
                    produced = chunkSize - Int(stream.avail_out)
                }
                if produced > 0 {
                    output.append(contentsOf: outBuffer[0..<produced])
                }
                if status != Z_OK && status != Z_STREAM_END {
                    throw QuranArchiveError.zlibInflateFailed(status)
                }
            } while status != Z_STREAM_END
        }
        return output
    }

    public static func crc32Checksum(_ data: Data) -> UInt32 {
        data.withUnsafeBytes { raw in
            guard let base = raw.bindMemory(to: Bytef.self).baseAddress else { return 0 }
            let val = zlib.crc32(0, base, uInt(data.count))
            return UInt32(truncatingIfNeeded: val)
        }
    }

    private static func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
