import Darwin


func usage() {
    print("Usage:")
    print(" simplang --scan foo.sl arg1 [args..]")
    print(" simplang --parse foo.sl")
    print(" simplang --parse-exp foo.sl")
    print(" simplang --interpret foo.sl arg1 [args..]")
    exit(0)
}

if CommandLine.arguments.count < 3 {
    usage()
} else {
    let option = CommandLine.arguments[1]
    let sourcePath = CommandLine.arguments[2]

    var scanner = Scanner(sourcePath: sourcePath)

    if option == "--scan" {
        for token in scanner.tokens {
            print("\(token.scannerDescription)")
        }
        exit(0)
    }
    
    var parser = Parser(tokens: scanner.tokens, parseExpression: option.contains("-exp"))

    if option == "--parse" {
        if CommandLine.arguments.count != 3 {
            print("Warning: additional parameters ignored")
        }
        print("\(parser.syntaxTreeString)")
    } else if option == "--parse-exp" {
        if CommandLine.arguments.count != 3 {
            print("Warning: additional parameters ignored")
        }
        print("\(parser.expression!.parserDescription(depth: 0))")
    } else if option == "--interpret" {
        if let main = Memory.functions["main"] {
            print("\(main.evalWithParams(intParams: Array(CommandLine.arguments.dropFirst(3)).map {param in Int(param)!}))")
        } else {
            print("Error: missing main function")
        }
    } else if option == "--interpret-exp" {
        print("\(parser.expression!.eval().value)")
    }
}
