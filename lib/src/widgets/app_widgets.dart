import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ScreenPadding extends StatelessWidget {
  const ScreenPadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 720 ? 18.0 : 28.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 28),
          child: child,
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppTheme.primary,
    this.subtitle,
    super.key,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class SoftPanel extends StatelessWidget {
  const SoftPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 8,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    this.size = 96,
    this.color = AppTheme.primary,
    this.inverse = false,
    this.showRing = false,
    super.key,
  });

  final double size;
  final Color color;
  final bool inverse;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final markColor = inverse ? Colors.white : color;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showRing)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: markColor.withValues(alpha: 0.78),
                  width: 1.4,
                ),
              ),
            ),
          Container(
            width: showRing ? size * 0.64 : size,
            height: showRing ? size * 0.64 : size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: inverse
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.32),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
            ),
            child: CustomPaint(
              painter: _StockEaseMarkPainter(markColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockEaseMarkPainter extends CustomPainter {
  const _StockEaseMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    final outer = Path()
      ..moveTo(w * 0.18, h * 0.22)
      ..lineTo(w * 0.84, h * 0.22)
      ..lineTo(w * 0.34, h * 0.90)
      ..lineTo(w * 0.26, h * 0.72)
      ..lineTo(w * 0.54, h * 0.36)
      ..lineTo(w * 0.26, h * 0.36)
      ..close();
    canvas.drawPath(outer, paint);

    final cutPaint = Paint()
      ..color = inverseFillFor(color)
      ..style = PaintingStyle.fill;

    final stripe1 = Path()
      ..moveTo(w * 0.28, h * 0.39)
      ..lineTo(w * 0.57, h * 0.39)
      ..lineTo(w * 0.51, h * 0.48)
      ..lineTo(w * 0.34, h * 0.48)
      ..close();
    final stripe2 = Path()
      ..moveTo(w * 0.35, h * 0.54)
      ..lineTo(w * 0.48, h * 0.54)
      ..lineTo(w * 0.42, h * 0.63)
      ..lineTo(w * 0.31, h * 0.63)
      ..close();
    canvas.drawPath(stripe1, cutPaint);
    canvas.drawPath(stripe2, cutPaint);
  }

  static Color inverseFillFor(Color color) {
    return color == Colors.white ? AppTheme.primaryDark : Colors.white;
  }

  @override
  bool shouldRepaint(covariant _StockEaseMarkPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class FloatingIconField extends StatelessWidget {
  const FloatingIconField({
    required this.controller,
    required this.icon,
    required this.labelText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.enabled = true,
    this.inputFormatters,
    super.key,
  });

  final TextEditingController controller;
  final IconData icon;
  final String labelText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(-10, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.13),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                obscureText: obscureText,
                validator: validator,
                onFieldSubmitted: onFieldSubmitted,
                inputFormatters: inputFormatters,
                decoration: InputDecoration(
                  labelText: labelText,
                  contentPadding: const EdgeInsets.fromLTRB(28, 14, 16, 14),
                  suffixIcon: suffixIcon,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider(color: AppTheme.line)),
      ],
    );
  }
}

class SocialButtonRow extends StatelessWidget {
  const SocialButtonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(label: 'G', color: Color(0xFF4285F4)),
        SizedBox(width: 18),
        _SocialButton(label: 'f', color: Color(0xFF315AA9)),
        SizedBox(width: 18),
        _SocialButton(label: 't', color: AppTheme.primary),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppTheme.softShadow,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class ResponsiveCards extends StatelessWidget {
  const ResponsiveCards({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 760
                ? 3
                : width >= 520
                    ? 2
                    : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: width < 520 ? 2.2 : 1.45,
          children: children,
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: AppTheme.primary),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: error.toString(),
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {this.style, super.key});

  final num value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(formatMoney(value), style: style);
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge(
      {required this.quantity, required this.threshold, super.key});

  final int quantity;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final isOut = quantity <= 0;
    final isLow = !isOut && quantity <= threshold;
    final color = isOut
        ? AppTheme.danger
        : isLow
            ? AppTheme.warning
            : AppTheme.success;
    final label = isOut
        ? 'Out of stock'
        : isLow
            ? 'Low stock'
            : 'In stock';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $quantity',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    required this.points,
    this.height = 220,
    this.valueFormatter = formatMoney,
    super.key,
  });

  final List<dynamic> points;
  final double height;
  final String Function(num value) valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart,
        title: 'No chart data',
        message: 'Completed sales will appear here.',
      );
    }

    final maxValue = points
        .map<double>((point) => (point.value as num).toDouble())
        .fold<double>(0, (max, value) => value > max ? value : max);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      valueFormatter(point.value as num),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: maxValue == 0
                            ? 0.04
                            : ((point.value as num) / maxValue)
                                .clamp(0.04, 1)
                                .toDouble(),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      point.label.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.danger : AppTheme.primaryDark,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
