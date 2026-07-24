import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class CreatePostController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? selectedMedia;
  String mediaType = 'image'; // 'image' | 'video'
  bool isPosting = false;
  Map<String, dynamic>? existingPost; // For edit mode

  CreatePostController({this.existingPost}) {
    if (existingPost != null) {
      textController.text = existingPost!['content'] ?? '';
      mediaType = existingPost!['media_type'] ?? 'image';
    }
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedMedia = File(image.path);
      mediaType = 'image';
      notifyListeners();
    }
  }

  /// Pick video from gallery
  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      selectedMedia = File(video.path);
      mediaType = 'video';
      notifyListeners();
    }
  }

  /// Upload media (image or video) to Supabase Storage and return public URL.
  /// Content-type is inferred from the file extension by Supabase Storage.
  Future<String?> _uploadMedia(File file, String userId) async {
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";
    final storagePath = "posts/$userId/$fileName";

    // Upload with upsert true → allows replacing old file if same path exists
    await Supabase.instance.client.storage
        .from('post-images')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    final imageUrl = Supabase.instance.client.storage
        .from('post-images')
        .getPublicUrl(storagePath);

    return imageUrl;
  }

  /// Create or update a post
  Future<String?> savePost() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "Not logged in";

    final text = textController.text.trim();
    if (text.isEmpty && selectedMedia == null && existingPost == null) {
      return "Write something or add media!";
    }

    try {
      isPosting = true;
      notifyListeners();

      String? imageUrl = existingPost?['image_url'];

      if (selectedMedia != null) {
        imageUrl = await _uploadMedia(selectedMedia!, user.id);
      }

      if (existingPost != null) {
        // Update post
        await Supabase.instance.client
            .from('posts')
            .update({
              'content': text,
              'image_url': imageUrl,
              'media_type': mediaType,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingPost!['id']);
      } else {
        // Create new post
        await Supabase.instance.client.from('posts').insert({
          'user_id': user.id,
          'content': text,
          'image_url': imageUrl,
          'media_type': mediaType,
          'created_at': DateTime.now().toIso8601String(), // ✅ Important
        });
      }

      textController.clear();
      selectedMedia = null;
      mediaType = 'image';
      existingPost = null;
      isPosting = false;
      notifyListeners();

      return null; // success
    } catch (e) {
      isPosting = false;
      notifyListeners();
      return e.toString();
    }
  }
}
