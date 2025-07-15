package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*

@Test
class QuestionTest {
    @TestCase
    func testFromBytes() {
        let data: Array<UInt8> = [
                12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
                2, b'c', b'n', // "cn"
                0, // end of name
                0, 1, // QType A (1)
                0, 1 // QClass IN (1)
            ]

        let buffer = ByteBuffer()
        buffer.write(data)

        let question = Question.fromBytes(buffer)
        @Expect(question.name.toString() == "cangjie-lang.cn")
        @Expect(question.qType == TypeA)
        @Expect(question.qClass == ClassIN)
    }

    @TestCase
    func testFromByteInvalidData() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // end of name
            0, 1] // QType A (1), but missing QClass

        let buffer = ByteBuffer()
        buffer.write(data)

        @ExpectThrows(Question.fromBytes(buffer)) 
    }
}
