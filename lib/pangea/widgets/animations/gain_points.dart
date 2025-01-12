import 'dart:async';
import 'dart:math' show Random;

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pangea/enum/activity_type_enum.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/pangea/controllers/get_analytics_controller.dart';
import 'package:fluffychat/pangea/controllers/put_analytics_controller.dart';
import 'package:fluffychat/pangea/utils/bot_style.dart';
import 'package:fluffychat/widgets/matrix.dart';

class PointsGainedAnimation extends StatefulWidget {
  final Color? gainColor;
  final Color? loseColor;
  final AnalyticsUpdateOrigin origin;
  final Size? parentSize;
  final ActivityTypeEnum? activityType;

  const PointsGainedAnimation({
    super.key,
    required this.origin,

    this.gainColor = Colors.green,
    this.loseColor = Colors.red,

    this.parentSize,
    this.activityType,
  });

  @override
  PointsGainedAnimationState createState() => PointsGainedAnimationState();
}

class PointsGainedAnimationState extends State<PointsGainedAnimation>
    with SingleTickerProviderStateMixin {
  final List<_PointWidget> _points = [];

  StreamSubscription? _pointsSubscription;
  int? get _prevXP =>
      MatrixState.pangeaController.getAnalytics.constructListModel.prevXP;
  int? get _currentXP =>
      MatrixState.pangeaController.getAnalytics.constructListModel.totalXP;
  int? _addedPoints;

  late TextStyle _style;

  @override
  void initState() {
    super.initState();

    _pointsSubscription = MatrixState
        .pangeaController.getAnalytics.analyticsStream.stream
        .listen(_showPointsGained);

    _style = BotStyle.text(
      context,
      big: true,
      setColor: true,
      existingStyle: const TextStyle(
        color: Colors.green,
      ).copyWith(fontSize: 30),
    );
  }

  @override
  void dispose() {
    _pointsSubscription?.cancel();
    super.dispose();
  }

  void _showPointsGained(AnalyticsStreamUpdate update) {
    if (update.origin != widget.origin) return;
    setState(() => _addedPoints = (_currentXP ?? 0) - (_prevXP ?? 0));
    if (_prevXP != _currentXP) {

      setState(() {
        // Change to loseColor appropriately and whether we gained or lost points
        bool gain = true;
        if (_addedPoints! < 0) { 
          _style = _style.copyWith(color: widget.loseColor); 
          gain = false;
        } else {
          _style = _style.copyWith(color: widget.gainColor);
        }

        print(widget.parentSize);

        // Create n PointWidgets for each amt of XP gained
        for (int i = 0; i < _addedPoints!.abs(); i++) {
          final double x = (Random().nextBool() ? 1 : -1) * Random().nextDouble() * (widget.parentSize!.width/2) ;
          final double y = -widget.parentSize!.height/2 + (Random().nextBool() ? 1 : -1) * (Random().nextDouble() * 10); // Get to top of parent widget, with variance

          _points.add(_PointWidget(
            key: UniqueKey(),
            initialPosition: widget.parentSize != null ? Offset( x, y) : const Offset(0,0),
            style: _style,
            gain: gain,
            onComplete: () {
              setState(() => _points.removeWhere((p) => p.key == i));
            },
          ),);
        }
      });

    }
  }

  bool get animate =>
      _currentXP != null &&
      _prevXP != null &&
      _addedPoints != null &&
      _prevXP! != _currentXP!;

  @override
  Widget build(BuildContext context) {
    if (!animate) return const SizedBox();


    return Stack(
      children: _points,
    );

    /*return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          '${_addedPoints! > 0 ? '+' : ''}$_addedPoints',
          style: BotStyle.text(
            context,
            big: true,
            setColor: textColor == null,
            existingStyle: TextStyle(
              color: textColor,
            ),
          ),
        ),
      ),
    );*/
  }
}

// Combine a bunch of these to create the animation. 
// A text widget with animations attached to sway left and right, and move up
class _PointWidget extends StatefulWidget {
  Offset initialPosition;
  final VoidCallback onComplete;
  final TextStyle style;
  final bool gain;

  _PointWidget({
    super.key,
    required this.initialPosition,
    required this.onComplete,
    required this.style,
    required this.gain,
  });

  @override
  _PointWidgetState createState() => _PointWidgetState();
  
}

class _PointWidgetState extends State<_PointWidget> with SingleTickerProviderStateMixin {
  late TextStyle _style; 
  late AnimationController _controller;
  late Animation<Offset> _movementAni;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  // Initialize vars for our animation and '+' text. 
  @override 
  void initState() {
    _style = widget.style;

    _controller = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _sizeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.2, 
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
    
    // Create a sequence of movements for the text widget to follow
    Offset position = widget.initialPosition;
    final double xMovement = 17.5 * (Random().nextBool() ? 1 : -1);
    const double yMovement = 5;
    _movementAni = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset> (
          begin: position ,
          end: position = Offset(position.dx + xMovement, position.dy - yMovement),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset> (
          begin: position,
          end: position = Offset(position.dx - xMovement, position.dy - yMovement),
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset> (
          begin: position,
          end: position = Offset(position.dx - xMovement, position.dy - yMovement),
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset> (
          begin: position,
          end: position = Offset(position.dx + xMovement, position.dy - yMovement),
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset> (
          begin: position,
          end: position = Offset(position.dx + xMovement, position.dy - yMovement),
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 1.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });

    _controller.forward();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String text = widget.gain ? '+' : '-';

    return AnimatedBuilder(
      animation: Listenable.merge([_movementAni, _fadeAnimation, _sizeAnimation]),
      builder: (context, child) { 
        final offsetTranslate = _movementAni.value;


        return Transform.translate(
          offset: offsetTranslate,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.scale(
              scale: _sizeAnimation.value,
              child: Text(
                text,
                style: _style,
              ),
            )
              
          ),
        );
      },
    );

  }

  @override dispose() {
    _controller.dispose();
    super.dispose();
  }

}