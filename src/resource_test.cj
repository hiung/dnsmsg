package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.net.*

@Test
class ResourceTest {
    @TestCase
    func testResourceFromBytesForA() {
        let data: Array<UInt8> = [
            12,
            b'c',
            b'a',
            b'n',
            b'g',
            b'j',
            b'i',
            b'e',
            b'-',
            b'l',
            b'a',
            b'n',
            b'g', // "cangjie-lang"
            2,
            b'c',
            b'n', // "cn"
            0, // End of name
            0,
            1, // Type A
            0,
            1, // Class IN
            0,
            0,
            0,
            60, // TTL 60 seconds
            0,
            4, // RDATA length
            192,
            168,
            1,
            1 //  rdata for A record 
        ]
        let buffer = ByteBuffer()
        buffer.write(data)

        let resource = ResourceRecord.fromBytes(buffer)
        @Expect(resource.name.toString() == "cangjie-lang.cn")
        @Expect(resource.rType == TypeA)
        @Expect(resource.rClass == ClassIN)
        @Expect(resource.ttl == 60)
        @Expect(resource.rData == RData.A(IPv4Address(192, 168, 1, 1)))
    }

    @TestCase
    func testResourceFromBytesForNS() {
        let data: Array<UInt8> = [
            12,
            b'c',
            b'a',
            b'n',
            b'g',
            b'j',
            b'i',
            b'e',
            b'-',
            b'l',
            b'a',
            b'n',
            b'g', // "cangjie-lang"
            2,
            b'c',
            b'n', // "cn"
            0, // End of name
            0,
            2, // Type NS
            0,
            1, // Class IN
            0,
            0,
            0,
            60, // TTL 60 seconds
            0,
            5, // RDATA length
            2,
            b'n',
            b's', // "ns"
            0xc0,
            0x00 // Pointer to the start of the name
        ]
        let buffer = ByteBuffer()
        buffer.write(data)

        let resource = ResourceRecord.fromBytes(buffer)
        @Expect(resource.name.toString() == "cangjie-lang.cn")
        @Expect(resource.rType == TypeNS)
        @Expect(resource.rClass == ClassIN)
        @Expect(resource.ttl == 60)
        @Expect(resource.rData == RData.NS(Name("ns.cangjie-lang.cn")))
    }
}
