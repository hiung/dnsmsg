package dnsmsg

import std.io.*
import std.collection.*

// Message represents a DNS message, which includes a header, questions, answers, authorities, and additionals.
public struct Message {
    public Message(
        public let header: Header,
        public let questions: Array<Question>,
        public let answers: Array<Resource>,
        public let authorities: Array<Resource>,
        public let additionals: Array<Resource>
    ) {}
}

extend Message {
    public static func fromStream<T>(stream: T): Message where T <: InputStream & Seekable {
        // Read the header
        let header = Header.fromStream(stream)

        // Read the number of questions, answers, authorities, and additionals
        let qdCount = header.qdCount
        let anCount = header.anCount
        let nsCount = header.nsCount
        let arCount = header.arCount

        // Read the questions
        let questions = 0..qdCount |> map {
            _ => Question.fromStream(stream)
        } |> collectArray

        // Read the answers
        let answers = 0..anCount |> map {
            _ => Resource.fromStream(stream)
        } |> collectArray

        // Read the authorities
        let authorities = 0..nsCount |> map {
            _ => Resource.fromStream(stream)
        } |> collectArray

        // Read the additionals
        let additionals = 0..arCount |> map {
            _ => Resource.fromStream(stream)
        } |> collectArray

        return Message(header, questions, answers, authorities, additionals)
    }

    public static func tryFromStream<T>(stream: T): Option<Message> where T <: InputStream & Seekable {
        try {
            Message.fromStream(stream)
        } catch (_) {
            None
        }
    }

    public func toArray(): Array<UInt8> {
        let headerBytes = header.toArray()
        let questionsBytes = questions |> map { question => question.toArray() } |> flatten 
        let answersBytes = answers |> map { answer => answer.toArray() } |> flatten
        let authoritiesBytes = authorities |> map { authority => authority.toArray() } |> flatten
        let additionalsBytes = additionals |> map { additional => additional.toArray() } |> flatten

        return headerBytes |> concat(questionsBytes) |> concat(answersBytes) |> concat(authoritiesBytes) |> concat(additionalsBytes) |> collectArray
    }

    public func toCompressedArray(): Array<UInt8> {
        // This method is a placeholder for future compression logic
        return this.toArray()
    }
}
