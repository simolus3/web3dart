#!/usr/bin/env bash

# Collect coverage, run all tests
dart tool/run_tests_with_coverage.dart

# Format coverage as lcov
pub run coverage:format_coverage --lcov --packages=.packages --report-on=lib -i coverage.json -o lcov.info