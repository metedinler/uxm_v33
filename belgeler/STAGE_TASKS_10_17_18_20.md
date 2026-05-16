# UXM Stage Tasks: 10 / 17 / 18 / 20

## Stage-10
Task: FP basics, matrix-advanced entry, tensor baseline, memory model and regression safety for older services.
Status: Implemented; the 16 MB memory model was verified through V11. Remaining apparent failures were runner/expected-output issues, rechecked by Stage-20.

## Stage-17
Task: Test framework, `.expect` parsing, exact/compact/contains modes, fast failed-test rerun and Turkish reporting.
Status: Implemented; V14 fixes the `#source:embedded_EXPECT_OUTPUT` metadata bug permanently.

## Stage-18
Task: Mega corpus / translator examples, domain mini programs, tensor 2D/3D/4D bridges and realistic service usage.
Status: Remaining tensor4d test was fixed by writing required dims/index values into DATA before service calls.

## Stage-20
Task: Release quality gate covering Stage-10 memory, Stage-17 runner correctness, Stage-18 tensor bridge and basic DATA/FIFO/native paths.
Status: Implemented in V14. Tests live under `uxm/tests/stage20/`.
