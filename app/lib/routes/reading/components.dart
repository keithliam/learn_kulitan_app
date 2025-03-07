import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../components/buttons/CustomButton.dart';
import '../../components/misc/LinearProgressBar.dart';
import '../../components/misc/CustomCard.dart';
import '../../components/misc/Paragraphs.dart';
import '../../styles/theme.dart';
import '../../db/GameData.dart';

class ChoiceButton extends StatefulWidget {
  const ChoiceButton({
    @required this.isKulitan,
    @required this.text,
    @required this.type,
    @required this.onTap,
    @required this.disable,
    @required this.resetStream,
    @required this.showAnswerStream,
    @required this.buttonGroup,
  });

  static const int right = 0;
  static const int wrong = 1;

  final bool isKulitan;
  final String text;
  final int type;
  final VoidCallback onTap;
  final bool disable;
  final Stream resetStream;
  final Stream showAnswerStream;
  final CustomButtonGroup buttonGroup;

  @override
  _ChoiceButtonState createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<ChoiceButton> with TickerProviderStateMixin {
  static final GameData _gameData = GameData();

  StreamSubscription _resetStreamSubscription;
  StreamSubscription _showAnswerStreamSubscription;

  Animation<Color> _animation;
  AnimationController _controller;
  ColorTween _tween;

  Animation<Color> _animationText;
  AnimationController _controllerText;
  ColorTween _tweenText;
  
  bool _isTapped = false;
  bool _isKulitan;
  bool _isInit = true;
  bool _changeMode = false;
  double _opacity = 1.0;

  _initColors() {
    final Color _buttonColor = widget.type == ChoiceButton.right ? _gameData.getColor('cardChoicesRight') : _gameData.getColor('cardChoicesWrong');
    final Color _textColor = widget.type == ChoiceButton.right ? _gameData.getColor('cardChoicesRightText') : _gameData.getColor('cardChoicesWrongText');
    _tween = ColorTween(begin: _gameData.getColor('cardChoices'), end: _buttonColor);
    _tweenText = ColorTween(begin: _gameData.getColor('cardChoicesText'), end: _textColor);
    _animation = _tween.animate(_controller)
      ..addListener(() => setState(() {}));
    _animationText = _tweenText.animate(_controllerText)
      ..addListener(() => setState(() {}));
  }

  @override
  void initState() {
    super.initState();
    _isKulitan = widget.isKulitan;
    _controller = AnimationController(duration: Duration(milliseconds: showAnswerChoiceDuration), vsync: this);
    _controllerText = AnimationController(duration: Duration(milliseconds: showAnswerChoiceDuration), vsync: this);
    _initColors();
    _resetStreamSubscription = widget.resetStream.listen((_) => _reset());
    _showAnswerStreamSubscription = widget.showAnswerStream.listen((_) => _showAnswer());
  }

  void _toggleColor({bool isReset = false}) {
    final int _delay = isReset? resetChoicesDuration : showAnswerChoiceDuration;
    _controller.duration = Duration(milliseconds: _delay);
    _controllerText.duration = Duration(milliseconds: _delay);
    if (!isReset) {
      _controller.forward();
      _controllerText.forward();
    } else {
      _controller.reverse();
      _controllerText.reverse();
    }
  }

  void _showAnswer() {
    if(widget.type == ChoiceButton.right && !_isTapped) _toggleColor();
    _isTapped = true;
  }

  void _reset() async {
    setState(() => _opacity = 0.0);
    if(_isTapped || widget.type == ChoiceButton.right)
      _toggleColor(isReset: true);
    await Future.delayed(const Duration(milliseconds: resetChoicesDuration));
    if (_changeMode) {
      _changeMode = false;
      setState(() => _isKulitan = widget.isKulitan);
    }
    setState(() => _opacity = 1.0);
    await Future.delayed(const Duration(milliseconds: resetChoicesDuration));
    _isTapped = false;
  }

  @override
  void didUpdateWidget(ChoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInit) {
        _isInit = false;
        _isKulitan = widget.isKulitan;
    } else if (widget.isKulitan != oldWidget.isKulitan) {
      _changeMode = true;
    }
    if(widget.type != oldWidget.type) _initColors();
    if(widget.showAnswerStream != oldWidget.showAnswerStream)
      _showAnswerStreamSubscription = widget.showAnswerStream.listen((_) => _showAnswer());
    if(widget.resetStream != oldWidget.resetStream)
      _resetStreamSubscription = widget.resetStream.listen((_) => _reset());
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerText.dispose();
    _resetStreamSubscription.cancel();
    _showAnswerStreamSubscription.cancel();
    super.dispose();
  }

