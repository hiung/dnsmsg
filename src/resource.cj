package dnsmsg

import std.net.*
import std.io.*

// Resource for DNS answers, authorities, and additionals.
public struct ResourceRecord {
    public ResourceRecord(
        public let name: Name,
        public let rType: Type,
        public let rClass: Class,
        public let ttl: UInt32,
        public let rdLength: UInt16,
        public let rData: Record // The decent rdata
    ) {}
}

extend ResourceRecord {
    public static func fromBytes<T>(buffer: T): ResourceRecord where T <: InputStream & Seekable {
        // Read the name
        let name = Name.fromBytes(buffer)

        // Read the type, class, ttl, rdLength
        let rType = readUInt16(buffer).getOrThrow({=> Exception("Failed to read resource type from buffer")})
        let rClass = readUInt16(buffer).getOrThrow({=> Exception("Failed to read resource class from buffer")})
        let ttl = readUInt32(buffer).getOrThrow({=> Exception("Failed to read TTL from buffer")})
        let rdLength = readUInt16(buffer).getOrThrow({=> Exception("Failed to read RDATA length from buffer")})

        // Read the rdata
        let record = getRecord(buffer, rType, rdLength)

        return ResourceRecord(name, rType, rClass, ttl, rdLength, record)
    }

    public static func tryFromStream<T>(buffer: T): Option<ResourceRecord> where T <: InputStream & Seekable {
        try {
            ResourceRecord.fromBytes(buffer)
        } catch (_) {
            None
        }
    }

    private static func getRecord<T>(buffer: T, rType: Type, rdLength: UInt16): Record where T <: InputStream & Seekable {
        if (rdLength <= 0) {
            throw Exception("Invalid RDATA length: ${rdLength}")
        }
        // Save the current position to check the length later
        let prePos = buffer.position

        let record = if (rType == TypeA) {
            let ipv4bites = readUInt32(buffer).getOrThrow({=> Exception("Failed to read A record data from buffer")})
            Record.A(IPv4Address(ipv4bites))
        } else if (rType == TypeNS) {
            let name = Name.fromBytes(buffer)
            Record.NS(name)
        } else if (rType == TypeCNAME) {
            let name = Name.fromBytes(buffer)
            Record.CNAME(name)
        } else if (rType == TypeSOA) {
            let mname = Name.fromBytes(buffer)
            let rname = Name.fromBytes(buffer)
            let serial = readUInt32(buffer).getOrThrow({=> Exception("Failed to read SOA serial from buffer")})
            let refresh = readUInt32(buffer).getOrThrow({=> Exception("Failed to read SOA refresh from buffer")})
            let retry = readUInt32(buffer).getOrThrow({=> Exception("Failed to read SOA retry from buffer")})
            let expire = readUInt32(buffer).getOrThrow({=> Exception("Failed to read SOA expire from buffer")})
            let minimum = readUInt32(buffer).getOrThrow({=> Exception("Failed to read SOA minimum from buffer")})
            Record.SOA(SOAValue(mname, rname, serial, refresh, retry, expire, minimum))
        } else if (rType == TypeWKS) {
            let ipv4bytes = readUInt32(buffer).getOrThrow({=> Exception("Failed to read WKS IPv4 from buffer")})
            let protocol = readUInt8(buffer).getOrThrow({=> Exception("Failed to read WKS protocol from buffer")})
            let bitmapLength = rdLength - 5 // 4 bytes for IPv4 + 1 byte for protocol
            let bitmap = readBytes(buffer, Int64(bitmapLength)).getOrThrow(
                {=> Exception("Failed to read WKS bitmap from buffer")})
            Record.WKS(IPv4Address(ipv4bytes), protocol, bitmap)
        } else if (rType == TypePTR) {
            let name = Name.fromBytes(buffer)
            Record.PTR(name)
        } else if (rType == TypeHINFO) {
            throw Exception("HINFO records are not supported in this implementation")
        } else if (rType == TypeMINFO) {
            let mailbox = Name.fromBytes(buffer)
            let errorsMailbox = Name.fromBytes(buffer)
            Record.MINFO(mailbox, errorsMailbox)
        } else if (rType == TypeMX) {
            let preference = readUInt16(buffer).getOrThrow({=> Exception("Failed to read MX preference from buffer")})
            let name = Name.fromBytes(buffer)
            Record.MX(preference, name)
        } else if (rType == TypeTXT) {
            let text = String.fromUtf8(readBytes(buffer, Int64(rdLength)).getOrThrow(
                {=> Exception("Failed to read TXT record data from buffer")}))
            Record.TXT(text)
        } else if (rType == TypeAAAA) {
            let bytes = readBytes(buffer, 16).getOrThrow({=> Exception("Failed to read AAAA record data from buffer")})
            Record.AAAA(
                IPv6Address(bytes)
            )
        } else if (rType == TypeSRV) {
            let priority = readUInt16(buffer).getOrThrow({=> Exception("Failed to read SRV priority from buffer")})
            let weight = readUInt16(buffer).getOrThrow({=> Exception("Failed to read SRV weight from buffer")})
            let port = readUInt16(buffer).getOrThrow({=> Exception("Failed to read SRV port from buffer")})
            let target = Name.fromBytes(buffer)
            Record.SRV(priority, weight, port, target)
        } else if (rType == TypeOPT) {
            let extendedRCode = readUInt16(buffer).getOrThrow({=> Exception("Failed to read OPT extended RCODE from buffer")})
            let optionsLength = rdLength - 2 // 2 bytes for extended RCODE
            let options = readBytes(buffer, Int64(optionsLength)).getOrThrow({=> Exception("Failed to read OPT options from buffer")})
            Record.OPT(extendedRCode, options)
        } else {
            let data = readBytes(buffer, Int64(rdLength)).getOrThrow({=> Exception("Failed to read RDATA from buffer")})
            Record.Unknown(rType, data)
        }

        let lastPos = buffer.position
        if (lastPos - prePos != Int64(rdLength)) {
            throw Exception("RDATA length mismatch: expected ${rdLength}, got ${lastPos - prePos}")
        }

        return record
    }
}

