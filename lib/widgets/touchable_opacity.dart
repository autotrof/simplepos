import 'package:flutter/material.dart';

class TouchableOpacity extends StatelessWidget {
  double? width;
  double? height;
  final double border;
  final double borderRadius;
  final void Function()? onTap;
  MaterialColor theme;
  final Widget child;
  final bool disabled;
  final bool withBorder;

  TouchableOpacity({
    super.key, 
    this.width,
    this.height,
    this.border = 0.75, 
    this.borderRadius = 0, 
    this.onTap, 
    this.disabled = false,
    this.theme = Colors.grey,
    required this.child,
    this.withBorder = true
  });

  @override
  Widget build(BuildContext context) {
    if (disabled) theme = Colors.grey;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(border: Border.all(width: withBorder ? border : 0, color: theme[500]!), borderRadius: BorderRadius.circular(borderRadius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: theme[100],
          surfaceTintColor: disabled ? theme[100] : theme[200],
          type: MaterialType.button,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            mouseCursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
            focusColor: disabled ? theme[100] : theme[200],
            highlightColor: disabled ? theme[100] : theme[200],
            hoverColor: disabled ? theme[100] : theme[200],
            splashColor: disabled ? theme[100] : theme[300],
            onTap: () {
              if (!disabled && onTap != null) {
                onTap!();
              }
            },
            child: child
          )
        )
      )
    );
  }

}