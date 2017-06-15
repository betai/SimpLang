import Foundation

class VM {
    var parser : Parser
    init(parser: Parser) {
        self.parser = parser
    }
}


class ValueArray {
    private var stackPointer : Int = 0
    private var valueArray : [Int] = [0]

    public func addToStackPointer(number: Int) {
        stackPointer += number
    }

    public func decrementStackPointer(number: Int) {
        stackPointer -= number
    }

    public func get(relativePosition: Int) -> Int {
        let targetIndex = stackPointer + relativePosition
        assert(targetIndex > 0 && targetIndex < valueArray.count, "ValueArray: tried to get index \(targetIndex) of valueArray which has count \(valueArray.count)")
        return valueArray[targetIndex]
    }

    public func set(relativePosition: Int, value: Int) {
        let targetIndex = stackPointer + relativePosition
        assert(targetIndex < valueArray.count && targetIndex >= 0, "ValueArray: tried to set index \(targetIndex) of valueArray which has count \(valueArray.count)")
        valueArray[targetIndex] = value
    }

    public func copy(dst: Int, src: Int) {
        let dstIndex = stackPointer + dst
        let srcIndex = stackPointer + src
        assert(dstIndex < valueArray.count && dstIndex >= 0, "ValueArray: dstIndex out of range. \(dstIndex) isn't between 0 and \(valueArray.count)")
        assert(srcIndex < valueArray.count && srcIndex >= 0, "ValueArray: srcIndex out of range. \(srcIndex) isn't between 0 and \(valueArray.count)")
        if valueArray[dstIndex] == valueArray[srcIndex] {
            return
        }
        valueArray[dstIndex] = valueArray[srcIndex]
    }
}
