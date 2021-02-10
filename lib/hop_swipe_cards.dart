library hop_swipe_cards;

import 'dart:math';

import 'package:disposable_provider/disposable_provider.dart';
import 'package:flutter/material.dart';

enum TriggerDirection {
  none,
  rightOnCard,
  leftOnCard,
  rightOnProfile,
  leftOnProfile,
  top,
  bottom,
  rewind,
}

enum InProgressSwipingDirection {
  left,
  right,
  center,
}

enum CardSwipeOrientation { left, right, recover, top, bottom }

/// Used to show current swiping direction of card
///Usually used for swapping color of cards based on direction of swipe
InProgressSwipingDirection progressSwipe(double direction) {
  if (direction < -0.2) {
    return InProgressSwipingDirection.left;
  } else if (direction > 0.2) {
    return InProgressSwipingDirection.right;
  } else {
    return InProgressSwipingDirection.center;
  }
}

///A Hop like swipe card
class HopSwipeCards extends StatefulWidget {
  //A builder for swipe cards
  final SwipeCardBuilder _cardBuilder;

  //Widget representing when no cards left on stack
  final Widget _noMoreSwipeCardsLeft;

  //Total number of cards
  final int _totalCards;

  final int _stackNumber;

  final Duration _animationDuration;

  //The edge at which cards have to be swiped
  final double _swipeEdge;

  final bool _allowSwipeUpAndDown;

  //Status of front card after swiping is completed
  final CardSwipeCompleteCallback swipeCompleteCallback;

  //Controller for swipe feature of card
  final CardController cardController;

  final List<Size> _cardSizes = [];

  final List<Alignment> _cardAligns = [];

  //If you have points left, you can swipe the card
  final bool _canSwipe;

  final VoidCallback cantSwipeLikeWhenNoPointsCallback;

  final OnRestrictLeftSwipeCallBack _onRestrictLeftSwipeCallBack;

  final VoidCallback _triedSwipeLeftDuringRestriction;

  @override
  _HopSwipeCardsState createState() => _HopSwipeCardsState();

  HopSwipeCards({
    @required SwipeCardBuilder cardBuilder,
    @required int totalNum,
    int currentStack = 3,
    Duration animationDuration = const Duration(milliseconds: 500),
    double swipeEdge = 3.0,
    double maxWidth,
    double maxHeight,
    double minWidth,
    double minHeight,
    Widget noMoreSwipeCardsLeft,
    bool isPointsLeft,
    bool allowSwipeUpAndDown = false,
    this.cardController,
    this.swipeCompleteCallback,
    this.cantSwipeLikeWhenNoPointsCallback,
    VoidCallback triedSwipeLeftDuringRestriction,
    OnRestrictLeftSwipeCallBack onRestrictLeftSwipeCallBack,
  })  : assert(currentStack > 1),
        assert(swipeEdge > 0),
        assert(maxWidth > minWidth && maxHeight > minHeight),
        _cardBuilder = cardBuilder,
        _noMoreSwipeCardsLeft = noMoreSwipeCardsLeft,
        _totalCards = totalNum,
        _stackNumber = currentStack,
        _animationDuration = animationDuration,
        _canSwipe = isPointsLeft,
        _swipeEdge = swipeEdge,
        _allowSwipeUpAndDown = allowSwipeUpAndDown,
        _triedSwipeLeftDuringRestriction = triedSwipeLeftDuringRestriction,
        _onRestrictLeftSwipeCallBack = onRestrictLeftSwipeCallBack {
    final widthGap = maxWidth - minWidth;
    final heightGap = maxHeight - minHeight;

    for (var i = 0; i < _stackNumber; i++) {
      _cardSizes.add(
        Size(minWidth + (widthGap / _stackNumber) * i,
            minHeight + (heightGap / _stackNumber) * i),
      );
      _cardAligns.add(Alignment.center);
    }
  }
}

