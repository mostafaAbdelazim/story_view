import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../controller/story_controller.dart';
import '../utils.dart';

class VideoLoader {
  String url;

  File videoFile;

  Map<String, dynamic> requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    if (this.videoFile != null) {
      this.state = LoadState.success;
      onComplete();
    }

    final fileStream = DefaultCacheManager()
        .getFileStream(this.url, headers: this.requestHeaders);

    fileStream.listen((fileResponse) {
      if (fileResponse is FileInfo) {
        if (this.videoFile == null) {
          this.state = LoadState.success;
          this.videoFile = fileResponse.file;
          onComplete();
        }
      }
    });
  }
}

class StoryVideo extends StatefulWidget {
  final StoryController storyController;
  final String videoUrl;

  StoryVideo(this.videoUrl, {this.storyController, Key key})
      : super(key: key ?? UniqueKey());

  static StoryVideo url(String url,
      {StoryController controller,
      Map<String, dynamic> requestHeaders,
      Key key}) {
    return StoryVideo(
      url,
      storyController: controller,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void> playerLoader;

  StreamSubscription _streamSubscription;

  VideoPlayerController playerController;

  @override
  void initState() {
    super.initState();

    widget.storyController.pause();
    this.playerController = VideoPlayerController.network(widget.videoUrl);

    playerController.initialize().then((v) {
      setState(() {});
      widget.storyController.play();
    });

    if (widget.storyController != null) {
      _streamSubscription =
          widget.storyController.playbackNotifier.listen((playbackState) {
        if (playbackState == PlaybackState.pause) {
          playerController.pause();
            } else {
              playerController.play();
            }
          });
        }
  }

  Widget getContentView() {
    if (playerController.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: playerController.value.aspectRatio,
          child: VideoPlayer(playerController),
        ),
      );
    } else {
      return Center(
        child: Container(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: getContentView(),
    );
  }

  @override
  void dispose() {
    playerController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
