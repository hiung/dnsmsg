package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*

@Test
class HeaderTest {
    @TestCase
    func testToOpCode() {
        @Expect(match (0u8.toOpCode()) {
            case OpCode.Query => true
            case _ => false
        })

        @Expect(match (1u8.toOpCode()) {
            case OpCode.IQuery => true
            case _ => false
        })

        @Expect(match (2u8.toOpCode()) {
            case OpCode.Status => true
            case _ => false
        })

        @Expect(match (3u8.toOpCode()) {
            case OpCode.Reserved(3u8) => true
            case _ => false
        })
    }

    @TestCase
    func testToRCode() {
        @Expect(match (0u8.toRCode()) {
            case RCode.NoError => true
            case _ => false
        })

        @Expect(match (1u8.toRCode()) {
            case RCode.FormatError => true
            case _ => false
        })

        @Expect(match (2u8.toRCode()) {
            case RCode.ServerFailure => true
            case _ => false
        })

        @Expect(match (3u8.toRCode()) {
            case RCode.NameError => true
            case _ => false
        })

        @Expect(match (4u8.toRCode()) {
            case RCode.NotImplemented => true
            case _ => false
        })

        @Expect(match (5u8.toRCode()) {
            case RCode.Refused => true
            case _ => false
        })

        @Expect(match (6u8.toRCode()) {
            case RCode.Reserved(6u8) => true
            case _ => false
        })
    }

    @TestCase
    func testHeaderFromStream() {
        let data: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00, // Flags: response, opcode=Query, authoritative, truncated, recursion desired, recursion available, rcode=NoError
            0x00, 0x01, // QDCount
            0x00, 0x00, // ANCount
            0x00, 0x00, // NSCount
            0x00, 0x00  // ARCount
        ]
        let stream = ByteArrayStream()
        stream.write(data)

        let header = Header.fromStream(stream)
        @Expect(header.id == 0xdb42)
        @Expect(header.response == false)
        @Expect(match (header.opCode) {
            case OpCode.Query => true
            case _ => false
        })
        @Expect(header.authoritative == false)
        @Expect(header.truncated == false)
        @Expect(header.recursionDesired == true)
        @Expect(header.recursionAvailable == false)
        @Expect(match (header.rCode) {
            case RCode.NoError => true
            case _ => false
        })
        @Expect(header.qdCount == 1)
        @Expect(header.anCount == 0)
        @Expect(header.nsCount == 0)
        @Expect(header.arCount == 0)
    }

    @TestCase
    func testHeaderFromStreamInvalid() {
        let data: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00  // Flags: response, opcode=Query, authoritative, truncated, recursion desired, recursion available, rcode=NoError
            // Missing QDCount, ANCount, NSCount, ARCount
        ]
        let stream = ByteArrayStream()
        stream.write(data)

        @ExpectThrows(Header.fromStream(stream))
    }

    @TestCase
    func testHeaderTryFromStream() {
        let data: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00, // Flags: response, opcode=Query, authoritative, truncated, recursion desired, recursion available, rcode=NoError
            0x00, 0x01, // QDCount
            0x00, 0x00, // ANCount
            0x00, 0x00, // NSCount
            0x00, 0x00  // ARCount
        ]
        let stream = ByteArrayStream()
        stream.write(data)

        let header = Header.tryFromStream(stream)
        @Expect(header.isSome())
        @Expect(header?.id == 0xdb42)
    }

    @TestCase
    func testHeaderTryFromStreamInvalid() {
        let data: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00  // Flags: response, opcode=Query, authoritative, truncated, recursion desired, recursion available, rcode=NoError
            // Missing QDCount, ANCount, NSCount, ARCount
        ]
        let stream = ByteArrayStream()
        stream.write(data)

        let header = Header.tryFromStream(stream)
        @Expect(header.isNone())
    }

    @TestCase
    func testHeaderToArray() {
        let header = Header(
            0xdb42,
            false,
            OpCode.Query,
            false,
            false,
            true,
            false,
            RCode.NoError,
            1,
            0,
            0,
            0
        )

        let expectedData: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00, // Flags
            0x00, 0x01, // QDCount
            0x00, 0x00, // ANCount
            0x00, 0x00, // NSCount
            0x00, 0x00  // ARCount
        ]

        @Expect(header.toArray(), expectedData)
    }
}
