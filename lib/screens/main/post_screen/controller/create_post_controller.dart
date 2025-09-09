import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class CreatePostController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  bool isPosting = false;

  /// Pick image from gallery
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage = File(image.path);
      notifyListeners();
    }
  }

  /// Upload image to Supabase Storage and return public URL
  Future<String?> _uploadImage(File file, String userId) async {
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";
    final storagePath = "posts/$userId/$fileName";

    // Upload to "post-images" bucket
    await Supabase.instance.client.storage
        .from('post-images')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // Get public URL
    final imageUrl = Supabase.instance.client.storage
        .from('post-images')
        .getPublicUrl(storagePath);
    return imageUrl;
  }

  /// Create a new post
  Future<String?> createPost() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "Not logged in";

    final text = textController.text.trim();
    if (text.isEmpty && selectedImage == null) {
      return "Write something or add an image!";
    }

    try {
      isPosting = true;
      notifyListeners();

      String? imageUrl;
      if (selectedImage != null) {
        imageUrl = await _uploadImage(selectedImage!, user.id);
      }

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'content': text,
        'image_url': imageUrl,
      });

      textController.clear();
      selectedImage = null;
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
