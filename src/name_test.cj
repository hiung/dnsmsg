package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*

@Test
class NameTest {
    @TestCase
    func testNameFromBytes() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c',
            b'n', // "cn"
                0] // end of QName
        let buffer = ByteBuffer()
        buffer.write(data)
        let name = Name.fromBytes(buffer)

        @Expect(name.labels == ["cangjie-lang", "cn"])
        @Expect(name.toString() == "cangjie-lang.cn")
    }

    @TestCase
    func testNameFromBytesCompressionPointer() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
                2, b'c', b'n', // "cn"
                0, // end of QName
                0xFF, 0xFF, // delimited bytes
                3, b'w', b'w', b'w', // "www"
                0xc0, 0x00, // pointer 
                111
            ] 
        let buffer = ByteBuffer()
        buffer.write(data)
        buffer.seek(SeekPosition.End(-7)) // Move to the start of the last domain name
        let name = Name.fromBytes(buffer)

        @Expect(name.labels == ["www", "cangjie-lang", "cn"])
        @Expect(name.toString() == "www.cangjie-lang.cn")
        @Expect(readUInt8(buffer) == Some(111)) // Read the last byte after the name, make sure the position is correct
    }

    @TestCase
    func testNameFromBytesInvalidData1() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c',
            b'n'] // Missing end of QName
        let buffer = ByteBuffer()
        buffer.write(data)

        @ExpectThrows(Name.fromBytes(buffer))
    }

    @TestCase
    func testNameFromBytesInvalidData2() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c'] // Invalid bytes (should be 2 bytes for "cn")
        let buffer = ByteBuffer()
        buffer.write(data)

        @ExpectThrows(Name.fromBytes(buffer))
    }

    @TestCase
    func testNameFromBytesInvalidData3() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g'] // Missing end of QName
        let buffer = ByteBuffer()
        buffer.write(data)

        @ExpectThrows(Name.fromBytes(buffer))
    }

    @TestCase
    func testNameFromBytesInvalidData4() {
        let data: Array<UInt8> = [] // Empty data
        let buffer = ByteBuffer()
        buffer.write(data)

        @ExpectThrows(Name.fromBytes(buffer))
    }

    @TestCase
    func testNameFromString() {
        let name = Name("cangjie-lang.cn")

        @Expect(name.labels == ["cangjie-lang", "cn"])
        @Expect(name.toString() == "cangjie-lang.cn")
    }
}
