# Hospital administration data access: confirmed cause and owner handoff

Inspected on 8 October 2026 on branch `Auchithya`. Existing changes were
preserved. No Auth users, cloud data, deployed rules, or Git remotes were changed.
The user does not have Firebase Console access and requested no rule publishing.

## Live evidence

The existing OPD-Connect browser sessions were inspected read-only. Their
Firebase Auth token was valid and unexpired, with audience `opd-connect`.
Tokens/passwords were not logged, exported, or changed. The signed-in UID is:

**aDNGa1sXaXWOcXOVhzeBiKDtuPh1**

| Read in `(default)` Firestore database | Live result |
| --- | --- |
| `users/aDNGa1sXaXWOcXOVhzeBiKDtuPh1` | HTTP 200 |
| `users` collection query | HTTP 403 `PERMISSION_DENIED` |
| `hospital_settings/default` | HTTP 403 `PERMISSION_DENIED` |
| `staff_activity` query ordered by `time` | HTTP 403 `PERMISSION_DENIED` |

The readable own profile contains `role: "admin"` and `isVerified: true`, but
**no `staffRole`, no explicit `isActive`, and no `hospitalId`**. Firebase Auth
also reports **emailVerified: false**. No role/hospital custom claims were
present. The app uses Firestore profile roles, not custom claims.

This establishes a real authorization failure, not a network outage or wrong
Firebase project. The profile lacks the explicit staff role required by the app
and the local rule reference. Missing `isActive` is treated as active by the
legacy app/reference; set it explicitly rather than relying on that default.

The exact deployed rule could not be inspected because neither the user nor
this workspace has project-owner credentials. The 403 responses do not prove
whether the deployed policy denies these reads because of the missing role,
an email-verification requirement, self-only reads, or another condition.
They also do not establish whether the hospital settings document exists.
Do not guess or broaden security to remove the errors.

## Local code issues corrected

The staff controller previously derived its actor role from the entire `users`
query. When that query was denied, it lost the actor profile and could not tell
an incomplete administrator role from a read-permission failure. It now listens
independently to `users/{signed-in UID}`, with snapshot metadata. Missing roles,
missing profiles, inactive/unverified profiles, cached permissions, expired
sessions, unavailable Firebase, and rule denials have separate messages.

Only an explicit, active, verified staff profile with server-confirmed permissions
can display workspace data. Super/hospital administrators can manage it;
support coordinators can view it and cannot write. This UI gate does not replace
Firestore authorization or grant any cloud permissions.

Denied directory queries show **Directory unavailable**, not `0 accounts`.
Failed activity loads show **Activity unavailable**. Failed settings loads show
**Departments unavailable**; a missing/empty configuration has a distinct
`hospital_settings/default` message. Denied reads clear cached activity/settings;
cached account/activity records are labelled explicitly. Live mode never
substitutes demo records.

## Firebase project owner: exact safe steps

1. Open **Firebase Console → opd-connect → Authentication → Users** and find
   UID **aDNGa1sXaXWOcXOVhzeBiKDtuPh1**. Confirm it belongs to the intended
   administrator and is enabled. Do not create another user or change the UID.
2. Open **Firestore Database → `(default)` → Data → users → that UID**. Preserve
   existing fields. If this person is authorized to administer the hospital,
   update only their intended access fields:

   ```json
   {
     "role": "admin",
     "staffRole": "Hospital administrator",
     "isActive": true,
     "isVerified": true
   }
   ```

   `role` and `isVerified` already have those values. The specifically missing
   role is `staffRole`; `isActive` should also be explicit. Use
   `Super administrator` only if this account is the designated super
   administrator. A support account uses `role: "admin"` and
   `staffRole: "Support coordinator"`; it must remain read-only. Assigning this
   role to one verified, intended account is not permission for all sign-ins.
3. Inspect the deployed **Firestore Database → Rules** policy before changing it.
   Save a copy. Evaluate this exact UID against the three denied paths above.
   Check whether it expects `staffRole`, a different role spelling/custom claim,
   `isActive`, Firebase Auth `email_verified`, hospital membership, or an expired
   test-mode date. Do not remove such requirements blindly. If email verification
   is required, arrange legitimate Firebase email verification for the account,
   then refresh the session. Setting Firestore `isVerified` does not verify an
   Auth email address.
