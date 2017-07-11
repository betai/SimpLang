#!/bin/bash

swift build -c release
echo scanner test -------------------------------------------------------------------------
../tests/test.py ../tests/scanner .build/release/simplang --scan
echo parser 1.2 -------------------------------------------------------------------------
../tests/test.py ../tests/parser-1.2 .build/release/simplang --parse-exp
echo interpret 1.3 -------------------------------------------------------------------------
../tests/test.py ../tests/interpreter-1.3 .build/release/simplang --interpret-exp
echo parser 1.4 -------------------------------------------------------------------------
../tests/test.py ../tests/parser-1.4 .build/release/simplang --parse-exp
echo interpret 1.5 -------------------------------------------------------------------------
../tests/test.py ../tests/interpreter-1.5 .build/release/simplang --interpret-exp
echo parser 1.6 -------------------------------------------------------------------------
../tests/test.py ../tests/parser-1.6 .build/release/simplang --parse-exp
echo full test -------------------------------------------------------------------------
../tests/test.py ../tests/full .build/release/simplang --interpret
