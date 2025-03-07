import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import '../../components/misc/DividerNew.dart';
import '../../styles/theme.dart';
import '../../db/GameData.dart';

class _KeyHint extends StatefulWidget {
  const _KeyHint({this.hint, this.visible, this.child});

  final String hint;
  final bool visible;
  final Widget child;

  @override
  _KeyHintState createState() => _KeyHintState();
}

class _KeyHintState extends State<_KeyHint>
    with SingleTickerProviderStateMixin {
  static final GameData _gameData = GameData();
  OverlayEntry _overlay;
  bool _shouldRemove = false;

  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: keyHintOpacityDuration),
        vsync: this)
      ..addStatusListener(_handleStatusChanged);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _removeEntry();
  }

  @override
  void deactivate() {
    _controller.reverse();
    super.deactivate();
  }

  void _removeEntry() {
    if (_overlay != null) {
      _overlay.remove();
      _overlay = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (_overlay != null) _overlay.remove();
    _overlay = this._createKeyHint();
    Overlay.of(context).insert(_overlay);
  }

  void _removeOverlay() async {
    _shouldRemove = true;
    _controller.reverse();
    await Future.delayed(const Duration(milliseconds: keyHintOpacityDuration));
    if (_shouldRemove) _removeEntry();
  }

  @override
  void didUpdateWidget(_KeyHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.visible && oldWidget.visible)
      _removeOverlay();
    else if (widget.visible && !oldWidget.visible) {
      _shouldRemove = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_overlay == null) {
          _overlay = this._createKeyHint();
          Overlay.of(context).insert(_overlay);
        }
        _controller.forward();
      });
    }
    if (widget.hint != oldWidget.hint && widget.visible && oldWidget.visible)
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  OverlayEntry _createKeyHint() {
    RenderBox renderBox = context.findRenderObject();
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    Widget _child;
    final String _hintText = widget.hint;
    if ((_hintText == 'i' || _hintText == 'u') ||
        (_hintText.length > 1 &&
            _hintText.endsWith('a') &&
            !(_hintText.endsWith('aa') ||
                _hintText.endsWith('ii') ||
                _hintText.endsWith('uu')))) {
      String _substring = _hintText.substring(0, _hintText.length - 1);
      if (_hintText == 'i')
        _substring = 'y';
      else if (_hintText == 'u')
        _substring = 'w';
      final String _i = _substring + 'i';
      final String _u = _substring + 'u';

      _child = Column(
        children: <Widget>[
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                _i,
                textAlign: TextAlign.center,
                style: _gameData.getStyle('kulitanKeyboard'),
              ),
            ),
          ),
          SizedBox(
            height: size.height * keyHintASizeRatio,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                _hintText,
                textAlign: TextAlign.center,
                style: _gameData.getStyle('kulitanKeyboard'),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                _u,
                textAlign: TextAlign.center,
                style: _gameData.getStyle('kulitanKeyboard'),
              ),
            ),
          ),
        ],
      );
    } else {
      _child = FittedBox(
        fit: BoxFit.contain,
        child: Text(
          _hintText,
          textAlign: TextAlign.center,
          style: _gameData.getStyle('kulitanKeyboard'),
        ),
      );
    }

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          left:
              offset.dx + ((size.width - (keyHintSizeRatio * size.height)) / 2),
          top: offset.dy - size.height - keyHintTopOffset,
          child: FadeTransition(
            opacity:
                Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
              parent: _controller,
              curve: keyHintOpacityCurve,
            )),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: _hintText == 'a' ||
                        _hintText == 'aa' ||
                        _hintText == 'ii' ||
                        _hintText == 'uu'
                    ? const EdgeInsets.all(keyHintPadding + 10.0)
                    : const EdgeInsets.all(keyHintPadding),
                height: keyHintSizeRatio * size.height,
                width: keyHintSizeRatio * size.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: _gameData.getColor('keyboardKeyHint'),
                ),
                child: _child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _KeyboardKey extends StatefulWidget {
  const _KeyboardKey({this.keyType, this.height, this.keyPressed});

  final String keyType;
  final double height;
  final Function keyPressed;

  @override
  _KeyboardKeyState createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<_KeyboardKey> {
  static final GameData _gameData = GameData();

  double _startPos = 0.0;
  double _endPos = 0.0;
  bool _half1Pressed = false;
  bool _half2Pressed = false;
  Timer _deleteLongPressTimer;

  String _keyHintText = '';
  RenderBox _renderBox;

  @override
  void initState() {
    super.initState();
    if (widget.keyType == 'a')
      _keyHintText = 'a';
    else if (widget.keyType == 'i')
      _keyHintText = 'i';
    else if (widget.keyType == 'u')
      _keyHintText = 'u';
    else
      _keyHintText = widget.keyType + 'a';
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _renderBox = context.findRenderObject());
  }

  void _pressHighlight({bool top, bool bottom}) {
    if (top && !_half1Pressed)
      setState(() => _half1Pressed = true);
    else if (!top && _half1Pressed) setState(() => _half1Pressed = false);
    if (bottom && !_half2Pressed)
      setState(() => _half2Pressed = true);
    else if (!bottom && _half2Pressed) setState(() => _half2Pressed = false);
  }

  void _dragStart(DragStartDetails details) {
    if (widget.keyType != 'a') _startPos = details.globalPosition.dy;
    _pressHighlight(top: true, bottom: true);
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (widget.keyType == 'a') {
      if (_renderBox.paintBounds
          .contains(_renderBox.globalToLocal(details.globalPosition)))
        _pressHighlight(top: true, bottom: true);
      else
        _pressHighlight(top: false, bottom: false);
    } else {
      _endPos = details.globalPosition.dy;
      if (_startPos - (keyboardKeyMiddleZoneHeight / 2.0) <= _endPos &&
          _endPos <= _startPos + (keyboardKeyMiddleZoneHeight / 2.0)) {
        if (!_keyHintText.endsWith('a')) {
          if (widget.keyType == 'i')
            setState(() => _keyHintText = 'i');
          else if (widget.keyType == 'u')
            setState(() => _keyHintText = 'u');
          else
            setState(() => _keyHintText = widget.keyType + 'a');
        }
        _pressHighlight(top: true, bottom: true);
      } else if (_startPos > _endPos) {
        if (widget.keyType == 'i')
          setState(() => _keyHintText = 'yi');
        else if (widget.keyType == 'u')
          setState(() => _keyHintText = 'wi');
        else
          setState(() => _keyHintText = widget.keyType + 'i');
        _pressHighlight(top: true, bottom: false);
      } else {
        if (widget.keyType == 'i')
          setState(() => _keyHintText = 'yu');
        else if (widget.keyType == 'u')
          setState(() => _keyHintText = 'wu');
        else
          setState(() => _keyHintText = widget.keyType + 'u');
        _pressHighlight(top: false, bottom: true);
      }
    }
  }

  void _dragEnd(DragEndDetails details) {
    if (widget.keyType == 'a') {
      if (_half1Pressed) widget.keyPressed('a');
    } else {
      if (_startPos - (keyboardKeyMiddleZoneHeight / 2.0) <= _endPos &&
          _endPos <= _startPos + (keyboardKeyMiddleZoneHeight / 2.0)) {
        if (widget.keyType == 'i')
          widget.keyPressed('e');
        else if (widget.keyType == 'u')
          widget.keyPressed('o');
        else
          widget.keyPressed(widget.keyType + 'a');
      } else if (_startPos > _endPos) {
        if (widget.keyType == 'i')
          widget.keyPressed('yi');
        else if (widget.keyType == 'u')
          widget.keyPressed('wi');
        else
          widget.keyPressed(widget.keyType + 'i');
      } else {
        if (widget.keyType == 'i')
          widget.keyPressed('yu');
        else if (widget.keyType == 'u')
          widget.keyPressed('wu');
        else
          widget.keyPressed(widget.keyType + 'u');
      }
    }
    _pressHighlight(top: false, bottom: false);
  }

  void _deleteLongPressDown(_) {
    _deleteLongPressTimer = Timer.periodic(
        const Duration(milliseconds: keyDeleteLongPressFrequency),
        (_) => widget.keyPressed('delete'));
  }

  void _deleteLongPressUp() {
    setState(() => _half1Pressed = false);
    _deleteLongPressTimer?.cancel();
    _deleteLongPressTimer = null;
  }

  @override
  void dispose() {
    _deleteLongPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Stack _mainWidget = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Column(
          children: <Widget>[
            Flexible(
              child: AnimatedOpacity(
                opacity: widget.keyType != 'clear' &&
                        widget.keyType != 'delete' &&
                        widget.keyType != 'enter' &&
                        _half1Pressed &&
                        !_half2Pressed
                    ? keyboardMainPressOpacity
                    : ((widget.keyType == 'clear' ||
                                    widget.keyType == 'delete' ||
                                    widget.keyType == 'enter') &&
                                _half1Pressed) ||
                            _half2Pressed
                        ? keyboardPressOpacity
                        : 0.0,
                duration:
                    const Duration(milliseconds: keyboardPressOpacityDuration),
                curve: keyboardPressOpacityCurve,
                child: Container(
                    color: !(widget.keyType == 'clear' ||
                                widget.keyType == 'delete' ||
                                widget.keyType == 'enter') &&
                            (_half1Pressed && !_half2Pressed)
                        ? _gameData.getColor('keyboardMainPress')
                        : _gameData.getColor('keyboardPress')),
              ),
            ),
            Flexible(
              child: AnimatedOpacity(
                opacity: _half2Pressed && !_half1Pressed
                    ? keyboardMainPressOpacity
                    : _half1Pressed ? keyboardPressOpacity : 0.0,
                duration:
                    const Duration(milliseconds: keyboardPressOpacityDuration),
                curve: keyboardPressOpacityCurve,
                child: Container(
                    color: _half2Pressed && !_half1Pressed
                        ? _gameData.getColor('keyboardMainPress')
                        : _gameData.getColor('keyboardPress')),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(keyboardKeyPadding),
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: _KeyboardKeyContainer(keyType: this.widget.keyType),
          ),
        ),
      ],
    );

    if (widget.keyType == 'delete') {
      return SizedBox(
        height: widget.height,
        child: GestureDetector(
          onLongPressStart: _deleteLongPressDown,
          onLongPressUp: _deleteLongPressUp,
          onTapDown: (_) => setState(() => _half1Pressed = true),
          onTapUp: (_) => setState(() => _half1Pressed = false),
          onTapCancel: () => setState(() => _half1Pressed = false),
          onTap: () => widget.keyPressed(widget.keyType),
          child: _mainWidget,
        ),
      );
    } else if (widget.keyType == 'clear' || widget.keyType == 'enter') {
      return SizedBox(
        height: widget.height,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _half1Pressed = true),
          onTapUp: (_) => setState(() => _half1Pressed = false),
          onTapCancel: () => setState(() => _half1Pressed = false),
          onTap: () => widget.keyPressed(widget.keyType),
          child: _mainWidget,
        ),
      );
    } else {
      return _KeyHint(
        hint: _keyHintText,
        visible: _half1Pressed || _half2Pressed,
        child: SizedBox(
          height: widget.height,
          child: GestureDetector(
            onVerticalDragStart: _dragStart,
            onVerticalDragUpdate: _dragUpdate,
            onVerticalDragEnd: _dragEnd,
            child: _mainWidget,
          ),
        ),
      );
    }
  }
}

