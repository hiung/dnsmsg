package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*

@Test
class ResourceTest {
    @TestCase
    func testFromBytes() {
        // DNS Resource Record for cangjie-lang.cn, Type A, Class IN, TTL 60, rdata 192.168.1.1
        let data:Array<UInt8> = [
            12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0,                                      // End of name
            0, 1,                                   // Type A
            0, 1,                                   // Class IN
            0, 0, 0, 60,                            // TTL: 60
            0, 4,                                   // rdLength: 4
            192, 168, 1, 1                          // rdata: 192.168.1.1
        ]

        let resource = Resource.fromBytes(data)
        @Expect(resource.name.toString() == "cangjie-lang.cn")
        @Expect(resource.rType == TypeA)
        @Expect(resource.rClass == ClassIN)
        @Expect(resource.ttl == 60)
        @Expect(resource.rdLength == 4)
        @Expect(resource.rdata == [192, 168, 1, 1])
        @ExpectThrows(Resource.fromBytes([1, 2, 3])) // Invalid data
    }
}