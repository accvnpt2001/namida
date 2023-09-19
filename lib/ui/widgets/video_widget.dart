import 'dart:async';

import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:namida/controller/current_color.dart';
import 'package:namida/controller/navigator_controller.dart';
import 'package:namida/controller/player_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/controller/video_controller.dart';
import 'package:namida/youtube/controller/youtube_controller.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/namida_converter_ext.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/packages/tap_detector.dart';
import 'package:namida/packages/three_arched_circle.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';

class NamidaVideoControls extends StatefulWidget {
  final CachedVideoPlayerController? controller;
  final Widget? child;
  final bool showControls;
  final VoidCallback? onMinimizeTap;
  final Widget? fallbackChild;
  final bool isFullScreen;
  final List<NamidaPopupItem> qualityItems;

  const NamidaVideoControls({
    super.key,
    required this.controller,
    required this.child,
    required this.showControls,
    required this.onMinimizeTap,
    required this.fallbackChild,
    required this.isFullScreen,
    this.qualityItems = const [],
  });

  @override
  State<NamidaVideoControls> createState() => NamidaVideoControlsState();
}

class NamidaVideoControlsState extends State<NamidaVideoControls> with TickerProviderStateMixin {
  Widget _getSliderContainer(
    Color colorScheme,
    BoxConstraints constraints,
    double percentage,
    int alpha,
  ) {
    return Container(
      height: 6.0,
      width: constraints.maxWidth * percentage,
      decoration: BoxDecoration(
        color: Color.alphaBlend(Colors.white.withOpacity(0.3), colorScheme).withAlpha(alpha),
        borderRadius: BorderRadius.circular(6.0.multipliedRadius),
      ),
    );
  }

  bool _isVisible = false;
  final hideDuration = const Duration(seconds: 3);
  final transitionDuration = const Duration(milliseconds: 300);

  Timer? _hideTimer;
  void _resetTimer({bool hideControls = false}) {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (hideControls) setControlsVisibily(false);
  }

  void _startTimer() {
    _resetTimer();
    if (_isVisible) {
      _hideTimer = Timer(hideDuration, () {
        setControlsVisibily(false);
      });
    }
  }

  void setControlsVisibily(bool visible) {
    _isVisible = visible;
    if (mounted) setState(() {});
  }

  final userSeek = ValueNotifier<double>(0.0);

