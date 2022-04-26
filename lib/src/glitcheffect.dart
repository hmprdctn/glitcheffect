import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class GlithEffect extends StatefulWidget {
  final Widget child;
  final bool onlyFirstTime;
  final Duration? duration;
  final List<Color>? colors;

  const GlithEffect(
      {Key? key,
      required this.child,
      this.duration,
      this.colors,
      this.onlyFirstTime = false})
      : super(key: key);

  @override
  _GlithEffectState createState() => _GlithEffectState();
}

class _GlithEffectState extends State<GlithEffect>
    with SingleTickerProviderStateMixin {
  late GlitchController _controller;
  late Timer _timer;
  bool showFirstEffect = false;

  @override
  void initState() {
    showFirstEffect = widget.onlyFirstTime;
    _controller = GlitchController(
      duration: const Duration(
        milliseconds: 400,
      ),
    );

    /// Duration after which the glitch effect will be reset
    _timer = widget.onlyFirstTime
        ? Timer.periodic(widget.duration ?? const Duration(seconds: 3),
            (timer) {
            if (showFirstEffect) {
              _controller
                ..reset()
                ..forward();
            }
            showFirstEffect = false;
          })
        : Timer.periodic(
            widget.duration ?? const Duration(seconds: 3),
            (_) {
              _controller
                ..reset()
                ..forward();
            },
          );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    _controller.dispose();
  }

  List<Color> get _colors {
    return widget.colors ??
        [
          Colors.white,
          Colors.grey,
          Colors.black,
        ];
  }

  Color get _randomColor {
    return _colors[math.Random().nextInt(_colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final color = _randomColor.withOpacity(0.5);
        if (!_controller.isAnimating) {
          return widget.child;
        }
        return Stack(
          children: [
            if (random.nextBool()) _clipedChild,
            Transform.translate(
              offset: randomOffset,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: <Color>[
                      color,
                      color,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcATop,
                child: _clipedChild,
              ),
            ),
          ],
        );
      },
    );
  }

  Offset get randomOffset => Offset(
        (random.nextInt(10) - 5).toDouble(),
        (random.nextInt(10) - 5).toDouble(),
      );

  Widget get _clipedChild => ClipPath(
        clipper: GlitchClipper(),
        child: widget.child,
      );
}

final random = math.Random();

class GlitchClipper extends CustomClipper<Path> {
  final deltaMax = 15;
  final min = 3;

  @override
  getClip(Size size) {
    final path = Path();
    double y = randomStep;
    while (y < size.height) {
      final yRandom = randomStep;
      double x = randomStep;

      while (x < size.width) {
        final xRandom = randomStep;
        path.addRect(
          Rect.fromPoints(
            Offset(x, y.toDouble()),
            Offset(x + xRandom, y + yRandom),
          ),
        );
        x += randomStep * 2;
      }
      y += yRandom;
    }

    path.close();
    return path;
  }

  double get randomStep => min + random.nextInt(deltaMax).toDouble();

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) => true;
}

class GlitchController extends Animation<int>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  GlitchController({required this.duration});

  late Duration duration;
  List<Timer> _timers = [];
  bool isAnimating = false;

  forward() {
    isAnimating = true;
    final oneStep = (duration.inMicroseconds / 3).round();
    _status = AnimationStatus.forward;
    _timers = [
      Timer(
        Duration(microseconds: oneStep),
        () => setValue(1),
      ),
      Timer(
        Duration(microseconds: oneStep * 2),
        () => setValue(2),
      ),
      Timer(
        Duration(microseconds: oneStep * 3),
        () => setValue(3),
      ),
      Timer(
        Duration(microseconds: oneStep * 4),
        () {
          _status = AnimationStatus.completed;
          isAnimating = false;
          notifyListeners();
        },
      ),
    ];
  }

  setValue(value) {
    _value = value;
    notifyListeners();
  }

  reset() {
    _status = AnimationStatus.dismissed;
    _value = 0;
  }

  @override
  void dispose() {
    for (var timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  AnimationStatus get status => _status;
  late AnimationStatus _status;

  @override
  int get value => _value;
  late int _value;
}
