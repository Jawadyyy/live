import 'package:flutter/material.dart';
import 'package:live/components/appbar.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:live/components/chat_fab.dart';
import 'package:live/screens/main/chat_screen/search_screen/search_screen.dart';
import 'package:live/screens/main/chat_screen/message_screen/message_screen.dart';
import 'package:live/screens/main/chat_screen/message_screen/message_service/message_service.dart';
import 'package:provider/provider.dart';
import 'package:live/screens/main/controllers/friends_controller.dart';
import 'package:live/services/presence_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (_) => FriendsController()..fetchFriends(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: const Text('Chat'),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
          centerTitle: true,
          onToggleDarkMode: () async {
            final t = Provider.of<ThemeProvider>(context, listen: false);
            await t.toggleTheme(!t.isDarkMode);
          },
        ),
        body: Consumer<FriendsController>(
          builder: (context, controller, _) {
            final theme = Theme.of(context);
            final isDarkMode = theme.brightness == Brightness.dark;

            if (controller.isLoading && controller.friends.isEmpty) {
              return Center(
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double v, _) => Transform.scale(
                    scale: v,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C56E1).withOpacity(0.2 * v),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF7C56E1)),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (controller.friends.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.fetchFriends,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                    _EmptyStateWidget(isDarkMode: isDarkMode, theme: theme),
                  ],
                ),
              );
            }

            final filtered = controller.friends
                .where((f) => (f['username'] ?? '')
                    .toLowerCase()
                    .contains(controller.searchQuery.toLowerCase()))
                .toList();

            return Column(children: [
              _SearchBar(
                  isDarkMode: isDarkMode, onChanged: controller.updateSearch),
              _FriendCounter(
                count: filtered.length,
                hasSearchQuery: controller.searchQuery.isNotEmpty,
                isDarkMode: isDarkMode,
                onClear: () => controller.updateSearch(''),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.fetchFriends,
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.12),
                            _NoResultsWidget(
                                isDarkMode: isDarkMode, theme: theme),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _ChatListItem(
                            friend: filtered[index],
                            index: index,
                          ),
                        ),
                ),
              ),
            ]);
          },
        ),
        floatingActionButton: const ChatFab(searchScreen: SearchScreen()),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.isDarkMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.6)
                    ]
                  : [const Color(0xFFF3F0FF), const Color(0xFFEDE9FF)]),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C56E1).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search friends...',
            hintStyle: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF888888),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              child: const Icon(Icons.search_rounded,
                  color: Color(0xFF7C56E1), size: 22),
            ),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                  color: const Color(0xFF7C56E1).withOpacity(0.3), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Color(0xFF7C56E1), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _FriendCounter extends StatelessWidget {
  final int count;
  final bool hasSearchQuery;
  final bool isDarkMode;
  final VoidCallback onClear;
  const _FriendCounter(
      {required this.count,
      required this.hasSearchQuery,
      required this.isDarkMode,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '$count Friend${count != 1 ? 's' : ''}',
              key: ValueKey(count),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? const Color(0xFFB0B0B0)
                    : const Color(0xFF666666),
              ),
            ),
          ),
          if (hasSearchQuery)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C56E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Clear',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C56E1),
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final bool isDarkMode;
  final ThemeData theme;
  const _EmptyStateWidget({required this.isDarkMode, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                const Color(0xFF7C56E1).withOpacity(0.1),
                const Color(0xFF7C56E1).withOpacity(0.05),
              ]),
            ),
            child: const Icon(Icons.people_outline,
                size: 50, color: Color(0xFF7C56E1)),
          ),
          const SizedBox(height: 24),
          Text('No Friends Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.primaryColor,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 12),
          Text('Add friends to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:
                      isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600],
                  fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C56E1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 3,
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person_add, size: 18),
              SizedBox(width: 8),
              Text('Find Friends'),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _NoResultsWidget extends StatelessWidget {
  final bool isDarkMode;
  final ThemeData theme;
  const _NoResultsWidget({required this.isDarkMode, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded,
              size: 60, color: const Color(0xFF7C56E1).withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No results found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryColor)),
          const SizedBox(height: 8),
          Text('Try searching with a different name',
              style: TextStyle(
                  color:
                      isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600])),
        ]),
      ),
    );
  }
}

// Caches streams per friend so they're created once, not on every rebuild
final _streamCache = <String, Stream<Map<String, dynamic>?>>{};

