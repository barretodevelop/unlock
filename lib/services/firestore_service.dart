// FirestoreService
// lib/services/firestore_service.dart - FirestoreService
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unlock/models/user_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // User operations
  Future<UserModel?> getUser(String uid) async {
    try {
      if (kDebugMode) {
        print(
          'ℹ️ [FirestoreService.getUser] Attempting to get user with UID: $uid',
        );
      }
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        if (kDebugMode) {
          print('✅ [FirestoreService.getUser] User found: $uid');
        }
        return UserModel.fromJson(doc.data()!);
      } else {
        if (kDebugMode) {
          print('⚠️ [FirestoreService.getUser] User not found: $uid');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FirestoreService.getUser] Error getting user $uid: $e');
      }
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      if (kDebugMode) {
        print(
          'ℹ️ [FirestoreService.createUser] Attempting to create user: ${user.uid} - ${user.username}',
        );
      }
      await _db.collection('users').doc(user.uid).set(user.toJson());
      if (kDebugMode) {
        print(
          '✅ [FirestoreService.createUser] User created successfully: ${user.uid}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ [FirestoreService.createUser] Error creating user ${user.uid}: $e',
        );
      }
      rethrow;
    }
  }
  // Substitua o método updateUser existente no FirestoreService por este:

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print(
          'ℹ️ [FirestoreService.updateUser] Attempting to update user: $userId with data: $data',
        );
      }

      // Adiciona timestamp de última atualização automaticamente
      final updateData = Map<String, dynamic>.from(data);
      updateData['lastUpdatedAt'] = DateTime.now().toIso8601String();

      await _db.collection('users').doc(userId).update(updateData);

      if (kDebugMode) {
        print(
          '✅ [FirestoreService.updateUser] User updated successfully: $userId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ [FirestoreService.updateUser] Error updating user $userId: $e',
        );
        print('   Data attempted: $data');
      }
      rethrow; // Re-lança o erro para ser tratado pelo chamador
    }
  }

  // OPCIONAL: Manter método com UserModel para compatibilidade (se necessário)
  Future<void> updateUserModel(UserModel user) async {
    await updateUser(user.uid, user.toJson());
  }

  Future<void> deleteUser(String uid) async {}
}