class _KeyboardAddKey extends StatefulWidget {
  const _KeyboardAddKey({this.height, this.getGlyph, this.keyPressed});

  final double height;
  final String Function() getGlyph;
  final Function keyPressed;

  @override
  _KeyboardKeyAddState createState() => _KeyboardKeyAddState();
}

class _KeyboardKeyAddState extends State<_KeyboardAddKey> {
  static final GameData _gameData = GameData();
  static final List<String> _allowedGlyphs = [
    'a',
    'i',
    'u',
    'g',
    'ga',
    'gi',
    'gu',
    'k',
    'ka',
    'ki',
    'ku',
    'ng',
    'nga',
    'ngi',
    'ngu',
    't',
    'ta',
    'ti',
    'tu',
    'd',
    'da',
    'di',
    'du',
    'n',
    'na',
    'ni',
    'nu',
    'l',
    'la',
    'li',
    'lu',
    's',
    'sa',
    'si',
    'su',
    'm',
    'ma',
    'mi',
    'mu',
    'p',
    'pa',
    'pi',
    'pu',
    'b',
    'ba',
    'bi',
    'bu',
    'ya',
    'yi',
    'yu',
    'ia',
    'iu',
    'wa',
    'wi',
    'wu',
    'ua',
    'ui',
  ];
  String _keyHintText = '';
  bool _isPressed = false;
  RenderBox _renderBox;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _renderBox = context.findRenderObject());
  }

  void _dragStart(DragStartDetails _) {
    final _oldGlyph = widget.getGlyph();
    if (_allowedGlyphs.contains(_oldGlyph)) {
      if (_oldGlyph.endsWith('i')) {
        setState(() => _keyHintText = _oldGlyph + 'i');
      } else if (_oldGlyph.endsWith('u')) {
        setState(() => _keyHintText = _oldGlyph + 'u');
      } else {
        setState(() => _keyHintText = _oldGlyph + 'a');
      }
      setState(() => _isPressed = true);
    } else if (_keyHintText != '') {
      setState(() => _keyHintText = '');
    }
  }

  void _dragUpdate(DragUpdateDetails details) {
    final bool _withinBounds = _renderBox.paintBounds
        .contains(_renderBox.globalToLocal(details.globalPosition));
    if (_withinBounds && !_isPressed && _keyHintText.length > 0)
      setState(() => _isPressed = true);
    else if (!_withinBounds && _isPressed) setState(() => _isPressed = false);
  }

  void _dragEnd(DragEndDetails details) {
    if (_isPressed) {
      if (_keyHintText.length > 0)
        widget.keyPressed('add', glyph: _keyHintText);
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Stack _mainWidget = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedOpacity(
          opacity: _isPressed ? keyboardPressOpacity : 0.0,
          duration: const Duration(milliseconds: keyboardPressOpacityDuration),
          curve: keyboardPressOpacityCurve,
          child: Container(color: _gameData.getColor('keyboardPress')),
        ),
        Container(
          padding: const EdgeInsets.all(keyboardKeyPadding),
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: _KeyboardKeyContainer(keyType: 'add'),
          ),
        ),
      ],
    );

    return _KeyHint(
      hint: _keyHintText,
      visible: _isPressed,
      child: SizedBox(
        height: widget.height,
        child: GestureDetector(
          onVerticalDragStart: _dragStart,
          onVerticalDragUpdate: _dragUpdate,
          onVerticalDragEnd: _dragEnd,
          child: _mainWidget,
        ),
      ),
    );
  }
}

