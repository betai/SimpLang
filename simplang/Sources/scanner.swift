import Foundation

/******************************************
 *  Token
 * *****************************************/

enum Keyword: Int {
    case Let = 1
    case And, In, If, Then, Else, Recur, Loop, End
    var simpleDescription: String {
        get {
            switch self {
            case .Let:
                return "let"
            case .And:
                return "and"
            case .In:
                return "in"
            case .If:
                return "if"
            case .Then:
                return "then"
            case .Else:
                return "else"
            case .Recur:
                return "recur"
            case .Loop:
                return "loop"
            case .End:
                return "end"
            }
        }
    }
}

func KeywordFromString(name: String) -> Keyword {
    var index = 1
    while let keyword = Keyword(rawValue: index) {
        if keyword.simpleDescription == name {
            return keyword
        }
        index += 1
    }
    assert(false, "Token: Tried to create keyword token with non-keyword string \(name)")
    return Keyword(rawValue: 0)!
}

var _Keywords : [Keyword]?
var Keywords: [Keyword] {
    if _Keywords == nil {
        var index = 1
        var keywords = [Keyword]()
        while let kw = Keyword(rawValue: index) {
            keywords.append(kw)
            index += 1
        }
        _Keywords = keywords
    }
    return _Keywords!
}

var _KeywordStrings : [String]?
var KeywordStrings: [String] {
    if _KeywordStrings == nil {
        _KeywordStrings = Keywords.map {(keyword) -> String in return keyword.simpleDescription}
    }
    return _KeywordStrings!
}

enum Operator: Int {
    case Not = 1
    case Negative, OpenParen, CloseParen, Assign, And, Or, Equals, LessThan, Plus, Multiply
    var simpleDescription: String {
        get {
            switch self {
            case .Not:
                return "!"
            case .Negative:
                return "-"
            case .OpenParen:
                return "("
            case .CloseParen:
                return ")"
            case .Assign:
                return "="
            case .And:
                return "&&"
            case .Or:
                return "||"
            case .Equals:
                return "=="
            case .LessThan:
                return "<"
            case .Plus:
                return "+"
            case .Multiply:
                return "*"
            }
        }
    }
}

func OperatorFromString(op: String) -> Operator {
    var index = 1
    while let t = Operator(rawValue: index) {
        if t.simpleDescription == op {
            return t
        }
        index += 1
    }
    assert(false, "Token: Tried to create operator token with non-operator string \(op)")
    return Operator(rawValue: 0)!
}

var UnaryOperatorTokens : [Operator] {
    return [.Not, .Negative]
}

var BinaryOperatorTokens : [Operator] {
    return [.LessThan, .Plus, .Multiply, .Equals, .And, .Or]
}

var SingleOperatorTokens: [Operator] {
    return [.Not, .Negative, .OpenParen, .CloseParen, .Assign, .LessThan, .Plus, .Multiply]
}


var _SingleOperatorTokenStrings : [String]?
var SingleOperatorTokenStrings: [String] {
    if _SingleOperatorTokenStrings == nil {
        _SingleOperatorTokenStrings = SingleOperatorTokens.map {(op) -> String in return op.simpleDescription}
    }
    return _SingleOperatorTokenStrings!
}

var DoubleOperatorTokens: [Operator] {
    return [.Equals, .And, .Or]
}

var _DoubleOperatorTokenStrings : [String]?
var DoubleOperatorTokenStrings: [String] {
    if _DoubleOperatorTokenStrings == nil {
        _DoubleOperatorTokenStrings = DoubleOperatorTokens.map {(op) -> String in return op.simpleDescription}
    }
    return _DoubleOperatorTokenStrings!
}

let AllOperators = SingleOperatorTokens + DoubleOperatorTokens
let AllOperatorStrings = SingleOperatorTokenStrings + DoubleOperatorTokenStrings


enum TokenType {
    case Keyword, Identifier, Integer, Operator
    var simpleDescription: String {
        get {
            switch self {
            case .Keyword:
                return "keyword"
            case .Identifier:
                return "identifier"
            case .Integer:
                return "integer"
            case .Operator:
                return "operator"
            }
        }
    }
}

protocol Token {
    var type: TokenType { get set }
    var simpleDescription: String { get }
    var scannerDescription: String { get }
}

class KeywordToken : Token {
    var keyword : Keyword
    var type: TokenType = TokenType.Keyword

    init(keyword: Keyword) {
        self.keyword = keyword
    }

    var simpleDescription: String {
        return "\(keyword.simpleDescription)"
    }

