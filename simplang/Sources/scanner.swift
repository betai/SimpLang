import Foundation

/******************************************
 *  Token
 * *****************************************/

enum TokenKeyword: Int {
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

enum TokenOperator: Int {
    case OpenParen = 1
    case CloseParen, Not, LessThan, Plus, Multiply, Negative, Assign, DividingLine, Equals, And, Or
    var simpleDescription: String {
        get {
            switch self {
            case .OpenParen:
                return "("
            case .CloseParen:
                return ")"
            case .Not:
                return "!"
            case .LessThan:
                return "<"
            case .Plus:
                return "+"
            case .Multiply:
                return "*"
            case .Negative:
                return "-"
            case .Assign:
                return "="
            case .DividingLine:
                assert(false, "Token: There is no reason to use this")
            case .Equals:
                return "=="
            case .And:
                return "&&"
            case .Or:
                return "||"
            }
        }
    }
}

var _SingleOperatorTokens : [String]?
var SingleOperatorTokens: [String] {
    if _SingleOperatorTokens == nil {
        var index = 1
        var operatorTokens = [String]()
        while let op = TokenOperator(rawValue: index) {
            if index < TokenOperator.DividingLine.rawValue {
                operatorTokens.append(op.simpleDescription)
                index += 1
            } else {
                break
            }
        }
        _SingleOperatorTokens = operatorTokens
    }
    return _SingleOperatorTokens!
}

var _DoubleOperatorTokens : [String]?
var DoubleOperatorTokens: [String] {
    if _DoubleOperatorTokens == nil {
        var index = TokenOperator.DividingLine.rawValue + 1
        var operatorTokens = [String]()
        while let op = TokenOperator(rawValue: index) {
            operatorTokens.append(op.simpleDescription)
            index += 1
        }
        _DoubleOperatorTokens = operatorTokens
    }
    return _DoubleOperatorTokens!
}

var _TokenKeywords : [String]?
var TokenKeywords: [String] {
    if _TokenKeywords == nil {
        var index = 1
        var keywords = [String]()
        while let kw = TokenKeyword(rawValue: index) {
            keywords.append(kw.simpleDescription)
            index += 1
        }
        _TokenKeywords = keywords
    }
    return _TokenKeywords!
}

let AllOperators = SingleOperatorTokens + DoubleOperatorTokens


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
    var type: TokenType = TokenType.Keyword
    var keyword : String {
        willSet {
            assert(TokenKeywords.contains(newValue), "Token: Tried creating keyword token with non-keyword")
        }
    }

    init(keyword: String) {
        self.keyword = keyword
    }

    var simpleDescription: String {
        return "\(keyword)"
    }

    var scannerDescription: String {
        return "\(type.simpleDescription) \(keyword)"
    }
}

class IdentifierToken : Token {
    var type: TokenType = TokenType.Identifier
    var name : String {
        willSet {
            assert(!TokenKeywords.contains(newValue), "Token: Tried creating identifier token with keyword")
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
    var op : String {
        willSet {
            assert(AllOperators.contains(newValue), "Token: Tried creating operator token with non-operator")
        }
    }

    init(op: String) {
        self.op = op
    }

    var simpleDescription: String {
        return "\(op)"
    }

    var scannerDescription: String {
        return "\(type.simpleDescription) \(op)"
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
//        print("Tokenizing \(sourcePath)..") // remove me
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
                if TokenKeywords.contains(name) {
                    tokens.append(KeywordToken(keyword: name))
                } else {
                    tokens.append(IdentifierToken(name: name))
                }
            } else if CharacterSet.decimalDigits.contains(currentChar) {
                var number = String(currentChar)
                while CharacterSet.decimalDigits.contains(nextChar) {
                    number += String(consume())
                }
                tokens.append(IntegerToken(value:Int(number)))

            } else if SingleOperatorTokens.contains(String(currentChar)) && !isEqualSign(char: currentChar) {
                tokens.append(OperatorToken(op: String(currentChar)))

            } else if DoubleOperatorTokens.contains(String(currentChar) + String(currentChar)) {
                if isEqualSign(char: currentChar) {
                    if !isEqualSign(char: nextChar) {
                        tokens.append(OperatorToken(op: String(currentChar)))
                        continue
                    }
                }
                tokens.append(OperatorToken(op: String(currentChar) + String(consume())))

            } else {
                assert(false, "Scanner: Something wrong happened")
            }
        }
    }
}
