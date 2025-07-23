package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*

@Test
class HeaderTest {
    @TestCase
    func testToOpCode() {
        @Expect(0u8.toOpCode()== OpCode.Query )

        @Expect(1u8.toOpCode() == OpCode.IQuery)

        @Expect(2u8.toOpCode() == OpCode.Status)

        @Expect(3u8.toOpCode() == OpCode.Unknown(3u8))
    }

    @TestCase
    func testToRCode() {
        @Expect(0u8.toRCode() == RCode.NoError)

        @Expect(1u8.toRCode() == RCode.FormatError)

        @Expect(2u8.toRCode() == RCode.ServerFailure)

        @Expect(3u8.toRCode() == RCode.NameError)

        @Expect(4u8.toRCode() == RCode.NotImplemented)

        @Expect(5u8.toRCode() == RCode.Refused)

        @Expect(6u8.toRCode() == RCode.Unknown(6u8))
    }

    @TestCase
    func testFlags() {
        let flags = Flags(0x8f81)
        @Expect(flags.response == true)
        @Expect(flags.opCode == OpCode.IQuery)
        @Expect(flags.authoritative == true)   
        @Expect(flags.truncated == true)
        @Expect(flags.recursionDesired == true)
        @Expect(flags.recursionAvailable == true)
        @Expect(flags.rCode == RCode.FormatError)
        @Expect(flags.toUInt16() == 0x8f81)
    }

    @TestCase
    func testHeaderFromBytes() {
        let data: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00, // Flags: response, opcode=Query, authoritative, truncated, recursion desired, recursion available, rcode=NoError
            0x00, 0x01, // QDCount
            0x00, 0x00, // ANCount
            0x00, 0x00, // NSCount
            0x00, 0x00  // ARCount
        ]
        let buffer = ByteBuffer()
        buffer.write(data)

        let header = Header.fromBytes(buffer)
        @Expect(header.id == 0xdb42)
        @Expect(header.flags.response == false)
        @Expect(header.flags.opCode == OpCode.Query)
        @Expect(header.flags.authoritative == false)
        @Expect(header.flags.truncated == false)
        @Expect(header.flags.recursionDesired == true)
        @Expect(header.flags.recursionAvailable == false)
        @Expect(header.flags.rCode == RCode.NoError)
        @Expect(header.qdCount == 1)
        @Expect(header.anCount == 0)
        @Expect(header.nsCount == 0)
        @Expect(header.arCount == 0)
    }

    @TestCase
    func testHeaderFromBytesInvalid() {
        let data: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00  // Flags: response, opcode=Query, authoritative, truncated, recursion desired, recursion available, rcode=NoError
            // Missing QDCount, ANCount, NSCount, ARCount
        ]
        let buffer = ByteBuffer()
        buffer.write(data)

        @ExpectThrows(Header.fromBytes(buffer))
    }
}
