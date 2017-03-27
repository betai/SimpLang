/******************************************
 *  Expression
 * *****************************************/


protocol Expression : ParserPrintable {
    func eval() -> (value: Int, newValues: [Int]?)
}

protocol ParserPrintable {
    func parserDescription(depth: Int) -> String
}

func spacingForDepth(depth: Int) -> String {
    return repeatElement("  ", count: depth).joined()
}

class IntegerExpression : Expression {
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

class IfExpression : Expression {
    var condition: Expression
    var consequent: Expression
    var alternative: Expression

    init(condition: Expression, consequent: Expression, alternative: Expression) {
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

class ParenthesizedExpression : Expression {
    var exp : Expression

    init(exp: Expression) {
        self.exp = exp
    }

    func eval() -> (value:Int, newValues: [Int]?) {
        return exp.eval()
    }

    func parserDescription(depth: Int) -> String {
        return exp.parserDescription(depth: depth)
    }
}

class UnaryExpression : Expression {
    var unaryOp : Operator
    var exp : Expression

    init(unaryOp: Operator, exp: Expression) {
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
            assert(false, "Expression: not a unary operation \(unaryOp.simpleDescription)")
        }
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + unaryOp.simpleDescription]
        result.append(exp.parserDescription(depth: depth + 1))
        return result.joined(separator: "\n")
    }
}

class BinaryExpression : Expression {
    var binaryOp : Operator
    var left : Expression
    var right : Expression

    init(binaryOp: Operator, left: Expression, right: Expression)
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
            assert(false, "Expression: not a binary operation \(binaryOp.simpleDescription)")
        }
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + binaryOp.simpleDescription]
        result.append(left.parserDescription(depth: depth + 1))
        result.append(right.parserDescription(depth: depth + 1))
        return result.joined(separator: "\n")
    }
}

class LetExpression : Expression {
    var bindings : [Binding]
    var exp : Expression

