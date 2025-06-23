package dnsmsg

import std.collection.*
import std.io.*

// Question for a DNS query.
struct Question {
    public Question(
        let name: Name,
        let qType: Type,
        let qClass: Class
    ) {}
}

extend Question {
    public static func fromStream<T>(stream: T): Question where T <: InputStream & Seekable {
        // Read the name
        let name = Name.fromStream(stream)

        // Read the type and class
        let qType = readUInt16(stream).getOrThrow({=> Exception("Failed to read question type from stream")})
        let qClass = readUInt16(stream).getOrThrow({=> Exception("Failed to read question class from stream")})

        return Question(name, qType, qClass)
    }

    public static func tryFromStream<T>(stream: T): Option<Question> where T <: InputStream & Seekable {
        try {
            Question.fromStream(stream)
        } catch (_) {
            None
        }
    }
}
