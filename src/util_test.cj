package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*

@Test
class UtilTest {
    @TestCase
    func testReadUInt8() {
        let data: Array<UInt8> = [0x01, 0x02, 0x03]
        let buffer = ByteBuffer()
        buffer.write(data)

        @Expect(readUInt8(buffer) == Some(0x01))
        @Expect(readUInt8(buffer) == Some(0x02))
        @Expect(readUInt8(buffer) == Some(0x03))
        @Expect(readUInt8(buffer).isNone()) // No more data
    }

    @TestCase
    func testReadUInt16() {
        let data: Array<UInt8> = [0x01, 0x02, 0x03, 0x04]
        let buffer = ByteBuffer()
        buffer.write(data)

        @Expect(readUInt16(buffer) == Some(0x0102))
        @Expect(readUInt16(buffer) == Some(0x0304))
        @Expect(readUInt16(buffer).isNone()) // No more data
    }

    @TestCase
    func testReadUInt8AndUInt16() {
        let data: Array<UInt8> = [0x01, 0x02, 0x03, 0x04]
        let buffer = ByteBuffer()
        buffer.write(data)

        @Expect(readUInt8(buffer) == Some(0x01))
        @Expect(readUInt16(buffer) == Some(0x0203))
        @Expect(readUInt16(buffer).isNone()) // No more data for UInt16
        @Expect(readUInt8(buffer) == Some(0x04))
        @Expect(readUInt16(buffer).isNone()) // No more data
    }

    @TestCase
    func testReadBytes() {
        let data: Array<UInt8> = [0x01, 0x02, 0x03, 0x04, 0x05]
        let buffer = ByteBuffer()
        buffer.write(data)

        @Expect(readBytes(buffer, -1).isNone()) // Invalid length
        @Expect(readBytes(buffer, 2) == Some([0x01u8, 0x02u8]))
        @Expect(readBytes(buffer, 2) == Some([0x03u8, 0x04u8]))
        @Expect(readBytes(buffer, 2).isNone()) // No more data for 2 bytes
        @Expect(readBytes(buffer, 1) == Some([0x05u8]))
    }
}
