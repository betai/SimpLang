import Foundation

/******************************************
 *  Token
 * *****************************************/

let TokenKeywords = [
  "let", "and", "in", "if", "then", "else", "recur", "loop", "end"
]

let TokenSingleOperators = [
  "(", ")", "!", "<", "+", "*", "-"
]

let TokenDoubleOperators = [
  "=", "&", "|"
]

let AllOperators = TokenSingleOperators + ["="] + TokenDoubleOperators.map({ (op) -> String in return op + op })

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
    var simpleDescription : String { get }
}

class TokenKeyword : Token {
    var type: TokenType = TokenType.Keyword
    var keyword : String {
        willSet {
            assert(TokenKeywords.contains(newValue), "Tried creating keyword token with non-keyword")
        }
    }

    init(keyword: String) {
        self.keyword = keyword
    }

    var simpleDescription: String {
        return "\(type.simpleDescription) \(keyword)"
    }
}

class TokenIdentifier : Token {
    var type: TokenType = TokenType.Identifier
    var name : String {
        willSet {
            assert(!TokenKeywords.contains(newValue), "Tried creating identifier token with keyword")
        }
    }

    init(name: String) {
        self.name = name
    }

    var simpleDescription: String {
        return "\(type.simpleDescription) \(name)"
    }
}

class TokenInteger : Token {
    var type: TokenType = TokenType.Integer
    var value : Int

    init(value: Int?) {
        assert(value != nil, "Integer token value is nil")
        self.value = value!
    }

    var simpleDescription: String {
        return "\(type.simpleDescription) \(value.description)"
    }
}


class TokenOperator : Token {
    var type: TokenType = TokenType.Operator
    var op : String {
        willSet {
            assert(AllOperators.contains(newValue), "Tried creating operator token with non-operator")
        }
    }

    init(op: String) {
        self.op = op
    }

    var simpleDescription: String {
        return "\(type.simpleDescription) \(op)"
    }
}

func charToString(character: Character?) -> String? {
    if character != nil {
        return String(describing: character!)
    }
    return nil
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
            print("Error getting contents from \(sourcePath): \(error)")
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
                    tokens.append(TokenKeyword(keyword: name))
                } else {
                    tokens.append(TokenIdentifier(name: name))
                }
            } else if CharacterSet.decimalDigits.contains(currentChar) {
                var number = String(currentChar)
                while CharacterSet.decimalDigits.contains(nextChar) {
                    number += String(consume())
                }
                tokens.append(TokenInteger(value:Int(number)))

            } else if TokenSingleOperators.contains(String(currentChar)) {
                tokens.append(TokenOperator(op: String(currentChar)))

            } else if TokenDoubleOperators.contains(String(currentChar)) {
                if isEqualSign(char: currentChar) {
                    if !isEqualSign(char: nextChar) {
                        tokens.append(TokenOperator(op: String(currentChar)))
                        continue
                    }
                }
                tokens.append(TokenOperator(op: String(currentChar) + String(consume())))

            } else {
                assert(false, "Something wrong happened in scanner")
            }
        }
    }
}