class _ChatListItem extends StatefulWidget {
  final Map<String, dynamic> friend;
  final int index;
  const _ChatListItem({required this.friend, required this.index});

  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Stream<Map<String, dynamic>?> _stream;
  Map<String, dynamic>? _cachedMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    final friendId = widget.friend['id'] as String;
    _stream = _streamCache.putIfAbsent(
      friendId,
      () => MessageService().getLastMessageStream(friendId),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _stream,
      builder: (context, snap) {
        // Cache last message so it shows instantly on rebuild
        if (snap.hasData) _cachedMessage = snap.data;

        final lastMessage = _cachedMessage;
        final isNewChat = lastMessage == null;
        final isSentByMe = lastMessage?['sender_id'] == currentUserId;
        final messageType = lastMessage?['message_type'] ?? 'text';
        String content;
        if (isNewChat) {
          content = 'Start a conversation';
        } else if (messageType == 'image') {
          content = '📷 Photo';
        } else if (messageType == 'file') {
          content = '📎 ${lastMessage?['file_name'] ?? 'File'}';
        } else {
          content = lastMessage?['content'] ?? '';
        }

        final timestamp = lastMessage?['created_at'] != null
            ? DateTime.parse(lastMessage!['created_at']).toLocal()
            : null;
        final hasUnread =
            !isNewChat && !isSentByMe && (lastMessage?['is_read'] == false);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MessageScreen(friend: widget.friend))),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: hasUnread
                        ? [
                            const Color(0xFF7C56E1).withOpacity(0.08),
                            const Color(0xFF7C56E1).withOpacity(0.04)
                          ]
                        : [
                            theme.cardColor,
                            isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.white
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasUnread
                        ? const Color(0xFF7C56E1).withOpacity(0.3)
                        : isDarkMode
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.05),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                      spreadRadius: 0.5,
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(isDarkMode, theme),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildContent(
                      theme,
                      isDarkMode,
                      content,
                      isNewChat,
                      timestamp,
                      hasUnread,
                      isSentByMe,
                    )),
                    const SizedBox(width: 12),
                    _buildChevron(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(bool isDarkMode, ThemeData theme) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Hero(
          tag: 'avatar_${widget.friend['id']}',
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C56E1), Color(0xFFA37BFF)]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C56E1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 26,
                backgroundImage: widget.friend['avatar_url'] != null
                    ? NetworkImage(widget.friend['avatar_url'])
                    : null,
                backgroundColor:
                    isDarkMode ? Colors.black.withOpacity(0.8) : Colors.white,
                child: widget.friend['avatar_url'] == null
                    ? Text(widget.friend['username']?[0]?.toUpperCase() ?? '?',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C56E1)))
                    : null,
              ),
            ),
          ),
        ),
        // Online dot — shown only while the friend is actually online.
        ValueListenableBuilder<Set<String>>(
          valueListenable: PresenceService.instance.online,
          builder: (_, ids, __) {
            if (!ids.contains(widget.friend['id'])) {
              return const SizedBox.shrink();
            }
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green
                          .withOpacity(0.5 + (0.3 * _pulseController.value)),
                      blurRadius: 6 + (4 * _pulseController.value),
                      spreadRadius: 1 * _pulseController.value,
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, bool isDarkMode, String content,
      bool isNewChat, DateTime? timestamp, bool hasUnread, bool isSentByMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.friend['username'] ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 0.3,
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.4)
                      : const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(timeago.format(timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: isDarkMode
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF7C56E1),
                    )),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(children: [
          if (!isNewChat && isSentByMe)
            Text('You: ',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? const Color(0xFF7C56E1).withOpacity(0.8)
                      : const Color(0xFF7C56E1),
                )),
          Expanded(
            child: Text(
              content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                color: isNewChat
                    ? const Color(0xFF7C56E1)
                    : isDarkMode
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF666666),
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                fontStyle: isNewChat ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C56E1), Color(0xFFA37BFF)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF7C56E1).withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Text('New',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  )),
            ),
          ],
        ]),
      ],
    );
  }

  Widget _buildChevron() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF7C56E1).withOpacity(0.1),
            const Color(0xFF7C56E1).withOpacity(0.05),
          ]),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chevron_right_rounded,
            size: 20, color: Color(0xFF7C56E1)),
      );
}
