# Deploy-All Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce `make deploy-all` wall-clock time by doing more one-time Flutter warmup before the parallel release fan-out while preserving current release behavior.

**Architecture:** Rework the Makefile so deploy preflight explicitly warms Flutter release artifacts and shared dependency state once, then keep web, Android, and iOS release branches parallel. Preserve the current version bump, commit, upload, purge, and cleanup flow while making the prewarm boundary clearer and more effective.

**Tech Stack:** GNU Make, Flutter CLI, Fastlane, CocoaPods, shell commands

---

## File Structure

- Modify: `Makefile`
  - Add a dedicated Flutter release prewarm target.
  - Fold existing preflight setup into a clearer shared warmup stage for `deploy-all`.
  - Keep branch-specific work in `_web-deploy-core`, `_android-deploy-core`, and `_ios-beta-core`.
- Reference: `docs/superpowers/specs/2026-05-31-deploy-all-performance-design.md`
  - Ensure the implementation matches the approved design.

### Task 1: Add an explicit shared Flutter release prewarm target

**Files:**
- Modify: `Makefile`
- Test: `Makefile` via `make -n _prepare-deploy` and `make -n deploy-all`

- [ ] **Step 1: Write the failing test**

Use command-based verification because this change is orchestration logic in `Makefile`, not Dart code.

Expected assertions before the change:

```text
make -n _prepare-deploy
```

Should show only:
- `flutter pub get`
- Ruby bundle preparation
- pod install

It should not yet show any explicit Flutter artifact prewarm command such as `flutter precache`.

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
make -n _prepare-deploy
```

Expected:
- PASS for current behavior inspection
- FAIL relative to the new requirement because no explicit shared Flutter release prewarm target exists yet

- [ ] **Step 3: Write minimal implementation**

Update `Makefile` so `_prepare-deploy` depends on a new Flutter warmup target that does one-time release-oriented preparation before the parallel build fan-out.

Implementation sketch:

```make
## _prepare-flutter-release: Warm Flutter release artifacts once before parallel deploy jobs
_prepare-flutter-release:
	@echo "$(COLOR_BLUE)Warming Flutter release artifacts...$(COLOR_RESET)"
	@flutter precache --ios --web

## _prepare-deploy: Parallel preflight for deploy targets
_prepare-deploy:
	@echo "$(COLOR_BLUE)Running deploy preflight in parallel...$(COLOR_RESET)"
	@gmake -s -j4 _prepare-flutter-deps _prepare-flutter-release _prepare-android-ruby _prepare-ios-ruby _prepare-ios-pods
```

The exact flags can be adjusted after validating what is safe and useful for the local deploy flow.

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
make -n _prepare-deploy
```

Expected:
- Output includes the new explicit Flutter release prewarm target
- Existing Ruby and pod prep still appear

- [ ] **Step 5: Commit**

```bash
git add Makefile docs/superpowers/plans/2026-05-31-deploy-all-performance.md
git commit -m "build: add shared flutter release prewarm"
```

### Task 2: Make `deploy-all` use the improved shared warmup stage without changing branch semantics

**Files:**
- Modify: `Makefile`
- Test: `Makefile` via `make -n deploy-all`

- [ ] **Step 1: Write the failing test**

Define the expected orchestration:

```text
make -n deploy-all
```

Must show:
- `_prepare-deploy` before the `gmake -j3` fan-out
- the three existing branch targets still fan out in parallel
- no change to the final cleanup placement

The goal of this task is to confirm that the improved warmup is part of the same `deploy-all` path, not a dead helper target.

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
make -n deploy-all
```

Expected:
- PASS for current structure inspection
- FAIL relative to the new requirement if the warmup target is not clearly represented before the fan-out

- [ ] **Step 3: Write minimal implementation**

Keep the current high-level flow, but ensure the improved prewarm target sits in the active path for `deploy-all` and remains ahead of the three release branches.

Implementation shape:

```make
deploy-all: check
	@$(MAKE) -s _ensure-changelog
	@$(MAKE) -s _bump-version BUMP=$(BUMP)
	@$(MAKE) -s _commit-before-build
	@$(MAKE) -s _prepare-deploy
	@gmake -s -j3 _web-deploy-core _android-deploy-core _ios-beta-core
	@$(MAKE) -s _cleanup-deploy-artifacts
```

If `_prepare-deploy` already exists in the right position, the implementation work for this task is to keep it there while making its contents stronger and clearer.

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
make -n deploy-all
```

Expected:
- `_prepare-deploy` remains before the parallel fan-out
- `_web-deploy-core`, `_android-deploy-core`, and `_ios-beta-core` still appear as the three release branches
- `_cleanup-deploy-artifacts` still runs after them

- [ ] **Step 5: Commit**

```bash
git add Makefile
git commit -m "build: keep deploy-all fan-out behind shared warmup"
```

### Task 3: Verify the change is behavior-preserving and document any limits

**Files:**
- Modify: `Makefile` if verification exposes an orchestration issue
- Test: `Makefile` via dry-run commands

- [ ] **Step 1: Write the failing test**

The verification conditions are:

- `_prepare-deploy` remains a stop-the-world preflight step
- no target names change
- `deploy-all-docker` still uses the same overall structure unless a shared helper naturally applies

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
make -n _prepare-deploy
make -n deploy-all
make -n deploy-all-docker
```

Expected:
- Any missing warmup in the dry-run output counts as failure
- Any accidental reordering of cleanup or branch targets counts as failure

- [ ] **Step 3: Write minimal implementation**

If dry-run inspection exposes duplication or mismatch, tighten the target definitions. For example, if the new helper belongs in both local and Docker paths safely, reuse it instead of duplicating shell lines.

Example direction:

```make
_prepare-deploy:
	@echo "$(COLOR_BLUE)Running deploy preflight in parallel...$(COLOR_RESET)"
	@gmake -s -j5 _prepare-flutter-deps _prepare-flutter-release _prepare-android-ruby _prepare-ios-ruby _prepare-ios-pods
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
make -n _prepare-deploy
make -n deploy-all
make -n deploy-all-docker
```

Expected:
- All three dry runs succeed
- Shared warmup is visible where intended
- Release branch names and ordering semantics remain unchanged

- [ ] **Step 5: Commit**

```bash
git add Makefile
git commit -m "build: verify deploy prewarm orchestration"
```

## Self-Review

- Spec coverage:
  - Shared prewarm target: covered by Task 1
  - Preserve `deploy-all` parallel fan-out: covered by Task 2
  - Behavior-preserving verification: covered by Task 3
- Placeholder scan:
  - No `TODO`/`TBD` markers remain
  - Commands and expected outputs are explicit
- Type consistency:
  - Target names match the current Makefile: `_prepare-deploy`, `_prepare-flutter-deps`, `_web-deploy-core`, `_android-deploy-core`, `_ios-beta-core`, `deploy-all`, `deploy-all-docker`
