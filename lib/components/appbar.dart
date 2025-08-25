import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final VoidCallback? onSignOut;

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
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final systemUiOverlayStyle =
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    // Combine provided actions with the dropdown menu
    final combinedActions = [...?actions, _buildDropdownMenu(context)];

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
              child: Container(
                child: Image.asset(
                  "assets/icons/live.png",
                  height: 28,
                  width: 28,
                  color: theme.colorScheme.primary,
                ),
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

  Widget _buildDropdownMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopupMenuButton<String>(
      elevation: 8,
      color: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(
        Icons.more_vert,
        color:
            theme.appBarTheme.actionsIconTheme?.color ??
            theme.colorScheme.primary,
      ),
      onSelected: (String value) {
        if (value == 'dark_mode' && onToggleDarkMode != null) {
          onToggleDarkMode!();
        } else if (value == 'sign_out' && onSignOut != null) {
          onSignOut!();
        }
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'dark_mode',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isDark ? 'Light Mode' : 'Dark Mode',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'sign_out',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign Out',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
