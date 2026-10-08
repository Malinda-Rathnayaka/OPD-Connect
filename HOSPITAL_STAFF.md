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

- `users/{uid}`: existing profiles plus optional `isActive`, `department`, `registrationNumber`, `staffRole`, `approvalStatus`, `reviewNote`, `reviewedAt` and `reviewedBy`.
- `hospital_settings/default`: hospital name, address, phone and department list.
- `staff_activity/{id}`: title, detail, actor, actor ID and server timestamp.

Account/settings changes and their activity entries are written in one Firestore batch. If permissions reject the write, the UI reports failure rather than pretending the change succeeded. The logged-in user's profile is observed so deactivation blocks their application screen.

Existing administrator profiles default to **Hospital administrator**. The Firebase project owner must assign `staffRole: "Super administrator"` to the designated owner account to enable staff role management. The UI never grants this access to the current user automatically.

This repository currently models one hospital. Multi-hospital isolation, trusted server authorization, authentication-account disabling, secure staff invitation delivery, and production audit retention need backend work before real deployment. UI role checks are not a security boundary: Firestore rules or a trusted backend must enforce the same permissions, protect approval/role fields, prevent self-promotion and unauthorized reads, and restrict audit writes. Review these rules with the Firebase owner; do not open the database to all users to make the demo work.

Staff invitations are intentionally available only as an explicitly labelled preview workflow. SMS, identity-registry, backups, uptime and database-load monitoring are not integrated; the live UI displays **Not connected** instead of fabricated operational metrics. No automated medical-credential validation is claimed.

The previous setup reported Firebase permission errors. Live account, hospital-setting and activity requests still need validation against the actual Firebase project. No cloud rules or production data were changed for this UI work.

## Group handoff

Agree with your teammates on hospital identifiers, doctor registration fields, which roles may approve doctors, and how patient/doctor modules should react to inactive accounts. Use the account ID, not a display name, to link bookings and queue records. Keep clinical notes outside the staff account directory.
