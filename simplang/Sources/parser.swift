/******************************************
 *  SyntaxNode
 * *****************************************/


protocol SyntaxNode : ParserPrintable {
    func eval() -> Int
}

protocol ParserPrintable {
    func parserDescription(depth: Int) -> String
}

func spacingForDepth(depth: Int) -> String {
    return repeatElement("  ", count: depth).joined()
}

class IntegerExpression : SyntaxNode {
    var token : IntegerToken
    init(token: IntegerToken) {
        self.token = token
    }

    func eval() -> Int {
        return token.value
    }

    func parserDescription(depth: Int) -> String {
        return spacingForDepth(depth: depth) + "\(token.value)"
    }
}

class IfExpression : SyntaxNode {
    var condition: SyntaxNode
    var consequent: SyntaxNode
    var alternative: SyntaxNode

    init(condition: SyntaxNode, consequent: SyntaxNode, alternative: SyntaxNode) {
        self.condition = condition
        self.consequent = consequent
        self.alternative = alternative
    }

    func eval() -> Int {
        return condition.eval() == 0 ? alternative.eval() : consequent.eval()
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + Keyword.If.simpleDescription]
        result.append(self.condition.parserDescription(depth: depth + 1))
        result.append(self.consequent.parserDescription(depth: depth + 1))
        result.append(self.alternative.parserDescription(depth: depth + 1))
        return result.joined(separator: "\n")
    }
}

class ParenthesizedExpression : SyntaxNode {
    var exp : SyntaxNode

    init(exp: SyntaxNode) {
        self.exp = exp
    }

    func eval() -> Int {
        return exp.eval()
    }

    func parserDescription(depth: Int) -> String {
        return exp.parserDescription(depth: depth)
    }
}

class UnaryExpression : SyntaxNode {
    var unaryOp : Operator
    var exp : SyntaxNode

    init(unaryOp: Operator, exp: SyntaxNode) {
        self.unaryOp = unaryOp
        self.exp = exp
    }

    func eval() -> Int {
        switch unaryOp {
        case .Not:
            return exp.eval() == 0 ? 1 : 0
        case .Negative:
            return -exp.eval()
        default:
            assert(false, "SyntaxNode: not a unary operation \(unaryOp.simpleDescription)")
        }
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + unaryOp.simpleDescription]
        result.append(exp.parserDescription(depth: depth + 1))
        return result.joined(separator: "\n")
    }
}

class BinaryExpression : SyntaxNode {
    var binaryOp : Operator
    var left : SyntaxNode
    var right : SyntaxNode

    init(binaryOp: Operator, left: SyntaxNode, right: SyntaxNode)
    {
        self.binaryOp = binaryOp
        self.left = left
        self.right = right
    }

    func eval() -> Int {
        switch binaryOp {
        case .LessThan:
            return left.eval() < right.eval() ? 1 : 0
        case .Plus:
            return left.eval() + right.eval()
        case .Multiply:
            return left.eval() * right.eval()
        case .Equals:
            return left.eval() == right.eval() ? 1 : 0
        case .And:
            return left.eval() == 0 || right.eval() == 0 ? 0 : 1
        case .Or:
            return left.eval() == 0 && right.eval() == 0 ? 0 : 1
        default:
            assert(false, "SyntaxNode: not a binary operation \(binaryOp.simpleDescription)")
        }
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + binaryOp.simpleDescription]
        result.append(left.parserDescription(depth: depth + 1))
        result.append(right.parserDescription(depth: depth + 1))
        return result.joined(separator: "\n")
    }
}

class LetExpression : SyntaxNode {
    var bindings : [Binding]
    var exp : SyntaxNode

    init(bindings: [Binding], exp: SyntaxNode) {
        self.bindings = bindings
        self.exp = exp
    }

    func eval() -> Int {
        for binding in bindings {
            if let _ = variableStack[binding.identifierName] {
                variableStack[binding.identifierName]!.Push(binding.exp.eval())
            } else {
                let stack = Stack<Int>()
                stack.Push(binding.exp.eval())
                variableStack[binding.identifierName] = stack
            }

        }
        let result = exp.eval()
        for binding in bindings {
            _ = variableStack[binding.identifierName]!.Pop()
        }
        return result
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + Keyword.Let.simpleDescription]
        for binding in bindings {
            result.append(binding.parserDescription(depth: depth + 2))
        }
        result.append(exp.parserDescription(depth: depth + 1))
        return result.joined(separator: "\n")
    }
}

var variableStack : [String: Stack<Int>] = [String: Stack<Int>]()

class IdentifierExpression : SyntaxNode {
    var token : IdentifierToken

