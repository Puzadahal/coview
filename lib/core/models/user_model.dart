import 'package:equatable/equatable.dart';

/// User role enum
enum UserRole {
  guest,      // Can create/join rooms, temporary access
  registered,  // Standard user, can become host, can view previous rooms
  host,        // Full control, can create/manage rooms
}

/// User model for authentication and role management
class User extends Equatable {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final UserRole role;
  final bool canHost; // Registered users can become hosts
  final DateTime? createdAt;
  final bool isGuestMode;

  const User({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    required this.role,
    this.canHost = false,
    this.createdAt,
    this.isGuestMode = false,
  });

  /// Create a guest user
  /// Guests can create and join rooms but cannot view previous rooms
  factory User.guest(String guestId) {
    return User(
      id: guestId,
      role: UserRole.guest,
      canHost: true, // Guests can create rooms (per flowchart)
      isGuestMode: true,
      createdAt: DateTime.now(),
    );
  }

  /// Create a registered user
  factory User.registered({
    required String id,
    required String email,
    String? name,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      email: email,
      name: name,
      avatarUrl: avatarUrl,
      role: UserRole.registered,
      canHost: true,
      isGuestMode: false,
      createdAt: DateTime.now(),
    );
  }

  /// Create a host user (from registered user)
  factory User.host(User registeredUser) {
    return User(
      id: registeredUser.id,
      email: registeredUser.email,
      name: registeredUser.name,
      avatarUrl: registeredUser.avatarUrl,
      role: UserRole.host,
      canHost: true,
      isGuestMode: false,
      createdAt: registeredUser.createdAt,
    );
  }

  /// Check if user can create rooms
  /// Both guests and registered users can create rooms (per flowchart)
  bool get canCreateRoom => canHost;

  /// Check if user can control playback
  /// Only hosts can control playback in rooms
  bool get canControlPlayback => role == UserRole.host;

  /// Check if user can manage participants
  /// Only hosts can manage participants
  bool get canManageParticipants => role == UserRole.host;

  /// Check if user can view previous rooms
  /// Only registered users can view their room history
  bool get canViewPreviousRooms => role == UserRole.registered || role == UserRole.host;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    UserRole? role,
    bool? canHost,
    DateTime? createdAt,
    bool? isGuestMode,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      canHost: canHost ?? this.canHost,
      createdAt: createdAt ?? this.createdAt,
      isGuestMode: isGuestMode ?? this.isGuestMode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatarUrl,
        role,
        canHost,
        createdAt,
        isGuestMode,
      ];
}
