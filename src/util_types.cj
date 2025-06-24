package dnsmsg

import std.collection.*
import std.io.*

func readUInt8<T>(stream: T): Option<UInt8> where T <: InputStream & Seekable {
    let byte = Array<UInt8>(1, item: 0)
    if (stream.read(byte) == 0) {
        return None // No data read, return None
    }

    return byte[0]
}

func readUInt16<T>(stream: T): Option<UInt16> where T <: InputStream & Seekable {
    let bytes = Array<UInt8>(2, item: 0)
    let bytesRead = stream.read(bytes)
    if (bytesRead != 2) {
        stream.seek(SeekPosition.Current(-bytesRead)) // Seek back to the current position
        return None // Not enough data read, return None
    }

    return (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
}

func readUInt32<T>(stream: T): Option<UInt32> where T <: InputStream & Seekable {
    let bytes = Array<UInt8>(4, item: 0)
    let bytesRead = stream.read(bytes)
    if (bytesRead != 4) {
        stream.seek(SeekPosition.Current(-bytesRead)) // Seek back to the current position
        return None // Not enough data read, return None
    }

    return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
}

func readBytes<T>(stream: T, length: Int64): Option<Array<UInt8>> where T <: InputStream & Seekable {
    if (length <= 0) {
        return None
    }

    let bytes = Array<UInt8>(length, item: 0)
    let bytesRead = stream.read(bytes)
    if (bytesRead != length) {
        stream.seek(SeekPosition.Current(-bytesRead)) // Seek back to the current position
        return None // Not enough data read, return None
    }

    return bytes
}

// Name represents a domain name, which is a sequence of labels separated by dots.
public struct Name {
    public Name(
        public let labels: Array<String>,
        public let length: Int64
    ) {}
}

extend Name {
    public static func fromStream<T>(stream: T): Name where T <: InputStream & Seekable {
        var labels = ArrayList<String>()
        while (true) {
            // Read the length of the next label
            let lengthOpt = readUInt8(stream)
            let length = lengthOpt.getOrThrow({
                => Exception("Failed to read label length from stream")
            })

            if (length == 0) {
                break // End of the name
            } else if ((length & 0b1100_0000) == 0b1100_0000) { // Check if the first two bits are set, indicating a pointer
                // Combine the next 14 bits to form the pointer
                let pointer = Int64((UInt16((length & 0b0011_1111)) << 8) | UInt16(readUInt8(stream).getOrThrow(
                    {
                        => Exception("Failed to read pointer from stream")
                    })))

                if (pointer < 0 || pointer >= stream.length) {
                    throw Exception("Invalid pointer value: ${pointer}") // Invalid pointer
                }
                // Save the current position
                let prePos = stream.position
                // Seek to the pointer position 
                stream.seek(SeekPosition.Begin(pointer))
                // Read the name from the pointer
                // This will recursively read the name from the pointer 
                let nameFromPointer = Name.fromStream(stream)
                // Append the labels from the name read from the pointer
                labels.appendAll(nameFromPointer.labels)
                // Reset to original position
                stream.seek(SeekPosition.Begin(prePos))
                // Exit the loop after processing the pointer
                break
            } else if (length > 0b0011_1111) {
                throw Exception("Invalid label length: ${length}")
            }

            let labelBytes = readBytes(stream, Int64(length)).getOrThrow(
                {
                    => Exception("Failed to read label bytes from stream")
                })

            let label = String.fromUtf8(labelBytes)
            labels.append(label)
        }

        let nameLength = (labels |> map {label => label.size} |> reduce {acc, len => acc + len + 1}) ??
            0

        return Name(labels.toArray(), Int64(nameLength))
    }

    public static func tryFromStream<T>(stream: T): Option<Name> where T <: InputStream & Seekable {
        try {
            Name.fromStream(stream)
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

    public func toBytes(): Array<UInt8> {
        labels |> 
        map { label =>
            let labelBytes = Array<UInt8>(label.size + 1, item: 0)
            labelBytes[0] = UInt8(label.size)
            labelBytes[1..=label.size] = label.toArray()
            labelBytes
        } |> 
        flatten |> 
        concat(Array<UInt8>(1, item: 0)) |> 
        collectArray
    }
}

// Type is the type of a DNS query.
type Type = UInt16
// Resource Record (RR) and Question types
const TypeA: Type = 1 // a host address
const TypeNS: Type = 2 // an authoritative name server
const TypeCNAME: Type = 5 // the canonical name for an alias
const TypeSOA: Type = 6 // marks the start of a zone of authority
const TypeWKS: Type = 11 // a well known service description
const TypePTR: Type = 12 // a domain name pointer
const TypeHINFO: Type = 13 // host information
const TypeMINFO: Type = 14 // mailbox or mail list information
const TypeMX: Type = 15 // mail exchange
const TypeTXT: Type = 16 // text strings
const TypeAAAA: Type = 28 // a host address (IPv6)
const TypeSRV: Type = 33 // service locator
const TypeOPT: Type = 41 // a pseudo-RR used to carry extended information in DNS messages

// Question types
const TypeAXFR: Type = 252 // A request for a transfer of an entire zone
const TypeMAILB: Type = 253 // A request for mailbox-related records (MB, MG or MR)
const TypeMAILA: Type = 254 // A request for mail agent RRs (Obsolete - used only for examples in RFCs)
const TypeANY: Type = 255 // A request for all records

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
