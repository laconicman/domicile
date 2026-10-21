import DomicileCore
import Testing

@Suite("TraceResponse")
struct TraceResponseTests {
    @Test func parsesFullSample() throws {
        let sample = """
        fl=123f45
        h=cloudflare.com
        ip=203.0.113.7
        ts=1690000000.0
        visit_scheme=https
        uag=curl/8.0
        colo=SJC
        sliver=none
        http=http/1.1
        loc=US
        tls=TLSv1.3
        sni=plaintext
        warp=off
        gateway=off
        rbi=off
        kex=X25519
        """
        let trace = try #require(TraceResponse(parsing: sample))
        #expect(trace.ip == "203.0.113.7")
        #expect(trace.loc == "US")
        #expect(trace.colo == "SJC")
    }

    @Test func missingIPIsNil() {
        #expect(TraceResponse(parsing: "fl=1\nloc=US\n") == nil)
        #expect(TraceResponse(parsing: "") == nil)
    }

    @Test func toleratesCRLFAndTrailingBlankLines() throws {
        let sample = "ip=198.51.100.4\r\ncolo=FRA\r\n\r\n"
        let trace = try #require(TraceResponse(parsing: sample))
        #expect(trace.ip == "198.51.100.4")
        #expect(trace.colo == "FRA")
        #expect(trace.loc == nil)
    }
}
