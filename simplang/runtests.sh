#!/bin/bash

swift build
../tests/test.py ../tests/scanner .build/debug/simplang --scan
../tests/test.py ../tests/parser-1.2 .build/debug/simplang --parse-exp
../tests/test.py ../tests/interpreter-1.3 .build/debug/simplang --interpret-exp
../tests/test.py ../tests/parser-1.4 .build/debug/simplang --parse-exp
../tests/test.py ../tests/interpreter-1.5 .build/debug/simplang --interpret-exp
../tests/test.py ../tests/parser-1.6 .build/debug/simplang --parse-exp
../tests/test.py ../tests/full .build/debug/simplang --interpret
