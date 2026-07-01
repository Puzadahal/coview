import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

typedef UploadProgressCallback = void Function(double progress);

class StorageUploadService {
  FirebaseStorage get _storage => FirebaseStorage.instanceFor(
        bucket: DefaultFirebaseOptions.currentPlatform.storageBucket,
      );

  Future<fb.User> ensureAuthenticatedUser() async {
    var user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      final cred = await fb.FirebaseAuth.instance.signInAnonymously();
      user = cred.user;
    }
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthenticated',
        message: 'Sign in required to upload files.',
      );
    }
    return user;
  }

  Future<String> uploadProfilePhoto(
    PlatformFile file, {
    String? extension,
  }) async {
    final user = await ensureAuthenticatedUser();

    final ext = _safeImageExtension(extension ?? file.extension);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'profile_photos/${user.uid}/avatar_$timestamp.$ext';

    final metadata = SettableMetadata(
      contentType: _imageContentType(ext),
    );

    final ref = _storage.ref().child(storagePath);
    final task = _startUpload(ref, file, metadata);

    try {
      await task;
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: friendlyMessage(e),
        stackTrace: e.stackTrace,
      );
    }
  }

  Future<String> uploadRoomVideo(
    PlatformFile file, {
    UploadProgressCallback? onProgress,
  }) async {
    final user = await ensureAuthenticatedUser();

    final originalName = (file.name.isNotEmpty ? file.name : 'video.mp4')
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ext = _extensionOf(originalName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        'room_uploads/${user.uid}/$timestamp-${timestamp % 1000}.$ext';

    final metadata = SettableMetadata(
      contentType: _contentTypeForExtension(ext),
      customMetadata: {'originalName': originalName},
    );

    final ref = _storage.ref().child(storagePath);
    final task = _startUpload(ref, file, metadata);

    StreamSubscription<TaskSnapshot>? sub;
    if (onProgress != null) {
      sub = task.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        if (total <= 0) return;
        onProgress(snapshot.bytesTransferred / total);
      });
    }

    try {
      await task;
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: friendlyMessage(e),
        stackTrace: e.stackTrace,
      );
    } finally {
      await sub?.cancel();
    }
  }

  UploadTask _startUpload(
    Reference ref,
    PlatformFile file,
    SettableMetadata metadata,
  ) {
    if (!kIsWeb && file.path != null && file.path!.trim().isNotEmpty) {
      return ref.putFile(File(file.path!), metadata);
    }

    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ref.putData(bytes, metadata);
    }

    throw FirebaseException(
      plugin: 'firebase_storage',
      code: 'invalid-argument',
      message:
          'Could not read the selected file. Try a smaller file or choose another.',
    );
  }

  static String friendlyMessage(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return 'Firebase Storage is not set up yet. In Firebase Console open '
            'Storage → Get started, then run: firebase deploy --only storage';
      case 'unauthorized':
      case 'permission-denied':
        return 'Upload denied. Deploy storage rules: firebase deploy --only storage';
      case 'unauthenticated':
        return 'Please sign in before uploading.';
      case 'canceled':
        return 'Upload was cancelled.';
      case 'retry-limit-exceeded':
        return 'Upload timed out. Check your connection and try a smaller file.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Upload failed (${e.code}).';
    }
  }

  String _imageContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
        return 'image/jpeg';
      default:
        return 'image/jpeg';
    }
  }

  String _safeImageExtension(String? extension) {
    final value = extension?.toLowerCase().replaceFirst('.', '') ?? '';
    switch (value) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return value;
      default:
        return 'jpg';
    }
  }

  String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return 'mp4';
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case 'mkv':
        return 'video/x-matroska';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }
}
