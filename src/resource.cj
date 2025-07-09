package dnsmsg

import std.format.*
import std.io.*

// Resource for DNS answers, authorities, and additionals.
public struct Resource {
    public Resource(
        public let name: Name,
        public let rType: Type,
        public let rClass: Class,
        public let ttl: UInt32,
        public let rdLength: UInt16,
        public let record: Record // The decent rdata
    ) {}
}

extend Resource {
    public static func fromStream<T>(stream: T): Resource where T <: InputStream & Seekable {
        // Read the name
        let name = Name.fromStream(stream)

        // Read the type, class, ttl, rdLength
        let rType = readUInt16(stream).getOrThrow({=> Exception("Failed to read resource type from stream")})
        let rClass = readUInt16(stream).getOrThrow({=> Exception("Failed to read resource class from stream")})
        let ttl = readUInt32(stream).getOrThrow({=> Exception("Failed to read TTL from stream")})
        let rdLength = readUInt16(stream).getOrThrow({=> Exception("Failed to read RDATA length from stream")})

        // Read the rdata
        let record = getRecord(stream, rType, rdLength)

        return Resource(name, rType, rClass, ttl, rdLength, record)
    }

    public static func tryFromStream<T>(stream: T): Option<Resource> where T <: InputStream & Seekable {
        try {
            Resource.fromStream(stream)
        } catch (_) {
            None
        }
    }

    private static func getRecord<T>(stream: T, rType: Type, rdLength: UInt16): Record where T <: InputStream & Seekable {
        if (rdLength <= 0) {
            throw Exception("Invalid RDATA length: ${rdLength}")
        }
        // Save the current position to check the length later
        let prePos = stream.position

        let record = if (rType == TypeA) {
            let bytes = readBytes(stream, 4).getOrThrow({=> Exception("Failed to read A record data from stream")})
            Record.A(IPv4(bytes[0], bytes[1], bytes[2], bytes[3]))
        } else if (rType == TypeNS) {
            let name = Name.fromStream(stream)
            Record.NS(name)
        } else if (rType == TypeCNAME) {
            let name = Name.fromStream(stream)
            Record.CNAME(name)
        } else if (rType == TypeSOA) {
            let mname = Name.fromStream(stream)
            let rname = Name.fromStream(stream)
            let serial = readUInt32(stream).getOrThrow({=> Exception("Failed to read SOA serial from stream")})
            let refresh = readUInt32(stream).getOrThrow({=> Exception("Failed to read SOA refresh from stream")})
            let retry = readUInt32(stream).getOrThrow({=> Exception("Failed to read SOA retry from stream")})
            let expire = readUInt32(stream).getOrThrow({=> Exception("Failed to read SOA expire from stream")})
            let minimum = readUInt32(stream).getOrThrow({=> Exception("Failed to read SOA minimum from stream")})
            Record.SOA(SOAValue(mname, rname, serial, refresh, retry, expire, minimum))
        } else if (rType == TypeWKS) {
            let ipv4Bytes = readBytes(stream, 4).getOrThrow({=> Exception("Failed to read WKS IPv4 from stream")})
            let protocol = readUInt8(stream).getOrThrow({=> Exception("Failed to read WKS protocol from stream")})
            let bitmapLength = rdLength - 5 // 4 bytes for IPv4 + 1 byte for protocol
            let bitmap = readBytes(stream, Int64(bitmapLength)).getOrThrow(
                {=> Exception("Failed to read WKS bitmap from stream")})
            Record.WKS(IPv4(ipv4Bytes[0], ipv4Bytes[1], ipv4Bytes[2], ipv4Bytes[3]), protocol, bitmap)
        } else if (rType == TypePTR) {
            let name = Name.fromStream(stream)
            Record.PTR(name)
        } else if (rType == TypeHINFO) {
            let cpu = Name.fromStream(stream).toString() // Assuming Name can be converted to String
            let os = Name.fromStream(stream).toString() // Assuming Name can be converted to String
            Record.HINFO(cpu, os)
        } else if (rType == TypeMINFO) {
            let mailbox = Name.fromStream(stream)
            let errorsMailbox = Name.fromStream(stream)
            Record.MINFO(mailbox, errorsMailbox)
        } else if (rType == TypeMX) {
            let preference = readUInt16(stream).getOrThrow({=> Exception("Failed to read MX preference from stream")})
            let name = Name.fromStream(stream)
            Record.MX(preference, name)
        } else if (rType == TypeTXT) {
            let text = Name.fromStream(stream).toString() // Assuming Name can be converted to String
            Record.TXT(text)
        } else if (rType == TypeAAAA) {
            let bytes = readBytes(stream, 16).getOrThrow({=> Exception("Failed to read AAAA record data from stream")})
            Record.AAAA(
                IPv6(
                    (UInt16(bytes[0]) << 8) | UInt16(bytes[1]),
                    (UInt16(bytes[2]) << 8) | UInt16(bytes[3]),
                    (UInt16(bytes[4]) << 8) | UInt16(bytes[5]),
                    (UInt16(bytes[6]) << 8) | UInt16(bytes[7]),
                    (UInt16(bytes[8]) << 8) | UInt16(bytes[9]),
                    (UInt16(bytes[10]) << 8) | UInt16(bytes[11]),
                    (UInt16(bytes[12]) << 8) | UInt16(bytes[13]),
                    (UInt16(bytes[14]) << 8) | UInt16(bytes[15])
                )
            )
        } else if (rType == TypeSRV) {
            let priority = readUInt16(stream).getOrThrow({=> Exception("Failed to read SRV priority from stream")})
            let weight = readUInt16(stream).getOrThrow({=> Exception("Failed to read SRV weight from stream")})
            let port = readUInt16(stream).getOrThrow({=> Exception("Failed to read SRV port from stream")})
            let target = Name.fromStream(stream)
            Record.SRV(priority, weight, port, target)
        } else if (rType == TypeOPT) {
            let extendedRCode = readUInt16(stream).getOrThrow({=> Exception("Failed to read OPT extended RCODE from stream")})
            let optionsLength = rdLength - 2 // 2 bytes for extended RCODE
            let options = readBytes(stream, Int64(optionsLength)).getOrThrow({=> Exception("Failed to read OPT options from stream")})
            Record.OPT(extendedRCode, options)
        } else {
            let data = readBytes(stream, Int64(rdLength)).getOrThrow({=> Exception("Failed to read RDATA from stream")})
            Record.Unknown(rType, data)
        }

        let lastPos = stream.position
        if (lastPos - prePos != Int64(rdLength)) {
            throw Exception("RDATA length mismatch: expected ${rdLength}, got ${lastPos - prePos}")
        }

        return record
    }

    public func toArray(): Array<UInt8> {
        let nameBytes = name.toArray()
        let typeBytes = [UInt8(rType >> 8), UInt8(rType & 0xFF)]
        let classBytes = [UInt8(rClass >> 8), UInt8(rClass & 0xFF)]
        let ttlBytes = [UInt8(ttl >> 24), UInt8((ttl >> 16) & 0xFF), UInt8((ttl >> 8) & 0xFF), UInt8(ttl & 0xFF)]
        let rdLengthBytes = [UInt8(rdLength >> 8), UInt8(rdLength & 0xFF)]
        let recordBytes = record.toArray()

        return nameBytes + typeBytes + classBytes + ttlBytes + rdLengthBytes + recordBytes
    }
}

