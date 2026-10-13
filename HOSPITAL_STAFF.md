# Hospital staff work for the group project

This section is the hospital administration workspace. It covers operational account management rather than clinical treatment or the patient booking journey.

## What your section includes

- **Overview:** real account counts, outstanding doctor reviews, recent changes and shortcuts.
- **Accounts:** search and filter patients, doctors and staff; inspect profiles; edit contact/team details; deactivate or reactivate with a recorded reason. Login email is not edited through the profile database.
- **Verifications:** inspect doctor registration and department information; confirm identity and credentials manually; approve or reject. Rejection preserves the record and reason.
- **Staff and roles:** staff directory, role descriptions and a permission matrix. Super administrators can edit other staff roles; hospital administrators handle accounts and reviews; support coordinators have read access.
- **Hospital setup:** validated hospital/contact details and departments with location and active status. Changes require saving, and navigation warns about unsaved edits.
- **Alerts and system health:** tasks needing attention and explicit service connection states. Example SMS/backup alerts can be acknowledged in preview; acknowledgement does not claim the service was repaired.
- **Activity:** searchable actions, names, reasons, staff actors and timestamps.

The layout uses a desktop sidebar and phone bottom navigation. Patient and doctor sections remain separate.

## Try the whole UI without Firebase

```powershell
cd "C:\HCI Project\OPD-Connect"
flutter run -d chrome --dart-define=STAFF_PREVIEW=true
```

Or choose **Hospital staff preview in Chrome** in VS Code's Run and Debug panel. The normal login page also has **Explore hospital staff preview**.

Preview uses fictional people, example registration numbers, and isolated in-memory data. It sends no invitations and changes no Firebase records. Restarting resets it.

Suggested demonstration: approve a doctor after checking both review boxes; reject the other with a reason; search for a patient and deactivate/reactivate them; edit a department and save; acknowledge an example alert; show the resulting activity log. Cancel actions as well, and show a phone-sized layout.

## Live integration and its limits

Administrator login opens the same workspace using Firebase:

- `users/{uid}`: existing profiles plus optional `isActive`, `department`, `registrationNumber`, `staffRole`, `approvalStatus`, `reviewNote`, `reviewedAt`, `reviewedBy` and `accountStatusReason`. Account status reasons are stored separately so deactivation/reactivation cannot replace a doctor's rejection reason.
- `hospital_settings/default`: hospital name, address, phone and department list.
- `staff_activity/{id}`: title, detail, actor, actor ID and server timestamp.

Account/settings changes and their activity entries are written in one Firestore batch. Doctor review decisions use a transaction that verifies the current pending state and saves the decision and activity atomically. If permissions reject the write, the UI reports failure rather than pretending the change succeeded. The logged-in user's profile is observed so deactivation blocks their application screen.

Firestore snapshot metadata distinguishes cached records from a server connection. Cached account or hospital settings data disables the affected changes until reconnection. Permission failures, expired sessions, configuration errors and malformed hospital settings have explicit messages. Failed hospital saves preserve the draft; fields and navigation are locked during a save. Selecting Hospital setup again does not remove the unsaved-change warning, and leaving/signing out also checks for unsaved changes.

Approval requires both review confirmations in the UI and controller. Reviews use the current account state, so a stale dialog cannot replace an existing decision. Profile editing cannot change approval/status fields through the generic edit action. Prepared preview invitations remain inactive and cannot be used as registered accounts. Support coordinators can inspect alerts but cannot acknowledge them.

Doctor review requires an active, verified administrator with an explicit `staffRole: "Hospital administrator"` or `staffRole: "Super administrator"`. Missing staff roles grant no management access. The Firebase owner must provision roles; the UI never grants them automatically. See [the verification investigation and owner steps](firebase/VERIFICATION_SETUP.md) for the denied-read fix and tested rule reference.

This repository currently models one hospital. Multi-hospital isolation, trusted server authorization, authentication-account disabling, secure staff invitation delivery, and production audit retention need backend work before real deployment. UI role checks are not a security boundary: Firestore rules or a trusted backend must enforce the same permissions, protect approval/role fields, prevent self-promotion and unauthorized reads, and restrict audit writes. Review these rules with the Firebase owner; do not open the database to all users to make the demo work.

Staff invitations are intentionally available only as an explicitly labelled preview workflow. SMS, identity-registry, backups, uptime and database-load monitoring are not integrated; the live UI displays **Not connected** instead of fabricated operational metrics. No automated medical-credential validation is claimed.

Read-only inspection of the existing browser session confirms a valid token for `opd-connect`, a readable own administrator profile missing `staffRole`, and HTTP 403 `PERMISSION_DENIED` for users, settings, and activity. See [the confirmed cause and exact Firebase owner steps](firebase/ADMIN_DATA_ACCESS_SETUP.md). The controller now observes the own profile independently of the directory and distinguishes missing roles, cached permissions, connection failures, and rule denials. Failed directories and activity show unavailable states. No cloud rules or production data were changed.

## Group handoff

Agree with your teammates on hospital identifiers, doctor registration fields, which roles may approve doctors, and how patient/doctor modules should react to inactive accounts. Use the account ID, not a display name, to link bookings and queue records. Keep clinical notes outside the staff account directory.

## Review checks

Run these checks from the project folder:

```powershell
flutter test
flutter analyze lib/staff test lib/widgets/auth_wrapper.dart
```

The Flutter suite passes 38 automated tests and the scoped analyzer reports no issues. Tests cover all seven sections at widths of 320, 390, 800 and 1440 pixels; doctor review checks and rejection reasons; account edits and status changes; staff permissions and invitations; hospital departments and activity; unsaved changes and pending saves; and simulated Firebase read/write failures and cached records. Administration access tests cover the observed missing-role profile and denied queries, independent own-profile reads, cached permissions, authorized module loading, support read-only access, and honest unavailable states.

The required `flutter run -d chrome --dart-define=STAFF_PREVIEW=true` launch was verified. A packaged preview built successfully with `flutter build web --dart-define=STAFF_PREVIEW=true --no-web-resources-cdn`. A separate headless Google Chrome check of that build passed navigation through all seven sections at the same four widths, both approval checks, rejection validation, the hospital draft guard, hospital saving and audit entries, with no JavaScript page errors. Browser screenshots and the result report are in the local, Git-ignored `.artifacts` folder. The initial 320-pixel review-dialog overflow found during this review is fixed.

`lib/staff/staff_store.dart` retains batch writes for account/settings changes and uses transactions for doctor reviews. `test/helpers/staff_test_store.dart` is a test double, not a Firebase emulator. The separate `firebase` test suite passes 30 emulator security tests against the unchanged rule reference, including every administration read path. Neither suite validates the deployed cloud policy; see [the owner handoff](firebase/ADMIN_DATA_ACCESS_SETUP.md).

`lib/widgets/auth_wrapper.dart` shows explicit profile access/missing-profile errors instead of silently returning to login. `lib/main.dart` no longer attempts client-side administrator provisioning at startup. Existing role routing and account approval gates are preserved.

Before live deployment, the Firebase owner still needs to test authenticated account/settings/activity reads and atomic writes with each role, enforce authorization and doctor-review concurrency on the server, and confirm that patient/doctor sessions respond correctly to staff decisions. The activity screen currently shows the latest 80 live records; production retention and pagination need backend work. External identity verification, invitation delivery, SMS, backups and operational monitoring remain unimplemented.
