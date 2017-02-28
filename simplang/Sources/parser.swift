/******************************************
 *  SyntaxNode
 * *****************************************/


protocol SyntaxNode : ParserPrintable {
    func eval() -> (value: Int, newValues: [Int]?)
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

    func eval() -> (value: Int, newValues: [Int]?) {
        return (value: token.value, nil)
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

    func eval() -> (value: Int, newValues: [Int]?) {
        return condition.eval().value == 0 ? alternative.eval() : consequent.eval()
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

    func eval() -> (value:Int, newValues: [Int]?) {
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

    func eval() -> (value: Int, newValues: [Int]?) {
        let evaluatedExp = exp.eval()
        switch unaryOp {
        case .Not:
            return evaluatedExp.value == 0 ? (value: 1, newValues: nil) : (value: 0, newValues: nil)
        case .Negative:
            return (value: -evaluatedExp.value, newValues: nil)
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

    func eval() -> (value: Int, newValues: [Int]?) {
        switch binaryOp {
        case .LessThan:
            return left.eval().value < right.eval().value ? (value: 1, newValues: nil) : (value: 0, newValues: nil)
        case .Plus:
            return (value: left.eval().value + right.eval().value, newValues: nil)
        case .Multiply:
            return (value: left.eval().value * right.eval().value, newValues: nil)
        case .Equals:
            return left.eval().value == right.eval().value ? (value: 1, newValues: nil) : (value: 0, newValues: nil)
        case .And:
            return left.eval().value == 0 || right.eval().value == 0 ? (value: 0, newValues: nil) : (value: 1, newValues: nil)
        case .Or:
            return left.eval().value == 0 && right.eval().value == 0 ? (value: 0, newValues: nil) : (value: 1, newValues: nil)
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

    func eval() -> (value: Int, newValues: [Int]?) {
        PushBindingScope(bindings: bindings)
        let result = exp.eval()
        PopBindingScope(bindings: bindings)
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

class LoopExpression : SyntaxNode {
    var bindings : [Binding]
    var exp : SyntaxNode

    init(bindings: [Binding], exp: SyntaxNode) {
        self.bindings = bindings
        self.exp = exp
    }

    func eval() -> (value: Int, newValues: [Int]?) {
        PushBindingScope(bindings: bindings)
        while true {
            let result = exp.eval()
            if result.newValues == nil {
                PopBindingScope(bindings: bindings)
                return result
            }
            for (index, binding) in bindings.enumerated() {
                variableStack[binding.identifierName]?.Update(topOfStack: result.newValues![index])
            }
        }
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + Keyword.Loop.simpleDescription]
        for binding in bindings {
            result.append(binding.parserDescription(depth: depth + 1))
        }
        result.append(exp.parserDescription(depth: depth + 1))
        return result.joined(separator: "\n")
    }
}

class RecurExpression : SyntaxNode {
    var args : [ParenthesizedExpression]

    init(args: [ParenthesizedExpression]) {
        self.args = args
    }

    func eval() -> (value: Int, newValues: [Int]?) {
        var values = [Int]()
        for arg in args {
            values.append(arg.eval().value)
        }
        return (value: 0, newValues: values)
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + Keyword.Recur.simpleDescription]
        for arg in args {
            result.append(arg.parserDescription(depth: depth + 1))
        }
        return result.joined(separator: "\n")
    }
}

func PushBindingScope(bindings: [Binding]) {
    for binding in bindings {
        if let _ = variableStack[binding.identifierName] {
            variableStack[binding.identifierName]!.Push(binding.exp.eval().value)
        } else {
            let stack = Stack<Int>()
            stack.Push(binding.exp.eval().value)
            variableStack[binding.identifierName] = stack
        }
    }
}

func PopBindingScope(bindings: [Binding]) {
    for binding in bindings {
        _ = variableStack[binding.identifierName]!.Pop()
    }
}


var variableStack : [String: Stack<Int>] = [String: Stack<Int>]()

class IdentifierExpression : SyntaxNode {
    var token : IdentifierToken

    init(token: IdentifierToken) {
        self.token = token
    }

    func eval() -> (value: Int, newValues: [Int]?) {
        return (value: variableStack[token.name]!.Peek()!, newValues: nil)
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

    private func peekNextToken() -> Token {
        return tokens[0]
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

    private func parseBindings() -> [Binding] {
        var bindings = [Binding]()
        while true {
            let identifer = nextToken()
            let identifierToken = identifer as! IdentifierToken // TODO: maybe handle this exception more gracefully
            expect(token: Operator.Assign)
            let expression = parseSyntaxNode()
            bindings.append(Binding(identifier: identifierToken, exp: expression))

            let next = nextToken()
            assert(next.type == TokenType.Keyword, "Parser: Expected keyword, got \(next.scannerDescription)")
            if next.type == TokenType.Keyword && (next as! KeywordToken).keyword != Keyword.And {
                putBackToken(token: next)
                break
            }
        }
        return bindings
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
            } else if Keyword.Let == currentKeywordToken.keyword || Keyword.Loop == currentKeywordToken.keyword {
                let bindings = parseBindings()
                expect(token: Keyword.In)
                let expression = parseSyntaxNode()
                expect(token: Keyword.End)
                return Keyword.Let == currentKeywordToken.keyword ? LetExpression(bindings: bindings, exp: expression) : LoopExpression(bindings: bindings, exp: expression)
            } else if Keyword.Recur == currentKeywordToken.keyword {
                var args = [ParenthesizedExpression]()

                while true {
                    let expression = parseSyntaxNode()
                    assert(expression is ParenthesizedExpression, "Parser: Expected parenthesized expression got \(expression.parserDescription(depth: 0))")
                    args.append(expression as! ParenthesizedExpression)
                    let next = peekNextToken()
                    if next.type == TokenType.Operator && (next as! OperatorToken).op == Operator.OpenParen {
                        continue
                    }
                    break;
                }
                return RecurExpression(args: args)
            } else {
                assert(false, "Parser: not yet implemented")
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
