class Stack<T> {

    public var count : Int {
        get {
            return data.count
        }
    }
    private var data : [T] = [T]()

    init() {
    }

    public func push(_ elem: T) {
        data = [elem] + data
    }

    public func pop() -> T? {
        if let first = data.first {
            data.removeFirst()
            return first
        }
        return nil
    }

    public func peek() -> T? {
        return data.first
    }

    public func update(topOfStack: T) {
        data[0] = topOfStack
    }
}
