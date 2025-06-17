package dnsmsg

import net.http.*

// OpCode is the operation code for a DNS message.
enum OpCode {
    Query
    | IQuery
    | Status
    | Reserved(UInt8)
}

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

extend UInt8 {
    public func toRCode(): RCode {
        match (this) {
            case 0x00 => RCode.NoError
            case 0x01 => RCode.FormatError
            case 0x02 => RCode.ServerFailure
            case 0x03 => RCode.NameError
            case 0x04 => RCode.NotImplemented
            case 0x05 => RCode.Refused
            case _ => RCode.Reserved(this)
        }
    }
}

// Header for a DNS message header.
struct Header {
    public Header(
        let id: UInt16,
        let response: Bool,
        let opcode: OpCode,
        let authoritative: Bool,
        let truncated: Bool,
        let recursionDesired: Bool,
        let recursionAvailable: Bool,
        let rcode: RCode,
        let qdCount: UInt16,
        let anCount: UInt16,
        let nsCount: UInt16,
        let arCount: UInt16
    ) {}
}

extend Header {
    public static func fromBytes(data: Array<UInt8>): Header {
        if (data.size < 12) {
            throw Exception("Header data too short: ${data.size} bytes")
        }

        let id: UInt16 = (UInt16(data[0]) << 8) | UInt16(data[1])
        let flags1 = data[2]
        let flags2 = data[3]
        let response = (flags1 & 0x01 << 7) != 0
        let opcode = (flags1 >> 3 & 0x0F).toOpCode()
        let authoritative = (flags1 & 0x01 << 2) != 0
        let truncated = (flags1 & 0x01 << 1) != 0
        let recursionDesired = (flags1 & 0x01) != 0
        let recursionAvailable = (flags2 & 0x01 << 7) != 0
        let rcode = (flags2 & 0x0F).toRCode()

        let qdCount: UInt16 = (UInt16(data[4]) << 8) | UInt16(data[5])
        let anCount: UInt16 = (UInt16(data[6]) << 8) | UInt16(data[7])
        let nsCount: UInt16 = (UInt16(data[8]) << 8) | UInt16(data[9])
        let arCount: UInt16 = (UInt16(data[10]) << 8) | UInt16(data[11])

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

    public static func tryFromBytes(data: Array<UInt8>): Option<Header> {
        try {
            Header.fromBytes(data)
        } catch (_) {
            None
        }
    }

    public func pack(): Array<UInt8> {
        // let flags1: UInt8 = 
        //     (if (response) 0x80 else 0x00) |
        //     (opcode.toUInt8() << 3) |
        //     (if (authoritative) 0x04 else 0x00) |
        //     (if (truncated) 0x02 else 0x00) |
        //     (if (recursionDesired) 0x01 else 0x00)

        // let flags2: UInt8 = 
        //     (if (recursionAvailable) 0x80 else 0x00) |
        //     rcode.toUInt8()

        // return [
        //     UInt8(id >> 8),
        //     UInt8(id & 0xFF),
        //     flags1,
        //     flags2,
        //     UInt8(qdCount >> 8),
        //     UInt8(qdCount & 0xFF),
        //     UInt8(anCount >> 8),
        //     UInt8(anCount & 0xFF),
        //     UInt8(nsCount >> 8),
        //     UInt8(nsCount & 0xFF),
        //     UInt8(arCount >> 8),
        //     UInt8(arCount & 0xFF)
        // ]
        throw Exception("Not implemented yet")
    }
}

func test() {
    // 1. 构建 client 实例
    let client = ClientBuilder().build()
    // 2. 发送 request
    let rsp = client.get("http://example.com/hello")
    // 3. 读取response
    // 4. 关闭连接
    client.close()
}