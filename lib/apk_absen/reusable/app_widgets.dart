import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Skala tipografi: tebal dan rapat. Angka memakai tabular figures.
class AppText {
  AppText._();

  static TextStyle display(Color color) => TextStyle(
    color: color,
    fontSize: 40,
    height: 1.02,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.6,
  );

  static TextStyle title(Color color) => TextStyle(
    color: color,
    fontSize: 22,
    height: 1.15,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.7,
  );

  static TextStyle heading(Color color) => TextStyle(
    color: color,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static TextStyle body(Color color) => TextStyle(
    color: color,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static TextStyle caption(Color color) => TextStyle(
    color: color,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );

  static TextStyle figures(
    Color color, {
    double size = 14,
    FontWeight weight = FontWeight.w800,
  }) => TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Kotak dengan garis tepi tebal dan bayangan keras (tanpa blur).
class BrutalBox extends StatelessWidget {
  const BrutalBox({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.shadow = 4,
    this.borderWidth = 2,
    this.clip = false,
    this.expand = true,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double shadow;
  final double borderWidth;
  final bool clip;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Container(
      width: expand ? double.infinity : null,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.border, width: borderWidth),
        boxShadow: shadow <= 0
            ? null
            : [
                BoxShadow(
                  color: p.shadow,
                  offset: Offset(shadow, shadow),
                  blurRadius: 0,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Tombol tebal: saat ditekan, tombol "masuk" ke bayangannya.
class BrutalButton extends StatefulWidget {
  const BrutalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foreground,
    this.loading = false,
    this.height = 54,
    this.expand = true,
    this.alignStart = false,
    this.showArrow = false,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Kosong = warna primer (teks putih).
  final Color? color;
  final Color? foreground;
  final bool loading;
  final double height;
  final bool expand;
  final bool alignStart;
  final bool showArrow;
  final double fontSize;

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) {
      setState(() {
        _down = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    final enabled = widget.onPressed != null;
    final fill = widget.color ?? p.primary;
    final fg = widget.foreground ?? (widget.color == null ? p.onPrimary : p.onBlock);

    final pressed = _down && enabled;
    final offset = pressed ? 3.0 : 0.0;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: widget.alignStart
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 22, color: fg),
        if (widget.loading || widget.icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (widget.showArrow) ...[
          if (widget.alignStart) const Spacer(),
          if (!widget.alignStart) const SizedBox(width: 10),
          Icon(Icons.arrow_forward_rounded, size: 22, color: fg),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Opacity(
        opacity: enabled || widget.loading ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOut,
            width: widget.expand ? double.infinity : null,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            transform: Matrix4.translationValues(offset, offset, 0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
                  offset: Offset(4 - offset, 4 - offset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon persegi.
class BrutalIconButton extends StatelessWidget {
  const BrutalIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
    this.size = 46,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    final fill = color ?? p.surface;
    final fg = color == null ? p.ink : p.onBlock;

    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border, width: 2),
        boxShadow: [
          BoxShadow(color: p.shadow, offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: fg,
                    ),
                  )
                : Icon(icon, size: 22, color: fg),
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(message: tooltip!, child: button);
  }
}

/// Label kecil bergaya stiker.
class Sticker extends StatelessWidget {
  const Sticker({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.icon,
    this.angle = 0,
  });

  final String label;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final fg = textColor ?? p.onBlock;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (angle == 0) {
      return chip;
    }

    return Transform.rotate(angle: angle, child: chip);
  }
}

/// Kotak ikon berwarna dengan garis tepi.
class BlockIcon extends StatelessWidget {
  const BlockIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border, width: 2),
      ),
      child: Icon(icon, color: p.onBlock, size: iconSize),
    );
  }
}

/// Garis pemisah tebal.
class ThickDivider extends StatelessWidget {
  const ThickDivider({super.key, this.thickness = 2});

  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(height: thickness, color: AppColors.of(context).border);
  }
}

/// AppBar seragam: panah kembali, judul, dan garis tebal di bawahnya.
PreferredSizeWidget buildAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
}) {
  final p = AppColors.of(context);

  return AppBar(
    backgroundColor: p.bg,
    leading: IconButton(
      onPressed: () => Navigator.maybePop(context),
      tooltip: 'Kembali',
      icon: Icon(Icons.arrow_back_rounded, color: p.ink, size: 26),
    ),
    titleSpacing: 0,
    title: title,
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(2),
      child: Container(height: 2, color: p.border),
    ),
  );
}

/// Dialog konfirmasi bergaya brutalist.
Widget buildAppDialog(
  BuildContext context, {
  required String title,
  required String message,
  required List<Widget> actions,
}) {
  final p = AppColors.of(context);

  return Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    child: BrutalBox(
      radius: 20,
      shadow: 6,
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.title(p.ink)),
          const SizedBox(height: 8),
          Text(message, style: AppText.body(p.muted)),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                actions[i],
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
