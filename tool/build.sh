#!/usr/bin/env bash
EXIT_CODE=0

dartfmt --set-exit-if-changed -n . || EXIT_CODE=$?
dartanalyzer --fatal-infos --fatal-warnings . || EXIT_CODE=$?

pub run test --coverage test_coverage || EXIT_CODE=$?
dart tool/format_coverage.dart

exit $EXIT_CODE