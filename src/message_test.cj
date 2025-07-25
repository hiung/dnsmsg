package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.net.*

@Test
class MessageTest {
    @TestCase
    func testMessageFromBytes() {
        let data: Array<UInt8> = [
            // Header
            0x01, 0x00, // ID
            0x8f, 0x81, // Flags 
            0x00, 0x01, // QDCOUNT (1 question)
            0x00, 0x01, // ANCOUNT (1 answer)
            0x00, 0x00, // NSCOUNT (0 authorities)
            0x00, 0x00, // ARCOUNT (0 additionals)

            // Question
            12, b'c', b'a',b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // End of name
            0,
            1, // Type A
            0,
            1, // Class IN

            // Answer
            3, b'w', b'w', b'w', // "www"
            0xc0, 0x0c, // pointer to the question name
            0, 1, // Type A
            0, 1, // Class IN
            0, 0, 0, 60, // TTL 60 seconds
            0, 4, // RDATA length
            192, 168, 1, 1 // rdata for A record
        ]

        let buffer = ByteBuffer()
        buffer.write(data)

        let message = Message.fromBytes(buffer)

        @Expect(message.header.id == 0x0100) // ID from header

        @Expect(message.header.flags.response == true) // Response flag
        @Expect(message.header.flags.opCode == OpCode.IQuery)
        @Expect(message.header.flags.authoritative == true) // Authoritative flag
        @Expect(message.header.flags.truncated == true) // Truncated flag
        @Expect(message.header.flags.recursionDesired == true) // Recursion desired flag
        @Expect(message.header.flags.recursionAvailable == true) // Recursion available flag
        @Expect(message.header.flags.rCode == RCode.FormatError)

        @Expect(message.header.qdCount == 1) // One question
        @Expect(message.header.anCount == 1) // One answer  
        @Expect(message.header.nsCount == 0) // No authorities
        @Expect(message.header.arCount == 0) // No additionals

        @Expect(message.questions.size == 1) // One question
        @Expect(message.answers.size == 1) // One answer
        @Expect(message.authorities.size == 0) // No authorities
        @Expect(message.additionals.size == 0) // No additionals

        let question = message.questions[0]
        @Expect(question.name.toString() == "cangjie-lang.cn")
        @Expect(question.qType == TypeA)
        @Expect(question.qClass == ClassIN)

        let answer = message.answers[0]
        @Expect(answer.name.toString() == "www.cangjie-lang.cn")
        @Expect(answer.rType == TypeA)
        @Expect(answer.rClass == ClassIN)
        @Expect(answer.ttl == 60)
        @Expect(answer.rData == RData.A(IPv4Address(192, 168, 1, 1)))
        println(" ipv4 address: ${answer.rData.toString()}")

        let messageBytes = message.toBytes()
        @Expect(message.toBytes() == data)

        let uncompressedData: Array<UInt8> = [
            // Header
            0x01, 0x00, // ID
            0x8f, 0x81, // Flags 
            0x00, 0x01, // QDCOUNT (1 question)
            0x00, 0x01, // ANCOUNT (1 answer)
            0x00, 0x00, // NSCOUNT (0 authorities)
            0x00, 0x00, // ARCOUNT (0 additionals)

            // Question
            12, b'c', b'a',b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // End of name
            0, 1, // Type A
            0, 1, // Class IN

            // Answer
            3, b'w', b'w', b'w', // "www"
            12, b'c', b'a',b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // End of name
            0, 1, // Type A
            0, 1, // Class IN
            0, 0, 0, 60, // TTL 60 seconds
            0, 4, // RDATA length
            192, 168, 1, 1 // rdata for A record
        ]

        @Expect(message.toBytes(compress: false) == uncompressedData)
    }

