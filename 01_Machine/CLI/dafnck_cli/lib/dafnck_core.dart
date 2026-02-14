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
    try {
      return jsonDecode(file.readAsStringSync());
    } catch (e) {
      return {};
    }
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

  String? getCurrentStepFilePath() {
    final dna = getDna();
    final currentStep = dna['workflow_state']?['current_step'];
    if (currentStep == null) return null;
    final defs = dna['step_definitions'] ?? {};
    return defs[currentStep]?['file_path'];
  }

  List<String> getOutputArtifacts() {
    final relPath = getCurrentStepFilePath();
    if (relPath == null) return [];
    final fullPath = p.join(rootPath, relPath);
    final file = File(fullPath);
    if (!file.existsSync()) return [];

    final content = file.readAsLinesSync();
    final artifacts = <String>[];
    bool inChecklist = false;
    for (final line in content) {
      if (line.contains('Output Artifacts Checklist')) {
        inChecklist = true;
        continue;
      }
      if (inChecklist) {
        if (line.trim().startsWith('- [ ]') || line.trim().startsWith('- [x]')) {
          artifacts.add(line.trim());
        } else if (line.trim().isNotEmpty && line.startsWith('#')) {
          break;
        }
      }
    }
    return artifacts;
  }

  List<String> getDetailedTasks() {
    final relPath = getCurrentStepFilePath();
    if (relPath == null) return [];
    final fullPath = p.join(rootPath, relPath);
    final file = File(fullPath);
    if (!file.existsSync()) return [];

    final content = file.readAsLinesSync();
    final tasks = <String>[];
    for (final line in content) {
      final trimmed = line.trim();
      if (trimmed.startsWith('### Subtask') || trimmed.startsWith('## Task')) {
        tasks.add(trimmed.replaceFirst(RegExp(r'^#+\s*'), ''));
      }
    }
    return tasks;
  }
}
