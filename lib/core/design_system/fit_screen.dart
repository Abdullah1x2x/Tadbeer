import 'package:flutter/material.dart';

/// يضع [child] بقدر الشاشة بلا تمرير: يأخذ العرض حتى [maxWidth] وارتفاعاً لا يقل عن
/// ارتفاع الشاشة، فإن طال عنها على هاتف صغير صغّره كله حتى يسعها.
class FitScreen extends StatelessWidget {
  /// أقصى عرض للمحتوى، يتوسط ما زاد عنه.
  final double maxWidth;
  final Widget child;

  const FitScreen({
    super.key,
    this.maxWidth = double.infinity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // يملأ ما أُعطي ولو كان القيد مرناً، فيتوسط المحتوى أفقياً.
      builder: (context, box) => SizedBox(
        width: box.maxWidth,
        height: box.maxHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: box.maxWidth < maxWidth ? box.maxWidth : maxWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
