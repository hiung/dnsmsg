package dnsmsg

import std.collection.*
import std.io.*

// Question for a DNS query.
public struct Question {
    Question(
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
        let qType = readUInt16(buffer).getOrThrow({=> Exception("Failed to read question type from stream")})
        let qClass = readUInt16(buffer).getOrThrow({=> Exception("Failed to read question class from stream")})

        return Question(name, qType, qClass)
    }
}
