import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;
  final Color? backgroundColor;
  final double elevation;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final double toolbarHeight;
  final bool automaticallyImplyLeading;
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
    this.showBackButton = true,
    this.backgroundColor,
    this.elevation = 1,
    this.onBackPressed,
    this.leading,
    this.toolbarHeight = kToolbarHeight,
    this.automaticallyImplyLeading = true,
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
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading:
            leading ??
            (showBackButton && Navigator.of(context).canPop()
                ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
                : null),
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

    return PopupMenuButton<String>(
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
                  Icon(
                    theme.brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    theme.brightness == Brightness.dark
                        ? 'Light Mode'
                        : 'Dark Mode',
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'sign_out',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Sign Out',
                    style: TextStyle(color: theme.colorScheme.error),
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
