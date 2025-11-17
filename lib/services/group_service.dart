import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/group_member.dart';

class GroupService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Generate a random 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude similar chars
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Create a new group and add the creator as an admin
  Future<Group?> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique invite code
      String inviteCode;
      bool isUnique = false;
      int attempts = 0;

      do {
        inviteCode = _generateInviteCode();
        final existing = await _supabase
            .from('groups')
            .select('id')
            .eq('invite_code', inviteCode)
            .maybeSingle();

        isUnique = existing == null;
        attempts++;
      } while (!isUnique && attempts < 10);

      if (!isUnique) {
        throw Exception('Failed to generate unique invite code');
      }

      // Create the group
      final groupData = await _supabase.from('groups').insert({
        'name': name,
        'description': description,
        'invite_code': inviteCode,
        'created_by': userId,
      }).select().single();

      final group = Group.fromJson(groupData);

      // Add creator as admin
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
        'role': 'admin',
      });

      // Refresh groups list
      await fetchUserGroups();

      return group;
    } catch (e) {
      _error = 'Failed to create group: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Join a group using an invite code
  Future<bool> joinGroup(String inviteCode) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Find group by invite code
      final groupData = await _supabase
          .from('groups')
          .select()
          .eq('invite_code', inviteCode.toUpperCase())
          .maybeSingle();

      if (groupData == null) {
        _error = 'Invalid invite code';
        return false;
      }

      final group = Group.fromJson(groupData);

      // Check if already a member
      final existingMember = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', group.id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        _error = 'You are already a member of this group';
        return false;
      }

      // Add user as member
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
        'role': 'member',
      });

      // Refresh groups list
      await fetchUserGroups();

      return true;
    } catch (e) {
      _error = 'Failed to join group: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all groups the current user is a member of
  Future<void> fetchUserGroups() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _groups = [];
        return;
      }

      // Get groups where user is a member
      final response = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (response as List).map((e) => e['group_id']).toList();

      if (groupIds.isEmpty) {
        _groups = [];
        return;
      }

      // Fetch group details
      final groupsData = await _supabase
          .from('groups')
          .select()
          .inFilter('id', groupIds)
          .order('created_at', ascending: false);

      _groups = (groupsData as List)
          .map((json) => Group.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to fetch groups: $e';
      _groups = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get members of a specific group
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      return (response as List)
          .map((json) => GroupMember.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to fetch group members: $e';
      return [];
    }
  }

  /// Get members with profile information
  Future<List<Map<String, dynamic>>> getGroupMembersWithProfiles(String groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('*, profiles:user_id(email, display_name)')
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = 'Failed to fetch group members: $e';
      return [];
    }
  }

  /// Check if current user is admin of a group
  Future<bool> isGroupAdmin(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final member = await _supabase
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      return member?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is the only admin
      final members = await getGroupMembers(groupId);
      final admins = members.where((m) => m.role == 'admin').toList();
      final currentUserMember = members.firstWhere((m) => m.userId == userId);

      if (currentUserMember.role == 'admin' && admins.length == 1) {
        _error = 'You are the only admin. Please assign another admin before leaving.';
        return false;
      }

      // Remove user from group
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      // Refresh groups list
      await fetchUserGroups();

      return true;
    } catch (e) {
      _error = 'Failed to leave group: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a group (only creator can delete)
  Future<bool> deleteGroup(String groupId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is the creator
      final groupData = await _supabase
          .from('groups')
          .select('created_by')
          .eq('id', groupId)
          .single();

      if (groupData['created_by'] != userId) {
        _error = 'Only the creator can delete this group';
        return false;
      }

      // Delete the group (cascade will handle group_members and photos)
      await _supabase
          .from('groups')
          .delete()
          .eq('id', groupId);

      // Refresh groups list
      await fetchUserGroups();

      return true;
    } catch (e) {
      _error = 'Failed to delete group: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
