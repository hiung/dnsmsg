package dnsmsg

import std.collection.*

// Name represents a domain name, which is a sequence of labels separated by dots.
struct Name {
    public Name(
        let labels: Array<String>,
        let length: Int64
    ) {}
}

extend Name {
    public static func fromBytes(data: Array<UInt8>): Name {
        var labels = ArrayList<String>()
        var index = 0

        while (index < data.size) {
            let length = data[index]
            if (length == 0) {
                break // End of the name
            }

            index += 1

            if (index + Int64(length) > data.size - 1) { // data[index + Int64(length)] should be label length or the end of name(0)
                throw Exception("Invalid label length at index ${index}")
            }
            labels.append(String.fromUtf8(data[index..(index + Int64(length))]))
            index += Int64(length)
        }

        let length = (labels |> map {label => Int64(label.size)} |> reduce {acc: Int64, len: Int64 => acc + len + 1}) ??
            0

        return Name(labels.toArray(), length)
    }

    public static func tryFromBytes(data: Array<UInt8>): Option<Name> {
        try {
            fromBytes(data)
        } catch (_) {
            None
        }
    }

    public static func fromString(name: String): Name {
        let labels = name.split(".")
        return Name(labels.toArray(), name.size)
    }

    public func toString(): String {
        return String.join(labels, delimiter: ".")
    }
}

// Type is the type of a DNS query.
type Type = UInt16
// Resource Record (RR) and Question types
const TypeA: Type = 1
const TypeNS: Type = 2
const TypeCNAME: Type = 5
const TypeSOA: Type = 6
const TypePTR: Type = 12
const TypeMX: Type = 15
const TypeTXT: Type = 16
const TypeAAAA: Type = 28
const TypeSRV: Type = 33
const TypeOPT: Type = 41
// Question types
const TypeWKS: Type = 11
const TypeHINFO: Type = 13
const TypeMINFO: Type = 14
const TypeIXFR: Type = 251
const TypeAXFR: Type = 252
const TypeMAILB: Type = 253
const TypeMAILA: Type = 254
const TypeANY: Type = 255

// Class is the class of a DNS query.
type Class = UInt16
// Resource Record (RR) and Question classes
const ClassIN: Class = 1 // Internet
const ClassCS: Class = 2 // CSNET
const ClassCH: Class = 3 // CHAOS
const ClassHS: Class = 4 // Hesiod
// Question classes
const ClassNONE: Class = 254 // None
const ClassANY: Class = 255 // Any