  void _tapped() {
    if(!_isTapped) {
      _toggleColor();
      _isTapped = true;
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      height: MediaQuery.of(context).size.height < smallHeight ? 45.0 : MediaQuery.of(context).size.height < 950.0 ? quizChoiceButtonHeight : 70.0,
      color: _animation.value,
      onPressed: _tapped,
      disable:  widget.disable || _isTapped,
      elevation: MediaQuery.of(context).size.height < smallHeight ? 7.0 : MediaQuery.of(context).size.height < 950.0 ? quizChoiceButtonElevation : 12.0,
      borderRadius: 15.0,
      padding: const EdgeInsets.all(12.0),
      pressDelay: quizChoicePressDuration,
      buttonGroup: widget.buttonGroup,
      child: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: resetChoicesDuration),
          curve: customButtonPressCurve,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _isKulitan ? widget.text : kulitanGlyphs[widget.text],
              textAlign: TextAlign.center,
              style: _isKulitan
                ? _gameData.getStyle('textQuizChoice').copyWith(
                  color: widget.type == ChoiceButton.wrong? _animationText.value : _gameData.getColor('foreground'),
                ) : _gameData.getStyle('textQuizChoice').copyWith(
                  fontFamily: 'Kulitan Semi Bold',
                  fontSize: 100.0,
                  color: widget.type == ChoiceButton.wrong? _animationText.value : _gameData.getColor('foreground'),
                ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  const QuizCard({
    @required this.isKulitan,
    @required this.kulitan,
    @required this.answer,
    @required this.progress,
    @required this.color,
    @required this.showAnswer,
    @required this.width,
    @required this.originalWidth,
    this.animateProgressBar = true,
  });

  final bool isKulitan;
  final String kulitan;
  final String answer;
  final double progress;
  final Color color;
  final bool showAnswer;
  final double width;
  final double originalWidth;
  final bool animateProgressBar;

  static final GameData _gameData = GameData();

  @override
  Widget build(BuildContext context) {
    Widget _kulitan = Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isKulitan ? kulitan : answer,
            style: isKulitan
              ? _gameData.getStyle('kulitanQuiz')
              : _gameData.getStyle('kulitanQuiz').copyWith(
                fontFamily: 'Barlow',
                fontSize: 100.0,
                fontWeight: FontWeight.w500,
              ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    Widget _progressBar = Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: LinearProgressBar(
        progress: progress,
        animate: animateProgressBar,
      ),
    );

    List _cardContents = <Widget>[
      _kulitan,
      _progressBar,
    ];

    if(showAnswer)
      _cardContents.insert(1,
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isKulitan ? answer : kulitan,
                textAlign: TextAlign.center,
                style: isKulitan
                  ? _gameData.getStyle('textQuizAnswer')
                  : _gameData.getStyle('textQuizAnswer').copyWith(
                    fontFamily: 'Kulitan Semi Bold',
                    fontSize: 130.0,
                  ),
              ),
            ),
          ),
        )
      );
    else if(_cardContents.length == 3)
      _cardContents.removeAt(1);

    return CustomCard(
      color: color,
      height: width,
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: cardQuizHorizontalPadding, vertical: cardQuizVerticalPadding),
          height: originalWidth,
          width: originalWidth,
          child: Column(
            children: _cardContents,
          ),
        ),
      ),
    );
  }
}

class AnimatedQuizCard extends StatefulWidget {
  const AnimatedQuizCard({
    @required this.isKulitan,
    @required this.kulitan,
    @required this.answer,
    @required this.progress,
    @required this.stackNumber,
    @required this.stackWidth,
    @required this.heightToStackTop,
    @required this.horizontalScreenPadding,
    this.revealAnswer,
    this.swipedLeft,
    this.swipingCard,
    this.swipingCardDone,
    this.flipStream,
    this.disableSwipe = true,
  });

