dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage/test/rule_test.dart.vm.json --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib
