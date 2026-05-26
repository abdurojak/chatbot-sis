# Notification Unread Count and Read State Design

## Goal

Make the notification badge use the unread total returned by
`POST /api/open-notification`, and mark notifications as read when the user
opens the notification page through `POST /api/read-notification`.

## Current Behavior and Root Cause

`NotificationService.openNotifications()` already posts the authenticated
payload to `/open-notification`. However, `NotificationResult.fromJson()`
calculates `count` only by counting unread entries in `body.data.detail`.
The API response for the unread total can contain only:

```json
{
  "body": {
    "data": {
      "jumlah": "1"
    }
  }
}
```

Because this response has no `detail` list, the application currently shows a
badge count of zero even when `jumlah` is nonzero.

`NotificationPage` is also created inside an `IndexedStack` while the Chat tab
is initially selected. Triggering a read request from `NotificationPage`
initialization would mark notifications as read before the user opens that
tab.

## Design

### API Service

Keep `openNotifications()` as the request used to fetch notification data.
Update `NotificationResult.fromJson()` so `count` reads
`body.data.jumlah` when present. If `jumlah` is absent or cannot be parsed,
fall back to counting unread `detail` items to remain compatible with list
responses.

Add `NotificationService.readNotifications()` that posts the same session
payload:

```json
{
  "IdLogin": "<session id>",
  "token": "<session token>"
}
```

to `/read-notification`. It treats the documented success response with
`body.data == "Success"` as successful completion.

### Page Open Flow

Use `_requireLoginOrOpenNotifications()` as the user-intent boundary for
opening notifications. After confirming a valid login session and selecting
the notification tab, call `readNotifications()`, then refresh notification
data and the badge through the existing load flow.

Do not call `readNotifications()` from `NotificationPage.initState()`, because
the hidden page is initialized at application startup.

### Error Handling

Opening the notification page must not be blocked if the read request fails.
The page remains accessible and the normal notification reload still runs. A
failed read request therefore leaves the server-derived badge/list state as
the source of truth on refresh.

## Testing

Add service tests before implementation for:

1. A `jumlah`-only `/open-notification` response producing the badge count.
2. The fallback unread count when a list response omits `jumlah`.
3. `readNotifications()` posting the expected path and session payload and
   accepting the documented success response.

Run the focused notification service tests, then run Dart analysis and the
project test suite after the code change.

## Scope

This change only affects notification API parsing and the page-open read
action. Existing theme/UI edits and unrelated chat behavior are out of scope.
