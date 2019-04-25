import 'package:flutter/material.dart';

class IconButtonNew extends StatefulWidget {
  const IconButtonNew({
    @required this.icon,
    @required this.onPressed,
    @required this.iconSize,
    @required this.color,
    this.width,
    this.alignment = Alignment.center,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color color;
  final double width;
  final Alignment alignment;

  @override
  _IconButtonNewState createState() => _IconButtonNewState();
}

class _IconButtonNewState extends State<IconButtonNew> {
  double _opacity = 1.0;

  void _pressDown(details) => setState(() => _opacity = 0.6);

  void _cancel() => setState(() => _opacity = 1.0);

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: _pressDown,
      onTapUp: (_) => _cancel(),
      onTapCancel: _cancel,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.width ?? 48.0,
          minHeight: 48.0,
        ),
        child: AnimatedOpacity(
          opacity: _opacity,
          curve: Curves.fastOutSlowIn,
          duration: Duration(milliseconds: 250),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: widget.iconSize,
              width: widget.iconSize,
              child: Align(
                alignment: widget.alignment,
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
