package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*

@Test
class ResourceTest {
    @TestCase
    func testResourceFromStreamForA() {
        let data: Array<UInt8> = [
            12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // End of name
            0, 1, // Type A
            0, 1, // Class IN
            0, 0, 0, 60, // TTL 60 seconds
            0, 4, // RDATA length
            192, 168, 1, 1 //  rdata for A record 
        ]
        let stream = ByteArrayStream()
        stream.write(data)

         Record.A(IPv4(192, 168, 1,1))

        let resource = Resource.fromStream(stream)
        @Expect(resource.name.toString() == "cangjie-lang.cn")
        @Expect(resource.rType == TypeA)
        @Expect(resource.rClass == ClassIN)
        @Expect(resource.ttl == 60)
        @Expect(resource.rdLength == 4)
        @Expect(match (resource.record) {
            case Record.A(addr) => addr.toString() == "192.168.1.1"
            case _ => false
        })
    }

    @TestCase
    func testResourceFromStreamForNS() {
        let data: Array<UInt8> = [
            12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // End of name
            0, 2, // Type NS
            0, 1, // Class IN
            0, 0, 0, 60, // TTL 60 seconds
            0, 5, // RDATA length
            2, b'n', b's', // "ns"
            0xc0, 0x00 // Pointer to the start of the name
        ]
        let stream = ByteArrayStream()
        stream.write(data)

        let resource = Resource.fromStream(stream)
        @Expect(resource.name.toString() == "cangjie-lang.cn")
        @Expect(resource.rType == TypeNS)
        @Expect(resource.rClass == ClassIN)
        @Expect(resource.ttl == 60)
        @Expect(resource.rdLength == 5)
        @Expect(match (resource.record) {
            case Record.NS(name) => name.toString() == "ns.cangjie-lang.cn"
            case _ => false
        })
    }
}

