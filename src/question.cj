package dnsmsg

import std.collection.*
import std.io.*

// Question for a DNS query.
public struct Question {
    public Question(
        public let name: Name,
        public let qType: Type,
        public let qClass: Class
    ) {}
}

extend Question {
    static func fromBytes<T>(buffer: T): Question where T <: InputStream & Seekable {
        // Read the name
        let name = Name.fromBytes(buffer)

        // Read the type and class
        let qType = readUInt16(buffer) ?? throw Exception("Failed to read question type from bytes")
        let qClass = readUInt16(buffer) ?? throw Exception("Failed to read question class from bytes")

        return Question(name, qType, qClass)
    }
}
