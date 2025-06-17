package dnsmsg

import std.unittest.*
import std.unittest.testmacro.*

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

        let question = Question.fromBytes(data)

        @Expect(question.name.toString() == "cangjie-lang.cn")
        @Expect(question.name.labels == ["cangjie-lang", "cn"])
        @Expect(question.name.length == 15) // "cangjie-lang.cn" has 15 characters
        @Expect(question.qType == TypeA)
        @Expect(question.qClass == ClassIN)
    }

    @TestCase
    func testFromBytesInvalidData() {
        let data: Array<UInt8> = [12, b'c', b'a', b'n', b'g', b'j', b'i', b'e', b'-', b'l', b'a', b'n', b'g', // "cangjie-lang"
            2, b'c', b'n', // "cn"
            0, // end of name
            0, 1] // QType A (1), but missing QClass

        @ExpectThrows(Question.fromBytes(data))
    }
}
