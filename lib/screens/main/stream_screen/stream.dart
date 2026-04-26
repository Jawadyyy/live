import 'package:flutter/material.dart';
import 'package:live/components/appbar.dart';
import 'package:live/components/stream_fab.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:live/screens/main/stream_screen/create_stream_screen.dart';
import 'package:live/screens/main/stream_screen/watch_stream_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class StreamScreen extends StatefulWidget {
  const StreamScreen({super.key});
  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _streamsStream(String status) {
    return _supabase
        .from('streams')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((d) => d.where((s) => s['status'] == status).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Stream'),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        centerTitle: true,
        onToggleDarkMode: () async {
          final t = Provider.of<ThemeProvider>(context, listen: false);
          await t.toggleTheme(!t.isDarkMode);
        },
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F0FF),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF7C56E1),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: '🔴  Live Now'),
              Tab(text: '📅  Scheduled'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _StreamList(
                  stream: _streamsStream('live'),
                  status: 'live',
                  isDark: isDark),
              _StreamList(
                  stream: _streamsStream('scheduled'),
                  status: 'scheduled',
                  isDark: isDark),
            ],
          ),
        ),
      ]),
      floatingActionButton: StreamFab(),
    );
  }
}

// ── Stream List ───────────────────────────────────────────
class _StreamList extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> stream;
  final String status;
  final bool isDark;

  const _StreamList(
      {required this.stream, required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C56E1)));
        }
        if (snap.hasError) {
          return _EmptyStreams(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: snap.error.toString(),
            isDark: isDark,
          );
        }
        final streams = snap.data ?? [];
        if (streams.isEmpty) {
          return _EmptyStreams(
            icon:
                status == 'live' ? Icons.live_tv_rounded : Icons.event_rounded,
            title: status == 'live' ? 'No live streams' : 'Nothing scheduled',
            subtitle: status == 'live'
                ? 'Be the first to go live!'
                : 'No upcoming streams yet.',
            isDark: isDark,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: streams.length,
          itemBuilder: (_, i) =>
              _StreamCard(stream: streams[i], isDark: isDark),
        );
      },
    );
  }
}

// ── Stream Card ───────────────────────────────────────────
class _StreamCard extends StatelessWidget {
  final Map<String, dynamic> stream;
  final bool isDark;

  const _StreamCard({required this.stream, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLive = stream['status'] == 'live';
    final createdAt = DateTime.tryParse(stream['created_at'] ?? '')?.toLocal();
    final viewerCount = stream['viewer_count'] ?? 0;

    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('users')
          .select('username, avatar_url')
          .eq('id', stream['user_id'])
          .maybeSingle(),
      builder: (context, snap) {
        final user = snap.data ?? {};
        final username = user['username'] ?? 'Unknown';
        final avatarUrl = user['avatar_url'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            border: Border.all(
              color: isLive
                  ? const Color(0xFF7C56E1).withOpacity(0.3)
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05)),
            ),
            boxShadow: [
              BoxShadow(
                color: isLive
                    ? const Color(0xFF7C56E1).withOpacity(0.12)
                    : Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: isLive
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WatchStreamScreen(streamData: stream),
                        ),
                      );
                    }
                  : null,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Stack(children: [
                        stream['thumbnail_url'] != null
                            ? Image.network(
                                stream['thumbnail_url'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _ThumbnailPlaceholder(isDark: isDark),
                              )
                            : _ThumbnailPlaceholder(isDark: isDark),

                        // Live badge
                        if (isLive)
                          Positioned(
                              top: 12,
                              left: 12,
                              child: _LiveBadge(viewerCount: viewerCount)),

                        // Scheduled badge
                        if (!isLive)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      createdAt != null
                                          ? timeago.format(createdAt)
                                          : 'Soon',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ]),
                            ),
                          ),

                        // Dark gradient at bottom of thumbnail
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),

                    // Info
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  Color(0xFF7C56E1),
                                  Color(0xFFA37BFF)
                                ]),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: isDark
                                    ? const Color(0xFF1A1A2E)
                                    : Colors.white,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Text(username[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: Color(0xFF7C56E1),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13))
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stream['title'] ?? 'Untitled Stream',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(username,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        )),
                                    if (stream['description'] != null &&
                                        stream['description']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          stream['description'],
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                              height: 1.4),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ]),
                            ),
                          ]),
                    ),
                  ]),
            ),
          ),
        );
      },
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  final bool isDark;
  const _ThumbnailPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D1B69), const Color(0xFF1A1040)]
              : [const Color(0xFFEDE9FF), const Color(0xFFD4C8FF)],
        ),
      ),
      child: Center(
        child: Icon(Icons.live_tv_rounded,
            size: 48, color: const Color(0xFF7C56E1).withOpacity(0.4)),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  final int viewerCount;
  const _LiveBadge({required this.viewerCount});
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this)
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Opacity(
            opacity: _pulse.value,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Text('LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            )),
        if (widget.viewerCount > 0) ...[
          const SizedBox(width: 6),
          Container(width: 1, height: 10, color: Colors.white38),
          const SizedBox(width: 6),
          Text('${widget.viewerCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
        ],
      ]),
    );
  }
}

class _EmptyStreams extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  const _EmptyStreams(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7C56E1).withOpacity(0.1),
          ),
          child: Icon(icon, size: 44, color: const Color(0xFF7C56E1)),
        ),
        const SizedBox(height: 20),
        Text(title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            )),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ]),
    );
  }
}
