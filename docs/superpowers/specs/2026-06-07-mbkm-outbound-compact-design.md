# MBKM Outbound Compact Redesign

## Goal

Make the MBKM outbound page easier to scan and shorter to scroll while preserving the existing data and actions.

## Scope

- Keep the current API and models.
- Keep actions for applying MBKM, viewing logs, adding competencies, opening more-info links, and refreshing data.
- Make the main list more compact by showing only the most important data per application.
- Move secondary data into expanded detail.
- Improve loading, empty, and error states.
- Do not show the header copy "Pantau pengajuan, kompetensi, log kegiatan, dan tautan program dalam satu tempat."

## App Design

The page uses a compact dashboard structure:

- App bar title: `MBKM Outbound`.
- Short gradient header with `Outbound MBKM` only.
- Compact biodata summary with student name, NIM, application count, competency count, and a log placeholder count.
- Primary `Ajukan MBKM` button below the summary.
- Compact application cards showing activity type, scale, status, title, company, period, mentor, and primary actions.
- Expanded detail shows semester, date range, selection/result dates, description, competencies, add competency, log, and link actions.
- Empty state invites the student to start an application.
- Error state shows a retry action.

## Testing

Widget tests should verify that:

- Injected data renders the compact dashboard and application card.
- The removed header copy is not rendered.
- Empty data renders a friendly empty state and `Ajukan MBKM` remains accessible.
