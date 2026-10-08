# Running OPD Connect on Windows

## Using VS Code

1. Open the `OPD-Connect` folder in VS Code.
2. Open **Terminal > New Terminal** and run `flutter pub get`.
3. Open **Run and Debug**, select **OPD Connect in Chrome**, and press **F5**.
4. Use the stop button to stop the app.

## Using PowerShell

Open a new PowerShell window and run:

```powershell
cd "C:\HCI Project\OPD-Connect"
flutter pub get
flutter run -d chrome
```

Keep the terminal open while using the app. Press **Ctrl+C** to stop it.

If `flutter` is not recognized after installation, restart VS Code and open a new terminal.
On Auchithya's computer, Flutter is installed at `C:\Users\auchi\develop\flutter`.
Flutter is configured for browser development. Chrome and Edge are detected.
Native Windows builds are disabled because Windows Developer Mode is not enabled.

## What to expect

The app opens its introduction pages, followed by login and registration.
Registration sends an email verification link. Doctor accounts need administrator approval.
Patient and doctor home screens currently show welcome messages; booking and queue features are still to be developed.

The app connects to the existing Firebase project and needs internet access.
Firebase configuration and `.env` must be present. If Firebase reports a permission or authentication error,
the Firebase project owner may need to check its configuration.
During setup, the introduction and login screens were verified in Chrome.
The startup administrator check reported `[cloud_firestore/permission-denied] Missing or insufficient permissions`.
Account workflows have not been verified; the Firebase project owner needs to review the database access rules.

## Hospital staff preview

Run `flutter run -d chrome --dart-define=STAFF_PREVIEW=true` to open the hospital staff workspace without Firebase.
VS Code also has a **Hospital staff preview in Chrome** launch option.
See [HOSPITAL_STAFF.md](HOSPITAL_STAFF.md) for workflows, the group-work scope, and backend integration details.

## Development branch

Use `git branch --show-current` to check your branch. Development belongs on `Auchithya`.