class _KeyboardKeyContainer extends StatelessWidget {
  static final GameData _gameData = GameData();

  const _KeyboardKeyContainer({this.keyType});

  final String keyType;

  @override
  Widget build(BuildContext context) {
    if (keyType == 'a') {
      return FittedBox(
        fit: BoxFit.contain,
        child: Text(
          keyType,
          textAlign: TextAlign.center,
          style: _gameData.getStyle('kulitanKeyboard').copyWith(shadows: <Shadow>[
            Shadow(color: _gameData.getColor('keyboardStrokeShadow'), offset: Offset(0.75, 0.75))
          ]),
        ),
      );
    } else if (keyType == 'clear') {
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            'CLEAR\nALL',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 0.8,
              fontFamily: 'Barlow',
              fontWeight: FontWeight.w900,
              color: _gameData.getColor('keyboardStroke'),
              shadows: <Shadow>[
                Shadow(
                    color: _gameData.getColor('keyboardStrokeShadow'), offset: Offset(1.8, 1.8))
              ],
            ),
          ),
        ),
      );
    } else if (keyType == 'delete' || keyType == 'enter' || keyType == 'add') {
      final double _aspectRatio = MediaQuery.of(context).size.aspectRatio;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomPaint(
          painter: _KeyIconPainter(
            strokePercent: _aspectRatio > mediumMaxAspect ? 1.5 : (MediaQuery.of(context).size.width / 414.0),
            keyType: keyType,
          ),
        ),
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.fitHeight,
            child: Text(
              keyType,
              textAlign: TextAlign.center,
              style: _gameData.getStyle('kulitanKeyboard').copyWith(shadows: <Shadow>[
                Shadow(
                    color: _gameData.getColor('keyboardStrokeShadow'),
                    offset: Offset(0.75, 0.75))
              ]),
            ),
          ),
          FittedBox(
            fit: BoxFit.fitHeight,
            child: Opacity(
              opacity: 0.55,
              child: Text(
                keyType != 'i'
                    ? keyType != 'u' ? keyType + 'i' : 'wi'
                    : 'yi',
                textAlign: TextAlign.center,
                style: _gameData.getStyle('kulitanKeyboard'),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.fitHeight,
            child: Opacity(
              opacity: 0.55,
              child: Text(
                keyType != 'i'
                    ? keyType != 'u' ? keyType + 'u' : 'wu'
                    : 'yu',
                textAlign: TextAlign.center,
                style: _gameData.getStyle('kulitanKeyboard'),
              ),
            ),
          ),
        ],
      );
    }
  }
}

