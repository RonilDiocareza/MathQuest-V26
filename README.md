# flutter_mathquest

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Global leaderboard

The leaderboard is stored in `leaderboard/{uid}`. Each document is keyed by the
Firebase Authentication UID and contains `uid`, `displayName`, `totalScore`,
and a server-maintained `updatedAt` timestamp. Only approved student accounts
are listed.

`totalScore` is derived by a trusted Cloud Function from the unique level IDs
in `users/{uid}.progress.completedLevels`: 10 points per completed level,
counted once per level (up to 60 levels). The function also refreshes names and
removes entries when an account is deleted or is no longer an approved student.
Clients can read leaderboard documents but cannot create, update, or delete
them.

### Deploy

1. Select the configured Firebase project with `firebase use <project-id>` and
   ensure the Firebase CLI is authenticated. Use Node.js 22 for the Functions
   runtime.
2. Install the Cloud Functions dependencies:

   ```powershell
   npm --prefix functions ci
   ```

3. Deploy the rules, indexes, and Functions from the project root:

   ```powershell
   firebase deploy --only firestore:rules,firestore:indexes,functions
   ```

   Cloud Functions deployment requires a Firebase project with billing enabled
   (Blaze plan).
4. Sign in as an administrator and press the sync icon in the Admin Dashboard
   once. This securely backfills leaderboard entries for existing approved
   students. New account/progress/profile changes are synchronized
   automatically.

### Ranking and scale

The live screen queries the top 100 entries ordered by `totalScore` descending,
then UID ascending for deterministic ties. Rank is the number of entries with
a higher score, plus entries with the same score and a lower UID, plus one.
The signed-in student's own entry and exact rank are shown even when they are
outside the top 100. The required composite indexes are checked into
`firestore.indexes.json` and created by the deploy command.

### Test

1. Deploy the Firebase resources above, then run `flutter pub get` and launch
   the app.
2. As an administrator, use the Admin Dashboard sync icon to seed scores for
   existing approved students.
3. Sign in as an approved student and open **Leaderboard** from Home. Confirm
   the current user's row and rank are highlighted.
4. Complete a previously incomplete level. Its score should rise by 10 after
   the Firestore trigger runs, and other open leaderboard screens should
   refresh automatically. Replaying the same level must not add another 10.
5. Change the profile name and confirm the displayed leaderboard name updates.
6. Verify a signed-in client can read the collection but a client write to
   `leaderboard/{uid}` or a `totalScore` field on `users/{uid}` is denied by
   Firestore Rules.

The game currently stores level completion on the client. Rules limit a client
progress update to at most one additional completed level, and the score
function validates and deduplicates the allowed level IDs; however, this does
not prove that the game challenge was genuinely solved on a hostile client.
Preventing deliberate gameplay cheating would require moving challenge
validation to a trusted backend.
