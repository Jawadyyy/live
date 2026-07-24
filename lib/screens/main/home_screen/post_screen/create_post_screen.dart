import 'dart:io';
import 'package:flutter/material.dart';
import 'package:live/screens/main/home_screen/post_screen/controller/create_post_controller.dart';
import 'package:provider/provider.dart';

class CreatePostScreen extends StatelessWidget {
  final Map<String, dynamic>? existingPost;
  const CreatePostScreen({super.key, this.existingPost});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostController(existingPost: existingPost),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatelessWidget {
  const _CreatePostView();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CreatePostController>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.existingPost != null ? "Edit Post" : "Create Post",
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Post Input Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: controller.textController,
                  maxLines: 5,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: "What's on your mind?",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Media Preview
            _MediaPreview(controller: controller),
            const SizedBox(height: 12),

            // Photo / Video picker buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text("Photo"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text("Video"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Floating Save Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: controller.isPosting
                ? null
                : () async {
                    final error = await controller.savePost();
                    if (error == null) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
            icon: controller.isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, size: 22),
            label: Text(
              controller.existingPost != null ? "Update" : "Post",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

/// Preview of the picked/existing media. Videos show a placeholder (no player
/// in the compose screen — kept lightweight); images render inline.
class _MediaPreview extends StatelessWidget {
  final CreatePostController controller;
  const _MediaPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final picked = controller.selectedMedia;
    final existingUrl = controller.existingPost?['image_url'];

    Widget wrap(Widget child) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        );

    if (picked != null) {
      if (controller.mediaType == 'video') return _videoPlaceholder(context);
      return wrap(Image.file(File(picked.path),
          height: 200, width: double.infinity, fit: BoxFit.cover));
    }
    if (existingUrl != null && existingUrl.toString().isNotEmpty) {
      if (controller.mediaType == 'video') return _videoPlaceholder(context);
      return wrap(Image.network(existingUrl,
          height: 200, width: double.infinity, fit: BoxFit.cover));
    }
    return const DottedBorderContainer();
  }

  Widget _videoPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text("Video selected",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

/// A modern dashed border container for image upload
class DottedBorderContainer extends StatelessWidget {
  const DottedBorderContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              "Tap to add an image",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
