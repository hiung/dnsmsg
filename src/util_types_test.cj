package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*

@Test
class UtilTypesTest {
    @TestCase
    func testNameFromBytes() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
                                  2, b'c', b'n', // "cn"
                                  0] // end of QName
        let name = Name.fromBytes(data)
        
        @Expect(name.labels == ["cangjie-lang", "cn"])
        @Expect(name.length == 15) // "cangjie-lang.cn" has 15 characters
        @Expect(name.toString() == "cangjie-lang.cn")
        @Expect(Name.tryFromBytes(data).isSome())
    }

    @TestCase
    func testNameFromBytesInvalidData() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
                                  2, b'c', b'n'] // Missing end of QName
        
        @ExpectThrows(Name.fromBytes(data))
        @Expect(Name.tryFromBytes(data).isNone())
    }

    @TestCase
    func testNameFromString() {
        let name = Name.fromString("cangjie-lang.cn")
        
        @Expect(name.labels == ["cangjie-lang", "cn"])
        @Expect(name.length == 15) // "cangjie-lang.cn" has 15 characters
        @Expect(name.toString() == "cangjie-lang.cn")
    }
}