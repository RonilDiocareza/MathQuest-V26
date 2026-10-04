import { initializeApp } from "firebase-admin/app";
import { FieldPath, FieldValue, getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const pointsPerLevel = 10;
const maximumLevel = 60;

function completedLevelCount(userData: FirebaseFirestore.DocumentData): number {
  const completedLevels = userData.progress?.completedLevels;
  if (!Array.isArray(completedLevels)) return 0;

  const validLevels = new Set<number>();
  for (const value of completedLevels) {
    const level = typeof value === "number" ? value : Number(value);
    if (Number.isInteger(level) && level >= 1 && level <= maximumLevel) {
      validLevels.add(level);
    }
  }
  return validLevels.size;
}

async function updateLeaderboard(uid: string, userData: FirebaseFirestore.DocumentData) {
  const leaderboardRef = db.collection("leaderboard").doc(uid);
  if (userData.role !== "student" || userData.status !== "approved") {
    await leaderboardRef.delete();
    return;
  }

  const displayName =
    typeof userData.name === "string" && userData.name.trim()
      ? userData.name.trim().slice(0, 80)
      : "Player";
  const totalScore = completedLevelCount(userData) * pointsPerLevel;

  await leaderboardRef.set({
    uid,
    displayName,
    totalScore,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export const syncLeaderboardFromUser = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const after = event.data?.after;
    if (!after?.exists) {
      await db.collection("leaderboard").doc(uid).delete();
      return;
    }

    const userData = after.data();
    if (!userData) {
      await db.collection("leaderboard").doc(uid).delete();
      return;
    }
    await updateLeaderboard(uid, userData);
  },
);

export const syncMyLeaderboard = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in to sync your leaderboard entry.");
  }

  const userSnapshot = await db.collection("users").doc(uid).get();
  if (!userSnapshot.exists) {
    throw new HttpsError("not-found", "Your user profile could not be found.");
  }

  const userData = userSnapshot.data()!;
  if (userData.role !== "student" || userData.status !== "approved") {
    throw new HttpsError("failed-precondition", "Only approved student accounts can use the leaderboard.");
  }

  await updateLeaderboard(uid, userData);
  return {
    uid,
    totalScore: completedLevelCount(userData) * pointsPerLevel,
  };
});

export const backfillLeaderboard = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in as an admin to backfill the leaderboard.");
  }

  const adminSnapshot = await db.collection("users").doc(uid).get();
  if (adminSnapshot.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can backfill the leaderboard.");
  }

  const users = db.collection("users");
  let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  let processed = 0;

  while (true) {
    let query = users.orderBy(FieldPath.documentId()).limit(400);
    if (cursor) query = query.startAfter(cursor);

    const page = await query.get();
    if (page.empty) break;

    const batch = db.batch();
    let writes = 0;
    for (const user of page.docs) {
      const userData = user.data();
      if (userData.role !== "student" || userData.status !== "approved") {
        continue;
      }

      const completedLevels = completedLevelCount(userData);
      const displayName =
        typeof userData.name === "string" && userData.name.trim()
          ? userData.name.trim().slice(0, 80)
          : "Player";
      batch.set(db.collection("leaderboard").doc(user.id), {
        uid: user.id,
        displayName,
        totalScore: completedLevels * pointsPerLevel,
        updatedAt: FieldValue.serverTimestamp(),
      });
      writes += 1;
      processed += 1;
    }

    if (writes > 0) await batch.commit();
    if (page.size < 400) break;
    cursor = page.docs[page.docs.length - 1];
  }

  return { processed };
});
