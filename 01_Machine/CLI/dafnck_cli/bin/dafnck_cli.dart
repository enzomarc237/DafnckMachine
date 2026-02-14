import 'dart:io';
import 'package:args/args.dart';
import 'package:dafnck_cli/dafnck_core.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addCommand('init')
    ..addCommand('status')
    ..addCommand('next')
    ..addCommand('chat')
    ..addCommand('list-agents')
    ..addCommand('tasks')
    ..addCommand('validate');

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Error: ${e.toString()}');
    printUsage(parser);
    return;
  }

  final rootPath = p.absolute(Directory.current.path);
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
    case 'list-agents':
      handleListAgents(core);
      break;
    case 'tasks':
      handleTasks(core);
      break;
    case 'validate':
      handleValidate(core, effectiveRoot);
      break;
    default:
      printUsage(parser);
  }
}

void printUsage(ArgParser parser) {
  print('🚀 DafnckMachine CLI Agent');
  print('Usage: dafnck_cli <command> [arguments]');
  print('Commands:');
  for (final cmd in parser.commands.keys) {
    print('  ${cmd.padRight(12)} - ${getCommandDescription(cmd)}');
  }
}

String getCommandDescription(String command) {
  switch (command) {
    case 'init': return 'Initialize or verify project structure';
    case 'status': return 'Show current workflow and agent status';
    case 'next': return 'Advance to the next workflow step';
    case 'chat': return 'Start a chat session with an agent';
    case 'list-agents': return 'List all registered agents';
    case 'tasks': return 'List tasks and artifacts for the current step';
    case 'validate': return 'Run system validation checks';
    default: return '';
  }
}

void handleInit(DafnckCore core, String root) {
  print('🏗️  DafnckMachine Structure Check');
  print('===============================');
  final dirs = ['01_Machine', '02_Vision', '03_Project'];
  bool allExist = true;
  for (final dir in dirs) {
    final d = Directory(p.join(root, dir));
    if (d.existsSync()) {
      print('✅ ${dir.padRight(12)} FOUND');
    } else {
      print('❌ ${dir.padRight(12)} MISSING');
      allExist = false;
    }
  }

  if (allExist) {
    print('\n🎉 DafnckMachine structure is valid and ready!');
  } else {
    print('\n⚠️  Some directories are missing. Please check your installation.');
  }
}

void handleStatus(DafnckCore core) {
  final dna = core.getDna();
  print('🧠 DAFNCK MACHINE - STATUS');
  print('========================');
  print('');
  print('📍 Step: ${workflowState['current_step'] ?? 'Unknown'}');
  print('🤖 Agent: ${workflowState['current_agent'] ?? step['currentAgent'] ?? 'Unknown'}');
  print('📁 Phase: ${workflowState['current_phase'] ?? 'Unknown'}');

  final progress = workflowState['progress'] ?? {};
  print('📈 Progress: ${progress['percentage'] ?? 0}% (${progress['completed_steps'] ?? 0}/${progress['total_steps'] ?? 0})');
  print('');
  print('🔙 Previous: ${workflowState['previous_step'] ?? 'None'}');
  print('🔜 Next: ${workflowState['next_step'] ?? 'None'}');
  print('');
  print('⚡ Current Task: ${workflowState['current_task'] ?? 'None'}');
  print('');
  print('========================');
}

void handleNext(DafnckCore core) {
  final dna = core.getDna();
  final workflowState = dna['workflow_state'] ?? {};
  final currentStep = workflowState['current_step'];
  final nextStep = workflowState['next_step'];

  if (nextStep == null || nextStep == 'null') {
    print('✨ Workflow is already complete!');
    return;
  }

  print('⏭️  Advancing from $currentStep to $nextStep...');

  workflowState['previous_step'] = currentStep;
  workflowState['current_step'] = nextStep;
  workflowState['current_task'] = nextStep;

  final defs = dna['step_definitions'] ?? {};
  final nextDef = defs[nextStep] ?? {};
  workflowState['next_step'] = nextDef['next_task'];
  workflowState['current_phase'] = nextDef['phase'];

  final progress = workflowState['progress'] ?? {};
  progress['completed_steps'] = (progress['completed_steps'] ?? 0) + 1;
  progress['percentage'] = (progress['completed_steps'] / progress['total_steps'] * 100).round();

  core.updateDna(dna);

  final step = core.getStep();
  step['currentWorkflowStep'] = nextStep;
  step['currentPhase'] = nextDef['phase'];
  step['currentAgent'] = nextDef['agent'];
  core.updateStep(step);

  print('✅ Successfully transitioned to $nextStep');
}

void handleChat(ArgResults command) {
  if (command.arguments.isEmpty) {
    print('❌ Usage: dafnck_cli chat <agent-name>');
    return;
  }
  final agent = command.arguments.first;
  print('💬 Opening secure channel to @$agent...');
  print('🤖 @$agent: System ready. Awaiting your instructions.');
  print('\n(Mock: Chat session active. Type "exit" to close)');
}

void handleListAgents(DafnckCore core) {
  final dna = core.getDna();
  final registry = dna['agentRegistry'] as List?;

  print('🤖 Registered Agents Registry');
  print('============================');
  if (registry == null) {
    print('No agents found in registry.');
    return;
  }

  for (final agent in registry) {
    final name = agent['agentName'];
    final phases = (agent['phases'] as List?)?.join(', ') ?? 'None';
    print('• @${name.padRight(35)} [Phases: $phases]');
  }
  print('============================');
  print('Total Agents: ${registry.length}');
}

void handleTasks(DafnckCore core) {
  final artifacts = core.getOutputArtifacts();
  final tasks = core.getDetailedTasks();

  print('📋 Current Step Action Plan');
  print('==========================');

  if (tasks.isNotEmpty) {
    print('⚡ Tasks:');
    for (final task in tasks) {
      print('  - $task');
    }
  } else {
    print('⚡ No detailed tasks found for this step.');
  }

  print('\n📦 Required Output Artifacts:');
  if (artifacts.isNotEmpty) {
    for (final artifact in artifacts) {
      print('  $artifact');
    }
  } else {
    print('  No specific artifacts listed.');
  }
  print('==========================');
}

void handleValidate(DafnckCore core, String root) {
  print('🔍 Running DafnckMachine System Validation...');

  // 1. Structure check
  final dirs = ['01_Machine', '02_Vision', '03_Project'];
  for (final dir in dirs) {
    if (!Directory(p.join(root, dir)).existsSync()) {
      print('❌ Missing directory: $dir');
    }
  }

  // 2. DNA check
  final dna = core.getDna();
  if (dna.isEmpty) {
    print('❌ DNA.json is missing or invalid.');
  } else {
    print('✅ DNA.json loaded');
    if (dna['agentRegistry'] == null) {
      print('⚠️  agentRegistry missing in DNA.json');
    }
  }

  // 3. Step check
  final step = core.getStep();
  if (step.isEmpty) {
    print('❌ Step.json is missing or invalid.');
  } else {
    print('✅ Step.json loaded');
    print('📊 System Status: ${step['systemStatus'] ?? 'Unknown'}');
  }

  print('\n✅ Validation sequence complete.');
  print('Hint: For deep agent validation, run the python unified_agent_validator.py');
}