  final bool isKulitan;
  final String kulitan;
  final String answer;
  final double progress;
  final int stackNumber;
  final double stackWidth;
  final double heightToStackTop;
  final Stream<bool> flipStream;
  final Function revealAnswer;
  final VoidCallback swipedLeft;
  final VoidCallback swipingCard;
  final VoidCallback swipingCardDone;
  final bool disableSwipe;
  final double horizontalScreenPadding;

  @override
  _AnimatedQuizCard createState() => _AnimatedQuizCard();
}

class _AnimatedQuizCard extends State<AnimatedQuizCard> with SingleTickerProviderStateMixin {
  static final GameData _gameData = GameData();
  StreamSubscription<bool> _flipStreamSubscription;
  Animation<double> _animation;
  AnimationController _controller;
  Tween<double> _tween;
  ColorTween _colorTween;
  Animation _colorAnimation;
  Animation _curveAnimation;
  Curve _autoSwipeDownCurve = quizCardAutoSwipeDownCurve;
  Curve _swipeDownCurve = quizCardSwipeDownCurve;
  Curve _swipeLeftCurve = quizCardSwipeLeftCurve;
  Curve _forwardCurve = quizCardForwardCurve;
  double _cardSwipeDownY = 0.5;
  double _cardRotate = 0.5;
  double _cardSwipeLeftX = 0.0;
  double _cardTransform = 0.0;
  double _cardWidth = 50.0;

  double _topOffset = 0.0;
  double _leftOffset = 0.0;

  bool _isSwipeDownSnapping = false;
  bool _isSwipeLeftSnapping = false;
  bool _isColorTweening = false;
  bool _isFlipped = false;
  bool _showBackCard = false;
  bool _hasSeenAnswer = false;
  bool _animateProgressBar = true;
  bool _disableSwipe = false;
  bool _isKulitan;
  bool _isInit = true;
  bool _changeMode = false;

  @override
  void initState() {
    super.initState();
    _leftOffset = widget.horizontalScreenPadding;    
    _isKulitan = widget.isKulitan;
    _controller = AnimationController(duration: Duration(milliseconds: swipeDownSnapDuration), vsync: this);
    _curveAnimation = CurvedAnimation(parent: _controller, curve: _swipeDownCurve);
    _tween = Tween<double>(begin: 0.0, end: 1.0);
    _colorTween = ColorTween();
    _colorAnimation = _colorTween.animate(_curveAnimation);
    _animation = _tween.animate(_curveAnimation)
      ..addListener(_noneListener);
    if (widget.flipStream != null) {
      _flipStreamSubscription = widget.flipStream.listen((bool flip) {
        _animateSwipe(_cardRotate, flip ? 1.0 : 0.5);
      });
    }
  }

  void _animateColor() {
    _colorTween
      ..begin = widget.stackNumber == 1? _gameData.getColor('cardQuiz2') : _gameData.getColor('cardQuiz3')
      ..end = widget.stackNumber == 1? _gameData.getColor('cardQuiz1') : widget.stackNumber == 2? _gameData.getColor('cardQuiz2') : _gameData.getColor('cardQuiz3');
    _controller
      ..value = 0.0
      ..forward();
  }

  void _updatedStackNumber() async {
    setState(() => _animateProgressBar = false);
    if(widget.stackNumber == 1)
      setState(() {
        _cardSwipeDownY = 0.5;
        _cardRotate = 0.5;
        _cardSwipeLeftX = 0.0;
        _cardTransform = 0.0;
        _isFlipped = false;
        _showBackCard = false;
        _hasSeenAnswer = false;
      });
    setState(() => _isColorTweening = true);
    _animateSwipe(0.0, 1.0, isSwipeDown: false, isForward: true);
    _animateColor();
    await Future.delayed(Duration(milliseconds: forwardQuizCardsDuration));
    setState(() {
      _isColorTweening = false;
      _animateProgressBar = true;
    });
  }

