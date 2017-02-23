import Darwin

if CommandLine.arguments.count != 2 {
    print("Usage: simplang foo.sl")
    print("Does not support multiple files yet")
    exit(1)
} else {
    let sourcePath = CommandLine.arguments[1]
    var scanner = Scanner(sourcePath: sourcePath)
    for token in scanner.tokens {
        print("\(token.simpleDescription)")
    }
}