    var scannerDescription: String {
        return "\(type.simpleDescription) \(keyword.simpleDescription)"
    }
}

class IdentifierToken : Token {
    var type: TokenType = TokenType.Identifier
    var name : String {
        willSet {
            assert(!KeywordStrings.contains(newValue), "Token: Tried creating identifier token with keyword")
        }
    }

    init(name: String) {
        self.name = name
    }

    var simpleDescription: String {
        return "\(name)"
    }

    var scannerDescription: String {
        return "\(type.simpleDescription) \(name)"
    }
}

class IntegerToken : Token {
    var type: TokenType = TokenType.Integer
    var value : Int

    init(value: Int?) {
        assert(value != nil, "Token: Integer token value is nil")
        self.value = value!
    }

    var simpleDescription: String {
        return "\(type.simpleDescription) \(value.description)"
    }

    var scannerDescription: String {
        return "\(type.simpleDescription) \(value)"
    }
}


class OperatorToken : Token {
    var type: TokenType = TokenType.Operator
    var op : Operator

    init(op: Operator) {
        self.op = op
    }

    var simpleDescription: String {
        return "\(op.simpleDescription)"
    }

    var scannerDescription: String {
        return "\(type.simpleDescription) \(op.simpleDescription)"
    }
}

/******************************************
 *  Scanner
 * *****************************************/

class Scanner {
    public var tokens : [Token] = []
    private let sourceString : String
    private let view : String.UnicodeScalarView
    private let endIndex : String.UnicodeScalarView.Index
    private var currentIndex : String.UnicodeScalarView.Index?
    private var nextIndex : String.UnicodeScalarView.Index?
    private var nextChar : UnicodeScalar

    init(sourcePath: String) {
        do {
            let sourceString = try String(contentsOf: URL(fileURLWithPath: sourcePath))
            self.sourceString = sourceString
            self.view = sourceString.unicodeScalars
            self.endIndex = view.endIndex
            self.nextIndex = view.startIndex
            self.nextChar = view[nextIndex!]
        } catch let error as NSError {
            print("Scanner: Error getting contents from \(sourcePath): \(error)")
            exit(1)
        }
        tokenize()
    }

    private func consume() -> UnicodeScalar {
        currentIndex = currentIndex == nil ? view.startIndex : view.index(after: currentIndex!)
        setNextChar()
        return view[currentIndex!]
    }

    private func setNextChar() {
        nextIndex = view.index(after:currentIndex!)
        nextChar = view[nextIndex!]
    }

    private func doneScanning() -> Bool {
        return nextIndex == endIndex
    }

    private func isUnderscore(char: UnicodeScalar) -> Bool {
        return char == "_".unicodeScalars.first!
    }

    private func isEqualSign(char: UnicodeScalar) -> Bool {
        return char == "=".unicodeScalars.first!
    }

    private func tokenize() {
        while !doneScanning() {
            let currentChar = consume()

            if CharacterSet.whitespacesAndNewlines.contains(currentChar) {
                while CharacterSet.whitespacesAndNewlines.contains(nextChar) {
                    _ = consume()
                }
            } else if CharacterSet.letters.contains(currentChar) || isUnderscore(char: currentChar) {
                var name = String(currentChar)
                while CharacterSet.alphanumerics.contains(nextChar) || isUnderscore(char: currentChar) {
                    name += String(consume())
                }
                if KeywordStrings.contains(name) {
                    tokens.append(KeywordToken(keyword: KeywordFromString(name: name)))
                } else {
                    tokens.append(IdentifierToken(name: name))
                }
            } else if CharacterSet.decimalDigits.contains(currentChar) {
                var number = String(currentChar)
                while CharacterSet.decimalDigits.contains(nextChar) {
                    number += String(consume())
                }
                tokens.append(IntegerToken(value:Int(number)))

            } else if SingleOperatorTokenStrings.contains(String(currentChar)) && !isEqualSign(char: currentChar) {
                tokens.append(OperatorToken(op: OperatorFromString(op: String(currentChar))))

            } else if DoubleOperatorTokenStrings.contains(String(currentChar) + String(currentChar)) {
                if isEqualSign(char: currentChar) {
                    if !isEqualSign(char: nextChar) {
                        tokens.append(OperatorToken(op: OperatorFromString(op: String(currentChar))))
                        continue
                    }
                }
                tokens.append(OperatorToken(op: OperatorFromString(op: String(currentChar) + String(consume()))))

            } else {
                assert(false, "Scanner: Something wrong happened")
            }
        }
    }
}