    @TestCase
    func testMessageFromBytesRespFromDNSServer() {
        let payload: Array<UInt8> = [
            // Header
            0x00, 0xd0, // ID
            0x00, 0x00, // Flags 
            0x00, 0x01, // QDCOUNT (1 question)
            0x00, 0x00, // ANCOUNT (0 answer)
            0x00, 0x00, // NSCOUNT (0 authorities)
            0x00, 0x00, // ARCOUNT (0 additionals)

            // Question
            12, b'c',b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // End of name
            0, 1, // Type A
            0, 1 // Class IN
            
        ]
        let bytes = Array<UInt8>(512, repeat: 0) // DNS messages are typically small, 512 bytes is a common size

        try (udpSocket = UdpSocket(bindAt: 8888)) {
            udpSocket.sendTimeout = Duration.second * 2
            udpSocket.receiveTimeout = Duration.second * 2
            udpSocket.bind()
            udpSocket.sendTo(IPSocketAddress("192.168.0.2", 53), payload)
            let (_, bytesRead) = udpSocket.receiveFrom(bytes)

            @Expect(bytesRead > 0)

            let buffer = ByteBuffer()
            buffer.write(bytes)

            let message = Message.fromBytes(buffer)

            @Expect(message.header.id == 0x00d0) // ID from header
            @Expect(message.header.flags.response == true) // Response flag
            @Expect(message.header.flags.opCode == OpCode.Query )
            @Expect(message.header.flags.authoritative == false) // Authoritative flag
            @Expect(message.header.flags.truncated == false) // Truncated flag
            @Expect(message.header.flags.recursionDesired == false) // Recursion desired flag
            @Expect(message.header.flags.recursionAvailable == true) // Recursion available flag
            @Expect(message.header.flags.rCode == RCode.NoError)
            @Expect(message.header.qdCount == 1) // One question
            @Expect(message.header.anCount == 1) // No answers
            @Expect(message.header.nsCount == 0) // Four authorities
            @Expect(message.header.arCount == 0) // No additionals

            @Expect(message.questions.size == 1) // One question
            @Expect(message.answers.size == 1) // No answers
            @Expect(message.authorities.size == 0) // Four authorities
            @Expect(message.additionals.size == 0) // No additionals

            @Expect(message.questions[0].name.toString() == "cangjie-lang.cn")
            @Expect(message.questions[0].qType == TypeA)
            @Expect(message.questions[0].qClass == ClassIN)

            // check answer
            @Expect(message.answers[0].name.toString() == "cangjie-lang.cn")
            @Expect(message.answers[0].rType == TypeA)
            @Expect(message.answers[0].rClass == ClassIN)
            @Expect(message.answers[0].rData == RData.A(IPv4Address(123, 249, 12, 207)))
        }
    }

    @TestCase
    func testMessageBuilder() {
        let message = MessageBuilder(id: 0x1234)
            .addQuestion(Question(Name("example.com"), TypeA, ClassIN))
            .addAnswer(ResourceRecord(Name("example.com"), TypeA, ClassIN, 3600, RData.A(IPv4Address(0x7f000001))))
            .setFlags(Flags(response: true))
            .build()

        @Expect(message.header.id == 0x1234)
        @Expect(message.header.flags.response == true)
        @Expect(message.header.flags.opCode == OpCode.Query)
        @Expect(message.questions.size == 1)
        @Expect(message.answers.size == 1)
        @Expect(message.authorities.size == 0)
        @Expect(message.additionals.size == 0)
    }

    @TestCase
    func testMessageBuilderFromBytesRespFromDNSServer() {
        let message = MessageBuilder(id: 0x00d0)
            .addQuestion(Question(Name("cangjie-lang.cn"), TypeA, ClassIN))
            .build()
        let payload = message.toBytes()
        let bytes = Array<UInt8>(512, repeat: 0) // DNS messages are typically small, 512 bytes is a common size

        try (udpSocket = UdpSocket(bindAt: 8888)) {
            udpSocket.sendTimeout = Duration.second * 2
            udpSocket.receiveTimeout = Duration.second * 2
            udpSocket.bind()
            udpSocket.sendTo(IPSocketAddress("192.168.0.2", 53), payload)
            let (_, bytesRead) = udpSocket.receiveFrom(bytes)

            @Expect(bytesRead > 0)

            let buffer = ByteBuffer()
            buffer.write(bytes)

            let message = Message.fromBytes(buffer)

            @Expect(message.header.id == 0x00d0) // ID from header
            @Expect(message.header.flags.response == true) // Response flag
            @Expect(message.header.flags.opCode == OpCode.Query)
            @Expect(message.header.flags.authoritative == false) // Authoritative flag
            @Expect(message.header.flags.truncated == false) // Truncated flag
            @Expect(message.header.flags.recursionDesired == false) // Recursion desired flag
            @Expect(message.header.flags.recursionAvailable == true) // Recursion available flag
            @Expect(message.header.flags.rCode ==RCode.NoError)
            @Expect(message.header.qdCount == 1) // One question
            @Expect(message.header.anCount == 1) // No answers
            @Expect(message.header.nsCount == 0) // Four authorities
            @Expect(message.header.arCount == 0) // No additionals

            @Expect(message.questions.size == 1) // One question
            @Expect(message.answers.size == 1) // No answers
            @Expect(message.authorities.size == 0) // Four authorities
            @Expect(message.additionals.size == 0) // No additionals

            @Expect(message.questions[0].name.toString() == "cangjie-lang.cn")
            @Expect(message.questions[0].qType == TypeA)
            @Expect(message.questions[0].qClass == ClassIN)

            // check answer
            @Expect(message.answers[0].name.toString() == "cangjie-lang.cn")
            @Expect(message.answers[0].rType == TypeA)
            @Expect(message.answers[0].rClass == ClassIN)
            @Expect(message.answers[0].rData == RData.A(IPv4Address(123, 249, 12, 207)))
        }
    }
}
