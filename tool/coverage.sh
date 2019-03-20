#!/usr/bin/env bash

EXIT_CODE=0

# Collect coverage, run all tests
pub run coverage:collect_coverage --uri=http://localhost:9876/ -o coverage.json --resume-isolates --on-exit &
dart --enable-vm-service=9876 --pause-isolates-on-exit tool/all_tests.dart || EXIT_CODE=$?
wait

# Format coverage as lcov
pub run coverage:format_coverage --lcov --packages=.packages --report-on=lib -i coverage.json -o lcov.info

exit $EXIT_CODE