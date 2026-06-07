# Exam Slip Redesign Design

## Goal

Improve the exam participant card experience in the app and in generated PDFs. The mobile page should be easier to scan than the current table, and the PDFs should look formal, printable, and clearer for students and exam supervisors.

## Scope

- Replace the app table with period cards.
- Keep two explicit actions per period: standard exam card PDF and QR exam PDF.
- Add useful loading, empty, and error states.
- Preserve the existing API endpoint and session-based request.
- Improve PDF layout without changing the backend data contract.

## App Design

The page keeps the existing Trisakti theme color and app bar behavior. The content becomes a stacked mobile layout:

- Header band with page title and short context.
- Summary card showing available periods and total scheduled subjects.
- One card per exam period with exam name, semester, subject count, first schedule date, and status.
- Two action buttons inside each card: `Kartu PDF` and `QR Ujian`.
- Empty state with a retry action when no valid exam slip data exists.
- Error state with a retry action when the request fails.

## PDF Design

The standard PDF keeps the official header, student photo, identity block, and schedule table. It improves spacing, table headers, period label, signature area, and fallbacks for missing values.

The QR PDF keeps the official header and student identity block, then renders a grid of QR cards. Each QR card contains the QR image when available, course code, course name, date/time, and room. If no QR image is present, the card shows a clear placeholder instead of silently leaving a blank area.

## Testing

Widget tests should verify that:

- Provided exam data renders as cards, not a plain table-only experience.
- Action labels are visible for each card.
- Empty data shows a friendly empty state and retry affordance.

PDF generation remains manually verified through analyzer/build because `printing` opens platform print UI and the PDF bytes are produced inside callbacks.
