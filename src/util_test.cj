package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*

@Test
class UtilTest {
    @TestCase
    func testReadUInt8() {
        let data: Array<UInt8> = [0x01, 0x02, 0x03]
        let stream = ByteArrayStream()
        stream.write(data)

        @Expect(readUInt8(stream) == Some(0x01))
        @Expect(readUInt8(stream) == Some(0x02))
        @Expect(readUInt8(stream) == Some(0x03))
        @Expect(readUInt8(stream).isNone()) // No more data
    }

    @TestCase
    func testReadUInt16() {
        let data: Array<UInt8> = [0x01, 0x02, 0x03, 0x04]
        let stream = ByteArrayStream()
        stream.write(data)

        @Expect(readUInt16(stream) == Some(0x0102))
        @Expect(readUInt16(stream) == Some(0x0304))
        @Expect(readUInt16(stream).isNone()) // No more data
    }

    @TestCase
    func testReadUInt8AndUInt16() {
        let data: Array<UInt8> = [0x01, 0x02, 0x03, 0x04]
        let stream = ByteArrayStream()
        stream.write(data)

        @Expect(readUInt8(stream) == Some(0x01))
        @Expect(readUInt16(stream) == Some(0x0203))
        @Expect(readUInt16(stream).isNone()) // No more data for UInt16
        @Expect(readUInt8(stream) == Some(0x04))
        @Expect(readUInt16(stream).isNone()) // No more data
    }

    @TestCase
    func testReadBytes() {
        let data: Array<UInt8> = [0x01, 0x02, 0x03, 0x04, 0x05]
        let stream = ByteArrayStream()
        stream.write(data)

        @Expect(readBytes(stream, -1).isNone()) // Invalid length
        @Expect(readBytes(stream, 2) == Some([0x01u8, 0x02u8]))
        @Expect(readBytes(stream, 2) == Some([0x03u8, 0x04u8]))
        @Expect(readBytes(stream, 2).isNone()) // No more data for 2 bytes
        @Expect(readBytes(stream, 1) == Some([0x05u8]))
    }

    @TestCase
    func testNameFromStream() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c',
            b'n', // "cn"
                0] // end of QName
        let stream = ByteArrayStream()
        stream.write(data)
        let name = Name.fromStream(stream)

        @Expect(name.labels == ["cangjie-lang", "cn"])
        @Expect(name.length == 15) // "cangjie-lang.cn" has 15 characters
        @Expect(name.toString() == "cangjie-lang.cn")
    }

    @TestCase
    func testNameFromStreamCompressionPointer() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
                2, b'c', b'n', // "cn"
                0, // end of QName
                0xFF, 0xFF, // delimited bytes
                3, b'w', b'w', b'w', // "www"
                0xc0, 0x00, // Pointer to the start of the name
                111
            ] 
        let stream = ByteArrayStream()
        stream.write(data)
        stream.seek(SeekPosition.End(-7)) // Move to the start of the name
        let name = Name.fromStream(stream)

        @Expect(name.labels == ["www", "cangjie-lang", "cn"])
        @Expect(name.length == 19) // "cangjie-lang.cn" has 15 characters
        @Expect(name.toString() == "www.cangjie-lang.cn")
        @Expect(readUInt8(stream) == Some(111)) // Read the last byte after the name, make sure the position is correct
    }

    @TestCase
    func testNameFromStreamInvalidData1() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c',
            b'n'] // Missing end of QName
        let stream = ByteArrayStream()
        stream.write(data)

        @ExpectThrows(Name.fromStream(stream))
        @Expect(Name.tryFromStream(stream).isNone())
    }

    @TestCase
    func testNameFromStreamInvalidData2() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c'] // Invalid bytes (should be 2 bytes for "cn")
        let stream = ByteArrayStream()
        stream.write(data)

        @ExpectThrows(Name.fromStream(stream))
        @Expect(Name.tryFromStream(stream).isNone())
    }

    @TestCase
    func testNameFromStreamInvalidData3() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g'] // Missing end of QName
        let stream = ByteArrayStream()
        stream.write(data)

        @ExpectThrows(Name.fromStream(stream))
        @Expect(Name.tryFromStream(stream).isNone())
    }

    @TestCase
    func testNameFromStreamInvalidData4() {
        let data: Array<UInt8> = [] // Empty data
        let stream = ByteArrayStream()
        stream.write(data)

        @ExpectThrows(Name.fromStream(stream))
        @Expect(Name.tryFromStream(stream).isNone())
    }

    @TestCase
    func testNameFromString() {
        let name = Name.fromString("cangjie-lang.cn")

        @Expect(name.labels == ["cangjie-lang", "cn"])
        @Expect(name.length == 15) // "cangjie-lang.cn" has 15 characters
        @Expect(name.toString() == "cangjie-lang.cn")
    }

    @TestCase
    func testNameToArray() {
        let name = Name.fromString("cangjie-lang.cn")
        let bytes = name.toArray()

        @Expect(bytes == [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g',
                          2, b'c', b'n', 0]) // Corresponding byte representation
    }
}
