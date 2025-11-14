import 'dart:io';

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/error/error.dart';

import 'producer.dart';
import 'settings.dart';
import 'visitor.dart';

final plugin = PreferShorthandsPlugin();

class PreferShorthandsPlugin extends Plugin {
  @override
  String get name => 'prefer_shorthands';

  late final Settings settings;

  @override
  Future<void> register(PluginRegistry registry) async {
    settings = await Settings.loadFromAnalysisOptions();
    stderr.writeln('[Prefer Shorthands] Settings: $settings');
    registry.registerWarningRule(PreferShorthandsRule());
    registry.registerFixForRule(
      PreferShorthandsRule.code,
      ConvertToShorthand.new,
    );
  }
}

class PreferShorthandsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_shorthands',
    'Prefer shorthands',
    correctionMessage: "Try using shorthand syntax instead.",
  );

  PreferShorthandsRule()
    : super(name: 'prefer_shorthands', description: 'Prefer shorthands');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    Visitor(this, context).registerNodeProcessors(registry, this);
  }
}