class _KeyIconPainter extends CustomPainter {
  static final GameData _gameData = GameData();

  const _KeyIconPainter({this.keyType, this.strokePercent});

  final String keyType;
  final double strokePercent;

  @override
  bool shouldRepaint(_KeyIconPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset _shadowOffset =
        Offset(2.5 * strokePercent, 2.5 * strokePercent);
    final double _strokeWidth = 3.0 * strokePercent;
    final double _width = size.height / 0.6588;
    final double _start = ((size.width - _width) / 2.0) + ((_strokeWidth + _shadowOffset.dx) / 2.0);
    final double _end = ((size.width + _width) / 2.0) - ((_strokeWidth + _shadowOffset.dx) / 2.0);
    final double _middle = size.height / 2.0;

    Paint _stroke = Paint()
      ..color = _gameData.getColor('keyboardStrokeShadow')
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    if (keyType == 'delete') {
      final double _arrowOffset = (_width - size.height - _strokeWidth);
      final double _crossOrigin = _start + _arrowOffset + (size.height / 2.0) - (_strokeWidth / 2.0);
      final double _crossOffset = size.height * 0.19;
      final Path _outline = Path()
        ..moveTo(_start, _middle)
        ..lineTo(_start + _arrowOffset, _middle - _arrowOffset)
        ..lineTo(_end, _middle - _arrowOffset)
        ..lineTo(_end, _middle + _arrowOffset)
        ..lineTo(_start + _arrowOffset, _middle + _arrowOffset)
        ..lineTo(_start, _middle);
      final Path _cross1 = Path()
        ..moveTo(_crossOrigin - _crossOffset, _middle - _crossOffset)
        ..lineTo(_crossOrigin + _crossOffset, _middle + _crossOffset);
      final Path _cross2 = Path()
        ..moveTo(_crossOrigin - _crossOffset, _middle + _crossOffset)
        ..lineTo(_crossOrigin + _crossOffset, _middle - _crossOffset);
      canvas.drawPath(_outline.shift(_shadowOffset), _stroke);
      canvas.drawPath(_cross1.shift(_shadowOffset), _stroke);
      canvas.drawPath(_cross2.shift(_shadowOffset), _stroke);
      canvas.drawPath(_outline, _stroke..color = _gameData.getColor('keyboardStroke'));
      canvas.drawPath(_cross1, _stroke..color = _gameData.getColor('keyboardStroke'));
      canvas.drawPath(_cross2, _stroke..color = _gameData.getColor('keyboardStroke'));
    } else if (keyType == 'enter') {
      final double _offset1 = _width * 0.26544;
      final Path _head = Path()
        ..moveTo(_start + _offset1, _middle - _offset1)
        ..lineTo(_start, _middle)
        ..lineTo(_start + _offset1, _middle + _offset1);
      final Path _body = Path()
        ..moveTo(_start, _middle)
        ..lineTo(_end, _middle)
        ..lineTo(_end, _middle - (_width * 0.29824));
      canvas.drawPath(_head.shift(_shadowOffset), _stroke);
      canvas.drawPath(_body.shift(_shadowOffset), _stroke);
      canvas.drawPath(_head, _stroke..color = _gameData.getColor('keyboardStroke'));
      canvas.drawPath(_body, _stroke..color = _gameData.getColor('keyboardStroke'));
    } else if (keyType == 'add') {
      final double _offset = _width * 0.33391;
      final double _center = (_start + _end) / 2.0;
      final Path _topDown = Path()
        ..moveTo(_center, _middle - _offset)
        ..lineTo(_center, _middle + _offset);
      final Path _leftRight = Path()
        ..moveTo(_center - _offset, _middle)
        ..lineTo(_center + _offset, _middle);
      canvas.drawPath(_topDown.shift(_shadowOffset), _stroke);
      canvas.drawPath(_leftRight.shift(_shadowOffset), _stroke);
      canvas.drawPath(_topDown, _stroke..color = _gameData.getColor('keyboardStroke'));
      canvas.drawPath(_leftRight, _stroke..color = _gameData.getColor('keyboardStroke'));
    }
  }
}

