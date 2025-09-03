import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendRequestsController extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> requests = [];
  bool isLoading = false;

  Future<void> fetchRequests() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('friendships')
          .select(
            'id, requester_id, status, created_at, users!friendships_requester_id_fkey(username, avatar_url)',
          )
          .eq('addressee_id', currentUserId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      requests = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error fetching friend requests: $e");
      requests = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await supabase.from('friendships').insert({
        'requester_id': currentUserId,
        'addressee_id': addresseeId,
        'status': 'pending',
      });

      debugPrint("✅ Friend request sent to $addresseeId");
    } catch (e) {
      debugPrint("❌ Error sending friend request: $e");
    }
  }

  Future<void> respondToRequest(String requestId, String action) async {
    try {
      await supabase
          .from('friendships')
          .update({
            'status': action, // accepted / rejected / blocked
          })
          .eq('id', requestId);

      // Refresh requests after response
      await fetchRequests();
    } catch (e) {
      debugPrint("❌ Error updating request: $e");
    }
  }
}
