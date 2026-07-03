# Dashboard Quick Shortcuts: Documents for Selected Exam + Its Subcategories

Date: 2026-07-03
Status: Approved (option 1 — client-side aggregation, grouped by category)

> Revision: after seeing the first version, the user narrowed the scope from
> "all categories" to "the selected exam/lesson and its subcategories".
> `BCDDocumentsScreen` now takes `includeSubcategories: true` instead of an
> all-categories mode; the dashboard passes the selected `examBcdId` again.
> Aggregation fetches the category's own documents plus its subcategories
> (two levels), grouped by category name. The rest of the design below applies
> with that substitution.

## Problem

The dashboard Quick Access "Theory Documents" shortcut opens `BCDDocumentsScreen`
with only the currently selected exam's `examBcdId`
(`lib/features/dashboard/widgets/dashboard_body.dart` → `_openDocuments`), so the
list shows documents for a single category. The user wants the shortcut to show
documents from **all** categories.

## Approach

Client-side aggregation — no backend change:

1. `BCDDocumentsScreen` gains an all-categories mode: `categoryBcdId` becomes
   nullable with a `BCDDocumentsScreen.allCategories()` constructor.
2. In all-categories mode, `initState`:
   - calls `ApiService.fetchBCDAllCategories()`;
   - for categories with `has_children == true`, also fetches
     `fetchBCDSubcategories()` to reach leaf categories;
   - fetches `fetchBCDDocuments(bcdId)` for every resulting category in
     parallel (`Future.wait`);
   - categories whose fetch fails or that have zero documents are skipped.
3. Rendering: one scrollable list **grouped by category** — a section header
   with the category name, then the existing document card rows. The
   single-category mode keeps its current flat list and behavior (used from the
   BCD category hub).
4. AppBar title in all-categories mode: `bcd_hub_theory_docs` (existing key,
   newline stripped) — no new translation keys required. Section headers show
   API-provided category names. Empty state reuses `bcd_no_documents`.
5. Dashboard `_openDocuments` opens `BCDDocumentsScreen.allCategories()`.

## Rejected alternatives

- New backend endpoint `api/v2/documents/` — cleaner but requires backend
  deployment; not needed for the expected small number of categories.
- Hardcoded category IDs in the app — fragile.

## Testing

- `flutter analyze` clean.
- Manual: dashboard shortcut shows grouped documents from all categories;
  category hub documents screen unchanged; empty and error states show the
  existing "no documents" message instead of crashing.