class KulitanKeyboard extends StatelessWidget {
  static final GameData _gameData = GameData();

  const KulitanKeyboard(
      {this.visibility, this.getGlyph, this.onKeyPress, this.child});

  final String Function() getGlyph;
  final double visibility;
  final void Function(String) onKeyPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    final double _aspectRatio = _size.aspectRatio;
    final double _padMultiplier = _aspectRatio > smallMaxAspect && _size.height <= smallHeight
      ? (_aspectRatio * 2.0)
      : _aspectRatio > mediumMaxAspect
        ? ((0.75 / _aspectRatio) * 4.0)
        : 1.0;
    final double _horizontalPadding = transcribeHorizontalScreenPadding * _padMultiplier;

    final double _keyboardPreferredHeight = (MediaQuery.of(context).size.width - ((_horizontalPadding - transcribeHorizontalScreenPadding) * 2.0)) * 0.6588;
    final double _keyboardHeight = _keyboardPreferredHeight > 330.0 ? 330.0 : _keyboardPreferredHeight;
    final double _keyHeight = (_keyboardHeight - keyboardDividerHeight) / 4.0;

    Widget _keyboard = Table(
      defaultColumnWidth: FlexColumnWidth(1.0),
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'g',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'k',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'ng',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'a',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'clear',
              keyPressed: onKeyPress,
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            _KeyboardKey(
              height: _keyHeight,
              keyType: 't',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'd',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'n',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'i',
              keyPressed: onKeyPress,
            ),
            Container(),
          ],
        ),
        TableRow(
          children: <Widget>[
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'l',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 's',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'm',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'u',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'delete',
              keyPressed: onKeyPress,
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'p',
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'b',
              keyPressed: onKeyPress,
            ),
            Container(),
            _KeyboardAddKey(
              height: _keyHeight,
              getGlyph: getGlyph,
              keyPressed: onKeyPress,
            ),
            _KeyboardKey(
              height: _keyHeight,
              keyType: 'enter',
              keyPressed: onKeyPress,
            ),
          ],
        ),
      ],
    );

    return Stack(
      children: <Widget>[
        Positioned(
          top: -_keyboardHeight * visibility,
          bottom: _keyboardHeight * visibility,
          left: 0.0,
          right: 0.0,
          child: child,
        ),
        Positioned(
          bottom: -_keyboardHeight + (_keyboardHeight * visibility),
          left: keyboardPadding,
          right: keyboardPadding,
          child: SizedBox(
            height: _keyboardHeight,
            child: Column(
              children: <Widget>[
                Opacity(
                  opacity: 0.55,
                  child: DividerNew(
                    height: keyboardDividerHeight,
                    color: _gameData.getColor('white'),
                  ),
                ),
                Expanded(
                  child: _keyboard,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class Blinker extends StatefulWidget {
  const Blinker({@required this.child});

  final Widget child;

  @override
  _BlinkerState createState() => _BlinkerState();
}

class _BlinkerState extends State<Blinker> {
  static const int _visibilityDuration = kulitanCursorBlinkDuration ~/ 2;
  static const int _cycleDuration =
      _visibilityDuration + kulitanCursorBlinkDelay;
  bool _show = false;
  Timer _showTimer;
  Timer _hideTimer;

  void _initializeTimers() async {
    _showTimer = Timer.periodic(const Duration(milliseconds: _cycleDuration),
        (_) => setState(() => _show = true));
    await Future.delayed(const Duration(milliseconds: _visibilityDuration));
    if (mounted)
      _hideTimer = Timer.periodic(const Duration(milliseconds: _cycleDuration),
          (_) => setState(() => _show = false));
  }

  @override
  void initState() {
    super.initState();
    _initializeTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _show = true);
      await Future.delayed(Duration(milliseconds: _visibilityDuration));
      if (mounted) setState(() => _show = false);
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _show ? 1.0 : 0.0,
      duration: Duration(milliseconds: _visibilityDuration),
      curve: kulitanCursorBlinkCurve,
      child: widget.child,
    );
  }
}

class Tutorial extends StatefulWidget {
  const Tutorial({@required this.onTap, @required this.tutorialNo});

  final VoidCallback onTap;
  final int tutorialNo;

  @override
  _TutorialState createState() => _TutorialState();
}

class _TutorialState extends State<Tutorial>
    with SingleTickerProviderStateMixin {
  static final GameData _gameData = GameData();

  AnimationController _controller;
  OverlayEntry _overlay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
  }

  @override
  void didUpdateWidget(Tutorial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tutorialNo != widget.tutorialNo) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
    }
  }

  void _showOverlay() async {
    if (_overlay == null) {
      await Future.delayed(const Duration(milliseconds: tutorialOverlayDelay));
      _overlay = _createOverlay();
      Overlay.of(context).insert(_overlay);
      _controller.forward();
    }
  }

  void _dismissOverlay(_) async {
    _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onTap();
    _overlay?.remove();
    _overlay = null;
  }

  Widget _flare({top, left, height, right, flipV = false, arrowUp = false}) {
    final Widget _flare = FlareActor(
      'assets/flares/${arrowUp ? 'swipe_down' : 'shaking_pointer'}.flr',
      color: _gameData.getColor('accent'),
      animation: widget.tutorialNo == 2 ? 'down' : 'shake',
    );

    Widget _widget;
    if (flipV) {
      _widget = Transform(
        transform: Matrix4.identity()..scale(1.0, -1.0, 1.0),
        child: _flare,
      );
    } else
      _widget = _flare;

    return Positioned(
      top: top,
      left: left,
      height: height,
      right: right,
      child: IgnorePointer(
        child: _widget,
      ),
    );
  }

  Widget _text({top, left, right}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: _gameData.getColor('tutorialsOverlayBackground'),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Text(
                  widget.tutorialNo == 1
                  ? 'Editing the text above transcribes it to Kulitan, while editing the Kulitan syllables below shows their approximate romanized text counterparts.'
                  : widget.tutorialNo == 2
                    ? 'Swipe up to reveal the Kulitan keyboard ⌨️'
                    : 'Some keys can be swiped up or down. These swipes put diacritical marks on the top or bottom of the syllables.',
                  style: _gameData.getStyle('textTutorialOverlay')),
            ),
          ),
        ),
      ),
    );
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) {
        final Size _dimensions = MediaQuery.of(context).size.width >= maxPageWidth ? Size(maxPageWidth, MediaQuery.of(context).size.height) : MediaQuery.of(context).size;
        final double _relHeight = _dimensions.height / 896.0;
        List<Widget> _elements = [];
        if (widget.tutorialNo == 1) {
          _elements.addAll([
            _flare(
              top: (_dimensions.height / 2) - (115.0 * _relHeight),
              left: 0.0,
              right: 0.0,
              height: 100.0 * _relHeight,
            ),
            _flare(
              top: (_dimensions.height / 2) + (240.0 * _relHeight),
              left: 0.0,
              right: 0.0,
              height: 100.0 * _relHeight,
              flipV: true,
            ),
          ]);
        } else {
          double _vectorSize;
          if (widget.tutorialNo == 2) _vectorSize = 700.0;
          else _vectorSize = 100.0;
          double _topOffset;
          if (widget.tutorialNo == 2) _topOffset = ((_dimensions.height + (_vectorSize * _relHeight)) / 2) + (100 * _relHeight);
          else _topOffset = _dimensions.height - (250.0 * _relHeight);
          _elements.add(
            _flare(
              top: _topOffset,
              left: 0.0,
              right: 0.0,
              height: _vectorSize * _relHeight,
              flipV: true,
              arrowUp: widget.tutorialNo == 2 ? true : false,
            ),
          );
        }
        _elements.add(
          _text(
            top: _dimensions.height / 2,
            left: 25.0,
            right: 25.0,
          ),
        );

        return Positioned.fill(
          child: GestureDetector(
            onTapDown: _dismissOverlay,
            behavior: HitTestBehavior.translucent,
            child: FadeTransition(
              opacity:
                  Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOut,
              )),
              child: Stack(children: _elements),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _overlay?.remove();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
