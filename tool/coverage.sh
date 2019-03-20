#!/usr/bin/env bash

# Collect coverage, run all tests
dart --enable-vm-service=9876 --pause-isolates-on-exit tool/all_tests.dart &
pub run coverage:collect_coverage --uri=http://localhost:9876/ -o coverage.json --resume-isolates --on-exit

wait

# Format coverage as lcov
pub run coverage:format_coverage --lcov --packages=.packages --report-on=lib -i coverage.json -o lcov.info