  Widget _getBuilder({
    required Widget Function(double visiblePercentage, CachedVideoPlayerValue? playerController) child,
    ValueListenable<CachedVideoPlayerValue>? playerController,
  }) {
    return IgnorePointer(
      ignoring: !_isVisible,
      child: AnimatedOpacity(
        duration: transitionDuration,
        opacity: _isVisible ? 1.0 : 0.0,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: transitionDuration,
          builder: (context, perc, _) => playerController == null
              ? child(perc, null)
              : ValueListenableBuilder(
                  valueListenable: playerController,
                  builder: (context, CachedVideoPlayerValue c, _) {
                    return child(perc, c);
                  }),
        ),
      ),
    );
  }

  void _onTap() {
    if (_isVisible) {
      setControlsVisibily(false);
    } else {
      if (widget.showControls) {
        setControlsVisibily(true);
      }
    }
    _startTimer();
  }

  int _seekSeconds = 0;

  void _onDoubleTap(TapDownDetails details) async {
    final totalWidth = context.width;
    final halfScreen = totalWidth / 2;
    final middleAmmountToIgnore = totalWidth / 6;
    final pos = details.localPosition.dx - halfScreen;
    if (pos.abs() > middleAmmountToIgnore) {
      if (pos.isNegative) {
        animateSeekControllers(false);
        _seekSeconds = await Player.inst.seekSecondsBackward();
      } else {
        animateSeekControllers(true);
        _seekSeconds = await Player.inst.seekSecondsForward();
      }
    }
  }

  void animateSeekControllers(bool isForward) async {
    if (isForward) {
      // -- first container
      _animateAfterDelayMS(controller: seekAnimationForward1, delay: 0, target: 1.0);
      _animateAfterDelayMS(controller: seekAnimationForward1, delay: 500, target: 0.0);

      // -- second container
      _animateAfterDelayMS(controller: seekAnimationForward2, delay: 200, target: 1.0);
      _animateAfterDelayMS(controller: seekAnimationForward2, delay: 600, target: 0.0);
    } else {
      // -- first container
      _animateAfterDelayMS(controller: seekAnimationBackward1, delay: 0, target: 1.0);
      _animateAfterDelayMS(controller: seekAnimationBackward1, delay: 500, target: 0.0);

      // -- second container
      _animateAfterDelayMS(controller: seekAnimationBackward2, delay: 200, target: 1.0);
      _animateAfterDelayMS(controller: seekAnimationBackward2, delay: 600, target: 0.0);
    }
  }

  Future<void> _animateAfterDelayMS({
    required AnimationController controller,
    required int delay,
    required double target,
  }) async {
    await Future.delayed(Duration(milliseconds: delay));
    await controller.animateTo(target);
  }

  @override
  void initState() {
    super.initState();
    const dur = Duration(milliseconds: 200);
    const dur2 = Duration(milliseconds: 200);
    seekAnimationForward1 = AnimationController(
      vsync: this,
      duration: dur,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    seekAnimationForward2 = AnimationController(
      vsync: this,
      duration: dur2,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    seekAnimationBackward1 = AnimationController(
      vsync: this,
      duration: dur,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    seekAnimationBackward2 = AnimationController(
      vsync: this,
      duration: dur2,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    seekAnimationForward1.dispose();
    seekAnimationForward2.dispose();
    seekAnimationBackward1.dispose();
    seekAnimationBackward2.dispose();
    super.dispose();
  }

  late AnimationController seekAnimationForward1;
  late AnimationController seekAnimationForward2;
  late AnimationController seekAnimationBackward1;
  late AnimationController seekAnimationBackward2;

  Widget _getSeekAnimatedContainer({
    required AnimationController controller,
    required bool isForward,
    required bool isSecondary,
  }) {
    final seekContainerSize = context.width;
    final offsetPercentage = isSecondary ? 0.7 : 0.55;
    final finalOffset = -(seekContainerSize * offsetPercentage);
    return Positioned(
      right: isForward ? finalOffset : null,
      left: isForward ? null : finalOffset,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Opacity(
              opacity: controller.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                width: seekContainerSize,
                height: seekContainerSize,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget getSeekTextWidget({
    required AnimationController controller,
    required bool isForward,
  }) {
    final seekContainerSize = context.width;
    final finalOffset = seekContainerSize * 0.05;
    final color = Colors.black.withOpacity(0.8);
    final forwardIcons = <int, IconData>{
      5: Broken.forward_5_seconds,
      10: Broken.forward_10_seconds,
      15: Broken.forward_15_seconds,
    };
    final backwardIcons = <int, IconData>{
      5: Broken.backward_5_seconds,
      10: Broken.backward_10_seconds,
      15: Broken.backward_15_seconds,
    };
    return Positioned(
      right: isForward ? finalOffset : null,
      left: isForward ? null : finalOffset,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Opacity(
              opacity: controller.value,
              child: Obx(
                () {
                  final seekSecondsInSett = settings.isSeekDurationPercentage.value ? null : settings.seekDurationInSeconds.value;
                  final ss = seekSecondsInSett ?? _seekSeconds;
                  return Column(
                    children: [
                      Icon(
                        isForward ? forwardIcons[ss] ?? Broken.forward : backwardIcons[ss] ?? Broken.backward,
                        color: color,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '$ss ${lang.SECONDS}',
                        style: context.textTheme.displayMedium?.copyWith(color: color),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dummyWidget = widget.fallbackChild ?? Container(color: Colors.transparent);
    final vc = widget.controller;
    final itemsColor = Colors.white.withAlpha(200);
    return Stack(
      alignment: Alignment.center,
      children: [
        TapDetector(
          onTap: (d) => _onTap(),
          onDoubleTap: _onDoubleTap,
          doubleTapTime: const Duration(milliseconds: 200),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                key: const Key('always_visible_child'),
                child: Obx(
                  () => VideoController.vcontroller.isInitialized ? widget.child ?? dummyWidget : dummyWidget,
                ),
              ),
              if (widget.showControls) ...[
                // ---- Top Row ----
                GestureDetector(
                  onTap: () {},
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _getBuilder(
                      child: (visiblePercentage, _) {
                        return Row(
                          children: [
                            if (widget.isFullScreen || widget.onMinimizeTap != null)
                              NamidaIconButton(
                                horizontalPadding: 12.0,
                                verticalPadding: 6.0,
                                onPressed: widget.isFullScreen ? NamidaNavigator.inst.exitFullScreen : widget.onMinimizeTap,
                                icon: Broken.arrow_down_2,
                                iconColor: itemsColor,
                                iconSize: 20.0,
                              ),
                            const Spacer(),
                            // ===== Speed Chip =====
                            NamidaPopupWrapper(
                              onPop: _startTimer,
                              onTap: () {
                                _resetTimer();
                                setControlsVisibily(true);
                              },
                              children: [
                                ...[0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
                                  return Obx(
                                    () {
                                      final isSelected = Player.inst.currentSpeed == speed;
                                      return NamidaInkWell(
                                        onTap: () {
                                          _startTimer();
                                          Navigator.of(context).pop();
                                          if (!isSelected) {
                                            Player.inst.setPlayerSpeed(speed);
                                          }
                                        },
                                        decoration: const BoxDecoration(),
                                        borderRadius: 6.0,
                                        bgColor: isSelected ? CurrentColor.inst.color.withAlpha(100) : null,
                                        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                        padding: const EdgeInsets.all(6.0),
                                        child: Row(
                                          children: [
                                            const Icon(Broken.play_cricle, size: 20.0),
                                            const SizedBox(width: 12.0),
                                            Text(
                                              "$speed",
                                              style: context.textTheme.displayMedium?.copyWith(fontSize: 13.0.multipliedFontScale),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6.0.multipliedRadius),
                                  child: NamidaBgBlur(
                                    blur: visiblePercentage * 3.0,
                                    child: NamidaInkWell(
                                      onTap: null,
                                      borderRadius: 6.0,
                                      bgColor: Colors.black.withOpacity(0.2 * visiblePercentage),
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                      child: Obx(
                                        () => Row(
                                          children: [
                                            Icon(
                                              Broken.play_cricle,
                                              size: 20.0,
                                              color: itemsColor,
                                            ),
                                            const SizedBox(width: 4.0).animateEntrance(showWhen: Player.inst.currentSpeed != 1.0, allCurves: Curves.easeInOutQuart),
                                            Text(
                                              "${Player.inst.currentSpeed}",
                                              style: context.textTheme.displaySmall?.copyWith(
                                                color: itemsColor,
                                                fontSize: 12.0,
                                              ),
                                            ).animateEntrance(showWhen: Player.inst.currentSpeed != 1.0, allCurves: Curves.easeInOutQuart),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // ===== Quality Chip =====
                            Obx(
                              () => NamidaPopupWrapper(
                                canOpenMenu: Player.inst.currentVideoStream?.resolution != null,
                                onPop: _startTimer,
                                onTap: () {
                                  _resetTimer();
                                  setControlsVisibily(true);
                                },
                                childrenDefault: widget.qualityItems,
                                children: [
                                  ...YoutubeController.inst.currentYTQualities.where((s) => s.formatSuffix != 'webm').map((element) {
                                    return Obx(
                                      () {
                                        final isSelected = element.resolution == Player.inst.currentVideoStream?.resolution;
                                        final id = Player.inst.nowPlayingVideoID?.id;
                                        final cachedFile = id == null ? null : element.getCachedFile(id);
                                        return NamidaInkWell(
                                          onTap: () {
                                            _startTimer();
                                            Navigator.of(context).pop();
                                            if (!isSelected) {
                                              Player.inst.onItemPlayYoutubeIDSetQuality(element, cachedFile, useCache: true);
                                            }
                                          },
                                          decoration: const BoxDecoration(),
                                          borderRadius: 6.0,
                                          bgColor: isSelected ? CurrentColor.inst.color.withAlpha(100) : null,
                                          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                          padding: const EdgeInsets.all(6.0),
                                          child: Row(
                                            children: [
                                              Icon(cachedFile != null ? Broken.tick_circle : Broken.story, size: 20.0),
                                              const SizedBox(width: 4.0),
                                              Text(
                                                element.resolution ?? '',
                                                style: context.textTheme.displayMedium?.copyWith(fontSize: 13.0.multipliedFontScale),
                                              ),
                                              Text(
                                                " • ${element.sizeInBytes?.fileSizeFormatted ?? ''}",
                                                style: context.textTheme.displaySmall?.copyWith(fontSize: 12.0.multipliedFontScale),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6.0.multipliedRadius),
                                    child: NamidaBgBlur(
                                      blur: visiblePercentage * 3.0,
                                      child: NamidaInkWell(
                                        onTap: null,
                                        borderRadius: 6.0,
                                        bgColor: Colors.black.withOpacity(0.2 * visiblePercentage),
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                        child: Row(
                                          children: [
                                            Obx(
                                              () => Text(
                                                Player.inst.currentVideoStream?.resolution ?? '',
                                                style: context.textTheme.displaySmall?.copyWith(color: itemsColor),
                                              ),
                                            ),
                                            const SizedBox(width: 4.0),
                                            Icon(
                                              Broken.setting,
                                              color: itemsColor,
                                              size: 20.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // ---- Bottom Row ----
                GestureDetector(
                  onTap: () {},
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _getBuilder(
                      playerController: vc,
                      child: (visiblePercentage, pcn) {
                        final playerPosition = pcn?.position ?? Duration.zero;
                        final playerDuration = pcn?.duration ?? Duration.zero;
                        final playerBuffered = pcn?.buffered ?? [];
                        final currentPosition = VideoController.vcontroller.isInitialized ? playerPosition : Duration.zero;
                        final borr = BorderRadius.circular(10.0.multipliedRadius);
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: borr,
                            child: NamidaBgBlur(
                              blur: visiblePercentage * 3.0,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2 * visiblePercentage),
                                  borderRadius: borr,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      currentPosition.inSeconds.secondsLabel,
                                      style: context.textTheme.displayMedium?.copyWith(
                                        color: itemsColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          void onSeekDragUpdate(double deltax) {
                                            final percentageSwiped = (deltax / constraints.maxWidth).withMinimum(0.0);
                                            final newSeek = percentageSwiped * (playerDuration.inMilliseconds);
                                            userSeek.value = newSeek;
                                          }

                                          void onSeekEnd() async {
                                            await Player.inst.seek(Duration(milliseconds: userSeek.value.toInt()));
                                            userSeek.value = 0;
                                          }

                                          return GestureDetector(
                                              behavior: HitTestBehavior.translucent,
                                              onTapDown: (details) {
                                                onSeekDragUpdate(details.localPosition.dx);
                                                _resetTimer();
                                              },
                                              onTapUp: (details) {
                                                onSeekEnd();
                                                _startTimer();
                                              },
                                              onTapCancel: () {
                                                userSeek.value = 0;
                                                _startTimer();
                                              },
                                              onHorizontalDragStart: (details) => _resetTimer(),
                                              onHorizontalDragUpdate: (details) => onSeekDragUpdate(details.localPosition.dx),
                                              onHorizontalDragEnd: (details) => onSeekEnd(),
                                              child: ValueListenableBuilder(
                                                valueListenable: userSeek,
                                                builder: (_, double seekvaluee, child) {
                                                  final durMS = playerDuration.inMilliseconds;
                                                  final currentSeekValue = seekvaluee == 0 ? currentPosition.inMilliseconds : seekvaluee;
                                                  final currentPercentage = durMS == 0.0 ? 0.0 : currentSeekValue / durMS;

                                                  const circleSize = 20.0;
                                                  final colorScheme = context.theme.colorScheme.secondary;
                                                  final nextBufferedRange = playerBuffered.lastOrNull;
                                                  return Stack(
                                                    alignment: Alignment.centerLeft,
                                                    children: [
                                                      _getSliderContainer(
                                                        colorScheme,
                                                        constraints,
                                                        currentPercentage,
                                                        160,
                                                      ),
                                                      if (nextBufferedRange != null)
                                                        _getSliderContainer(
                                                          colorScheme,
                                                          constraints,
                                                          (nextBufferedRange.end).inMilliseconds / durMS,
                                                          100,
                                                        ),
                                                      _getSliderContainer(
                                                        colorScheme,
                                                        constraints,
                                                        1.0,
                                                        60,
                                                      ),
                                                      Container(
                                                        alignment: Alignment.center,
                                                        margin:
                                                            EdgeInsets.only(left: ((constraints.maxWidth * currentPercentage) - circleSize * 0.5).clamp(0, constraints.maxWidth)),
                                                        decoration: BoxDecoration(
                                                          color: colorScheme,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        width: circleSize,
                                                        height: circleSize,
                                                        child: Container(
                                                          alignment: Alignment.center,
                                                          decoration: const BoxDecoration(
                                                            color: Color.fromARGB(220, 40, 40, 40),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          width: circleSize / 2,
                                                          height: circleSize / 2,
                                                        ),
                                                      )
                                                    ],
                                                  );
                                                },
                                              ));
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      playerDuration.inSeconds.secondsLabel,
                                      style: context.textTheme.displayMedium?.copyWith(
                                        color: itemsColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    NamidaIconButton(
                                      horizontalPadding: 0.0,
                                      padding: EdgeInsets.zero,
                                      iconSize: 20.0,
                                      icon: Broken.maximize_2,
                                      iconColor: itemsColor,
                                      onPressed: () {
                                        _startTimer();
                                        NamidaNavigator.inst.toggleFullScreen(
                                          VideoController.inst.getVideoWidget(
                                            'video_controls_full_screen',
                                            true,
                                            widget.onMinimizeTap,
                                            fullscreen: true,
                                            fallbackChild: widget.fallbackChild,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ---- Middle Actions ----
                _getBuilder(
                  playerController: vc,
                  child: (visiblePercentage, pcn) {
                    final shouldShowNext = Player.inst.currentIndex != Player.inst.currentQueueYoutube.length - 1;
                    final shouldShowPrev = Player.inst.currentIndex != 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(),
                        IgnorePointer(
                          ignoring: !shouldShowPrev,
                          child: Opacity(
                            opacity: shouldShowPrev ? 1.0 : 0.0,
                            child: ClipOval(
                              child: NamidaBgBlur(
                                blur: visiblePercentage * 2,
                                child: Container(
                                  color: Colors.black.withOpacity(0.2 * visiblePercentage),
                                  padding: const EdgeInsets.all(10.0),
                                  child: NamidaIconButton(
                                      icon: null,
                                      horizontalPadding: 0.0,
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        Player.inst.previous();
                                        _resetTimer(hideControls: true);
                                      },
                                      child: Icon(
                                        Broken.previous,
                                        size: 30.0,
                                        color: itemsColor,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ClipOval(
                          child: NamidaBgBlur(
                            blur: visiblePercentage * 2.5,
                            child: Container(
                              color: Colors.black.withOpacity(0.3 * visiblePercentage),
                              padding: const EdgeInsets.all(14.0),
                              child: Obx(
                                () {
                                  final currentPosition = Player.inst.nowPlayingPosition;
                                  final currentTotalDur = Player.inst.currentItemDuration?.inMilliseconds ?? 0;
                                  final reachedLastPosition = currentPosition != 0 && (currentPosition - currentTotalDur).abs() < 200; // 200ms allowance
                                  if (reachedLastPosition) {
                                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                      setControlsVisibily(true);
                                    });
                                  }
                                  return Player.inst.isBuffering || VideoController.vcontroller.isBuffering || !VideoController.vcontroller.isInitialized
                                      ? ThreeArchedCircle(
                                          color: itemsColor,
                                          size: 40.0,
                                        )
                                      : reachedLastPosition
                                          ? NamidaIconButton(
                                              icon: null,
                                              horizontalPadding: 0.0,
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                await Player.inst.seek(Duration.zero);
                                                await Player.inst.play();
                                                _startTimer();
                                              },
                                              child: Icon(
                                                Broken.refresh,
                                                size: 40.0,
                                                color: itemsColor,
                                                key: const Key('replay'),
                                              ),
                                            )
                                          : NamidaIconButton(
                                              icon: null,
                                              horizontalPadding: 0.0,
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                Player.inst.togglePlayPause();
                                                _startTimer();
                                              },
                                              child: Obx(
                                                () => AnimatedSwitcher(
                                                  duration: const Duration(milliseconds: 200),
                                                  child: Player.inst.isPlaying
                                                      ? Icon(
                                                          Broken.pause,
                                                          size: 40.0,
                                                          color: itemsColor,
                                                          key: const Key('paused'),
                                                        )
                                                      : Icon(
                                                          Broken.play,
                                                          size: 40.0,
                                                          color: itemsColor,
                                                          key: const Key('playing'),
                                                        ),
                                                ),
                                              ),
                                            );
                                },
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          ignoring: !shouldShowNext,
                          child: Opacity(
                            opacity: shouldShowNext ? 1.0 : 0.0,
                            child: ClipOval(
                              child: NamidaBgBlur(
                                blur: visiblePercentage * 2,
                                child: Container(
                                  color: Colors.black.withOpacity(0.2 * visiblePercentage),
                                  padding: const EdgeInsets.all(10.0),
                                  child: NamidaIconButton(
                                      icon: null,
                                      horizontalPadding: 0.0,
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        Player.inst.previous();
                                        _resetTimer(hideControls: true);
                                      },
                                      child: Icon(
                                        Broken.next,
                                        size: 30.0,
                                        color: itemsColor,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(),
                      ],
                    );
                  },
                ),
                Obx(
                  () => Player.inst.isBuffering || VideoController.vcontroller.isBuffering || !VideoController.vcontroller.isInitialized
                      ? ThreeArchedCircle(
                          color: itemsColor,
                          size: 40.0,
                        )
                      : const SizedBox(),
                ),

                // ===== Seek Animators ====

                // -- left --
                _getSeekAnimatedContainer(
                  controller: seekAnimationBackward1,
                  isForward: false,
                  isSecondary: false,
                ),
                _getSeekAnimatedContainer(
                  controller: seekAnimationBackward2,
                  isForward: false,
                  isSecondary: true,
                ),

                // -- right --
                _getSeekAnimatedContainer(
                  controller: seekAnimationForward1,
                  isForward: true,
                  isSecondary: false,
                ),
                _getSeekAnimatedContainer(
                  controller: seekAnimationForward2,
                  isForward: true,
                  isSecondary: true,
                ),

                // ===========
                getSeekTextWidget(
                  controller: seekAnimationBackward2,
                  isForward: false,
                ),
                getSeekTextWidget(
                  controller: seekAnimationForward2,
                  isForward: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}