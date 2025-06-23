package dnsmsg

import std.io.*

// OpCode is the operation code for a DNS message.
enum OpCode {
    Query
    | IQuery
    | Status
    | Reserved(UInt8)
}

// Extend UInt8 to convert to OpCode.
extend UInt8 {
    public func toOpCode() {
        match (this) {
            case 0x00 => OpCode.Query
            case 0x01 => OpCode.IQuery
            case 0x02 => OpCode.Status
            case _ => OpCode.Reserved(this)
        }
    }
}

// RCode is the response status code for a DNS message.
enum RCode {
    NoError
    | FormatError
    | ServerFailure
    | NameError
    | NotImplemented
    | Refused
    | Reserved(UInt8)
}

// Extend UInt8 to convert to RCode.
extend UInt8 {
    public func toRCode(): RCode {
        match (this) {
            case 0x00 => RCode.NoError // No error
            case 0x01 => RCode.FormatError // Format error
            case 0x02 => RCode.ServerFailure // SERVFAIL
            case 0x03 => RCode.NameError // NXDOMAIN
            case 0x04 => RCode.NotImplemented // Not implemented
            case 0x05 => RCode.Refused // Refused
            case _ => RCode.Reserved(this)
        }
    }
}

// Header for a DNS message header.
struct Header {
    public Header(
        let id: UInt16,
        let response: Bool,
        let opCode: OpCode,
        let authoritative: Bool,
        let truncated: Bool,
        let recursionDesired: Bool,
        let recursionAvailable: Bool,
        let rCode: RCode,
        let qdCount: UInt16,
        let anCount: UInt16,
        let nsCount: UInt16,
        let arCount: UInt16
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
}