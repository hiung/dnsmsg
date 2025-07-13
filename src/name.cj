package dnsmsg

import std.collection.*
import std.unicode.UnicodeStringExtension
import std.io.*

// Name represents a domain name, which is a sequence of labels separated by dots.
public struct Name {
    Name(
        public let labels: Array<String>
    ) {}

    public init(name: String) {
        if (name.isEmpty()) {
            throw Exception("Name cannot be empty")
        }
        
        labels = name.trimEnd(" .").toLower().split(".")
    }
}

extend Name <: Hashable {
    public func hashCode(): Int64 {
        this.toString().hashCode()
    }
}

extend Name <: Equatable<Name>{
    public operator func ==(rhs: Name): Bool {
        if (this.hashCode() != rhs.hashCode()) {
            return false    
        }
        return  true
    }
}

extend Name {
    static func fromBytes<T>(buffer: T): Name where T <: InputStream & Seekable {
        var labels = ArrayList<String>()
        while (true) {
            // Read the length of the next label
            let lengthOpt = readUInt8(buffer)
            let length = lengthOpt.getOrThrow({
                => Exception("Failed to read label length from buffer")
            })

            if (length == 0) {
                break // End of the name
            } else if ((length & 0b1100_0000) == 0b1100_0000) { // Check if the first two bits are set, indicating a pointer
                // Combine the next 14 bits to form the pointer
                let pointer = Int64((UInt16((length & 0b0011_1111)) << 8) | UInt16(readUInt8(buffer).getOrThrow(
                    {
                        => Exception("Failed to read pointer from buffer")
                    })))

                if (pointer < 0 || pointer >= buffer.length) {
                    throw Exception("Invalid pointer value: ${pointer}") // Invalid pointer
                }
                // Save the current position
                let prePos = buffer.position
                // Seek to the pointer position 
                buffer.seek(SeekPosition.Begin(pointer))
                // Read the name from the pointer
                // This will recursively read the name from the pointer 
                let nameFromPointer = Name.fromBytes(buffer)
                // Append the labels from the name read from the pointer
                labels.add(all: nameFromPointer.labels)
                // Reset to original position
                buffer.seek(SeekPosition.Begin(prePos))
                // Exit the loop after processing the pointer
                break
            } else if (length > 0b0011_1111) {
                throw Exception("Invalid label length: ${length}")
            }

            let labelBytes = readBytes(buffer, Int64(length)).getOrThrow(
                {
                    => Exception("Failed to read label bytes from buffer")
                })

            let label = String.fromUtf8(labelBytes)
            labels.add(label)
        }

        return Name(labels.toArray())
    }

    public func toString(): String {
        return String.join(labels, delimiter: ".")
    }
}