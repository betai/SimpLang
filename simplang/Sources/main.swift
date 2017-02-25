import Darwin

if CommandLine.arguments.count != 2 {
    print("Usage: simplang foo.sl")
    print("Does not support multiple files yet")
    exit(1)
} else {
    let sourcePath = CommandLine.arguments[1]
    var scanner = Scanner(sourcePath: sourcePath)
    // scanner shit
//    for token in scanner.tokens {
//        print("\(token.scannerDescription)")
//    }

    // parser shit
    var parser = Parser(tokens: scanner.tokens)
    print("\(parser.syntaxTreeString)")
//    for node in parser.nodes {
//        print("\(node.eval())")
//    }
}
