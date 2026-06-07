# Exam Slip Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the exam participant card screen and generated PDFs to match the approved mockup.

**Architecture:** Keep the feature in `lib/kpu_screen.dart` because the current screen and PDF generation already live there. Add small helper methods for formatting, summaries, state rendering, and repeated UI/PDF pieces so the file remains understandable without a broad refactor.

**Tech Stack:** Flutter Material widgets, existing `AppThemePalette`, `http`, `pdf`, `printing`, and Flutter widget tests.

---

### Task 1: Widget Tests For New Screen States

**Files:**
- Create: `test/kpu_screen_test.dart`
- Modify: `lib/kpu_screen.dart`

- [ ] **Step 1: Write failing tests**

Create tests that pump `ExamSlipPage` with injected test data and verify the new card UI labels and empty state.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/kpu_screen_test.dart`

Expected: fail because `ExamSlipPage` does not yet support injected data or render the new card layout.

- [ ] **Step 3: Add testability hooks and card UI**

Add optional constructor parameters for initial data and skipped fetch in tests, then replace the table body with card-based content, summary, loading, empty, and error states.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/kpu_screen_test.dart`

Expected: pass.

### Task 2: PDF Layout Polish

**Files:**
- Modify: `lib/kpu_screen.dart`

- [ ] **Step 1: Improve PDF helpers**

Update PDF header, title, student box, schedule table, signature, QR card grid, and value fallbacks.

- [ ] **Step 2: Verify static correctness**

Run: `flutter analyze lib/kpu_screen.dart test/kpu_screen_test.dart`

Expected: no analyzer errors in touched files.

### Task 3: Full Verification

**Files:**
- Verify: `lib/kpu_screen.dart`
- Verify: `test/kpu_screen_test.dart`

- [ ] **Step 1: Run focused tests**

Run: `flutter test test/kpu_screen_test.dart`

Expected: all focused tests pass.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/kpu_screen.dart test/kpu_screen_test.dart`

Expected: analyzer completes without errors.