4. Ensure the policy allows only the appropriate authenticated staff to perform
   the app's actual read operations. The unchanged, emulator-tested
   [rule reference](firestore.verifications.rules) contains `staffReader()`:
   an active, verified `role: "admin"` profile with one of the three explicit
   staff roles. If the deployed policy lacks those authorized reads, merge only
   the needed read clauses into its existing matches:

   ```javascript
   // Inside the existing service/database matches, using the tested
   // signedIn()/staffReader() helpers from firestore.verifications.rules:
   match /users/{uid} {
     allow get: if signedIn() &&
       (request.auth.uid == uid || staffReader());
     allow list: if staffReader();
     // Preserve secured create/update/delete conditions.
   }
   match /hospital_settings/default {
     allow read: if staffReader();
     // Preserve separately authorized writes.
   }
   match /staff_activity/{id} {
     allow read: if staffReader();
     // Preserve validated atomic audit creates and immutable log protection.
   }
   ```

   These are read conditions for explicitly authorized staff, not general
   `request.auth != null` collection permissions. The users directory needs
   **list** permission; an own-document **get** permission does not authorize
   that query. The activity query orders by `time` and returns up to 80 entries.
   Keep support writes denied, prevent client role escalation, and retain
   pending-only review transitions, both approval confirmations, rejection
   reasons, and linked atomic audit validation. Preserve unrelated module
   permissions. Do not blindly replace the deployed policy with the reference;
   it intentionally does not implement all other staff/module writes. Matching
   allow clauses are additive, so remove any broad overlapping bypass only
   after reviewing the complete policy.
5. Check actual data at these exact, case-sensitive locations:

   | Module data | Current app location |
   | --- | --- |
   | Users, staff and doctors | `users/{Auth UID}`; `role` is patient/doctor/admin |
   | Pending doctor registrations | Same `users` records; doctors not approved/rejected |
   | Hospital contact information | `hospital_settings/default`: name, address, phone |
   | Departments | `departments` array inside that settings document; each entry has id, name, location, active |
   | Activity | `staff_activity/{id}` with a Firestore Timestamp in `time` |

   An activity entry without `time` is excluded by the ordered query. A 403
   should be fixed before interpreting missing/empty data.
6. Confirm that `hospital_settings/default` and the top-level user/activity
   collections belong to the intended hospital. **The current project models
   one shared hospital**: there is no hospital identifier in the signed-in
   profile, no hospital-scoped query, and no per-hospital data layout in code.
   Do not grant a per-hospital administrator access to all hospitals if the
   actual database contains multiple hospitals. That case needs a confirmed
   membership/schema contract, scoped queries, and matching rules; an arbitrary
   `hospitalId` or guessed collection path is not a safe fix. No such migration
   was made here.
7. Test any proposed merged policy with the emulator or console Rules Playground
   before the owner publishes it. No rules were published by this task. After
   the owner corrects the intended account/policy, restart the app with the
   changed code, sign out/in to refresh authentication, and press Retry. Confirm
   real users/staff/pending doctors, hospital/departments, and ordered activity
   load; then validate support read-only access and unauthorized denials.

All generated platform options point to `opd-connect` (number `485137437849`).
Firebase is initialized from `DefaultFirebaseOptions.currentPlatform` before
the app starts. No configuration change or Firebase reinitialization is indicated
by the live evidence. Root `firebase.json` remains unchanged and does not deploy
the separate local rule reference automatically.

## Validation and files changed in this follow-up

- **38 Flutter tests passed**, including the actual missing-role/denied-query
  sequence, all authorized role loads, support read-only access, cached actor
  permissions, profile failure distinctions, and unavailable-data UI states.
- **30 Firestore emulator tests passed** against the unchanged local reference,
  including all administration reads and the exact own-read/denied-directory
  shape. They do not validate the deployed policy.
- Scoped Flutter analysis: **no issues**. `git diff --check`: passed.

Commands: `flutter test --no-pub`; `flutter analyze --no-pub lib/staff lib/main.dart
test lib/widgets/auth_wrapper.dart`; from `firebase`, `npm.cmd test`. Emulator
project: `demo-opd-connect`; no production writes.

Files changed: `lib/staff/staff_controller.dart`, `lib/staff/staff_store.dart`,
`lib/staff/staff_workspace.dart`, `test/helpers/staff_test_store.dart`,
`test/doctor_verifications_test.dart`, new `test/staff_data_access_test.dart`,
`firebase/verification.rules.test.mjs`, this document,
`firebase/VERIFICATION_SETUP.md`, and `HOSPITAL_STAFF.md`. Other pre-existing
changes were preserved. Read-only session evidence and the test log are stored
locally in ignored `.artifacts/live-staff-access-evidence.json` and
`.artifacts/staff-data-access-rules-results.log`.

Firebase references:
[role-based rule conditions](https://firebase.google.com/docs/firestore/security/rules-conditions),
[email verification](https://firebase.google.com/docs/auth/web/manage-users#send_a_user_a_verification_email).
