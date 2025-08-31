import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendSearchController extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  final TextEditingController textController = TextEditingController();

  List<Map<String, dynamic>> results = [];
  bool isLoading = false;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      results = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final currentUserId = supabase.auth.currentUser?.id;

      var responseQuery = supabase
          .from('users')
          .select('id, username, avatar_url, bio')
          .ilike('username', '%$query%');

      if (currentUserId != null) {
        responseQuery = responseQuery.neq('id', currentUserId);
      }

      final response = await responseQuery;

      results = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error searching users: $e");
      results = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
