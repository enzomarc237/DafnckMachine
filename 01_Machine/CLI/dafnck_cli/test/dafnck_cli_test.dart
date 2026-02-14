import 'package:dafnck_cli/dafnck_core.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

void main() {
  group('DafnckCore Tests', () {
    late Directory tempDir;
    late DafnckCore core;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dafnck_test');
      core = DafnckCore(tempDir.path);

      // Create required structure
      Directory(p.join(tempDir.path, '01_Machine', '03_Brain')).createSync(recursive: true);

      // Initial DNA
      File(core.dnaPath).writeAsStringSync(jsonEncode({
        'workflow_state': {
          'current_step': 'S1',
          'next_step': 'S2',
          'progress': {'percentage': 0, 'completed_steps': 0, 'total_steps': 2}
        },
        'step_definitions': {
          'S1': {'next_task': 'S2', 'phase': 'P1', 'agent': 'A1'},
          'S2': {'next_task': null, 'phase': 'P1', 'agent': 'A2'}
        }
      }));

      File(core.stepPath).writeAsStringSync(jsonEncode({
        'currentWorkflowStep': 'S1'
      }));

      File(core.statePath).writeAsStringSync(jsonEncode({
        'status': 'in_progress'
      }));
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('Read DNA', () {
      final dna = core.getDna();
      expect(dna['workflow_state']['current_step'], 'S1');
    });

    test('Update DNA', () {
      final dna = core.getDna();
      dna['workflow_state']['current_step'] = 'S2';
      core.updateDna(dna);

      final updatedDna = core.getDna();
      expect(updatedDna['workflow_state']['current_step'], 'S2');
    });
  });
}
