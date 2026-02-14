# DafnckMachine CLI Agent

A Dart-based CLI agent for managing the DafnckMachine workflow.

## Commands

- `init`: Verify or create the 3-tier directory structure (`01_Machine`, `02_Vision`, `03_Project`).
- `status`: Show the current workflow status, including the active agent, current phase, and progress.
- `next`: Advance to the next step in the workflow defined in `DNA.json`.
- `chat <agent-name>`: Simulate a chat session with a specialized agent.

## Usage

```bash
dart run bin/dafnck_cli.dart status
```

## Structure Integration

The CLI integrates with the following DafnckMachine Brain files:
- `01_Machine/03_Brain/DNA.json`: Workflow structure and agent registry.
- `01_Machine/03_Brain/Step.json`: Execution state and system health.
- `01_Machine/03_Brain/workflow_state.json`: Session and navigation state.
