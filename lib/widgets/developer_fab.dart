import 'package:flutter/material.dart';

/// Minecraft-style `</>` floating button that opens Developer Mode; shows a
/// redstone badge while the console holds errors.
class DeveloperFab extends StatelessWidget {
  const DeveloperFab(
      {super.key, required this.errorCount, required this.onPressed});

  final int errorCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return FloatingActionButton(
      backgroundColor: dark ? const Color(0xFF181D19) : Colors.white,
      foregroundColor: colors.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: dark ? const Color(0xFF39423A) : const Color(0xFFC9C2AD),
          width: 2,
        ),
      ),
      onPressed: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Text(
              '</>',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFFE8642B),
              ),
            ),
          ),
          if (errorCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFD9483F),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  errorCount > 9 ? '9+' : '$errorCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