public enum Record {
    A(IPv4)
    | NS(Name)
    | CNAME(Name)
    | SOA(SOAValue)
    | WKS(IPv4, UInt8, Array<UInt8>) // IPv4, protocol, bitmap
    | PTR(Name)
    | HINFO(String, String) // CPU, OS
    | MINFO(Name, Name) // mailbox name, errors mailbox
    | MX(UInt16, Name) // preference, name
    | TXT(String)
    | AAAA(IPv6)
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

    public func toArray(): Array<UInt8> {
        match (this) {
            case A(ipv4) => [UInt8(ipv4.a), UInt8(ipv4.b), UInt8(ipv4.c), UInt8(ipv4.d)]
            case NS(name) => name.toArray()
            case CNAME(name) => name.toArray()
            case SOA(soaVal) => soaVal.mname.toArray() + soaVal.rname.toArray() + [UInt8(soaVal.serial >> 24),
                UInt8((soaVal.serial >> 16) & 0xFF), UInt8((soaVal.serial >> 8) & 0xFF), UInt8(soaVal.serial & 0xFF),
                UInt8(soaVal.refresh >> 24), UInt8((soaVal.refresh >> 16) & 0xFF), UInt8((soaVal.refresh >> 8) & 0xFF),
                UInt8(soaVal.refresh & 0xFF), UInt8(soaVal.retry >> 24), UInt8((soaVal.retry >> 16) & 0xFF),
                UInt8((soaVal.retry >> 8) & 0xFF), UInt8(soaVal.retry & 0xFF), UInt8(soaVal.expire >> 24),
                UInt8((soaVal.expire >> 16) & 0xFF), UInt8((soaVal.expire >> 8) & 0xFF), UInt8(soaVal.expire & 0xFF),
                UInt8(soaVal.minimum >> 24), UInt8((soaVal.minimum >> 16) & 0xFF), UInt8((soaVal.minimum >> 8) & 0xFF),
                UInt8(soaVal.minimum & 0xFF)]
            case WKS(ipv4, protocol, bitmap) => [UInt8(ipv4.a), UInt8(ipv4.b), UInt8(ipv4.c), UInt8(ipv4.d), protocol] +
                bitmap
            case PTR(name) => name.toArray()
            case HINFO(cpu, os) => Name.fromString(cpu).toArray() + Name.fromString(os).toArray()
            case MINFO(mailbox, errorsMailbox) => mailbox.toArray() + errorsMailbox.toArray()
            case MX(preference, name) => [UInt8(preference >> 8), UInt8(preference & 0xFF)] + name.toArray()
            case TXT(text) => text.toArray()
            case AAAA(ipv6) => [UInt8(ipv6.a >> 8), UInt8(ipv6.a & 0xFF), UInt8(ipv6.b >> 8), UInt8(ipv6.b & 0xFF),
                UInt8(ipv6.c >> 8), UInt8(ipv6.c & 0xFF), UInt8(ipv6.d >> 8), UInt8(ipv6.d & 0xFF),
                UInt8(ipv6.e >> 8), UInt8(ipv6.e & 0xFF), UInt8(ipv6.f >> 8), UInt8(ipv6.f & 0xFF),
                UInt8(ipv6.g >> 8), UInt8(ipv6.g & 0xFF), UInt8(ipv6.h >> 8), UInt8(ipv6.h & 0xFF)]
            case SRV(priority, weight, port, target) => [UInt8(priority >> 8), UInt8(priority & 0xFF),
                UInt8(weight >> 8), UInt8(weight & 0xFF), UInt8(port >> 8), UInt8(port & 0xFF)] + target.toArray()
            case OPT(code, options) => [UInt8(code >> 8), UInt8(code & 0xFF)] + options
            case Unknown(_, data) => data
        }
    }
}

// 
public struct IPv4 {
    public IPv4(
        let a: UInt8,
        let b: UInt8,
        let c: UInt8,
        let d: UInt8
    ) {}

    public func toString(): String {
        return "${a}.${b}.${c}.${d}"
    }
}

public struct IPv6 {
    public IPv6(
        let a: UInt16,
        let b: UInt16,
        let c: UInt16,
        let d: UInt16,
        let e: UInt16,
        let f: UInt16,
        let g: UInt16,
        let h: UInt16
    ) {}

    public func toString(): String {
        return "${a.format("X")}:${b.format("X")}:${c.format("X")}:${d.format("X")}:${e.format("X")}:${f.format("X")}:${g.format("X")}:${h.format("X")}"
    }
}

public struct SOAValue {
    public SOAValue(
        let mname: Name,
        let rname: Name,
        let serial: UInt32,
        let refresh: UInt32,
        let retry: UInt32,
        let expire: UInt32,
        let minimum: UInt32
    ) {}

    public func toString(): String {
        return "${mname.toString()} ${rname.toString()} ${serial} ${refresh} ${retry} ${expire} ${minimum}"
    }
}
