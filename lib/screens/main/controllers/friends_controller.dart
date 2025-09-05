import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsController extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> friends = [];
  bool isLoading = false;

  /// Search query typed in the TextField
  String searchQuery = "";

  Future<void> fetchFriends() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('friendships')
          .select(
            'id, requester_id, addressee_id, '
            'requester:users!friendships_requester_id_fkey(username, avatar_url), '
            'addressee:users!friendships_addressee_id_fkey(username, avatar_url)',
          )
          .or('requester_id.eq.$currentUserId,addressee_id.eq.$currentUserId')
          .eq('status', 'accepted');

      final data = List<Map<String, dynamic>>.from(response);

      // Extract the "other" user for each friendship
      friends =
          data.map((f) {
            final isRequester = f['requester_id'] == currentUserId;
            return {
              'id': f['id'],
              'username':
                  isRequester
                      ? f['addressee']['username']
                      : f['requester']['username'],
              'avatar_url':
                  isRequester
                      ? f['addressee']['avatar_url']
                      : f['requester']['avatar_url'],
            };
          }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching friends: $e");
      friends = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Update search query from TextField
  void updateSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  /// Returns a filtered list of friends based on [searchQuery]
  List<Map<String, dynamic>> get filteredFriends {
    if (searchQuery.isEmpty) return friends;
    return friends.where((f) {
      final username = (f['username'] ?? '').toLowerCase();
      return username.contains(searchQuery.toLowerCase());
    }).toList();
  }
}
