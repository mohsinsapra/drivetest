# Deploy-All Performance Design

## Goal

Reduce the wall-clock time of `make deploy-all` while preserving the current release result:

- version bump and commit behavior remain unchanged
- web deploy still publishes to the web repo and purges Cloudflare
- Android still uploads to Play and promotes as it does today
- iOS still uploads to TestFlight
- cleanup still runs after the parallel release work completes

The bottleneck to optimize is build time, not store upload time.

## Current Behavior

`deploy-all` currently does:

1. `check`
2. changelog validation
3. version bump
4. pre-build commit
5. `_prepare-deploy`
6. parallel fan-out via `gmake -j3`:
   - `_web-deploy-core`
   - `_android-deploy-core`
   - `_ios-beta-core`
7. cleanup

This already overlaps the three release branches, so the remaining waste is inside the branches themselves:

- repeated Flutter bootstrap work before builds
- repeated dependency resolution and artifact warming
- branch-local setup that could be done once before fan-out
- inconsistent cache reuse across targets

## Constraints

- Result must remain the same from the user’s perspective.
- The change should target local `deploy-all`, not redesign the entire release system.
- The refactor must not make branch execution order-sensitive beyond the new shared prewarm step.
- The implementation should stay within the current Makefile/Fastlane structure unless a small helper target is clearly justified.

## Options Considered

### Option 1: Keep current structure and tune individual targets

Improve web/Android/iOS targets independently without introducing a shared stage.

Pros:
- lowest structural risk
- easy to reason about per target

Cons:
- leaves obvious duplicated setup in place
- speedup ceiling is limited

### Option 2: Add a shared prewarm stage before parallel builds

Do one-time Flutter preparation before the `gmake -j3` fan-out, then keep platform-specific work in parallel branches.

Pros:
- removes duplicated setup cost
- preserves current parallelism where it matters
- keeps user-visible release behavior unchanged

Cons:
- shared-state boundary has to be explicit to avoid contention

### Option 3: Fully split compile and deploy phases

Build all artifacts first, then upload/promote in separate later steps.

Pros:
- strongest long-term orchestration model

Cons:
- larger behavioral refactor
- more artifact plumbing
- unnecessary for the current goal

## Decision

Use Option 2.

Add a single shared prewarm phase before the parallel release fan-out. That phase prepares Flutter and dependency state once, then web/Android/iOS branch targets execute with less startup cost.

## Design

### 1. Introduce a shared prewarm target

Add a dedicated Make target invoked by `deploy-all` after `_prepare-deploy` and before `gmake -j3`.

Responsibilities:

- run `flutter pub get` once for the workspace
- prewarm Flutter artifacts needed by release builds
- prepare any release metadata or environment-derived files that are currently recomputed in each branch when possible
- avoid any platform build output generation that would serialize the actual release builds

This target must be idempotent and safe to run before all release variants.

### 2. Thin the per-platform build branches

Adjust `_web-deploy-core`, `_android-deploy-core`, and `_ios-beta-core` so they rely on the shared warm state instead of redoing common setup.

Expected reductions:

- less package/dependency resolution duplication
- fewer cold Flutter startup paths
- less redundant artifact downloading or generation

Platform-specific setup that truly cannot be shared should remain local to the branch.

### 3. Preserve parallel compile/deploy fan-out

After the prewarm target completes, keep the current `gmake -j3` release fan-out. This preserves overlapping work across web, Android, and iOS.

The change is not to remove parallelism. It is to ensure each parallel branch starts from a warmer, shared baseline.

### 4. Preserve release semantics

The following behavior must remain unchanged:

- version bump path
- commit-before-build path
- changelog preparation
- Android deploy lane selection
- iOS beta lane selection
- web deployment + Cloudflare purge
- cleanup after release branches finish

### 5. Keep Docker-specific behavior separate

The immediate target is `deploy-all`, not `deploy-all-docker`.

If a helper target can be shared safely by both flows, that is acceptable. But the implementation should not force Docker behavior changes just to optimize local `deploy-all`.

## Files Expected To Change

- `Makefile`
  - add shared prewarm target(s)
  - update `deploy-all` to call the prewarm step before parallel fan-out
  - remove or reduce duplicated setup inside release branches where safe

Potentially:

- `android/fastlane/Fastfile`
  - only if Android branch logic can skip redundant local Flutter preparation safely

## Error Handling

- If the shared prewarm step fails, `deploy-all` must stop before any release branch starts.
- Platform-specific failures after fan-out should continue to fail the overall make invocation as they do today.
- The prewarm step should not partially mutate release outputs in a way that makes retries unsafe.

## Testing Strategy

Testing should focus on behavior preservation plus proof that the orchestration changed as intended.

1. Static verification
   - inspect `make -n deploy-all` output to confirm the new prewarm stage executes before `gmake -j3`
   - confirm the three release branches remain parallelized

2. Target-level smoke verification
   - run the shared prewarm target directly
   - run dry-run output for `deploy-all`

3. Regression verification
   - confirm existing deploy target names and release lanes still resolve
   - confirm no change to cleanup invocation order

4. Optional real-world timing check
   - compare a before/after run time for `make deploy-all` on the same machine if the environment is available

## Non-Goals

- redesigning CI/CD outside this repo
- changing release destinations or track behavior
- rewriting Fastlane lanes broadly
- optimizing store upload durations
