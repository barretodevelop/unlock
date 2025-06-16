// lib/widgets/common/custom_button.dart
import 'package:flutter/material.dart';
import 'package:unlock/widgets/animated/bounce_widget.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final bool isOutlined;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.width,
    this.height,
    this.padding,
    this.isLoading = false,
    this.isOutlined = false,
    this.borderRadius = 16,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    Widget buttonChild = _buildButtonContent(theme);

    if (isOutlined) {
      return _buildOutlinedButton(theme, buttonChild);
    }

    return _buildFilledButton(theme, buttonChild, isEnabled);
  }

  Widget _buildButtonContent(ThemeData theme) {
    final effectiveTextColor =
        textColor ??
        (gradient != null || backgroundColor != null
            ? Colors.white
            : theme.colorScheme.onPrimary);

    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(color: effectiveTextColor, size: 20),
            child: icon!,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        color: effectiveTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFilledButton(ThemeData theme, Widget child, bool isEnabled) {
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.primary;

    return BounceWidget(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height ?? 56,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: gradient == null ? effectiveBackgroundColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isEnabled
              ? (boxShadow ??
                    [
                      BoxShadow(
                        color:
                            (gradient?.colors.first ?? effectiveBackgroundColor)
                                .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ])
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(alignment: Alignment.center, child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(ThemeData theme, Widget child) {
    final borderColor =
        gradient?.colors.first ?? backgroundColor ?? theme.colorScheme.primary;

    return BounceWidget(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height ?? 56,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(alignment: Alignment.center, child: child),
          ),
        ),
      ),
    );
  }
}

// Variações específicas do botão

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isOutlined: true,
      backgroundColor: theme.colorScheme.primary,
      textColor: theme.colorScheme.primary,
    );
  }
}

class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  const SuccessButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ),
    );
  }
}

class WarningButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  const WarningButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      ),
    );
  }
}
