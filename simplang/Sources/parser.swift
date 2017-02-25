/******************************************
 *  SyntaxNode
 * *****************************************/


protocol SyntaxNode {
    func eval() -> Int
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
        return spacingForDepth(depth: depth) + "\(token.value)" + "\n"
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
        assert(nextToken().simpleDescription == token.simpleDescription)
    }

    private func expect(token: Operator) {
        assert(nextToken().simpleDescription == token.simpleDescription)
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
            } else {
                assert(false, "Parser: not yet implemented")
            }

        default:
            assert(false, "Parser: not yet implemented")
        }
    }
}
