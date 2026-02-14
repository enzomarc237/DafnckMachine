import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class DafnckCore {
  final String rootPath;

  DafnckCore(this.rootPath);

  String get dnaPath => p.join(rootPath, '01_Machine', '03_Brain', 'DNA.json');
  String get stepPath => p.join(rootPath, '01_Machine', '03_Brain', 'Step.json');
  String get statePath => p.join(rootPath, '01_Machine', '03_Brain', 'workflow_state.json');

  Map<String, dynamic> readJson(String path) {
    final file = File(path);
    if (!file.existsSync()) return {};
    return jsonDecode(file.readAsStringSync());
  }

  void writeJson(String path, Map<String, dynamic> data) {
    final file = File(path);
    file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data));
  }

  Map<String, dynamic> getDna() => readJson(dnaPath);
  Map<String, dynamic> getStep() => readJson(stepPath);
  Map<String, dynamic> getState() => readJson(statePath);

  void updateState(Map<String, dynamic> state) => writeJson(statePath, state);
  void updateDna(Map<String, dynamic> dna) => writeJson(dnaPath, dna);
  void updateStep(Map<String, dynamic> step) => writeJson(stepPath, step);
}
