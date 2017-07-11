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
            return (value: 0, newValues: nil)
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
            return (value: Int.addWithOverflow(left.eval().value, right.eval().value).0, newValues: nil)
        case .Multiply:
            return (value: Int.multiplyWithOverflow(left.eval().value, right.eval().value).0, newValues: nil)
        case .Equals:
            return left.eval().value == right.eval().value ? (value: 1, newValues: nil) : (value: 0, newValues: nil)
        case .And:
            return left.eval().value == 0 || right.eval().value == 0 ? (value: 0, newValues: nil) : (value: 1, newValues: nil)
        case .Or:
            return left.eval().value == 0 && right.eval().value == 0 ? (value: 0, newValues: nil) : (value: 1, newValues: nil)
        default:
            assert(false, "Expression: not a binary operation \(binaryOp.simpleDescription)")
            return (value: 0, newValues: nil)
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
        Memory.pushBindingScope(bindings: bindings)
        let result = exp.eval()
        Memory.popBindingScope(bindings: bindings)
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
        Memory.pushBindingScope(bindings: bindings)
        while true {
            let result = exp.eval()
            if result.newValues == nil {
                Memory.popBindingScope(bindings: bindings)
                return result
            }
            for (index, binding) in bindings.enumerated() {
                Memory.variableStack[binding.identifierName]?.update(topOfStack: result.newValues![index])
            }
        }
    }

    func parserDescription(depth: Int) -> String {
        var result = [spacingForDepth(depth: depth) + Keyword.Loop.simpleDescription]
        for binding in bindings {
            result.append(binding.parserDescription(depth: depth + 2))
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

class IdentifierExpression : Expression {
    var token : IdentifierToken

    init(token: IdentifierToken) {
        self.token = token
    }

    func eval() -> (value: Int, newValues: [Int]?) {
        return (value: Memory.variableStack[token.name]!.peek()!, newValues: nil)
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

class Invocation : Expression {
    var functionName : String
    var params : [ParenthesizedExpression]

    init(functionName: String, params: [ParenthesizedExpression]) {
        self.functionName = functionName
        self.params = params
    }

    func eval() -> (value: Int, newValues: [Int]?) {
        let function = Memory.functions[functionName]!
        assert(params.count == function.params.count, "Parser: invocation with the wrong number of parameters. Expected \(function.params.count), got \(params.count)")

        var functionStack = [String : Stack<Int>]()
        var debugArgs = [Int]()
        for (index, param) in params.enumerated() {
            let stack = Stack<Int>()
            let paramValue = param.eval().value
            stack.push(paramValue)
            debugArgs.append(paramValue)
            functionStack[function.params[index].token.name] = stack
        }
        Memory.variableStacks.push(functionStack)

        Debug.addEntry(name: functionName, args: debugArgs , depth: Debug.currentDepth)
        Debug.currentDepth += 1
        let result = function.expression.eval().value
        Debug.currentDepth -= 1
        Debug.addExit(name: functionName, args: debugArgs, depth: Debug.currentDepth, result: result)
        _ = Memory.variableStacks.pop()
        return (value: result, newValues: nil)
    }

    func parserDescription(depth: Int) -> String {
        var result = [String]()
        result.append(spacingForDepth(depth: depth) + functionName)

        for param in params {
            result.append(param.parserDescription(depth: depth + 1))
        }
        return result.joined(separator: "\n")
    }
}

class Function : ParserPrintable {
    var name : String
    var expression : Expression
    var params : [IdentifierExpression]

    init(name: String, expression: Expression, params: [IdentifierExpression]) {
        self.name = name
        self.expression = expression
        self.params = params
    }

    func evalWithParams(intParams: [Int]) -> Int {
        var functionStack = [String: Stack<Int>]()
        var debugArgs = [Int]()
        for (index, param) in intParams.enumerated() {
            let stack = Stack<Int>()
            stack.push(param)
            debugArgs.append(param)
            functionStack[params[index].token.name] = stack
        }
        Memory.variableStacks.push(functionStack)

        Debug.addEntry(name: name, args: debugArgs , depth: Debug.currentDepth)
        Debug.currentDepth += 1
        let result = expression.eval().value
        Debug.currentDepth -= 1
        Debug.addExit(name: name, args: debugArgs, depth: Debug.currentDepth, result: result)

        _ = Memory.variableStacks.pop()
        return result
    }

    func parserDescription(depth: Int) -> String {
        var result = [String]()
        result.append(spacingForDepth(depth: depth) + "function")
        result.append(spacingForDepth(depth: depth + 2) + self.name)
        for param in params {
            result.append(spacingForDepth(depth: depth + 3) + param.token.name)
        }
        result.append(expression.parserDescription(depth: depth + 1))
        return result.joined(separator: "\n")
    }
}

class Memory {
    public static var variableStacks : Stack<[String: Stack<Int>]> = Stack<[String: Stack<Int>]>()
    public static var variableStack : [String: Stack<Int>] {
        get {
            return variableStacks.peek()!
        }
        set {
            variableStacks.update(topOfStack: newValue)
        }
    }
    public static var functions = [String : Function]()
    public static var knownFunctions = [String : Bool]()

    public static func pushBindingScope(bindings: [Binding]) {
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

    public static func popBindingScope(bindings: [Binding]) {
        for binding in bindings {
            _ = variableStack[binding.identifierName]!.pop()
        }
    }

    public static func isAKnownFunction(token: IdentifierToken) -> Bool {
        return knownFunctions[token.name] != nil
    }
}

class Debug {
    public static var invocationList : String {
        get {
            return invocations.joined(separator: "\n")
        }
    }
    public static var currentDepth = 0
    private static var invocations = [String]()

    public static func addEntry(name: String, args: [Int], depth: Int) {
        invocations.append(spacingForDepth(depth: depth) + name + " entry " + args.map{x in String(x)}.joined(separator: " "))
    }

    public static func addExit(name: String, args: [Int], depth: Int, result: Int) {
        invocations.append(spacingForDepth(depth: depth) + name + " exit " + args.map{x in String(x)}.joined(separator: " ") + " -> " + String(result))
    }
}
/******************************************
 *  Parser
 * *****************************************/

class Parser {
    private var tokens : [Token]
    public var syntaxTreeString: String {
        get {
            var result = [String]()
            for (_, function) in Memory.functions {
                result.append(function.parserDescription(depth: 0))
            }
            return result.joined(separator: "\n")
        }
    }
    public var expression : Expression?

    init(tokens: [Token], parseExpression: Bool, parseFunc: Bool) {
        self.tokens = tokens
        if tokens.count == 0 {
            return
        }
        if parseExpression {
            Memory.variableStacks.push([String: Stack<Int>]())
            expression = parseBinaryExpression()
        } else if parseFunc {
            parseFunction()
        } else {
            createSyntaxTree()
        }
    }

    private func createSyntaxTree() {
        while tokens.count > 0 {
            parseFunction()
        }
    }

    /***************************** Shunting yard algorithm *************************************************/

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

    /***************************** Helper methods **********************************************************/

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

    private func parseParams() -> [ParenthesizedExpression] {
        var params = [ParenthesizedExpression]()

        while true {
            let expression = parsePrimaryExpression() // Note: this should not be parseBinaryExpression
            params.append(expression as! ParenthesizedExpression)
            if let next = peekNextToken() {
                if next.type == TokenType.Operator && (next as! OperatorToken).op == Operator.OpenParen {
                    continue
                }
            }
            break;
        }
        return params
    }
    /***************************** Parsing methods *********************************************************/

    public func parseFunction() {
        expect(token: Keyword.Let)
        let functionNameToken = nextToken() as! IdentifierToken
        Memory.knownFunctions[functionNameToken.name] = true // need to do this to accommodate recursive functions

        var params = [IdentifierExpression]()
        while peekNextToken()!.type == TokenType.Identifier {
            params.append(IdentifierExpression(token: nextToken() as! IdentifierToken))
        }
        assert(params.count > 0, "Parser: functions must have at least one parameter")
        expect(token: Operator.Assign)

        let expression = parseBinaryExpression()
        expect(token: Keyword.End)

        Memory.functions[functionNameToken.name] = Function(name: functionNameToken.name, expression: expression, params: params)
    }

    private func parseBinaryExpression() -> Expression {
        enterNewScope()
        while true {
            resultStack.push(parsePrimaryExpression())
            if peekNextToken() == nil || peekNextToken()!.type != TokenType.Operator || !BinaryOperatorTokens.contains((peekNextToken()! as! OperatorToken).op) {
                break
            }
            let op = (nextToken() as! OperatorToken).op
            shuntinYardAlgorithm(newOperator: op)
        }
        let result = joinExpressionsWithOperators()!
        leaveScope()

        return result
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
                let args = parseParams()
                return RecurExpression(args: args)
            } else {
                assert(false, "Parser: not yet implemented")
            }
        case .Operator:
            let currentOperatorToken = currentToken as! OperatorToken
            if Operator.OpenParen == currentOperatorToken.op {
                let expression = parseBinaryExpression()
                expect(token: Operator.CloseParen)
                return ParenthesizedExpression(exp: expression)
            } else if UnaryOperatorTokens.contains(currentOperatorToken.op) {
                return UnaryExpression(unaryOp: currentOperatorToken.op, exp: parsePrimaryExpression())
            } else {
                assert(false, "Parser: not yet implemented")
            }
        case .Identifier:
            let currentIdentifierToken = currentToken as! IdentifierToken
            if Memory.isAKnownFunction(token: currentIdentifierToken) {
                let params = parseParams()
                return Invocation(functionName: currentIdentifierToken.name, params: params)
            }
            return IdentifierExpression(token: currentIdentifierToken)
        }
        assert(false, "Parser: unsupported token type")
        return IntegerExpression(token: IntegerToken(value: 0))
    }
}
