class Stack<T> {

    public var count : Int {
        get {
            return data.count
        }
    }
    private var data : [T] = [T]()

    init() {
    }

    public func Push(_ elem: T) {
        data = [elem] + data
    }

    public func Pop() -> T? {
        if let first = data.first {
            data.removeFirst()
            return first
        }
        return nil
    }

    public func Peek() -> T? {
        return data.first
    }

    public func Update(topOfStack: T) {
        data[0] = topOfStack
    }
}
