package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*

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

        @ExpectThrows(3u8.toOpCode())
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

        @ExpectThrows(6u8.toRCode())
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

        let header = Header.fromBytes(data);
        @Expect(header.id == 0xdb42)
        @Expect(header.response == false)
        @Expect(match (header.opcode) {
            case OpCode.Query => true
            case _ => false
        })
        @Expect(header.authoritative == false)
        @Expect(header.truncated == false)
        @Expect(header.recursionDesired == true)
        @Expect(header.recursionAvailable == false)
        @Expect(match (header.rcode) {
            case RCode.NoError => true
            case _ => false
        })
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

        @ExpectThrows(Header.fromBytes(data))
    }

    @TestCase
    func testHeaderTryFromBytes() {
        let data: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00, // Flags: response, opcode=Query, authoritative, truncated, recursion desired, recursion available, rcode=NoError
            0x00, 0x01, // QDCount
            0x00, 0x00, // ANCount
            0x00, 0x00, // NSCount
            0x00, 0x00  // ARCount
        ]

        let header = Header.tryFromBytes(data);
        @Expect(header.isSome())
        @Expect(header?.id == 0xdb42)
    }

    @TestCase
    func testHeaderTryFromBytesInvalid() {
        let data: Array<UInt8> = [
            0xdb, 0x42, // ID
            0x01, 0x00  // Flags: response, opcode=Query, authoritative, truncated, recursion desired, recursion available, rcode=NoError
            // Missing QDCount, ANCount, NSCount, ARCount
        ]

        let header = Header.tryFromBytes(data);
        @Expect(header.isNone())
    }
}
