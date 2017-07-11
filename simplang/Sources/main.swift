import Darwin


func usage() {
    print("Usage:")
    print(" simplang --scan foo.sl arg1 [args..]")
    print(" simplang --parse foo.sl")
    print(" simplang --parse-exp foo.sl")
    print(" simplang --interpret foo.sl arg1 [args..]")
    print(" simplang --invocation-list foo.sl arg1 [args..]")
    exit(1)
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
    
    var parser = Parser(tokens: scanner.tokens, parseExpression: option.contains("-exp"), parseFunc: option.contains("-func"))

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
    } else if option == "--parse-func" {
        if CommandLine.arguments.count != 3 {
            print("Warning: additional parameters ignored")
        }
        print("\(Memory.functions.first!.value.parserDescription(depth: 0))")
    }else if option == "--interpret" || option == "--invocation-list" {
        if CommandLine.arguments.count <= 3 {
            print("Simplang: must pass at least 1 argument")
            exit(1)
        }
        if let main = Memory.functions["main"] {
            let result = main.evalWithParams(intParams: Array(CommandLine.arguments.dropFirst(3)).map{param in Int(param)!})
            if option == "--interpret" {
                print(result)
            } else {
                print(Debug.invocationList)
            }
        } else {
            print("Error: missing main function")
        }
    } else if option == "--interpret-exp" {
        print("\(parser.expression!.eval().value)")
    }
}
