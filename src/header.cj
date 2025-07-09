package dnsmsg

import std.io.*

// OpCode is the operation code for a DNS message.
public enum OpCode {
    Query
    | IQuery
    | Status
    | Reserved(UInt8)

    public static func fromUInt8(value: UInt8): OpCode {
        match (value) {
            case 0x00 => OpCode.Query
            case 0x01 => OpCode.IQuery
            case 0x02 => OpCode.Status
            case _ => OpCode.Reserved(value)
        }
    }

    public func toUInt8(): UInt8 {
        match (this) {
            case OpCode.Query => 0x00
            case OpCode.IQuery => 0x01
            case OpCode.Status => 0x02
            case OpCode.Reserved(value) => value
        }
    }
}

// Extend UInt8 to convert to OpCode.
extend UInt8 {
    public func toOpCode() {
        OpCode.fromUInt8(this)
    }
}

// RCode is the response status code for a DNS message.
public enum RCode {
    NoError
    | FormatError
    | ServerFailure
    | NameError
    | NotImplemented
    | Refused
    | Reserved(UInt8)

    public static func fromUInt8(value: UInt8): RCode {
        match (value) {
            case 0x00 => RCode.NoError // No error
            case 0x01 => RCode.FormatError // Format error
            case 0x02 => RCode.ServerFailure // SERVFAIL
            case 0x03 => RCode.NameError // NXDOMAIN
            case 0x04 => RCode.NotImplemented // Not implemented
            case 0x05 => RCode.Refused // Refused
            case _ => RCode.Reserved(value)
        }
    }

    public func toUInt8(): UInt8 {
        match (this) {
            case RCode.NoError => 0x00 // No error
            case RCode.FormatError => 0x01 // Format error
            case RCode.ServerFailure => 0x02 // SERVFAIL
            case RCode.NameError => 0x03 // NXDOMAIN
            case RCode.NotImplemented => 0x04 // Not implemented
            case RCode.Refused => 0x05 // Refused
            case RCode.Reserved(value) => value
        }
    }
}

// Extend UInt8 to convert to RCode.
extend UInt8 {
    public func toRCode(): RCode {
        RCode.fromUInt8(this)
    }
}

// Header for a DNS message header.
public struct Header {
    public Header(
        public let id: UInt16,
        public let response: Bool,
        public let opCode: OpCode,
        public let authoritative: Bool,
        public let truncated: Bool,
        public let recursionDesired: Bool,
        public let recursionAvailable: Bool,
        public let rCode: RCode,
        public let qdCount: UInt16,
        public let anCount: UInt16,
        public let nsCount: UInt16,
        public let arCount: UInt16
    ) {}
}

extend Header {
    public static func fromStream<T>(stream: T): Header where T <: InputStream & Seekable  {
        let id = readUInt16(stream).getOrThrow({ =>
            Exception("Failed to read ID from stream")
        })
        let flags = readUInt16(stream).getOrThrow({ =>
            Exception("Failed to read flags from stream")
        })
        // Parse the flags
        // The flags are structured as follows:
        // response (1 bit), opcode (4 bits), authoritative (1 bit), truncated (1 bit),
        // recursion desired (1 bit), recursion available (1 bit),Z (3 bit), rcode (4 bits)
        let response = (flags & 0x0001 << 15) != 0
        let opcode = (UInt8(flags >> 11) & 0x0F).toOpCode()
        let authoritative = (flags & 0x0001 << 10) != 0
        let truncated = (flags & 0x0001 << 9) != 0
        let recursionDesired = (flags & 0x0001 << 8) != 0
        let recursionAvailable = (flags & 0x0001 << 7) != 0
        let rcode = (UInt8(flags & 0x0F)).toRCode()

        
        let qdCount = readUInt16(stream).getOrThrow({ =>
            Exception("Failed to read question count from stream")
        })
        let anCount = readUInt16(stream).getOrThrow({ =>
            Exception("Failed to read answer count from stream")
        })
        let nsCount = readUInt16(stream).getOrThrow({ =>
            Exception("Failed to read authority count from stream")
        })
        let arCount = readUInt16(stream).getOrThrow({ =>
            Exception("Failed to read additional count from stream")
        })

        return Header(
            id,
            response,
            opcode,
            authoritative,
            truncated,
            recursionDesired,
            recursionAvailable,
            rcode,
            qdCount,
            anCount,
            nsCount,
            arCount
        )
    }

    public static func tryFromStream<T>(data: T): Option<Header> where T <: InputStream & Seekable {
        try {
            Header.fromStream(data)
        } catch (_) {
            None
        }
    }

    public func toArray(): Array<UInt8> {
        let flags = (
            (if (response) {0x0001} else {0}) << 15 |
            (UInt16(opCode.toUInt8()) & 0x0F) << 11 |
            (if (authoritative) {0x0001} else {0}) << 10 |
            (if (truncated) {0x0001} else {0}) << 9 |
            (if (recursionDesired) {0x0001} else {0}) << 8 |
            (if (recursionAvailable) {0x0001} else {0}) << 7 |
            UInt16(rCode.toUInt8()) & 0x0F
        )

        return [
            UInt8(id >> 8), UInt8(id & 0xFF),
            UInt8(flags >> 8), UInt8(flags & 0xFF),
            UInt8(qdCount >> 8), UInt8(qdCount & 0xFF),
            UInt8(anCount >> 8), UInt8(anCount & 0xFF),
            UInt8(nsCount >> 8), UInt8(nsCount & 0xFF),
            UInt8(arCount >> 8), UInt8(arCount & 0xFF)
        ]
    }
}