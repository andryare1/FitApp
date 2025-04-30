import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';

class ExerciseDetailPage extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _hasError = false;
  Timer? _loadTimeoutTimer;

  @override
  void initState() {
    super.initState();
    
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {


    
  try {
    final videoUrl = widget.exercise['videoUrl']?.toString();
    
    if (videoUrl == null || videoUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    _startTimeoutTimer();

    // Инициализация с обработкой платформы
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      // Добавляем конфигурацию для Android/iOS
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    )..addListener(_videoListener);

    // Явная проверка поддержки формата
    final isFormatSupported = await _videoController.initialize().then((_) {
      return _videoController.value.isInitialized;
    }).catchError((_) => false);

    if (!isFormatSupported) {
      throw Exception('Формат видео не поддерживается');
    }

    if (mounted) {
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        showControls: true,
        allowedScreenSleep: false, // Важно для iOS
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
        errorBuilder: (context, errorMessage) {
          return _buildErrorPlaceholder();
        },
      );
      _cancelTimer();
      setState(() => _isVideoInitialized = true);
    }
  } catch (e) {
    debugPrint('Error initializing video: $e');
    if (mounted) setState(() => _hasError = true);
    _cancelTimer();
    await _videoController.dispose();
  }
}

  void _videoListener() {
    if (_videoController.value.hasError && mounted) {
      setState(() => _hasError = true);
      _cancelTimer();
    }
  }

  void _startTimeoutTimer() {
    _loadTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isVideoInitialized && !_hasError) {
        setState(() => _hasError = true);
      }
    });
  }

  void _cancelTimer() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = null;
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _chewieController?.dispose();
    _cancelTimer();
    super.dispose();
  }

  String getMuscleGroupName(dynamic muscleGroup) {
    if (muscleGroup is String) {
      switch (muscleGroup) {
        case 'Chest': return 'Грудь';
        case 'Back': return 'Спина';
        case 'Shoulders': return 'Плечи';
        case 'Arms': return 'Руки';
        case 'Legs': return 'Ноги';
        case 'Abs': return 'Пресс';
        default: return 'Неизвестная группа';
      }
    } else if (muscleGroup is int) {
      switch (muscleGroup) {
        case 0: return 'Грудь';
        case 1: return 'Спина';
        case 2: return 'Плечи';
        case 3: return 'Руки';
        case 4: return 'Ноги';
        case 5: return 'Пресс';
        default: return 'Неизвестная группа';
      }
    }
    return 'Неизвестная группа';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise['name']),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16/9,
                child: _buildVideoWidget(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Группа мышц:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(getMuscleGroupName(widget.exercise['muscleGroup']), 
              style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Описание:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(widget.exercise['description'] ?? 'Описание отсутствует',
              style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoWidget() {
    if (_hasError) {
      return _buildErrorPlaceholder();
    }

    if (!_isVideoInitialized) {
      return _buildLoadingIndicator();
    }

    return Chewie(controller: _chewieController!);
  }

  Widget _buildLoadingIndicator() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Видео недоступно',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _retryVideoLoading,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }

  void _retryVideoLoading() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _isVideoInitialized = false;
      });
      _initializeVideo();
    }
  }
}