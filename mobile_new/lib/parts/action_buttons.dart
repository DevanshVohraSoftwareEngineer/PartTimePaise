import 'package:flutter/material.dart';
import '../config/theme.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onNope;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final bool canUndo;

  const ActionButtons({
    Key? key,
    required this.onUndo,
    required this.onNope,
    required this.onSuperLike,
    required this.onLike,
    this.canUndo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo button
          _ActionButton(
            icon: Icons.undo,
            color: AppTheme.boostGold,
            onPressed: canUndo ? onUndo : null,
            size: 50,
            iconSize: 28,
          ),
          
          // Nope button
          _ActionButton(
            icon: Icons.close,
            color: AppTheme.nopeRed,
            onPressed: onNope,
            size: 60,
            iconSize: 32,
          ),
          
          // Super Like button
          _ActionButton(
            icon: Icons.star,
            color: AppTheme.superLikeBlue,
            onPressed: onSuperLike,
            size: 50,
            iconSize: 28,
          ),
          
          // Like button
          _ActionButton(
            icon: Icons.work,
            color: AppTheme.likeGreen,
            onPressed: onLike,
            size: 60,
            iconSize: 32,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.size,
    required this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDisabled ? AppTheme.grey300 : color,
            width: 3,
          ),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: isDisabled ? AppTheme.grey300 : color,
          size: iconSize,
        ),
      ),
    );
  }
}
