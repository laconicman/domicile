import Foundation

public enum DefaultRoute {
    private static let rtaxMax = 8

    public static func interface(to destination: String = "1.1.1.1") throws -> String? {
        let fd = socket(PF_ROUTE, SOCK_RAW, 0)
        guard fd >= 0 else { throw GatewayError.route("socket: \(String(cString: strerror(errno)))") }
        defer { close(fd) }

        var tv = timeval(tv_sec: 5, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        let headerLen = MemoryLayout<rt_msghdr>.size
        let total = headerLen + MemoryLayout<sockaddr_in>.size

        var request = rt_msghdr()
        request.rtm_msglen = UInt16(total)
        request.rtm_version = UInt8(RTM_VERSION)
        request.rtm_type = UInt8(RTM_GET)
        request.rtm_flags = Int32(RTF_UP | RTF_GATEWAY | RTF_HOST)
        request.rtm_addrs = Int32(RTA_DST | RTA_IFP)
        request.rtm_pid = getpid()
        request.rtm_seq = Int32(truncatingIfNeeded: getpid())

        var dst = sockaddr_in()
        dst.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        dst.sin_family = sa_family_t(AF_INET)
        dst.sin_addr.s_addr = inet_addr(destination)

        var out = [UInt8](repeating: 0, count: total)
        out.withUnsafeMutableBytes { raw in
            _ = memcpy(raw.baseAddress!, &request, headerLen)
            _ = memcpy(raw.baseAddress!.advanced(by: headerLen), &dst, MemoryLayout<sockaddr_in>.size)
        }

        let written = out.withUnsafeBytes { write(fd, $0.baseAddress, $0.count) }
        guard written == total else {
            throw GatewayError.route("write: \(String(cString: strerror(errno)))")
        }

        var buffer = [UInt8](repeating: 0, count: 8192)
        while true {
            let n = buffer.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) }
            if n < 0 {
                if errno == EINTR { continue }
                throw GatewayError.route("read: \(String(cString: strerror(errno)))")
            }
            if n == 0 { continue }

            var found: String?
            var matched = false
            buffer.withUnsafeBytes { raw in
                var offset = 0
                while offset + headerLen <= n {
                    let base = raw.baseAddress!.advanced(by: offset)
                    let msg = base.assumingMemoryBound(to: rt_msghdr.self).pointee
                    let msgLen = Int(msg.rtm_msglen)
                    guard msgLen >= headerLen, offset + msgLen <= n else { break }
                    offset += msgLen
                    guard msg.rtm_version == RTM_VERSION,
                          msg.rtm_type == UInt8(RTM_GET),
                          msg.rtm_pid == getpid() else { continue }
                    matched = true
                    found = parseAddresses(msg: msg, base: base + headerLen, limit: base + msgLen)
                    break
                }
            }
            if matched { return found }
        }
    }

    private static func parseAddresses(msg: rt_msghdr, base: UnsafeRawPointer, limit: UnsafeRawPointer) -> String? {
        var cursor = base
        for bit in 0 ..< rtaxMax {
            guard msg.rtm_addrs & Int32(1 << bit) != 0 else { continue }
            guard cursor + MemoryLayout<sockaddr>.size <= limit else { return nil }
            let sa = cursor.assumingMemoryBound(to: sockaddr.self).pointee
            if bit == ffsBit(RTA_IFP) {
                guard cursor + MemoryLayout<sockaddr_dl>.size <= limit else { return nil }
                var dl = cursor.assumingMemoryBound(to: sockaddr_dl.self).pointee
                let nlen = Int(dl.sdl_nlen)
                return withUnsafeBytes(of: &dl.sdl_data) { raw in
                    String(decoding: raw.prefix(nlen), as: UTF8.self)
                }
            }
            let len = Int(sa.sa_len)
            cursor += len > 0 ? (len + 3) & ~3 : 4
        }
        return nil
    }

    private static func ffsBit(_ mask: Int32) -> Int {
        var bit = 0
        var m = mask
        while m > 1 { m >>= 1; bit += 1 }
        return bit
    }
}
