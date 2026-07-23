import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:live/screens/main/controllers/notifications_controller.dart';
import 'package:live/screens/main/notification_screen/notification_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final Widget? leading;
  final double toolbarHeight;
  final double? titleSpacing;
  final TextStyle? titleTextStyle;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final VoidCallback? onToggleDarkMode;
  final VoidCallback? onNotificationTap;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 1,
    this.leading,
    this.toolbarHeight = kToolbarHeight,
    this.titleSpacing,
    this.titleTextStyle,
    this.gradient,
    this.borderRadius,
    this.onToggleDarkMode,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final systemUiOverlayStyle =
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    final combinedActions = [
      ...?actions,
      _NotificationButton(
        onTap: onNotificationTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.zero,
        gradient: gradient,
        color:
            gradient == null
                ? backgroundColor ?? theme.appBarTheme.backgroundColor
                : null,
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
        ],
      ),
      child: AppBar(
        systemOverlayStyle: systemUiOverlayStyle,
        automaticallyImplyLeading: false,
        leading:
            leading ??
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Image.asset(
                "assets/icons/live.png",
                height: 28,
                width: 28,
                color: theme.colorScheme.primary,
              ),
            ),
        title:
            title != null
                ? DefaultTextStyle(
                  style: (titleTextStyle ??
                          theme.appBarTheme.titleTextStyle ??
                          theme.textTheme.titleLarge!)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            theme.appBarTheme.titleTextStyle?.color ??
                            theme.textTheme.titleLarge?.color,
                      ),
                  child: title!,
                )
                : null,
        actions: combinedActions,
        centerTitle: centerTitle,
        elevation: 0,
        titleSpacing: titleSpacing,
        toolbarHeight: toolbarHeight,
        flexibleSpace:
            gradient != null
                ? Container(decoration: BoxDecoration(gradient: gradient))
                : null,
        shape:
            borderRadius != null
                ? RoundedRectangleBorder(borderRadius: borderRadius!)
                : null,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}

// Bell icon with a live unread-count badge (friend requests + activity).
class _NotificationButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NotificationButton({required this.onTap});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  final _controller = NotificationsController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _controller.fetch();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _controller.unreadCount;
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      child: IconButton(
        icon: Icon(
          Icons.notifications_outlined,
          color: theme.colorScheme.primary,
        ),
        onPressed: widget.onTap,
      ),
    );
  }
}
