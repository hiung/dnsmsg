package dnsmsg

import std.format.*

struct Resource {
    public Resource(
        let name: Name,
        let rType: Type,
        let rClass: Class,
        let ttl: UInt32,
        let rdLength: UInt16,
        let rdata: Array<UInt8>
    ) {}

    public static func fromBytes(data: Array<UInt8>): Resource {
        if (data.size < 10) {
            throw Exception("Data too short to parse Resource")
        }

        let name = Name.fromBytes(data)
        let index = name.length + 2 // +2 for the null byte and the length byte
        if (index + 10 > data.size) {
            throw Exception("Data too short after QName: ${data.size} bytes")
        }

        let rType: Type = (UInt16(data[index]) << 8) | UInt16(data[index + 1])
        let rClass: Class = (UInt16(data[index + 2]) << 8) | UInt16(data[index + 3])
        let ttl: UInt32 = (UInt32(data[index + 4]) << 24) | (UInt32(data[index + 5]) << 16) | (UInt32(data[index + 6]) <<
            8) | UInt32(data[index + 7])
        let rdLength: UInt16 = (UInt16(data[index + 8]) << 8) | UInt16(data[index + 9])

        if (index + 10 + Int64(rdLength) > data.size) {
            throw Exception("Data too short for rdata: expected ${rdLength} bytes, got ${data.size - index - 10} bytes")
        }

        let rdata = data[(index + 10)..(index + 10 + Int64(rdLength))]
        return Resource(name, rType, rClass, ttl, rdLength, rdata)
    }
}

enum Record {
    A(IPv4) 
    | NS(Name)
    | CNAME(Name)
    | SOA(Name, Name, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)
    | PTR(Name)
    | MX(UInt16, Name)
    | TXT(String)
    | AAAA(IPv6)
    | SRV(UInt16, UInt16, UInt16, Name)
    | Unknown(Type, Array<UInt8>)
    | None

    // public func toString(): String {
    //     match (this) {
    //         case A(name): return "A: ${name}"
    //         case NS(name): return "NS: ${name}"
    //         case CNAME(name): return "CNAME: ${name}"
    //         case SOA(mname, rname, serial, refresh, retry, expire, minimum): 
    //             return "SOA: ${mname} ${rname} ${serial} ${refresh} ${retry} ${expire} ${minimum}"
    //         case PTR(name): return "PTR: ${name}"
    //         case MX(name, preference): return "MX: ${name} preference=${preference}"
    //         case TXT(text): return "TXT: ${text}"
    //         case Unknown(rType, rdata): return "Unknown Record Type: ${rType}, Data: ${rdata.toString()}"
    //         case None: return "No Record"
    //     }
    // }
}

struct IPv4 {
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

struct IPv6 {
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