  @override
  void didUpdateWidget(AnimatedQuizCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stackNumber == 1 && _isInit) {
      _isInit = false;
      _isKulitan = widget.isKulitan;
    }
    if (widget.isKulitan != oldWidget.isKulitan) {
      if (widget.stackNumber == 1)
        _changeMode = true;
      else
        _isKulitan = widget.isKulitan;
    }
    if(widget.flipStream != oldWidget.flipStream) {
      _flipStreamSubscription.cancel();
      _flipStreamSubscription = widget.flipStream.listen((_) {
        if(widget.stackNumber == 1)
          _animateSwipe(_cardRotate, 1.0);
      });
    }
    if (widget.kulitan != oldWidget.kulitan && widget.stackNumber != 1)
      _updatedStackNumber();
    if(widget.heightToStackTop != oldWidget.heightToStackTop) {
      if(widget.stackNumber == 1)
        _topOffset = widget.heightToStackTop + quizCardStackTopSpace * (widget.stackWidth / 400.0);
      else if(widget.stackNumber == 2)
        _topOffset = widget.heightToStackTop + (quizCardStackTopSpace * (widget.stackWidth / 400.0) / 2);
      else
        _topOffset = widget.heightToStackTop;
    }
    if(widget.stackWidth != oldWidget.stackWidth) {
      if(widget.stackNumber == 1) {
        _cardWidth = widget.stackWidth;
      } else if(widget.stackNumber == 2) {
        _leftOffset += widget.stackWidth * 0.05;
        _cardWidth = widget.stackWidth * 0.9;
      } else if(widget.stackNumber == 3) {
        _leftOffset += widget.stackWidth * 0.1;
        _cardWidth = widget.stackWidth * 0.8;
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    if (_flipStreamSubscription != null) _flipStreamSubscription.cancel();
    super.dispose();
  }

  void _noneListener() => setState(() {});

  void _swipeDownListener() {
    if(_animation.value < 0.25 || 0.75 < _animation.value)
      setState(() => _showBackCard = true);
    else
      setState(() => _showBackCard = false);
  }

  void _forwardCardListener() {
    double _topStart = widget.stackNumber == 2? 0.0 : quizCardStackTopSpace * (widget.stackWidth / 400.0) / 2;
    double _topFin = widget.stackNumber == 3? -quizCardStackTopSpace * (widget.stackWidth / 400.0) / 2 : quizCardStackTopSpace * (widget.stackWidth / 400.0) / 2;
    double _leftStart = widget.stackNumber == 1? 0.05 : widget.stackNumber == 1? 0.05 : widget.stackNumber == 2? 0.1 : 0.15;
    double _leftFinDiff = 0.05;
    double _widthStart = widget.stackNumber == 1? 0.9 : widget.stackNumber == 2? 0.8 : 0.7;
    double _widthFinDiff = 0.1;
    setState(() {
      _topOffset = widget.heightToStackTop + _topStart + (_animation.value * _topFin);
      _leftOffset = widget.horizontalScreenPadding + (widget.stackWidth * _leftStart - (widget.stackWidth * _animation.value * _leftFinDiff));
      _cardWidth = widget.stackWidth * _widthStart + (widget.stackWidth * _animation.value * _widthFinDiff);
    });
  }

  void _animateSwipe(double fromValue, double toValue, {bool isSwipeDown: true, bool isForward: false}) async {
    Duration _duration;
    if(isSwipeDown) {
      bool _isAuto = fromValue == 0.5 && toValue == 1.0;
      _duration = Duration(milliseconds: _isAuto? autoSwipeDownDuration : swipeDownSnapDuration);
      _tween.animate(
        CurvedAnimation(
          parent: _controller,
          curve: _autoSwipeDownCurve,
        )
      )..removeListener(_swipeDownListener)..removeListener(_forwardCardListener)..addListener(_swipeDownListener);
      if(toValue == 0.0 || toValue == 1.0)
        setState(() {
          _isFlipped = true;
          _cardRotate = toValue;
        });
      else if (toValue == 0.5)
        setState(() {
          _isFlipped = false;
          _cardRotate = 0.5;
        });
    } else if(!isForward) {
      _duration = Duration(milliseconds: swipeLeftSnapDuration);
      _tween.animate(
        CurvedAnimation(
          parent: _controller,
          curve: quizCardSwipeLeftCurve,
        )
      )..removeListener(_swipeDownListener)..removeListener(_forwardCardListener);
    } else {
      _duration = Duration(milliseconds: quizCardsForwardDuration);
      _tween.animate(
        CurvedAnimation(
          parent: _controller,
          curve: _forwardCurve,
        )
      )..removeListener(_swipeDownListener)..removeListener(_forwardCardListener)..addListener(_forwardCardListener);
    }
    if(isSwipeDown)
      setState(() => _isSwipeDownSnapping = true);
    else if(!isForward)
      setState(() => _isSwipeLeftSnapping = true);
    setState(() => _disableSwipe = true);
    _tween
      ..begin = fromValue
      ..end = toValue;
    _controller
      ..value = 0.0
      ..duration = _duration
      ..forward();
    await Future.delayed(_duration);
    if(isSwipeDown)
      setState(() => _isSwipeDownSnapping = false);
    else if(!isForward)
      setState(() => _isSwipeLeftSnapping = false);
    setState(() => _disableSwipe = false);
  }

  void _swipeAction(details) {
    if(!_disableSwipe && !widget.disableSwipe) {
      widget.swipingCard();
      if(!_isFlipped) {
        double _swipeValue = _cardSwipeDownY + (details.delta.dy * swipeDownSensitivity * 0.00175);
        if(0.0 < _swipeValue && _swipeValue < 1.0) {
          double _rotationValue = _swipeDownCurve.transform(_swipeValue);
          setState(() {
            _cardSwipeDownY = _swipeValue;
            _cardRotate = _rotationValue;
          });
          if(_showBackCard && (0.25 < _rotationValue && _rotationValue < 0.75))
            setState(() => _showBackCard = false);
          else if(!_showBackCard && ((0.0 < _rotationValue && _rotationValue < 0.25) || (0.75 < _rotationValue && _rotationValue < 1.0)))
            setState(() {
              _showBackCard = true;
              _hasSeenAnswer = true;
            });
        }
      } else {
        double _slideValue = _cardSwipeLeftX + ((-details.delta.dx * swipeLeftSensitivity) / swipeLeftMax);
        if(_slideValue > 1.0) {
          setState(() {
            _cardSwipeLeftX = 1.0;
            _cardTransform = 1.0;
            _disableSwipe = true;
          });
          if (_changeMode) {
            _changeMode = false;
            setState(() => _isKulitan = widget.isKulitan);
          }
          widget.swipedLeft();
          _updatedStackNumber();
        } else if(_slideValue < 0.0) {
          setState(() {
            _cardSwipeLeftX = 0.0;
            _cardTransform = 0.0;
          });
        } else {
          setState(() {
            _cardSwipeLeftX = _slideValue;
            _cardTransform = _swipeLeftCurve.transform(_slideValue);
          });
        }
      }
    }
  }

  void _swipeActionCancel() async {
    if(!_disableSwipe && !widget.disableSwipe) {
      if(!_isFlipped) {
        if(_hasSeenAnswer) {
          setState(() {
            _hasSeenAnswer = false;
            _isFlipped = true;
          });
          if(_cardRotate < 0.01 || _cardRotate > 0.99) {
            setState(() => _cardRotate = _cardRotate < 0.01? 0.0 : 1.0);
            widget.revealAnswer();
          } else {
            widget.revealAnswer(delay: swipeDownSnapDuration);
            if(_cardRotate < 0.5) {
              _animateSwipe(_cardRotate, 0.0);
              setState(() {
                _cardSwipeDownY = 0.0;
                _cardRotate = 0.0;
              });
            } else {
              _animateSwipe(_cardRotate, 1.0);
              setState(() {
                _cardSwipeDownY = 1.0;
                _cardRotate = 1.0;
              });
            }
          }
        } else if(0.25 <= _cardRotate && _cardRotate <= 0.75) {
          _animateSwipe(_cardRotate, 0.5);
          setState(() {
            _cardSwipeDownY = 0.5;
            _cardRotate = 0.5;
          });
        }
          await Future.delayed(Duration(milliseconds: swipeDownSnapDuration));
          widget.swipingCardDone();
      } else {
        if(_cardSwipeLeftX <= swipeLeftThreshold) {
          _animateSwipe(_cardTransform, 0.0, isSwipeDown: false);
          setState(() {
            _cardSwipeLeftX = 0.0;
            _cardTransform = 0.0;
          });
        } else {
          _animateSwipe(_cardTransform, 1.0, isSwipeDown: false);
          setState(() {
            _cardSwipeLeftX = 1.0;
            _cardTransform = 1.0;
            _disableSwipe = true;
          });      
          await Future.delayed(Duration(milliseconds: swipeLeftSnapDuration));
          if (_changeMode) {
            _changeMode = false;
            setState(() => _isKulitan = widget.isKulitan);
          }
          widget.swipingCardDone();
          widget.swipedLeft();
          _updatedStackNumber();
        }  
      }
    }
  }

  double _getRotation(double x) {
    return (2 * x * math.pi)  - math.pi;
  }

  @override
  Widget build(BuildContext context) {
    Matrix4 _matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_getRotation(_isSwipeDownSnapping? _animation.value : _cardRotate));
    double _swipeRatio = _isSwipeLeftSnapping? _animation.value : _cardTransform;

    final Widget _card = QuizCard(
      isKulitan: _isKulitan,
      kulitan: widget.kulitan,
      answer: widget.answer,
      progress: widget.progress,
      color: _isColorTweening? _colorAnimation.value : widget.stackNumber == 1? _gameData.getColor('cardQuiz1') : widget.stackNumber == 2? _gameData.getColor('cardQuiz2') : _gameData.getColor('cardQuiz3'),
      showAnswer: _showBackCard,
      width: _cardWidth,
      originalWidth: widget.stackWidth,
      animateProgressBar: _animateProgressBar,
    );

    return Positioned(
      top: _topOffset - (_swipeRatio * quizCardMoveUpVelocity * 150.0),
      left: _leftOffset - (_swipeRatio * quizCardMoveLeftVelocity * ((widget.stackWidth + widget.horizontalScreenPadding) * 1.2)),
      child: widget.stackNumber != 1 ? _card : Transform.rotate(
        angle: (_swipeRatio * quizCardRotateVelocity * (-math.pi / 4)),
        alignment: FractionalOffset.center,
        child: Transform(
          transform: _matrix,
          alignment:FractionalOffset.center,
          child: GestureDetector(
            onPanUpdate: _swipeAction,
            onPanCancel: _swipeActionCancel,
            onPanEnd: (_) => _swipeActionCancel(),
            child: Transform(
              transform: _showBackCard? Matrix4.inverted(_matrix) : Matrix4.identity(),
              alignment: FractionalOffset.center,
              child: _card,
            ),
          ),
        ),
      ),
    );
  }
}

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    Key key,
    @required this.quizCardTop,
    @required this.quizCardBottom,
    @required this.width,
    @required this.animation,
    @required this.flare,
    @required this.tutorialNo,
    @required this.horizontalScreenPadding,
  }) : super(key: key);

  final double width;
  final double quizCardTop;
  final double quizCardBottom;
  final String animation;
  final String flare;
  final int tutorialNo;
  final double horizontalScreenPadding;

  @override
  _TutorialOverlayState createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  static final GameData _gameData = GameData();

  AnimationController _controller;
  OverlayEntry _overlay;
  bool _pageTwo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
  }

  void _showOverlay() async {
    if (_overlay == null) {
      if (widget.tutorialNo == 0) await Future.delayed(const Duration(milliseconds: tutorialOverlayDelay));
      _overlay = _createOverlay();
      Overlay.of(context).insert(_overlay);
      _controller.forward();
    }
  }

  void _showNextOverlay() {
    _pageTwo = true;
    _overlay = _createOverlay();
    Overlay.of(context).insert(_overlay);
    _controller.forward();
  }

  void _dismissOverlay(_) async {
    _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 500));
    if (_overlay != null) {
      _overlay.remove();
      _overlay = null;
    }
    if (widget.tutorialNo == 2 && !_pageTwo) _showNextOverlay();
  }

  Widget _flare({top, left, height, right, animation, flipH = false, flipV = false}) {
    final Widget _flare = FlareActor(
      'assets/flares/${widget.flare}',
      color: _gameData.getColor('accent'),
      animation: animation ?? widget.animation,
    );


    Widget _widget;
    if (flipH || flipV) {
      _widget = Transform(
        transform: Matrix4.identity()..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0, 1.0),
        alignment: FractionalOffset.center,
        child: _flare,
      );
    } else _widget = _flare;

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

  Widget _text({top, left, height, right, text}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      height: height,
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
              child: Text(text, style: _gameData.getStyle('textTutorialOverlay')),
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
        final double _relWidth = _dimensions.width / 414.0;

        double top = 0.0;
        double left = 50.0;
        double right = 50.0;
        double height = widget.quizCardTop + (_relWidth * 40.0);
        String text;
        List<Widget> _elements = [];

        double topF = widget.quizCardTop;
        double leftF = widget.horizontalScreenPadding;
        double rightF = 0.0;
        double heightF = widget.width;

        if (widget.tutorialNo == 2) {
          heightF = 100.0;
          if (!_pageTwo) {
            leftF = widget.horizontalScreenPadding + 45.0;
            topF = widget.quizCardTop - 55.0;
            _elements.add(_flare(top: widget.quizCardBottom + 10.0, height: heightF * _relWidth, left: 50.0, right: 100.0, flipH: true));
          } else {
            topF = widget.quizCardBottom - 50.0;
            leftF = 0.0;
          }
        } else if (widget.tutorialNo == 3 || widget.tutorialNo == 4) {
          heightF = 100.0;
          leftF = widget.horizontalScreenPadding + 45.0;
          topF = widget.quizCardTop - 55.0;
        }
        final bool flipV = widget.tutorialNo == 2 && _pageTwo;

        _elements.add(_flare(top: topF, left: leftF, right: rightF, height: heightF * _relWidth, flipV: flipV));

        if (widget.tutorialNo == 0)
          text = 'Swipe vertically to reveal the answer 👀';
        else if (widget.tutorialNo == 1)
          text = 'Swipe left to dismiss the card 👈';
        else if (widget.tutorialNo == 2) {
          if (!_pageTwo) text = 'This shows the number of syllables you have already mastered 💯';
          else text = 'Choose the correct answer below to increase your mastery 💪 Press "ga"';
        } else if (widget.tutorialNo == 3) {
          text = 'Increase your total mastery by answering this card ✔️ Press "da"';
        } else if (widget.tutorialNo == 4) {
          text = 'Mastered syllables may occassionally show up. These cards can\'t be skipped. Total mastery will decrease when these aren\'t answered correctly! ❌ Try it out!';
        }

        if (widget.tutorialNo == 2) {
          if (!_pageTwo) {
            top = widget.quizCardTop - 50.0;
            _elements.add(_text(
              top: widget.quizCardBottom + 30.0,
              left: left,
              right: right,
              height: height * _relWidth,
              text: 'This progress bar shows your mastery of the current syllable.',
            ));
          } else top = widget.quizCardBottom - 200.0;
        } else if (widget.tutorialNo > 2) {
          top = widget.quizCardTop - 50.0;
        }
        _elements.add(_text(top: top, left: left, right: right, height: height * _relWidth, text: text));
      
        HitTestBehavior hitTest = HitTestBehavior.translucent;

        if (widget.tutorialNo > 1) hitTest = HitTestBehavior.opaque;

        return Positioned.fill(
          child: GestureDetector(
            onTapDown: _dismissOverlay,
            behavior: hitTest,
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOut,
              )),
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxPageWidth),
                  child: Stack(children: _elements),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TutorialSuccess extends StatefulWidget {
  const TutorialSuccess({
    @required this.text,
    @required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  _TutorialSuccessState createState() => _TutorialSuccessState();
}

class _TutorialSuccessState extends State<TutorialSuccess> with SingleTickerProviderStateMixin {
  static final GameData _gameData = GameData();

  AnimationController _controller;
  OverlayEntry _overlay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
  }

  void _showOverlay() async {
    if (_overlay == null) {
      _overlay = _createOverlay();
      Overlay.of(context).insert(_overlay);
      _controller.forward();
    }
  }

  void _dismissOverlay() async {
    _controller?.reverse();
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onTap();
    _overlay?.remove();
    _overlay = null;
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            onTap: _dismissOverlay,
            behavior: HitTestBehavior.opaque,
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOut,
              )),
              child: Container(
                color: _gameData.getColor('background'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 175.0,
                      height: 175.0,
                      child: FlareActor(
                        'assets/flares/success_check.flr',
                        animation: 'Untitled',
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: maxPageWidth),
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width >= smallHeight ? 0.0 : 20.0,
                          vertical: 20.0,
                        ),
                        child: Paragraphs(
                          textAlign: TextAlign.center,
                          paragraphs: [TextSpan(
                            text: widget.text,
                            style: _gameData.getStyle('textTutorialOverlay'),
                          )],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    _controller.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
