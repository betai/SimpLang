import Darwin


func usage() {
    print("Usage:")
    print(" simplang --scan foo.sl")
    print(" simplang --parse foo.sl")
    print(" simplang --interpret foo.sl")
    print("Does not support multiple files yet")
    exit(0)
}

if CommandLine.arguments.count != 3 {
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
    
    var parser = Parser(tokens: scanner.tokens)

    if option == "--parse" {
        print("\(parser.syntaxTreeString)")
    } else if option == "--interpret" {
        if let root = parser.root {
            print("\(root.eval().value)")
        }
    }
}
