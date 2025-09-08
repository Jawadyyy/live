import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedImage; // placeholder for demo

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
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
                  controller: _textController,
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

            // Image Preview / Picker
            GestureDetector(
              onTap: () {
                // TODO: open image picker
                setState(() {
                  _selectedImage = "dummy_path"; // placeholder
                });
              },
              child:
                  _selectedImage == null
                      ? DottedBorderContainer()
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 200,
                          color: Colors.grey.shade300,
                          child: Center(
                            child: Text(
                              "Image preview here",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),

      // Floating Post Button
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
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty || _selectedImage != null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Post created!")));
              }
            },
            icon: const Icon(Icons.send, size: 22),
            label: const Text(
              "Post",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
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
