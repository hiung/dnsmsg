package dnsmsg

import std.collection.*
import std.unicode.UnicodeStringExtension
import std.io.*

// Name represents a domain name, which is a sequence of labels separated by dots.
public struct Name {
    Name(public let labels: Array<String>) {}

    public init(name: String) {
        if (name.isEmpty()) {
            throw Exception("Name cannot be empty")
        }

        labels = name.trimEnd(" .").toLower().split(".")
    }
}

extend Name <: Hashable {
    public func hashCode(): Int64 {
        toString().hashCode()
    }
}

extend Name <: Equatable<Name> {
    public operator func ==(rhs: Name): Bool {
        if (hashCode() != rhs.hashCode()) {
            return false
        }
        return true
    }
}

extend Name <: ToString {
    public func toString(): String {
        return String.join(labels, delimiter: ".")
    }
}

extend Name {
    static func fromBytes<T>(buffer: T): Name where T <: InputStream & Seekable {
        var labels = ArrayList<String>()
        while (true) {
            // Read the length of the next label
            let length = readUInt8(buffer) ?? throw Exception("Failed to read label length from buffer")
            if (length == 0) {
                break // End of the name
            } else if ((length & 0b1100_0000) == 0b1100_0000) { // Check if the first two bits are set, indicating a pointer
                let nameFromPointer = readCompressedName(buffer, length)
                labels.add(all: nameFromPointer.labels)
                break // End of the name after reading a pointer
            } else if (length > 0b0011_1111) {
                throw Exception("Invalid label length: ${length}")
            }

            let labelBytes = readBytes(buffer, Int64(length)) ?? throw Exception(
                "Failed to read label bytes from buffer")
            let label = String.fromUtf8(labelBytes)
            labels.add(label)
        }

        return Name(labels.toArray())
    }

    private static func readCompressedName<T>(buffer: T, highByte: UInt8): Name where T <: InputStream & Seekable {
        // Combine the next 14 bits to form the pointer
        let lowByte = readUInt8(buffer) ?? throw Exception("Failed to read low byte for pointer from buffer")
        let pointer = UInt16((highByte & 0b0011_1111)) << 8 | UInt16(lowByte)

        // Save the current position
        let currentPos = buffer.position

        if (pointer < 0 || Int64(pointer) >= currentPos) {
            throw Exception("Invalid pointer value: ${pointer}") // Invalid pointer
        }

        // Seek to the pointer position 
        buffer.seek(SeekPosition.Begin(Int64(pointer)))
        // Read the name from the pointer
        // This will recursively read the name from the pointer 
        let name = Name.fromBytes(buffer)
        // Reset to original position
        buffer.seek(SeekPosition.Begin(currentPos))
        return name
    }
}
