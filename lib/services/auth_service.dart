import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_account.dart';

class AuthService {
	static final _auth = FirebaseAuth.instance;
	static final _users = FirebaseFirestore.instance.collection('users');

	static User? get currentUser => _auth.currentUser;

	static Future<UserAccount> signIn(String email, String password) async {
		final credential = await _auth.signInWithEmailAndPassword(
			email: email.trim().toLowerCase(),
			password: password,
		);
		final account = await getAccount(credential.user!.uid);
		if (account == null) {
			await _auth.signOut();
			throw StateError(
				'Your account profile is missing for UID ${credential.user!.uid}. '
				'Create the users document with this exact ID in the same Firebase project.',
			);
		}
		if (!account.isApproved) {
			await _auth.signOut();
			throw StateError('Account pending admin approval.');
		}
		return account;
	}

	static Future<UserAccount> register({
		required String email,
		required String password,
		required String name,
		required String address,
		required String lrn,
		required String character,
	}) async {
		final credential = await _auth.createUserWithEmailAndPassword(
			email: email.trim().toLowerCase(),
			password: password,
		);
		final account = UserAccount(
			uid: credential.user!.uid,
			email: email.trim().toLowerCase(),
			role: 'student',
			status: 'pending',
			name: name,
			address: address,
			lrn: lrn,
			character: character,
		);
		await _users.doc(account.uid).set(account.toJson());
		await _auth.signOut();
		return account;
	}

	static Future<UserAccount?> getAccount(String uid) async {
		final snapshot = await _users.doc(uid).get();
		if (!snapshot.exists) return null;
		return UserAccount.fromJson({...snapshot.data()!, 'uid': snapshot.id});
	}

	static Future<List<UserAccount>> loadAccounts() async {
		final snapshot = await _users.orderBy('name').get();
		return snapshot.docs
				.map((doc) => UserAccount.fromJson({...doc.data(), 'uid': doc.id}))
				.toList();
	}

	static Future<void> updateAccount(UserAccount account) {
		final data = account.toJson()..remove('uid');
		return _users.doc(account.uid).update(data);
	}

	static Future<void> deleteAccount(UserAccount account) {
		return _users.doc(account.uid).delete();
	}

	static Future<void> updateCurrentProfile({
		required String name,
		required String address,
		required String lrn,
	}) async {
		final user = currentUser;
		if (user == null) throw StateError('Not signed in.');
		await _users.doc(user.uid).update({
			'name': name,
			'address': address,
			'lrn': lrn,
		});
	}

	static Future<void> signOut() => _auth.signOut();
}
