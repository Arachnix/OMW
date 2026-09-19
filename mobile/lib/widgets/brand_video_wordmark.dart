import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';

/// Plays the handwritten OnMyWay wordmark animation once, muted, from the
/// bundled MP4.
///
/// Falls back to the static wordmark image when the video can't be
/// initialised (e.g. unsupported platform, tests) or when the user has asked
/// the OS to reduce motion. [onFinished] fires when playback completes, or
/// right away when the fallback is shown.
class BrandVideoWordmark extends StatefulWidget {
  const BrandVideoWordmark({
    super.key,
    this.videoAsset = AppImages.wordmarkVideo,
    this.fallbackAsset = AppImages.wordmarkStill,
    this.width = 280,
    this.onFinished,
  });

  final String videoAsset;
  final String fallbackAsset;
  final double width;
  final VoidCallback? onFinished;

  @override
  State<BrandVideoWordmark> createState() => _BrandVideoWordmarkState();
}

class _BrandVideoWordmarkState extends State<BrandVideoWordmark> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _useFallback = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || _useFallback) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _showFallback();
    } else {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(
      widget.videoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(false);
      if (!mounted) return;
      controller.addListener(_onTick);
      await controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) _showFallback();
    }
  }

  void _onTick() {
    final value = _controller?.value;
    if (value == null ||
        !value.isInitialized ||
        value.duration == Duration.zero) {
      return;
    }
    if (value.position >= value.duration) _finish();
  }

  void _showFallback() {
    setState(() => _useFallback = true);
    _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final showVideo = _ready && !_useFallback && controller != null;
    return Semantics(
      image: true,
      label: 'OnMyWay',
      excludeSemantics: true,
      child: SizedBox(
        width: widget.width,
        child: AnimatedSwitcher(
          duration: AppMotion.medium,
          child: showVideo
              ? AspectRatio(
                  key: const ValueKey('video'),
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                )
              : _useFallback
              ? _still()
              // Blank space of the wordmark's size while the video loads,
              // so the still doesn't flash before the animation starts.
              : SizedBox(
                  key: const ValueKey('loading'),
                  height: widget.width * 110 / 355,
                ),
        ),
      ),
    );
  }

  Widget _still() {
    return Image.asset(
      widget.fallbackAsset,
      key: const ValueKey('still'),
      width: widget.width,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Text(
        'OnMyWay',
        textAlign: TextAlign.center,
        style: AppText.price.copyWith(color: AppColors.ink),
      ),
    );
  }
}