    init(token: IdentifierToken) {
        self.token = token
    }

    func eval() -> Int {
        return variableStack[token.name]!.Peek()!
    }

    func parserDescription(depth: Int) -> String {
        return spacingForDepth(depth: depth) + token.name
    }
}

class Binding : ParserPrintable {
    var identifier : IdentifierExpression
    var identifierName : String
    var exp : SyntaxNode

    init(identifier: IdentifierToken, exp: SyntaxNode) {
        self.identifier = IdentifierExpression(token: identifier)
        self.identifierName = identifier.name
        self.exp = exp
    }

    func parserDescription(depth: Int) -> String {
        return [identifier.parserDescription(depth: depth), exp.parserDescription(depth: depth + 1)].joined(separator: "\n")
    }
}

/******************************************
 *  Parser
 * *****************************************/

class Parser {
    public var nodes : [SyntaxNode] = []
    public var syntaxTreeString: String {
        get {
            var result = ""
            for node in self.nodes {
                result += node.parserDescription(depth: 0)
            }
            return result
        }
    }
    private var tokens : [Token]

    init(tokens: [Token]) {
        self.tokens = tokens
        createSyntaxTree()
    }

    private func createSyntaxTree() {
        while tokens.count > 0 {
            nodes.append(parseSyntaxNode())
        }
    }
    private func nextToken() -> Token {
        return tokens.removeFirst()
    }

    private func putBackToken(token: Token) {
        tokens = [token] + tokens
    }
    private func expect(token: Keyword) {
        assert(nextToken().simpleDescription == token.simpleDescription, "Parser: Expected keyword, got \(token.simpleDescription)")
    }

    private func expect(token: Operator) {
        assert(nextToken().simpleDescription == token.simpleDescription, "Parser: Expected operator, got \(token.simpleDescription)")
    }

    private func parseSyntaxNode() -> SyntaxNode {
        let currentToken = nextToken()
        switch currentToken.type {
        case .Integer:
            return IntegerExpression(token: currentToken as! IntegerToken)
        case .Keyword:
            let currentKeywordToken = currentToken as! KeywordToken
            if Keyword.If == currentKeywordToken.keyword {
                let condition = parseSyntaxNode()
                expect(token: Keyword.Then)
                let consequent = parseSyntaxNode()
                expect(token: Keyword.Else)
                let alternative = parseSyntaxNode()
                expect(token: Keyword.End)
                return IfExpression(condition: condition, consequent: consequent, alternative: alternative)
            } else if Keyword.Let == currentKeywordToken.keyword {
                var bindings = [Binding]()
                while true {
                    let identifer = nextToken()
                    let identifierToken = identifer as! IdentifierToken // TODO: maybe handle this exception more gracefully
                    expect(token: Operator.Assign)
                    let expression = parseSyntaxNode()
                    bindings.append(Binding(identifier: identifierToken, exp: expression))

                    let next = nextToken()
                    if next.type == TokenType.Keyword && (next as! KeywordToken).keyword != Keyword.And {
                        putBackToken(token: next)
                        break
                    }
                }
                expect(token: Keyword.In)
                let expression = parseSyntaxNode()
                expect(token: Keyword.End)
                return LetExpression(bindings: bindings, exp: expression)
            } else {
                assert(false, "Parser: not yet implemented")
                return IntegerExpression(token: IntegerToken(value: nil))
            }
        case .Operator:
            let currentOperatorToken = currentToken as! OperatorToken
            if Operator.OpenParen == currentOperatorToken.op {
                var expression = parseSyntaxNode()
                let next = nextToken()
                if next.type == TokenType.Operator && BinaryOperatorTokens.contains((next as! OperatorToken).op) {
                    let binaryOperatorToken = next as! OperatorToken
                    expression = BinaryExpression(binaryOp: binaryOperatorToken.op, left: expression, right: parseSyntaxNode())
                } else {
                    putBackToken(token: next)
                }
                expect(token: Operator.CloseParen)
                return ParenthesizedExpression(exp: expression)
            } else if UnaryOperatorTokens.contains(currentOperatorToken.op) {
                return UnaryExpression(unaryOp: currentOperatorToken.op, exp: parseSyntaxNode())
//            } else if BinaryOperatorTokens.contains(currentOperatorToken.op) {
//                assert(false, "Parser: not yet implemented")
//                return BinaryExpression(binaryOp: currentOperatorToken.op, left: ?, right: parseSyntaxNode())
            } else {
                assert(false, "Parser: not yet implemented")
            }
        case .Identifier:
            return IdentifierExpression(token: currentToken as! IdentifierToken)
        }
    }
}
