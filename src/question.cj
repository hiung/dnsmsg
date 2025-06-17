package dnsmsg

import std.collection.*

// Question for a DNS query.
struct Question {
    public Question(
        let name: Name,
        let qType: Type,
        let qClass: Class
    ) {}
}

extend Question {
    public static func fromBytes(data: Array<UInt8>): Question {
        if (data.size <= 4) {
            throw Exception("Question data too short: ${data.size} bytes")
        }

        var name = Name.fromBytes(data)
        let index = name.length + 2 
        if (index + 4 > data.size) {
            throw Exception("Question data too short after QName: ${data.size} bytes")
        }
        let qType: Type = (UInt16(data[index]) << 8) | UInt16(data[index + 1])
        let qClass: Class = (UInt16(data[index + 2]) << 8) | UInt16(data[index + 3])

        return Question(name, qType, qClass)
    }

    public static func tryFromBytes(data: Array<UInt8>): Option<Question> {
        try {
            fromBytes(data)
        } catch (_) {
            None
        }
    }
}
