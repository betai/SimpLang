#!/bin/bash

swift build
../tests/test.py ../tests/scanner .build/debug/simplang --scan
../tests/test.py ../tests/parser-1.2 .build/debug/simplang --parse-exp
../tests/test.py ../tests/interpreter-1.3 .build/debug/simplang --interpret-exp
