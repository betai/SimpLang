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
        var result = [spacingForDepth(depth: depth) + TokenKeyword.If.simpleDescription]
        result.append(self.condition.parserDescription(depth: depth + 1))
        result.append(self.consequent.parserDescription(depth: depth + 1))
        result.append(self.alternative.parserDescription(depth: depth + 1))
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

    private func expect(token: TokenKeyword) {
        assert(nextToken().simpleDescription == token.simpleDescription)
    }

    private func parseSyntaxNode() -> SyntaxNode {
        let currentToken = nextToken()
        switch currentToken.type {
        case .Integer:
            return IntegerExpression(token: currentToken as! IntegerToken)
        case .Keyword:
            let currentTokenKeyword = currentToken as! KeywordToken
            if TokenKeyword.If.simpleDescription == currentTokenKeyword.simpleDescription {
                let condition = parseSyntaxNode()
                expect(token: TokenKeyword.Then)
                let consequent = parseSyntaxNode()
                expect(token: TokenKeyword.Else)
                let alternative = parseSyntaxNode()
                expect(token: TokenKeyword.End)
                return IfExpression(condition: condition, consequent: consequent, alternative: alternative)
            } else {
                assert(false, "Parser: not yet implemented")
                return IntegerExpression(token: IntegerToken(value: nil))
            }
        default:
            assert(false, "Parser: not yet implemented")
            return IntegerExpression(token: IntegerToken(value: nil))
        }
    }
}