class _HopSwipeCardsState extends State<HopSwipeCards>
    with TickerProviderStateMixin {
  Alignment frontCardAlign = Alignment.center;
  Alignment afterSwipeAlignment = Alignment.center;

  AnimationController _animationController;

  int _currentFront;

  static TriggerDirection _trigger;

  static bool triedSwipingLikeWhenNoPoints = false;

  bool get isPointsLeft => widget._canSwipe == null || widget._canSwipe;

  int swipedCards = 0;

  bool _preventLeftSwipe = false;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HopSwipeCards oldWidget) {
    if (oldWidget._totalCards != widget._totalCards) {
      _initializeCurrentFront();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initializeCurrentFront() {
    _currentFront = widget._totalCards - widget._stackNumber;
  }

  void _initState() {
    _initializeCurrentFront();

    _preventLeftSwipe = widget._onRestrictLeftSwipeCallBack?.call(0);
    _animationController = AnimationController(
      vsync: this,
      duration: widget._animationDuration,
    )
      ..addListener(
        () => setState(() {}),
      )
      ..addStatusListener(
        (AnimationStatus status) {
          final index =
              widget._totalCards - widget._stackNumber - _currentFront;
          var direction = _HopSwipeCardsState._trigger;
          if (status == AnimationStatus.completed) {
            if (!isPointsLeft &&
                _HopSwipeCardsState.triedSwipingLikeWhenNoPoints) {
              widget.cantSwipeLikeWhenNoPointsCallback.call();
              direction = TriggerDirection.none;
              _HopSwipeCardsState.triedSwipingLikeWhenNoPoints = false;
            }

            CardSwipeOrientation orientation;
            if (frontCardAlign.x < -widget._swipeEdge) {
              orientation = CardSwipeOrientation.left;
            } else if (frontCardAlign.x > widget._swipeEdge) {
              orientation = CardSwipeOrientation.right;
            } else if (frontCardAlign.y > widget._swipeEdge) {
              orientation = CardSwipeOrientation.bottom;
            } else if (frontCardAlign.y < -widget._swipeEdge) {
              orientation = CardSwipeOrientation.top;
            } else {
              frontCardAlign = widget._cardAligns[widget._stackNumber - 1];
              orientation = CardSwipeOrientation.recover;
            }

            if (direction == TriggerDirection.none) {
              direction = orientation == CardSwipeOrientation.left
                  ? TriggerDirection.leftOnCard
                  : TriggerDirection.rightOnCard;
              if (orientation == CardSwipeOrientation.recover) {
                direction = TriggerDirection.none;
              }
            }
            if (_HopSwipeCardsState._trigger == TriggerDirection.rewind) {
              swipedCards--;
            }
            if (orientation != CardSwipeOrientation.recover) {
              swipedCards++;
              afterSwipeAlignment = frontCardAlign;
            }
            if (_preventLeftSwipe != null &&
                _preventLeftSwipe &&
                orientation == CardSwipeOrientation.recover) {
              widget._triedSwipeLeftDuringRestriction?.call();
            }
            if (widget.swipeCompleteCallback != null &&
                _HopSwipeCardsState._trigger != TriggerDirection.rewind) {
              widget.swipeCompleteCallback(index, direction);

              if (orientation != CardSwipeOrientation.recover) {
                if (index < widget._totalCards - 1) {
                  _preventLeftSwipe =
                      widget._onRestrictLeftSwipeCallBack?.call(index + 1);
                }
                changeCardOrder();
              }
            }
          }
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    widget.cardController?.addListener(triggerSwap);

    return Stack(children: _buildCards(context));
  }

  List<Widget> _buildCards(BuildContext context) {
    final cards = <Widget>[];

    for (var i = _currentFront; i < _currentFront + widget._stackNumber; i++) {
      cards.add(
        _buildCard(context, i),
      );
    }

    cards.add(
      SizedBox.expand(
        child: GestureDetector(
          onPanUpdate: (final details) {
            setState(() {
              frontCardAlign = Alignment(
                frontCardAlign.x +
                    details.delta.dx * 20 / MediaQuery.of(context).size.width,
                frontCardAlign.y +
                    details.delta.dy * 40 / MediaQuery.of(context).size.height,
              );
            });
          },
          onPanEnd: (final details) {
            animateCards(TriggerDirection.none);
          },
        ),
      ),
    );

    return cards;
  }

  Widget _buildCard(BuildContext context, int realIndex) {
    if (realIndex < 0) {
      return widget._noMoreSwipeCardsLeft;
    }
    final index = realIndex - _currentFront;

    if (index == widget._stackNumber - 1) {
      return Align(
        alignment: _animationController.status == AnimationStatus.forward
            ? frontCardAlign = CardAnimation.frontCardAlign(
                    swipedCards: swipedCards,
                    currentXLocation: frontCardAlign.x,
                    afterSwipeAlignment: afterSwipeAlignment,
                    controller: _animationController,
                    currentAlignment: frontCardAlign,
                    baseAlign: widget._cardAligns[widget._stackNumber - 1],
                    swipeEdge: widget._swipeEdge,
                    pointLeft: isPointsLeft,
                    allowSwipeUpAndDown: widget._allowSwipeUpAndDown,
                    preventLeftSwipe: _preventLeftSwipe)
                .value
            : frontCardAlign,
        child: Transform.rotate(
          angle: (pi / 80.0) *
              (_animationController.status == AnimationStatus.forward
                  ? CardAnimation.frontCardRotate(
                      _animationController,
                      frontCardAlign.x,
                    ).value
                  : frontCardAlign.x),
          child: SizedBox.fromSize(
            size: widget._cardSizes[index],
            child: widget._cardBuilder(
              context,
              widget._totalCards - realIndex - 1,
              progressSwipe(frontCardAlign.x),
              _getOpacity(frontCardAlign.x),
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: _animationController.status == AnimationStatus.forward &&
              (frontCardAlign.x > 3.0 ||
                  frontCardAlign.x < -3.0 ||
                  frontCardAlign.y > 3 ||
                  frontCardAlign.y < -3)
          ? CardAnimation.backCardAlign(
              _animationController,
              widget._cardAligns[index],
              widget._cardAligns[index + 1],
            ).value
          : widget._cardAligns[index],
      child: SizedBox.fromSize(
        size: _animationController.status == AnimationStatus.forward &&
                (frontCardAlign.x > 3.0 ||
                    frontCardAlign.x < -3.0 ||
                    frontCardAlign.y > 3 ||
                    frontCardAlign.y < -3)
            ? CardAnimation.backCardSize(
                _animationController,
                widget._cardSizes[index],
                widget._cardSizes[index + 1],
              ).value
            : widget._cardSizes[index],
        child: widget._cardBuilder(
          context,
          widget._totalCards - realIndex - 1,
          InProgressSwipingDirection.center,
          _getOpacity(frontCardAlign.x),
        ),
      ),
    );
  }

  void animateCards(TriggerDirection trigger) {
    if (_animationController.isAnimating ||
        _currentFront + widget._stackNumber == 0 ||
        (trigger == TriggerDirection.rewind && swipedCards == 0)) {
      return;
    }

    _trigger = trigger;
    if (trigger == TriggerDirection.rewind) {
      setState(() {
        _currentFront++;
      });
    }
    _animationController
      ..stop()
      ..value = 0.0
      ..forward();
  }

  void triggerSwap(TriggerDirection trigger) {
    animateCards(trigger);
  }

  void changeCardOrder() {
    setState(
      () {
        _currentFront--;
        frontCardAlign = widget._cardAligns[widget._stackNumber - 1];
      },
    );
  }
}

typedef SwipeCardBuilder = Widget Function(
  BuildContext context,
  int index,
  InProgressSwipingDirection direction,
  double opacity,
);

/// swipe card to [CardSwipeOrientation.left] or [CardSwipeOrientation.right]
/// , [CardSwipeOrientation.recover] means back to start.
typedef CardSwipeCompleteCallback = void Function(
  int index,
  TriggerDirection direction,
);
typedef OnRestrictLeftSwipeCallBack = bool Function(
  int index,
);

class CardAnimation {
  static Animation<Alignment> frontCardAlign(
      {double currentXLocation,
      AnimationController controller,
      Alignment currentAlignment,
      Alignment baseAlign,
      double swipeEdge,
      bool pointLeft,
      bool allowSwipeUpAndDown,
      int swipedCards,
      bool preventLeftSwipe,
      Alignment afterSwipeAlignment}) {
    double endX, endY;

    if (_HopSwipeCardsState._trigger == TriggerDirection.none) {
      endX = currentAlignment.x > 0
          ? (currentAlignment.x > swipeEdge
              ? currentAlignment.x + 10.0
              : baseAlign.x)
          : (currentAlignment.x < -swipeEdge
              ? currentAlignment.x - 10.0
              : baseAlign.x);
      endY = currentAlignment.x > 3.0 || currentAlignment.x < -swipeEdge
          ? currentAlignment.y
          : baseAlign.y;

      if (allowSwipeUpAndDown) {
        if (currentAlignment.y < 0) {
          endY = currentAlignment.y < -swipeEdge
              ? currentAlignment.y - 10.0
              : baseAlign.y;
        } else if (currentAlignment.y > 0) {
          endY = currentAlignment.y > swipeEdge
              ? currentAlignment.y + 10.0
              : baseAlign.y;
        }
      }

      if (!pointLeft && currentXLocation > 0) {
        endX = 0.0;
        endY = 0.0;
        _HopSwipeCardsState.triedSwipingLikeWhenNoPoints = true;
      }
      if (preventLeftSwipe != null &&
          preventLeftSwipe &&
          currentAlignment.x < 0) {
        endX = 0.0;
        endY = 0.0;
      }
    } else if (_HopSwipeCardsState._trigger == TriggerDirection.top ||
        _HopSwipeCardsState._trigger == TriggerDirection.bottom) {
      if (_HopSwipeCardsState._trigger == TriggerDirection.top) {
        endX = currentAlignment.x;
        endY = currentAlignment.y - swipeEdge;
      } else {
        endX = currentAlignment.x;
        endY = currentAlignment.y + swipeEdge;
      }
    } else if (_HopSwipeCardsState._trigger == TriggerDirection.rewind &&
        swipedCards > 0) {
      endY = 0;
      endX = 0;
      currentAlignment = afterSwipeAlignment;
    } else if (_HopSwipeCardsState._trigger == TriggerDirection.leftOnCard ||
        _HopSwipeCardsState._trigger == TriggerDirection.leftOnProfile) {
      endX = currentAlignment.x - swipeEdge;
      endY = currentAlignment.y + 0.5;
    } else {
      endX = currentAlignment.x + swipeEdge;
      endY = currentAlignment.y + 0.5;

      if (!pointLeft) {
        _HopSwipeCardsState.triedSwipingLikeWhenNoPoints = true;
        return CardAnimation.alignmentAnimationWhenNoPoints(
          controller,
          currentAlignment,
          Alignment(endX, endY),
        );
      }
      return CardAnimation.alignAnimtion(
        controller,
        currentAlignment,
        Alignment(endX, endY),
      );
    }

    return AlignmentTween(
      begin: currentAlignment,
      end: Alignment(endX, endY),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ),
    );
  }

  static Animation<Alignment> alignAnimtion(
    AnimationController controller,
    Alignment begin,
    Alignment end,
  ) {
    return AlignmentTween(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  static Animation<Alignment> alignmentAnimationWhenNoPoints(
    AnimationController controller,
    Alignment end,
    Alignment begin,
  ) {
    return TweenSequence(
      <TweenSequenceItem<Alignment>>[
        TweenSequenceItem<Alignment>(
          tween: AlignmentTween(begin: begin, end: end),
          weight: 40,
        ),
        TweenSequenceItem<Alignment>(
          tween: AlignmentTween(begin: end, end: Alignment.center),
          weight: 40,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  static Animation<double> frontCardRotate(
      AnimationController controller, double beginRot) {
    return Tween(begin: beginRot, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  static Animation<Size> backCardSize(
    AnimationController controller,
    Size beginSize,
    Size endSize,
  ) {
    return SizeTween(begin: beginSize, end: endSize).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  static Animation<Alignment> backCardAlign(
    AnimationController controller,
    Alignment beginAlign,
    Alignment endAlign,
  ) {
    return AlignmentTween(begin: beginAlign, end: endAlign).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }
}

double _getOpacity(double frontCardAlignX) {
  var opacity = frontCardAlignX.abs() + 0.4;

  if (opacity > 1) {
    opacity = 1;
  }

  return opacity ??= 0.0;
}

typedef TriggerListener = void Function(TriggerDirection trigger);

class CardController extends Disposable {
  TriggerListener _listener;

  void triggerLeftOnCard() {
    _listener?.call(TriggerDirection.leftOnCard);
  }

  void triggerRightOnCard() {
    _listener?.call(TriggerDirection.rightOnCard);
  }

  void triggerLeftOnProfile() {
    _listener?.call(TriggerDirection.leftOnProfile);
  }

  void triggerRightOnProfile() {
    _listener?.call(TriggerDirection.rightOnProfile);
  }

  void triggerTop() {
    _listener?.call(TriggerDirection.top);
  }

  void triggerDown() {
    _listener?.call(TriggerDirection.bottom);
  }

  // ignore: use_setters_to_change_properties
  void addListener(final TriggerListener listener) {
    _listener = listener;
  }

  void triggerRewind() {
    _listener?.call(TriggerDirection.rewind);
  }

  @override
  void dispose() {
    _listener = null;
  }
}