public enum Record {
    A(IPv4Address)
    | NS(Name)
    | CNAME(Name)
    | SOA(SOAValue)
    | WKS(IPv4Address, UInt8, Array<UInt8>) // IPv4, protocol, bitmap
    | PTR(Name)
    | HINFO(String, String) // CPU, OS
    | MINFO(Name, Name) // mailbox name, errors mailbox
    | MX(UInt16, Name) // preference, name
    | TXT(String)
    | AAAA(IPv6Address)
    | SRV(UInt16, UInt16, UInt16, Name) // priority, weight, port, target
    | OPT(UInt16, Array<UInt8>) // extended RCODE, options
    | Unknown(Type, Array<UInt8>)

    public func toString(): String {
        match (this) {
            case A(ipv4) => "A: ${ipv4.toString()}"
            case NS(name) => "NS: ${name.toString()}"
            case CNAME(name) => "CNAME: ${name.toString()}"
            case SOA(soaVal) => "SOA: ${soaVal.toString()}"
            case WKS(ipv4, protocol, bitmap) => "WKS: ${ipv4.toString()} ${protocol} ${bitmap}"
            case PTR(name) => "PTR: ${name.toString()}"
            case HINFO(cpu, os) => "HINFO: CPU=${cpu}, OS=${os}"
            case MINFO(mailbox, errorsMailbox) => "MINFO: Mailbox=${mailbox.toString()}, Errors=${errorsMailbox.toString()}"
            case MX(preference, name) => "MX: Preference=${preference}, Name=${name.toString()}"
            case TXT(text) => "TXT: ${text}"
            case AAAA(ipv6) => "AAAA: ${ipv6.toString()}"
            case SRV(priority, weight, port, target) => "SRV: Priority=${priority}, Weight=${weight}, Port=${port}, Target=${target.toString()}"
            case OPT(code, options) => "OPT: Code=${code}, Options=${options}"
            case Unknown(_type, data) => "Unknown Record Type(${_type}): Data=${data}"
        }
    }
}

public struct SOAValue {
    public SOAValue(
        public let mname: Name,
        public let rname: Name,
        public let serial: UInt32,
        public let refresh: UInt32,
        public let retry: UInt32,
        public let expire: UInt32,
        public let minimum: UInt32
    ) {}

    public func toString(): String {
        return "${mname.toString()} ${rname.toString()} ${serial} ${refresh} ${retry} ${expire} ${minimum}"
    }
}
