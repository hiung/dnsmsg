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
    static func fromBytes<T>(buffer: T): Header where T <: InputStream & Seekable  {
        let id = readUInt16(buffer).getOrThrow({ =>
            Exception("Failed to read ID from buffer")
        })
        let flags = readUInt16(buffer).getOrThrow({ =>
            Exception("Failed to read flags from buffer")
        })
        // Parse the flags
        // The flags are structured as follows:
        // response (1 bit), opcode (4 bits), authoritative (1 bit), truncated (1 bit),
        // recursion desired (1 bit), recursion available (1 bit),Z (3 bit), rcode (4 bits)
        let response = (flags & 1 << 15) != 0
        let opcode = (UInt8(flags >> 11) & 0x0F).toOpCode()
        let authoritative = (flags & 1 << 10) != 0
        let truncated = (flags & 1 << 9) != 0
        let recursionDesired = (flags & 1 << 8) != 0
        let recursionAvailable = (flags & 1 << 7) != 0
        let rcode = (UInt8(flags & 0x0F)).toRCode()
  
        let qdCount = readUInt16(buffer).getOrThrow({ =>
            Exception("Failed to read question count from buffer")
        })
        let anCount = readUInt16(buffer).getOrThrow({ =>
            Exception("Failed to read answer count from buffer")
        })
        let nsCount = readUInt16(buffer).getOrThrow({ =>
            Exception("Failed to read authority count from buffer")
        })
        let arCount = readUInt16(buffer).getOrThrow({ =>
            Exception("Failed to read additional count from buffer")
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

    public func getFlags(): UInt16 {
        var flags: UInt16 = 0
        if (response) {
            flags |= 1 << 15 // Response bit
            
        }
        flags |= (UInt16(opCode.toUInt8())) << 11 // Opcode bits
        if (authoritative) {
            flags |= 1 << 10 // Authoritative bit
        }
        if (truncated) {
            flags |= 1 << 9 // Truncated bit
        }
        if (recursionDesired) {
            flags |= 1 << 8 // Recursion desired bit
        }
        if (recursionAvailable) {
            flags |= 1 << 7 // Recursion available bit
        }
        flags |= UInt16(rCode.toUInt8() & 0x0F) // RCode bits
        return flags
    }
}