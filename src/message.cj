package dnsmsg

import std.io.*
import std.collection.*

// Message represents a DNS message, which includes a header, questions, answers, authorities, and additionals.
public struct Message {
    Message(
        public let header: Header,
        public let questions: Array<Question>,
        public let answers: Array<ResourceRecord>,
        public let authorities: Array<ResourceRecord>,
        public let additionals: Array<ResourceRecord>
    ) {}
}

extend Message {
    public static func fromBytes<T>(buffer: T): Message where T <: InputStream & Seekable {
        // Read the header
        let header = Header.fromBytes(buffer)

        // Read the number of questions, answers, authorities, and additionals
        let qdCount = header.qdCount
        let anCount = header.anCount
        let nsCount = header.nsCount
        let arCount = header.arCount

        // Read the questions
        let questions = 0..qdCount |> map {
            _ => Question.fromBytes(buffer)
        } |> collectArray

        // Read the answers
        let answers = 0..anCount |> map {
            _ => ResourceRecord.fromBytes(buffer)
        } |> collectArray

        // Read the authorities
        let authorities = 0..nsCount |> map {
            _ => ResourceRecord.fromBytes(buffer)
        } |> collectArray

        // Read the additionals
        let additionals = 0..arCount |> map {
            _ => ResourceRecord.fromBytes(buffer)
        } |> collectArray

        return Message(header, questions, answers, authorities, additionals)
    }

    public static func tryFromBytes<T>(buffer: T): Option<Message> where T <: InputStream & Seekable {
        try {
            Message.fromBytes(buffer)
        } catch (_) {
            None
        }
    }

    public func toBytes(): Array<UInt8> {
        let buffer = MessageBuffer()
        // Write header
        buffer.writeHeader(header)

        // Write questions
        for (question in questions) {
            buffer.writeQuestion(question)
        }

        // Write answers
        for (answer in answers) {
            buffer.writeResourceRecord(answer)
        }

        // Write authorities
        for (authority in authorities) {
            buffer.writeResourceRecord(authority)
        }

        // Write additionals
        for (additional in additionals) {
            buffer.writeResourceRecord(additional)
        }

        return buffer.bytes()
    }
}

class MessageBuffer {
    private let buffer: ByteBuffer
    private let nameMap: HashMap<Name, Int64>

    public MessageBuffer() {
        this.buffer = ByteBuffer()
        this.nameMap = HashMap<Name, Int64>()
    }

    func writeHeader(header: Header): Unit {
        buffer.writeUInt16(header.id)
        buffer.writeUInt16(header.getFlags())
        buffer.writeUInt16(header.qdCount)
        buffer.writeUInt16(header.anCount)
        buffer.writeUInt16(header.nsCount)
        buffer.writeUInt16(header.arCount)
    }

    private func writeName(name: Name): Unit { 
        if (nameMap.contains(name)) {
            // If the name is already in the map, write a pointer
            let pointer = nameMap[name]
            writePointer(pointer)
            return
        }

        nameMap.add(name, buffer.length)

        let currentLabel = name.labels[0]

        buffer.writeByte(UInt8(currentLabel.size))
        buffer.write(currentLabel.toArray())

        if (name.labels.size > 1) {
            writeName(Name(name.labels[1..]))
        } else {
            buffer.writeByte(0) // End of name
        }
    }
    
    private func writePointer(pointer: Int64) {
        if (pointer < 0 || pointer > 0x3FFF) {
            throw Exception("Invalid pointer value: ${pointer}")
        }

        let highByte = UInt8((pointer >> 8) | 0b1100_0000) // Set the two high bits to 11
        let lowByte = UInt8(pointer & 0xFF)

        buffer.write([highByte, lowByte])
    }

    func writeQuestion(question: Question): Unit {
        writeName(question.name)
        buffer.writeUInt16(question.qType)
        buffer.writeUInt16(question.qClass)
    }

    func writeResourceRecord(record: ResourceRecord): Unit {
        writeName(record.name)
        buffer.writeUInt16(record.rType)
        buffer.writeUInt16(record.rClass)
        buffer.writeUInt32(record.ttl)
        buffer.writeUInt16(record.rdLength)
        writeRDate(record.rData)
    }

    private func writeRDate(record: Record): Unit {
        match (record) {
            case A(ipv4) => 
                buffer.write(ipv4.getAddressBytes())
            case NS(name) => 
                writeName(name)
            case CNAME(name) => 
                writeName(name)
            case SOA(soaVal) => 
                writeName(soaVal.mname)
                writeName(soaVal.rname)
                buffer.writeUInt32(soaVal.serial)
                buffer.writeUInt32(soaVal.refresh)
                buffer.writeUInt32(soaVal.retry)
                buffer.writeUInt32(soaVal.expire)
                buffer.writeUInt32(soaVal.minimum)
            case WKS(ipv4, protocol, bitmap) => 
                buffer.write(ipv4.getAddressBytes())
                buffer.writeByte(protocol)
                buffer.write(bitmap.toArray())
            case PTR(name) => writeName(name)
            case HINFO(cpu, os) => 
                buffer.write(cpu.toArray())
                buffer.write(os.toArray())
            case MINFO(mailbox, errorsMailbox) => 
                writeName(mailbox)
                writeName(errorsMailbox)
            case MX(preference, name) => 
                buffer.writeUInt16(preference)
                writeName(name)
            case TXT(text) => 
                buffer.write(text.toArray())
            case AAAA(ipv6) =>  
                buffer.write(ipv6.getAddressBytes())
            case SRV(priority, weight, port, target) => 
                buffer.writeUInt16(priority)
                buffer.writeUInt16(weight)
                buffer.writeUInt16(port)
                writeName(target)
            case OPT(code, options) => 
                buffer.writeUInt16(code)
                buffer.write(options)
            case Unknown(_, data) =>
                buffer.write(data)
        }
    }

    func bytes(): Array<UInt8> {
        return buffer.bytes()
    }
}
