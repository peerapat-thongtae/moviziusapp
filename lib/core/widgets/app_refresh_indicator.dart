// A vendored copy of Flutter's Material [RefreshIndicator] (see
// packages/flutter/lib/src/material/refresh_indicator.dart) trimmed to the
// material spinner path this app uses, with one addition: [triggerFraction],
// the over-scroll distance (as a fraction of the viewport) the user must drag
// before the refresh arms. Flutter hardcodes this to 0.25 with no public knob;
// we raise the default to 0.40 so pull-to-refresh requires a longer, more
// intentional drag and stops firing by accident.
//
// The public API mirrors [RefreshIndicator] so it is a drop-in replacement.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/material.dart';

// How much the scroll's drag gesture can overshoot the indicator's
// displacement; max displacement = _kDragSizeFactorLimit * displacement.
const double _kDragSizeFactorLimit = 1.5;

// When the scroll ends, the duration of the indicator's animation to the
// indicator's displacement.
const Duration _kIndicatorSnapDuration = Duration(milliseconds: 150);

// The duration of the ScaleTransition that starts when the refresh action
// has completed.
const Duration _kIndicatorScaleDuration = Duration(milliseconds: 200);

enum _RefreshStatus { drag, armed, snap, refresh, done, canceled }

/// A Material "swipe to refresh" widget that requires a longer drag than the
/// stock [RefreshIndicator] before it arms. Drop-in compatible with
/// [RefreshIndicator]'s default constructor; tune the required drag via
/// [triggerFraction].
class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    super.key,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = RefreshProgressIndicator.defaultStrokeWidth,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.elevation = 2.0,
    this.triggerFraction = 0.60,
    required this.child,
  }) : assert(elevation >= 0.0),
       assert(triggerFraction > 0.0);

  final Widget child;
  final double displacement;
  final double edgeOffset;
  final RefreshCallback onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final ScrollNotificationPredicate notificationPredicate;
  final String? semanticsLabel;
  final String? semanticsValue;
  final double strokeWidth;
  final RefreshIndicatorTriggerMode triggerMode;
  final double elevation;

  /// Over-scroll distance to arm the refresh, as a fraction of the scrollable's
  /// viewport extent. Flutter's built-in value is 0.25; defaults to 0.40 here.
  final double triggerFraction;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator>
    with TickerProviderStateMixin<AppRefreshIndicator> {
  late AnimationController _positionController;
  late AnimationController _scaleController;
  late Animation<double> _positionFactor;
  late Animation<double> _scaleFactor;
  late Animation<double> _value;
  late Animation<Color?> _valueColor;

  _RefreshStatus? _status;
  late Future<void> _pendingRefreshFuture;
  bool? _isIndicatorAtTop;
  double? _dragOffset;
  late Color _effectiveValueColor =
      widget.color ?? Theme.of(context).colorScheme.primary;

  static final Animatable<double> _threeQuarterTween = Tween<double>(
    begin: 0.0,
    end: 0.75,
  );

  static final Animatable<double> _kDragSizeFactorLimitTween = Tween<double>(
    begin: 0.0,
    end: _kDragSizeFactorLimit,
  );

  static final Animatable<double> _oneToZeroTween = Tween<double>(
    begin: 1.0,
    end: 0.0,
  );

  @override
  void initState() {
    super.initState();
    _positionController = AnimationController(vsync: this);
    _positionFactor = _positionController.drive(_kDragSizeFactorLimitTween);

    // The "value" of the circular progress indicator during a drag.
    _value = _positionController.drive(_threeQuarterTween);

    _scaleController = AnimationController(vsync: this);
    _scaleFactor = _scaleController.drive(_oneToZeroTween);
  }

  @override
  void didChangeDependencies() {
    _setupColorTween();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant AppRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _setupColorTween();
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _setupColorTween() {
    // Reset the current value color.
    _effectiveValueColor =
        widget.color ?? Theme.of(context).colorScheme.primary;
    final Color color = _effectiveValueColor;
    if (color.a == 0.0) {
      // Set an always stopped animation instead of a driven tween.
      _valueColor = AlwaysStoppedAnimation<Color>(color);
    } else {
      // Respect the alpha of the given color.
      _valueColor = _positionController.drive(
        ColorTween(begin: color.withValues(alpha: 0.0), end: color).chain(
          CurveTween(curve: const Interval(0.0, 1.0 / _kDragSizeFactorLimit)),
        ),
      );
    }
  }

  bool _shouldStart(ScrollNotification notification) {
    // If notification.dragDetails is null, this scroll is not triggered by the
    // user dragging (e.g. ScrollController.jumpTo or a ballistic scroll), so we
    // don't want to trigger the refresh indicator.
    return ((notification is ScrollStartNotification &&
                notification.dragDetails != null) ||
            (notification is ScrollUpdateNotification &&
                notification.dragDetails != null &&
                widget.triggerMode == RefreshIndicatorTriggerMode.anywhere)) &&
        ((notification.metrics.axisDirection == AxisDirection.up &&
                notification.metrics.extentAfter == 0.0) ||
            (notification.metrics.axisDirection == AxisDirection.down &&
                notification.metrics.extentBefore == 0.0)) &&
        _status == null &&
        _start(notification.metrics.axisDirection);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }
    if (_shouldStart(notification)) {
      setState(() {
        _status = _RefreshStatus.drag;
      });
      return false;
    }
    final bool? indicatorAtTopNow =
        switch (notification.metrics.axisDirection) {
          AxisDirection.down || AxisDirection.up => true,
          AxisDirection.left || AxisDirection.right => null,
        };
    if (indicatorAtTopNow != _isIndicatorAtTop) {
      if (_status == _RefreshStatus.drag || _status == _RefreshStatus.armed) {
        _dismiss(_RefreshStatus.canceled);
      }
    } else if (notification is ScrollUpdateNotification) {
      if (_status == _RefreshStatus.drag || _status == _RefreshStatus.armed) {
        if (notification.metrics.axisDirection == AxisDirection.down) {
          _dragOffset = _dragOffset! - notification.scrollDelta!;
        } else if (notification.metrics.axisDirection == AxisDirection.up) {
          _dragOffset = _dragOffset! + notification.scrollDelta!;
        }
        _checkDragOffset(notification.metrics.viewportDimension);
      }
      if (_status == _RefreshStatus.armed && notification.dragDetails == null) {
        // On iOS start the refresh when the Scrollable bounces back from the
        // overscroll (these notifications don't have dragDetails because the
        // scroll activity is not directly triggered by a drag).
        _show();
      }
    } else if (notification is OverscrollNotification) {
      if (_status == _RefreshStatus.drag || _status == _RefreshStatus.armed) {
        if (notification.metrics.axisDirection == AxisDirection.down) {
          _dragOffset = _dragOffset! - notification.overscroll;
        } else if (notification.metrics.axisDirection == AxisDirection.up) {
          _dragOffset = _dragOffset! + notification.overscroll;
        }
        _checkDragOffset(notification.metrics.viewportDimension);
      }
    } else if (notification is ScrollEndNotification) {
      switch (_status) {
        case _RefreshStatus.armed:
          if (_positionController.value < 1.0) {
            _dismiss(_RefreshStatus.canceled);
          } else {
            _show();
          }
        case _RefreshStatus.drag:
          _dismiss(_RefreshStatus.canceled);
        case _RefreshStatus.canceled:
        case _RefreshStatus.done:
        case _RefreshStatus.refresh:
        case _RefreshStatus.snap:
        case null:
          // do nothing
          break;
      }
    }
    return false;
  }

  bool _handleIndicatorNotification(
    OverscrollIndicatorNotification notification,
  ) {
    if (notification.depth != 0 || !notification.leading) {
      return false;
    }
    if (_status == _RefreshStatus.drag) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  bool _start(AxisDirection direction) {
    assert(_status == null);
    assert(_isIndicatorAtTop == null);
    assert(_dragOffset == null);
    switch (direction) {
      case AxisDirection.down:
      case AxisDirection.up:
        _isIndicatorAtTop = true;
      case AxisDirection.left:
      case AxisDirection.right:
        _isIndicatorAtTop = null;
        // we do not support horizontal scroll views.
        return false;
    }
    _dragOffset = 0.0;
    _scaleController.value = 0.0;
    _positionController.value = 0.0;
    return true;
  }

  void _checkDragOffset(double containerExtent) {
    assert(_status == _RefreshStatus.drag || _status == _RefreshStatus.armed);
    double newValue = _dragOffset! / (containerExtent * widget.triggerFraction);
    if (_status == _RefreshStatus.armed) {
      newValue = math.max(newValue, 1.0 / _kDragSizeFactorLimit);
    }
    // This triggers various rebuilds.
    _positionController.value = clampDouble(newValue, 0.0, 1.0);
    if (_status == _RefreshStatus.drag &&
        _valueColor.value!.a == _effectiveValueColor.a) {
      _status = _RefreshStatus.armed;
    }
  }

  // Stop showing the refresh indicator.
  Future<void> _dismiss(_RefreshStatus newMode) async {
    await Future<void>.value();
    // This can only be called from _show() when refreshing and
    // _handleScrollNotification in response to a ScrollEndNotification or
    // direction change.
    assert(
      newMode == _RefreshStatus.canceled || newMode == _RefreshStatus.done,
    );
    setState(() {
      _status = newMode;
    });
    switch (_status!) {
      case _RefreshStatus.done:
        await _scaleController.animateTo(
          1.0,
          duration: _kIndicatorScaleDuration,
        );
      case _RefreshStatus.canceled:
        await _positionController.animateTo(
          0.0,
          duration: _kIndicatorScaleDuration,
        );
      case _RefreshStatus.armed:
      case _RefreshStatus.drag:
      case _RefreshStatus.refresh:
      case _RefreshStatus.snap:
        assert(false);
    }
    if (mounted && _status == newMode) {
      _dragOffset = null;
      _isIndicatorAtTop = null;
      setState(() {
        _status = null;
      });
    }
  }

  void _show() {
    assert(_status != _RefreshStatus.refresh);
    assert(_status != _RefreshStatus.snap);
    final completer = Completer<void>();
    _pendingRefreshFuture = completer.future;
    _status = _RefreshStatus.snap;
    _positionController
        .animateTo(
          1.0 / _kDragSizeFactorLimit,
          duration: _kIndicatorSnapDuration,
        )
        .then<void>((void value) {
          if (mounted && _status == _RefreshStatus.snap) {
            setState(() {
              // Show the indeterminate progress indicator.
              _status = _RefreshStatus.refresh;
            });

            final Future<void> refreshResult = widget.onRefresh();
            refreshResult.whenComplete(() {
              if (mounted && _status == _RefreshStatus.refresh) {
                completer.complete();
                _dismiss(_RefreshStatus.done);
              }
            });
          }
        });
  }

  /// Show the refresh indicator and run the refresh callback as if it had been
  /// started interactively. Quietly does nothing if a refresh is in progress.
  Future<void> show({bool atTop = true}) {
    if (_status != _RefreshStatus.refresh && _status != _RefreshStatus.snap) {
      if (_status == null) {
        _start(atTop ? AxisDirection.down : AxisDirection.up);
      }
      _show();
    }
    return _pendingRefreshFuture;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final Widget child = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _handleIndicatorNotification,
        child: widget.child,
      ),
    );
    assert(() {
      if (_status == null) {
        assert(_dragOffset == null);
        assert(_isIndicatorAtTop == null);
      } else {
        assert(_dragOffset != null);
        assert(_isIndicatorAtTop != null);
      }
      return true;
    }());

    final bool showIndeterminateIndicator =
        _status == _RefreshStatus.refresh || _status == _RefreshStatus.done;

    return Stack(
      children: <Widget>[
        child,
        if (_status != null)
          Positioned(
            top: _isIndicatorAtTop! ? widget.edgeOffset : null,
            bottom: !_isIndicatorAtTop! ? widget.edgeOffset : null,
            left: 0.0,
            right: 0.0,
            child: SizeTransition(
              alignment: AlignmentDirectional(
                -1.0,
                _isIndicatorAtTop! ? 1.0 : -1.0,
              ),
              sizeFactor: _positionFactor, // This is what brings it down.
              child: Padding(
                padding: _isIndicatorAtTop!
                    ? EdgeInsets.only(top: widget.displacement)
                    : EdgeInsets.only(bottom: widget.displacement),
                child: Align(
                  alignment: _isIndicatorAtTop!
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: ScaleTransition(
                    scale: _scaleFactor,
                    child: AnimatedBuilder(
                      animation: _positionController,
                      builder: (BuildContext context, Widget? child) {
                        return RefreshProgressIndicator(
                          semanticsLabel:
                              widget.semanticsLabel ??
                              MaterialLocalizations.of(
                                context,
                              ).refreshIndicatorSemanticLabel,
                          semanticsValue: widget.semanticsValue,
                          value: showIndeterminateIndicator
                              ? null
                              : _value.value,
                          valueColor: _valueColor,
                          backgroundColor: widget.backgroundColor,
                          strokeWidth: widget.strokeWidth,
                          elevation: widget.elevation,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
