import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateStreamScreen extends StatefulWidget {
  const CreateStreamScreen({super.key});
  @override
  State<CreateStreamScreen> createState() => _CreateStreamScreenState();
}

class _CreateStreamScreenState extends State<CreateStreamScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  File? _thumbnail;
  String _status = 'live';
  bool _isLoading = false;

  static const _purple = Color(0xFF7C56E1);

  Future<void> _pickThumbnail() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked != null && mounted)
      setState(() => _thumbnail = File(picked.path));
  }

  Future<String?> _uploadThumbnail() async {
    if (_thumbnail == null) return null;
    final userId = _supabase.auth.currentUser!.id;
    final path =
        'thumbnails/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from('stream-assets').upload(path, _thumbnail!,
        fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return _supabase.storage.from('stream-assets').getPublicUrl(path);
  }

  Future<void> _goLive() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final thumbnailUrl = await _uploadThumbnail();
      await _supabase.from('streams').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'thumbnail_url': thumbnailUrl,
        'status': _status,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_status == 'live'
              ? '🔴 You are now live!'
              : '📅 Stream scheduled!'),
          backgroundColor: _status == 'live' ? Colors.red : _purple,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Go Live',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Thumbnail picker
            GestureDetector(
              onTap: _pickThumbnail,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFF3F0FF),
                  border: Border.all(
                    color:
                        _thumbnail != null ? _purple : _purple.withOpacity(0.3),
                    width: _thumbnail != null ? 2 : 1.5,
                  ),
                  image: _thumbnail != null
                      ? DecorationImage(
                          image: FileImage(_thumbnail!), fit: BoxFit.cover)
                      : null,
                ),
                child: _thumbnail == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _purple.withOpacity(0.12),
                              ),
                              child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 28,
                                  color: _purple),
                            ),
                            const SizedBox(height: 12),
                            const Text('Add Thumbnail',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _purple,
                                  fontSize: 15,
                                )),
                            const SizedBox(height: 4),
                            Text('Optional — tap to upload',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                )),
                          ])
                    : Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: GestureDetector(
                            onTap: () => setState(() => _thumbnail = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Stream type toggle
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color:
                    isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F0FF),
              ),
              child: Row(children: [
                _StatusTab(
                    label: '🔴  Go Live',
                    value: 'live',
                    selected: _status == 'live',
                    onTap: () => setState(() => _status = 'live')),
                _StatusTab(
                    label: '📅  Schedule',
                    value: 'scheduled',
                    selected: _status == 'scheduled',
                    onTap: () => setState(() => _status = 'scheduled')),
              ]),
            ),

            const SizedBox(height: 24),

            // Title
            _buildLabel('Stream Title *'),
            const SizedBox(height: 8),
            _buildField(
              controller: _titleController,
              hint: "What's your stream about?",
              maxLines: 1,
              isDark: isDark,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),

            const SizedBox(height: 20),

            // Description
            _buildLabel('Description'),
            const SizedBox(height: 8),
            _buildField(
              controller: _descController,
              hint: 'Tell viewers what to expect...',
              maxLines: 4,
              isDark: isDark,
            ),

            const SizedBox(height: 32),

            // Tips card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _purple.withOpacity(0.08),
                border: Border.all(color: _purple.withOpacity(0.2)),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.tips_and_updates_rounded,
                    color: _purple, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tips for a great stream',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _purple,
                              fontSize: 13,
                            )),
                        const SizedBox(height: 6),
                        ...[
                          'Use a catchy, descriptive title',
                          'Add a thumbnail to attract viewers',
                          'Make sure your connection is stable',
                        ].map((t) => Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(children: [
                                Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: Colors.grey[500],
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(t,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              ]),
                            )),
                      ]),
                ),
              ]),
            ),

            const SizedBox(height: 32),

            // Go live button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _goLive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _status == 'live' ? Colors.red : _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(
                                _status == 'live'
                                    ? Icons.live_tv_rounded
                                    : Icons.event_rounded,
                                size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _status == 'live'
                                  ? 'Start Streaming'
                                  : 'Schedule Stream',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ));

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
          fontSize: 15, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F6FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _purple.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _purple.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _StatusTab(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? const Color(0xFF7C56E1) : Colors.transparent,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : Colors.grey[600],
              )),
        ),
      ),
    );
  }
}