    init(bindings: [Binding], exp: Expression) {
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

class LoopExpression : Expression {
    var bindings : [Binding]
    var exp : Expression

    init(bindings: [Binding], exp: Expression) {
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
                variableStack[binding.identifierName]?.update(topOfStack: result.newValues![index])
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

class RecurExpression : Expression {
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
            variableStack[binding.identifierName]!.push(binding.exp.eval().value)
        } else {
            let stack = Stack<Int>()
            stack.push(binding.exp.eval().value)
            variableStack[binding.identifierName] = stack
        }
    }
}

func PopBindingScope(bindings: [Binding]) {
    for binding in bindings {
        _ = variableStack[binding.identifierName]!.pop()
    }
}


var variableStack : [String: Stack<Int>] = [String: Stack<Int>]()

class IdentifierExpression : Expression {
    var token : IdentifierToken

    init(token: IdentifierToken) {
        self.token = token
    }

    func eval() -> (value: Int, newValues: [Int]?) {
        return (value: variableStack[token.name]!.peek()!, newValues: nil)
    }

    func parserDescription(depth: Int) -> String {
        return spacingForDepth(depth: depth) + token.name
    }
}

class Binding : ParserPrintable {
    var identifier : IdentifierExpression
    var identifierName : String
    var exp : Expression

    init(identifier: IdentifierToken, exp: Expression) {
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
    public var root : Expression?
    public var syntaxTreeString: String {
        get {
            var result = ""
            result = root == nil ? result : root!.parserDescription(depth: 0)
            return result
        }
    }
    private var tokens : [Token]

    init(tokens: [Token]) {
        self.tokens = tokens
        if tokens.count > 0 {
            resultStacks.push(Stack<Expression>())
            operatorStacks.push(Stack<Operator>())
            createSyntaxTree()
        }
    }

    private func createSyntaxTree() {
        root = parseBinaryExpression()
    }

    private var resultStacks : Stack<Stack<Expression>> = Stack<Stack<Expression>>()
    private var operatorStacks : Stack<Stack<Operator>> = Stack<Stack<Operator>>()

    private var resultStack: Stack<Expression> {
        get {
            return resultStacks.peek()!
        }
    }

    private var operatorStack: Stack<Operator> {
        get {
            return operatorStacks.peek()!
        }
    }

    private func enterNewScope() {
        resultStacks.push(Stack<Expression>())
        operatorStacks.push(Stack<Operator>())
    }

    private func leaveScope() {
        _ = resultStacks.pop()
        _ = operatorStacks.pop()
    }

    private func shuntinYardAlgorithm(newOperator: Operator) {
        while operatorStack.count > 0 && hasLowerPrecedence(op: newOperator, opOnTheStack: operatorStack.peek()!) {
            resultStack.push(createBinaryExpression())
        }
        operatorStack.push(newOperator)
    }

    private func hasLowerPrecedence(op: Operator, opOnTheStack: Operator) -> Bool {
        // the order of the operators in the enums reflect operator precedence
        return op.rawValue <= opOnTheStack.rawValue
    }

    private func createBinaryExpression() -> BinaryExpression {
        let op = operatorStack.pop()!
        let right = resultStack.pop()!
        let left = resultStack.pop()!
        return BinaryExpression(binaryOp: op, left: left, right: right)
    }

    private func joinExpressionsWithOperators() -> Expression? {
        while operatorStack.count > 0 {
            resultStack.push(createBinaryExpression())
        }
        return resultStack.pop()
    }

    private func peekNextToken() -> Token? {
        return tokens.first
    }

    private func nextToken() -> Token {
        return tokens.removeFirst()
    }

    private func putBackToken(token: Token) {
        tokens = [token] + tokens
    }
    private func expect(token: Keyword) {
        let nextKeyword = (nextToken() as! KeywordToken).keyword
        assert(nextKeyword == token, "Parser: Expected \(token.simpleDescription) got \(nextKeyword.simpleDescription)")
    }

    private func expect(token: Operator) {
        let nextOperator = (nextToken() as! OperatorToken).op
        assert(nextOperator == token, "Parser: Expected \(token.simpleDescription) got \(nextOperator.simpleDescription)")
    }

    private func parseBindings() -> [Binding] {
        var bindings = [Binding]()
        while true {
            let identifer = nextToken()
            let identifierToken = identifer as! IdentifierToken // TODO: maybe handle this exception more gracefully
            expect(token: Operator.Assign)
            let expression = parseBinaryExpression()
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

    private func parseBinaryExpression() -> Expression {
        while true {
            resultStack.push(parsePrimaryExpression())
            if peekNextToken() == nil || peekNextToken()!.type != TokenType.Operator || !BinaryOperatorTokens.contains((peekNextToken()! as! OperatorToken).op) {
                break
            }
            let op = (nextToken() as! OperatorToken).op
            shuntinYardAlgorithm(newOperator: op)
        }
        return joinExpressionsWithOperators()!
    }

    private func parsePrimaryExpression() -> Expression {
        let currentToken = nextToken()
        switch currentToken.type {
        case .Integer:
            return IntegerExpression(token: currentToken as! IntegerToken)
        case .Keyword:
            let currentKeywordToken = currentToken as! KeywordToken
            if Keyword.If == currentKeywordToken.keyword {
                let condition = parseBinaryExpression()
                expect(token: Keyword.Then)
                let consequent = parseBinaryExpression()
                expect(token: Keyword.Else)
                let alternative = parseBinaryExpression()
                expect(token: Keyword.End)
                return IfExpression(condition: condition, consequent: consequent, alternative: alternative)
            } else if Keyword.Let == currentKeywordToken.keyword || Keyword.Loop == currentKeywordToken.keyword {
                let bindings = parseBindings()
                expect(token: Keyword.In)
                let expression = parseBinaryExpression()
                expect(token: Keyword.End)
                return Keyword.Let == currentKeywordToken.keyword ? LetExpression(bindings: bindings, exp: expression) : LoopExpression(bindings: bindings, exp: expression)
            } else if Keyword.Recur == currentKeywordToken.keyword {
                var args = [ParenthesizedExpression]()

                while true {
                    let expression = parsePrimaryExpression() // Note: this should not be parseBinaryExpression
                    assert(expression is ParenthesizedExpression, "Parser: Expected parenthesized expression got \(expression.parserDescription(depth: 0))")
                    args.append(expression as! ParenthesizedExpression)
                    if let next = peekNextToken() {
                        if next.type == TokenType.Operator && (next as! OperatorToken).op == Operator.OpenParen {
                            continue
                        }
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
                enterNewScope()
                while true {
                    resultStack.push(parsePrimaryExpression())
                    let next = nextToken() as! OperatorToken
                    if next.op == Operator.CloseParen {
                        break
                    }
                    assert(BinaryOperatorTokens.contains(next.op), "Parser: expected a binary operator but got \(next.simpleDescription)")
                    shuntinYardAlgorithm(newOperator: next.op)
                }
                let expression = joinExpressionsWithOperators()!
                leaveScope()
                return ParenthesizedExpression(exp: expression)
            } else if UnaryOperatorTokens.contains(currentOperatorToken.op) {
                return UnaryExpression(unaryOp: currentOperatorToken.op, exp: parsePrimaryExpression())
            } else {
                assert(false, "Parser: not yet implemented")
            }
        case .Identifier:
            return IdentifierExpression(token: currentToken as! IdentifierToken)
        }
    }
}
