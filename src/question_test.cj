package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*

@Test
class QuestionTest {
    @TestCase
    func testFromStream() {
        let data: Array<UInt8> = [
                12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
                2, b'c', b'n', // "cn"
                0, // end of name
                0, 1, // QType A (1)
                0, 1 // QClass IN (1)
            ]

        let stream = ByteArrayStream()
        stream.write(data)

        let question = Question.fromStream(stream)
        @Expect(question.name.toString() == "cangjie-lang.cn")
        @Expect(question.qType == TypeA)
        @Expect(question.qClass == ClassIN)
    }

    @TestCase
    func testFromStreamInvalidData() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // end of name
            0, 1] // QType A (1), but missing QClass

        let stream = ByteArrayStream()
        stream.write(data)

        @ExpectThrows(Question.fromStream(stream)) 
    }

    @TestCase
    func testToArray() {
        let question = Question(Name.fromString("cangjie-lang.cn"), TypeA, ClassIN)
        let data: Array<UInt8> = [
                12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
                2, b'c', b'n', // "cn"
                0, // end of name
                0, 1, // QType A (1)
                0, 1 // QClass IN (1)
            ]
        @Expect(question.toArray(), data)
    }
}
