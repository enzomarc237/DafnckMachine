import 'dart:io';
import 'package:args/args.dart';
import 'package:dafnck_cli/dafnck_core.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addCommand('init')
    ..addCommand('status')
    ..addCommand('next')
    ..addCommand('chat');

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Error: ${e.toString()}');
    printUsage(parser);
    return;
  }

  final rootPath = p.absolute(Directory.current.path);
  // In some environments, we might be inside 01_Machine/CLI/dafnck_cli
  // We want the root of the DafnckMachine
  String effectiveRoot = rootPath;
  if (p.basename(effectiveRoot) == 'dafnck_cli') {
    effectiveRoot = p.dirname(p.dirname(p.dirname(effectiveRoot)));
  }

  final core = DafnckCore(effectiveRoot);

  final command = results.command;
  if (command == null) {
    printUsage(parser);
    return;
  }

  switch (command.name) {
    case 'init':
      handleInit(core, effectiveRoot);
      break;
    case 'status':
      handleStatus(core);
      break;
    case 'next':
      handleNext(core);
      break;
    case 'chat':
      handleChat(command);
      break;
    default:
      printUsage(parser);
  }
}

void printUsage(ArgParser parser) {
  print('DafnckMachine CLI Agent');
  print('Usage: dafnck_cli <command> [arguments]');
  print('Commands:');
  for (final cmd in parser.commands.keys) {
    print('  $cmd');
  }
}

void handleInit(DafnckCore core, String root) {
  print('🚀 Initializing DafnckMachine Check...');
  final dirs = ['01_Machine', '02_Vision', '03_Project'];
  bool allExist = true;
  for (final dir in dirs) {
    final d = Directory(p.join(root, dir));
    if (d.existsSync()) {
      print('✅ $dir exists');
    } else {
      print('❌ $dir missing');
      allExist = false;
    }
  }

  if (allExist) {
    print('🎉 DafnckMachine structure is valid!');
  } else {
    print('⚠️  Some directories are missing. Please check your installation.');
  }
}

void handleStatus(DafnckCore core) {
  final state = core.getState();
  final dna = core.getDna();
  final step = core.getStep();

  final workflowState = dna['workflow_state'] ?? {};

  print('🧠 DAFNCK MACHINE - STATUS');
  print('========================');
  print('');
  print('📍 Étape : ${workflowState['current_step'] ?? 'Unknown'}');
  print('🤖 Agent : ${workflowState['current_agent'] ?? step['currentAgent'] ?? 'Unknown'}');
  print('📁 Phase : ${workflowState['current_phase'] ?? 'Unknown'}');

  final progress = workflowState['progress'] ?? {};
  print('📈 Progrès : ${progress['percentage'] ?? 0}% (${progress['completed_steps'] ?? 0}/${progress['total_steps'] ?? 0})');
  print('');
  print('🔙 Précédente : ${workflowState['previous_step'] ?? 'None'}');
  print('🔜 Suivante : ${workflowState['next_step'] ?? 'None'}');
  print('');
  print('⚡ Tâche actuelle : ${workflowState['current_task'] ?? 'None'}');
  print('');
  print('========================');
}

void handleNext(DafnckCore core) {
  final dna = core.getDna();
  final workflowState = dna['workflow_state'] ?? {};
  final currentStep = workflowState['current_step'];
  final nextStep = workflowState['next_step'];

  if (nextStep == null || nextStep == 'null') {
    print('✅ No more steps in the workflow.');
    return;
  }

  print('⏭️ Advancing to next step: $nextStep');

  // Logic to advance step (simplified)
  workflowState['previous_step'] = currentStep;
  workflowState['current_step'] = nextStep;
  workflowState['current_task'] = nextStep;

  // Find next next step from step_definitions
  final defs = dna['step_definitions'] ?? {};
  final nextDef = defs[nextStep] ?? {};
  workflowState['next_step'] = nextDef['next_task'];
  workflowState['current_phase'] = nextDef['phase'];

  final progress = workflowState['progress'] ?? {};
  progress['completed_steps'] = (progress['completed_steps'] ?? 0) + 1;
  progress['percentage'] = (progress['completed_steps'] / progress['total_steps'] * 100).round();

  core.updateDna(dna);

  // Also update Step.json
  final step = core.getStep();
  step['currentWorkflowStep'] = nextStep;
  step['currentPhase'] = nextDef['phase'];
  step['currentAgent'] = nextDef['agent'];
  core.updateStep(step);

  print('✅ Successfully moved to $nextStep');
}

void handleChat(ArgResults command) {
  if (command.arguments.isEmpty) {
    print('Usage: dafnck_cli chat <agent-name>');
    return;
  }
  final agent = command.arguments.first;
  print('💬 Starting chat session with $agent...');
  print('🤖 $agent: Hello! I am the $agent. How can I assist you today?');
  print('(Simulation: Chat session ended)');
}
