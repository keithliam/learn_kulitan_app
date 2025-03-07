import 'package:flutter/material.dart';
import '../../styles/theme.dart';
import '../../components/buttons/RoundedBackButton.dart';
import '../../components/misc/StaticHeader.dart';
import '../../components/misc/LinearProgressBar.dart';
import '../../components/misc/GameLogicManager.dart';
import '../../db/GameData.dart';
import './components.dart';

class WritingPage extends StatefulWidget {
  const WritingPage();
  @override
  WritingPageState createState() => WritingPageState();
}

class WritingPageState extends State<WritingPage> with SingleTickerProviderStateMixin { 
  static final GameData _gameData = GameData();
  final GameLogicManager _gameLogicManager = GameLogicManager(isQuiz: false);
  bool _isTutorial = true;
  int _overallProgressCount = 0;
  List<Map<String, dynamic>> _cards = [
    {
      'kulitan': '',
      'answer': '',
      'progress': 0,
      'stackNumber': 1,
    },
    {
      'kulitan': '',
      'answer': '',
      'progress': 0,
      'stackNumber': 2,
    },
  ];

  AnimationController _panController;
  Animation<double> _panAnimation;

  set isTutorial(bool i) => setState(() => _isTutorial = i);
  set overallProgressCount(int n) => setState(() => _overallProgressCount = n);
  void setCard(Map<String, dynamic> card, int i) => setState(() => _cards[i] = card);
  void setCardStackNo(int i, int sNum) => setState(() => _cards[i]['stackNumber'] = sNum);
  void incOverallProgressCount() => setState(() => _overallProgressCount++);
  void decOverallProgressCount() => setState(() => _overallProgressCount--);
  void incCurrCardProgress() => setState(() => _cards[0]['progress']++);
  void decCurrCardProgress() => setState(() => _cards[0]['progress']--);
  void slideCard() => _panController.forward();
  void resetCard() => _panController.reset();
  get cards => _cards;
  get overallProgressCount => _overallProgressCount;

  @override
  void initState() {
    super.initState();   
    _gameLogicManager.init(this);
    _panController = AnimationController(duration: const Duration(milliseconds: writingNextCardDuration), vsync: this);
    final CurvedAnimation _panCurve = CurvedAnimation(parent: _panController, curve: writingCardPanLeftCurve);
    final Tween<double> _panTween = Tween<double>(begin: 0.0, end: 1.0);
    _panAnimation = _panTween.animate(_panCurve)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget _header = Padding(
      padding: EdgeInsets.fromLTRB(headerHorizontalPadding, headerVerticalPadding, headerHorizontalPadding, 0.0),
      child: StaticHeader(
        left: RoundedBackButton(),
        middle: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(headerHorizontalPadding, headerIconSize / 2, headerHorizontalPadding, 5.0),
              child: LinearProgressBar(
                progress: _overallProgressCount / totalGlyphCount,
                color: _gameData.getColor('writingHeaderProgressBG'),
              ),
            ),
            Text(
              'SYLLABLES LEARNED',
              style: _gameData.getStyle('textWritingProgressBar')
            )
          ],
        ),
        right: SizedBox(width: 48.0, height: 48.0),
      ),
    );

    final double _deviceWidth = MediaQuery.of(context).size.width;

    Widget _mainCard = Positioned(
      left: 0.0 - (_deviceWidth * _panAnimation.value),
      right: 0.0 + (_deviceWidth * _panAnimation.value),
      top: 0.0,
      bottom: 0.0,
      child: WritingCard(
        displayText: _cards[0]['answer'],
        kulitan: _cards[0]['kulitan'],
        progress: _cards[0]['progress'] / maxWritingGlyphProgress,
        stackNumber: _cards[0]['stackNumber'],
        writingDone: _gameLogicManager.correctAnswer,
      ),
    );

    Widget _secCard = Positioned(
      left: _deviceWidth - (_deviceWidth * _panAnimation.value),
      right: -_deviceWidth + (_deviceWidth * _panAnimation.value),
      top: 0.0,
      bottom: 0.0,
      child: WritingCard(
        displayText: _cards[1]['answer'],
        kulitan: _cards[1]['kulitan'],
        progress: _cards[1]['progress'] / maxWritingGlyphProgress,
        stackNumber: _cards[1]['stackNumber'],
        writingDone: _gameLogicManager.correctAnswer,
      ),
    );

    List<Widget> _pageStack = [
        Column(
        children: <Widget>[
          _header,
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Positioned>[
                _mainCard,
                _secCard,
              ],
            ),
          ),
        ],
      ),
    ];

    if (_isTutorial) {
      _pageStack.add(
        IgnorePointer(
          child: Tutorial(
            onTap: _gameLogicManager.finishTutorial,
          ),
        ),  
      );
    }

    return Material(
      color: _gameData.getColor('background'),
      child: SafeArea(
        child: Stack(children: _pageStack),
      ),
    );
  }
}

