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
    // fromBytes reads a DNS message from a byte stream and constructs a Message object.
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

    public func toBytes(compress!: Bool = true): Array<UInt8> {
        let buffer = MessageBuffer(compress: compress)
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

// MessageBuffer is a utility class for constructing DNS messages in a byte buffer.
private class MessageBuffer {
    // buffer is the byte buffer where the message is constructed.
    private let buffer: ByteBuffer
    // nameMap is a map to keep track of names and their corresponding pointers.
    private let nameMap: ?HashMap<Name, UInt16>

    MessageBuffer(compress!: Bool = true) {
        buffer = ByteBuffer()
        nameMap = if (compress) {
            HashMap<Name, UInt16>()
        } else {
            None
        }
    }

    func writeHeader(header: Header): Unit {
        buffer.writeUInt16(header.id)
        buffer.writeUInt16(header.flags.toUInt16())
        buffer.writeUInt16(header.qdCount)
        buffer.writeUInt16(header.anCount)
        buffer.writeUInt16(header.nsCount)
        buffer.writeUInt16(header.arCount)
    }

    func writeQuestion(question: Question): Unit {
        buffer.write(getNameBytes(question.name))
        buffer.writeUInt16(question.qType)
        buffer.writeUInt16(question.qClass)
    }

    func writeResourceRecord(record: ResourceRecord): Unit {
        buffer.write(getNameBytes(record.name))
        buffer.writeUInt16(record.rType)
        buffer.writeUInt16(record.rClass)
        buffer.writeUInt32(record.ttl)
        let rDataBytes = getRDataBytes(record.rData)
        let rdLength = UInt16(rDataBytes.size)
        buffer.writeUInt16(rdLength)
        buffer.write(rDataBytes)
    }

    private func getNameBytes(name: Name): Array<UInt8> {
        let buffer = ByteBuffer()
        if (let Some(nameMap) <- nameMap) {
            if (nameMap.contains(name)) {
                // If the name is already in the nameMap, write a pointer
                let pointer = nameMap[name]
                buffer.writeUInt16(pointer)
                return buffer.bytes()
            }
            // If the name is not in the nameMap, add it and pointer to nameMap
            let pointer = getPointer()
            nameMap.add(name, pointer)
        }

        // Write the first label
        let currentLabel = name.labels[0]
        buffer.writeByte(UInt8(currentLabel.size))
        buffer.write(currentLabel.toArray())

        // Write the rest of the labels
        if (name.labels.size > 1) {
            buffer.write(getNameBytes(Name(name.labels[1..])))
        } else {
            buffer.writeByte(0) // End of name
        }

        return buffer.bytes()
    }

    private func getPointer(): UInt16 {
        let length = buffer.length
        if (length < 0 || length > 0x3FFF) {
            throw Exception("Invalid pointer value: ${length}")
        }

        return UInt16(length | 0xC000)
    }

    private func getRDataBytes(rdata: RData): Array<UInt8> {
        let buffer = ByteBuffer()
        match (rdata) {
            case A(ipv4) => buffer.write(ipv4.getAddressBytes())
            case NS(name) => buffer.write(getNameBytes(name))
            case CNAME(name) => buffer.write(getNameBytes(name))
            case SOA(soaVal) =>
                buffer.write(getNameBytes(soaVal.mname))
                buffer.write(getNameBytes(soaVal.rname))
                buffer.writeUInt32(soaVal.serial)
                buffer.writeUInt32(soaVal.refresh)
                buffer.writeUInt32(soaVal.retry)
                buffer.writeUInt32(soaVal.expire)
                buffer.writeUInt32(soaVal.minimum)
            case WKS(ipv4, protocol, bitmap) =>
                buffer.write(ipv4.getAddressBytes())
                buffer.writeByte(protocol)
                buffer.write(bitmap.toArray())
            case PTR(name) => buffer.write(getNameBytes(name))
            case HINFO(cpu, os) =>
                buffer.write(cpu.toArray())
                buffer.write(os.toArray())
            case MINFO(mailbox, errorsMailbox) =>
                buffer.write(getNameBytes(mailbox))
                buffer.write(getNameBytes(errorsMailbox))
            case MX(preference, name) =>
                buffer.writeUInt16(preference)
                buffer.write(getNameBytes(name))
            case TXT(text) => buffer.write(text.toArray())
            case AAAA(ipv6) => buffer.write(ipv6.getAddressBytes())
            case SRV(priority, weight, port, target) =>
                buffer.writeUInt16(priority)
                buffer.writeUInt16(weight)
                buffer.writeUInt16(port)
                buffer.write(getNameBytes(target))
            case OPT(options) => for (opt in options) {
                buffer.writeUInt16(opt.code)
                let length = opt.data.size
                buffer.writeUInt16(UInt16(length))
                buffer.write(opt.data)
            }
            case Unknown(_, data) => buffer.write(data)
        }

        return buffer.bytes()
    }

    func bytes(): Array<UInt8> {
        return buffer.bytes()
    }
}

public class MessageBuilder {
    private var header: Header
    private let questions: ArrayList<Question> = ArrayList<Question>()
    private let answers: ArrayList<ResourceRecord> = ArrayList<ResourceRecord>()
    private let authorities: ArrayList<ResourceRecord> = ArrayList<ResourceRecord>()
    private let additionals: ArrayList<ResourceRecord> = ArrayList<ResourceRecord>()

    public MessageBuilder(id!: UInt16) {
        header = Header(id, Flags(0), 0, 0, 0, 0)
    }

    public func setFlags(flags: Flags): MessageBuilder {
        header.flags = flags
        return this
    }

    public func addQuestion(question: Question): MessageBuilder {
        questions.add(question)
        header.qdCount += 1
        return this
    }

    public func addAnswer(answer: ResourceRecord): MessageBuilder {
        answers.add(answer)
        header.anCount += 1
        return this
    }

    public func addAuthority(authority: ResourceRecord): MessageBuilder {
        authorities.add(authority)
        header.nsCount += 1
        return this
    }

    public func addAdditional(additional: ResourceRecord): MessageBuilder {
        additionals.add(additional)
        header.arCount += 1
        return this
    }

    public func build(): Message {
        return Message(header, questions.toArray(), answers.toArray(), authorities.toArray(), additionals.toArray())
    }
}
