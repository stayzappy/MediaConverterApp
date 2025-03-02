import 'dart:io';








import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/log.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:zapmediaconverter/models/file_manager.dart';
import 'package:zapmediaconverter/models/utility_classes_and_methods.dart';


class FileListItem extends StatefulWidget {
  final String fileName;
  final String fileFormat;
  final String filePath;

  final Function({
    required bool isConverting,
    required double progress,
    required int currentFile,
    required int totalFiles,
  }) onConversionStateChanged;

  const FileListItem({
    Key? key,
    required this.fileName,
    required this.fileFormat,
    required this.filePath,
    required this.onConversionStateChanged,
  }) : super(key: key);

  @override
  State<FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<FileListItem> {
  String _duration = '';
  String? _selectedFormat = 'MP4';
  final _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;

//////For my Trim Functionality////////////////////
  double _startTrim = 0.0;
  double _endTrim = 1.0;
  int _durationInSeconds = 0;

  final List<Map<String, List<String>>> _formats = [
    {
      'Video': ['AVI', 'MKV', 'MOV', 'MP4', 'WEBM'],
      'Audio': ['AAC', 'FLAC', 'MP3', 'WAV', 'OGG'],
    }
  ];

  VideoCodec _selectedVideoCodec = videoCodecs[0];
  AudioCodec _selectedAudioCodec = audioCodecs[0];
  VideoResolution _selectedResolution = resolutions[1]; // Default to 1080p
  AudioBitrate _selectedAudioBitrate = audioBitrates[1]; // Default to 128kbps
  SampleRate _selectedSampleRate = sampleRates[1]; // Default to 44.1kHz
  VideoBitrate _selectedVideoBitrate = videoBitrates[1]; // Default to 2.5Mbps
  AudioChannel _selectedAudioChannel = audioChannels[1];

  // Add constants for settings options
  static const resolutions = [
    VideoResolution(
        '3840x2160', '4K Ultra HD - Highest quality, best for large screens'),
    VideoResolution(
        '1920x1080', 'Full HD - Great quality, standard for most devices'),
    VideoResolution('1280x720', 'HD - Good balance of quality and file size'),
    VideoResolution('640x480', 'SD - Smaller file size, legacy format'),
    VideoResolution('640x360', 'Low - Smallest file size, good for mobile'),
  ];

  static const audioBitrates = [
    AudioBitrate(92, 'Lower quality, smallest file size'),
    AudioBitrate(128, 'Standard quality, good for most content'),
    AudioBitrate(160, 'Good quality, balanced compression'),
    AudioBitrate(192, 'High quality, great for music'),
    AudioBitrate(320, 'Maximum quality, audiophile grade'),
  ];

  static const sampleRates = [
    SampleRate(22050, 'Basic quality - Suitable for speech'),
    SampleRate(44100, 'CD quality - Standard for music'),
    SampleRate(48000, 'Professional - Best for video production'),
  ];

  static const videoBitrates = [
    VideoBitrate(1000, '1 Mbps - Good for mobile viewing'),
    VideoBitrate(2500, '2.5 Mbps - Balanced quality'),
    VideoBitrate(5000, '5 Mbps - High quality streaming'),
    VideoBitrate(8000, '8 Mbps - Professional quality'),
    VideoBitrate(15000, '15 Mbps - Maximum quality'),
  ];

  static const videoCodecs = [
    VideoCodec('H.264', 'Universal compatibility, great for sharing'),
    VideoCodec('H.265', 'Better compression, modern devices only'),
    VideoCodec('AV1', 'Next-gen codec, best compression but slower'),
    VideoCodec('MPEG-2', 'Legacy format, DVD compatible'),
    VideoCodec('MPEG-4', 'Older format, widely supported'),
    VideoCodec('VP8', 'Open format, good for web'),
    VideoCodec('VP9', 'Advanced compression, YouTube standard'),
    VideoCodec('XVID', 'Classic codec, compatible with old devices'),
  ];

  static const audioCodecs = [
    AudioCodec('MP3', 'Universal compatibility, good compression'),
    AudioCodec('MP2', 'Legacy format, DVD audio compatible'),
    AudioCodec('WMA', 'Windows media format, good quality'),
    AudioCodec('AAC', 'High quality, great for streaming'),
    AudioCodec('OGG', 'Open format, excellent quality'),
    AudioCodec('ALAC', 'Apple lossless, perfect quality'),
    AudioCodec('FLAC', 'Perfect quality, best compression'),
    AudioCodec('DSD', 'Highest quality, large file size'),
  ];

  static const audioChannels = [
    AudioChannel('Mono', 1, 'Single channel audio, good for voice recordings'),
    AudioChannel(
        'Stereo', 2, 'Two-channel audio, standard for music and most media'),
    AudioChannel(
        '5.1 Surround', 6, 'Six-channel audio for immersive sound experience'),
  ];

  @override
  void initState() {
    super.initState();
    _getDuration();
    _getAvailableFormats();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _getDuration() async {
    try {
      if (['mp3', 'wav', 'm4a', 'aac', 'opus', '']
          .contains(widget.fileFormat.toLowerCase())) {
        await _getAudioDuration();
      } else if (['mp4', 'mov', 'avi', 'mkv']
          .contains(widget.fileFormat.toLowerCase())) {
        await _getVideoDuration();
      }
      _durationInSeconds = int.tryParse(_duration) ?? 0;
    } catch (e) {
      print('Error getting duration: $e');
      setState(() {
        _duration = '0';
        _durationInSeconds = 0;
      });
    }
  }

  String _formatTimeValue(double value) {
    final totalSeconds = (_durationInSeconds * value).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _getAudioDuration() async {
    try {
      await _audioPlayer.setFilePath(widget.filePath);
      final duration = await _audioPlayer.duration;
      setState(() {
        _duration = (duration?.inSeconds ?? 0).toString();
      });
      await _audioPlayer.stop();
    } catch (e) {
      print('Error getting audio duration: $e');
      setState(() {
        _duration = '0';
      });
    }
  }

  Future<void> _getVideoDuration() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.filePath));
      await _videoController!.initialize();
      setState(() {
        _duration = _videoController!.value.duration.inSeconds.toString();
      });
      await _videoController!.dispose();
      _videoController = null;
    } catch (e) {
      print('Error getting video duration: $e');
      setState(() {
        _duration = '0';
      });
    }
  }

  void _getAvailableFormats() {
    // You can implement this method if needed
    // For now, we'll use the static list of formats
  }

  String _buildFFmpegCommand(String inputPath, String outputPath) {
    final List<String> command = [];

    // Input file
    // If trim is applied (not at start and end), add the trim parameters
    if (_startTrim > 0.0 || _endTrim < 1.0) {
      final startTimeSeconds = (_durationInSeconds * _startTrim).round();
      final durationSeconds =
          (_durationInSeconds * (_endTrim - _startTrim)).round();

      // Add start time parameter
      command.add("-ss $startTimeSeconds -i '$inputPath'");

      // Add duration parameter
      command.add("-t $durationSeconds");
    } else {
      // No trim, use standard input
      command.add("-y -i '$inputPath'");
    }

    // Rest of your existing code for video settings
    if (_formats[0]['Video']!.contains(_selectedFormat)) {
      // Video codec
      switch (_selectedVideoCodec.name) {
        case 'H.264':
          command.add('-c:v libx264');
          break;
        case 'H.265':
          command.add('-c:v libx265');
          break;
        case 'AV1':
          command.add('-c:v libaom-av1');
          break;
        case 'MPEG-2':
          command.add('-c:v mpeg2video');
          break;
        case 'MPEG-4':
          command.add('-c:v mpeg4');
          break;
        case 'VP8':
          command.add('-c:v libvpx');
          break;
        case 'VP9':
          command.add('-c:v libvpx-vp9');
          break;
        case 'XVID':
          command.add('-c:v libxvid');
          break;
      }

      // Video bitrate
      command.add('-b:v ${_selectedVideoBitrate.bitrate}k');

      // Resolution
      command.add('-s ${_selectedResolution.resolution}');
    } else {
      // If converting to audio format, remove video
      command.add('-vn');
    }

    // Rest of your existing audio settings
    switch (_selectedAudioCodec.name) {
      case 'MP3':
        command.add('-c:a libmp3lame');
        break;
      case 'MP2':
        command.add('-c:a mp2');
        break;
      case 'AAC':
        command.add('-c:a aac');
        break;
      case 'OGG':
        command.add('-c:a libvorbis');
        break;
      case 'FLAC':
        command.add('-c:a flac');
        break;
      case 'ALAC':
        command.add('-c:a alac');
        break;
      case 'DSD':
        // DSD not directly supported, fallback to high-quality PCM
        command.add('-c:a pcm_s24le');
        break;
      case 'WMA':
        // WMA not directly supported in FFmpeg, fallback to AAC
        command.add('-c:a aac');
        break;
    }

    // Audio bitrate
    command.add('-b:a ${_selectedAudioBitrate.bitrate}k');

    // Sample rate
    command.add('-ar ${_selectedSampleRate.rate}');

    // Audio channels
    command.add('-ac ${_selectedAudioChannel.channels}');

    // Output file
    command.add("'$outputPath'");

    // Join all parameters with spaces
    return command.join(' ');
  }

  AudioCodec _getSelectedAudioCodec() {
    return audioCodecs.firstWhere((codec) => codec.name == _selectedAudioCodec);
  }

  VideoCodec _getSelectedVideoCodec() {
    return videoCodecs.firstWhere((codec) => codec.name == _selectedVideoCodec);
  }

  String _getAudioCodecDescription(String codecName) {
    return audioCodecs
        .firstWhere((codec) => codec.name == codecName)
        .description;
  }

  String _getVideoCodecDescription(String codecName) {
    return videoCodecs
        .firstWhere((codec) => codec.name == codecName)
        .description;
  }

  void _showSettingsPicker<T>({
    required String title,
    required List<T> options,
    required T selectedValue,
    required Function(T) onSelect,
    required String Function(T) formatOption,
    required String Function(T) subtitleOption,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.grey[900],
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...options
                      .map((option) => _buildOptionTile(
                            option: option,
                            isSelected: option == selectedValue,
                            onSelect: (selectedOption) {
                              onSelect(selectedOption);
                              Navigator.of(context).pop();
                            },
                            formatOption: formatOption,
                            subtitleOption: subtitleOption,
                          ))
                      .toList(),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile<T>({
    required T option,
    required bool isSelected,
    required Function(T) onSelect,
    String Function(T)? formatOption,
    String Function(T)? subtitleOption,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(option),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.teal.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatOption?.call(option) ?? option.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.teal : Colors.white,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (subtitleOption != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitleOption(option),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrimSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Start: ${_formatTimeValue(_startTrim)}',
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
            Text(
              'End: ${_formatTimeValue(_endTrim)}',
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.teal,
            inactiveTrackColor: Colors.grey[700],
            thumbColor: Colors.teal,
            overlayColor: Colors.teal.withOpacity(0.2),
            valueIndicatorColor: Colors.teal,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            rangeThumbShape: const MyRoundRangeSliderThumbShape(
              enabledThumbRadius: 10.0,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            rangeValueIndicatorShape:
                const PaddleRangeSliderValueIndicatorShape(),
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: RangeSlider(
            values: RangeValues(_startTrim, _endTrim),
            min: 0.0,
            max: 1.0,
            divisions: _durationInSeconds > 0 ? _durationInSeconds : 100,
            labels: RangeLabels(
              _formatTimeValue(_startTrim),
              _formatTimeValue(_endTrim),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _startTrim = values.start;
                _endTrim = values.end;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrimPreview() {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[800],
      ),
      margin: const EdgeInsets.only(top: 4),
      child: CustomPaint(
        painter: TrimPreviewPainter(
          start: _startTrim,
          end: _endTrim,
          activeColor: Colors.teal.withOpacity(0.6),
          inactiveColor: Colors.grey[900]!,
        ),
        size: const Size(double.infinity, 24),
      ),
    );
  }

  void _showAdvancedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              backgroundColor: Colors.grey[900],
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogHeader(),
                      const Divider(color: Colors.grey),

                      // Add Trim Section
                      _buildSectionHeader('Trim Media'),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Duration: ${_formatTimeValue(1.0)}',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Modified slider implementation
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Start: ${_formatTimeValue(_startTrim)}',
                                      style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 14),
                                    ),
                                    Text(
                                      'End: ${_formatTimeValue(_endTrim)}',
                                      style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.teal,
                                    inactiveTrackColor: Colors.grey[700],
                                    thumbColor: Colors.teal,
                                    overlayColor: Colors.teal.withOpacity(0.2),
                                    valueIndicatorColor: Colors.teal,
                                    valueIndicatorTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    rangeThumbShape:
                                        const MyRoundRangeSliderThumbShape(
                                      enabledThumbRadius: 10.0,
                                    ),
                                    rangeTrackShape:
                                        const RoundedRectRangeSliderTrackShape(),
                                    rangeValueIndicatorShape:
                                        const PaddleRangeSliderValueIndicatorShape(),
                                    showValueIndicator:
                                        ShowValueIndicator.always,
                                  ),
                                  child: RangeSlider(
                                    values: RangeValues(_startTrim, _endTrim),
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: _durationInSeconds > 0
                                        ? _durationInSeconds
                                        : 100,
                                    labels: RangeLabels(
                                      _formatTimeValue(_startTrim),
                                      _formatTimeValue(_endTrim),
                                    ),
                                    onChanged: (RangeValues values) {
                                      // Update both the dialog state and the parent widget state
                                      setDialogState(() {
                                        // This updates the dialog's UI
                                      });

                                      // This updates the parent state
                                      setState(() {
                                        _startTrim = values.start;
                                        _endTrim = values.end;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[800],
                              ),
                              margin: const EdgeInsets.only(top: 4),
                              child: CustomPaint(
                                painter: TrimPreviewPainter(
                                  start: _startTrim,
                                  end: _endTrim,
                                  activeColor: Colors.teal.withOpacity(0.6),
                                  inactiveColor: Colors.grey[900]!,
                                ),
                                size: const Size(double.infinity, 24),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Selected segment: ${_formatTimeValue(_endTrim - _startTrim)}',
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.grey),

                      // Video Settings Section
                      _buildSectionHeader('Video Settings'),
                      _buildSettingsTile(
                        'Video Codec: ${_selectedVideoCodec.name}',
                        subtitle: _selectedVideoCodec.description,
                        icon: Icons.videocam,
                        onTap: () => _showSettingsPicker(
                          title: 'Video Codec',
                          options: videoCodecs,
                          selectedValue: _selectedVideoCodec,
                          onSelect: (VideoCodec codec) {
                            setDialogState(() {});
                            setState(() {
                              _selectedVideoCodec = codec;
                            });
                          },
                          formatOption: (codec) => codec.name,
                          subtitleOption: (codec) => codec.description,
                        ),
                      ),

                      // Rest of your existing video settings...
                      _buildSettingsTile(
                        'Resolution: ${_selectedResolution.resolution}',
                        subtitle: _selectedResolution.description,
                        icon: Icons.high_quality,
                        onTap: () => _showSettingsPicker(
                          title: 'Resolution',
                          options: resolutions,
                          selectedValue: _selectedResolution,
                          onSelect: (VideoResolution res) {
                            setDialogState(() {});
                            setState(() {
                              _selectedResolution = res;
                            });
                          },
                          formatOption: (res) => res.resolution,
                          subtitleOption: (res) => res.description,
                        ),
                      ),

                      _buildSettingsTile(
                        'Video Bitrate: ${_selectedVideoBitrate.bitrate}kbps',
                        subtitle: _selectedVideoBitrate.description,
                        icon: Icons.speed,
                        onTap: () => _showSettingsPicker(
                          title: 'Video Bitrate',
                          options: videoBitrates,
                          selectedValue: _selectedVideoBitrate,
                          onSelect: (VideoBitrate bitrate) {
                            setDialogState(() {});
                            setState(() {
                              _selectedVideoBitrate = bitrate;
                            });
                          },
                          formatOption: (bitrate) => '${bitrate.bitrate} kbps',
                          subtitleOption: (bitrate) => bitrate.description,
                        ),
                      ),

                      // Audio Settings Section
                      _buildSectionHeader('Audio Settings'),
                      // Rest of your existing audio settings...
                      _buildSettingsTile(
                        'Audio Codec: ${_selectedAudioCodec.name}',
                        subtitle: _selectedAudioCodec.description,
                        icon: Icons.audiotrack,
                        onTap: () => _showSettingsPicker(
                          title: 'Audio Codec',
                          options: audioCodecs,
                          selectedValue: _selectedAudioCodec,
                          onSelect: (AudioCodec codec) {
                            setDialogState(() {});
                            setState(() {
                              _selectedAudioCodec = codec;
                            });
                          },
                          formatOption: (codec) => codec.name,
                          subtitleOption: (codec) => codec.description,
                        ),
                      ),

                      _buildSettingsTile(
                        'Audio Bitrate: ${_selectedAudioBitrate.bitrate}kbps',
                        subtitle: _selectedAudioBitrate.description,
                        icon: Icons.graphic_eq,
                        onTap: () => _showSettingsPicker(
                          title: 'Audio Bitrate',
                          options: audioBitrates,
                          selectedValue: _selectedAudioBitrate,
                          onSelect: (AudioBitrate bitrate) {
                            setDialogState(() {});
                            setState(() {
                              _selectedAudioBitrate = bitrate;
                            });
                          },
                          formatOption: (bitrate) => '${bitrate.bitrate} kbps',
                          subtitleOption: (bitrate) => bitrate.description,
                        ),
                      ),

                      _buildSettingsTile(
                        'Sample Rate: ${_selectedSampleRate.rate}Hz',
                        subtitle: _selectedSampleRate.description,
                        icon: Icons.waves,
                        onTap: () => _showSettingsPicker(
                          title: 'Sample Rate',
                          options: sampleRates,
                          selectedValue: _selectedSampleRate,
                          onSelect: (SampleRate rate) {
                            setDialogState(() {});
                            setState(() {
                              _selectedSampleRate = rate;
                            });
                          },
                          formatOption: (rate) => '${rate.rate} Hz',
                          subtitleOption: (rate) => rate.description,
                        ),
                      ),

                      _buildSettingsTile(
                        'Audio Channels: ${_selectedAudioChannel.name}',
                        subtitle: _selectedAudioChannel.description,
                        icon: Icons.speaker,
                        onTap: () => _showSettingsPicker(
                          title: 'Audio Channels',
                          options: audioChannels,
                          selectedValue: _selectedAudioChannel,
                          onSelect: (AudioChannel channel) {
                            setDialogState(() {});
                            setState(() {
                              _selectedAudioChannel = channel;
                            });
                          },
                          formatOption: (channel) => channel.name,
                          subtitleOption: (channel) =>
                              '${channel.channels} Channel(s): ${channel.description}',
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildDialogActions(context),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    String title, {
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[400], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Advanced Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildDialogActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(
          'Apply',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String? _formatDurationInSeconds(String durationInSeconds) {
    if (durationInSeconds.trim().isEmpty) {
      return null;
    }

    double? seconds = double.tryParse(durationInSeconds.trim());
    if (seconds == null || seconds < 0) {
      return null;
    }

    Duration duration = Duration(milliseconds: (seconds * 1000).round());
    int hours = duration.inHours;
    int minutes = (duration.inMinutes % 60);
    int secs = (duration.inSeconds % 60);

    StringBuffer formatted = StringBuffer();

    if (hours > 0) {
      formatted.write('${hours.toString().padLeft(2, '0')}:');
    }

    formatted.write('${minutes.toString().padLeft(2, '0')}:');
    formatted.write(secs.toString().padLeft(2, '0'));

    return formatted.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        widget.fileFormat,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16.0),
                Text(
                  _formatDurationInSeconds(_duration) ?? '00:00',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                const Text(
                  'Convert to: ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  width: 120,
                  height: 40, // Fixed width for the dropdown
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<String>(
                        value: _selectedFormat,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        menuMaxHeight: 250,
                        items: [
                          const DropdownMenuItem<String>(
                            enabled: false,
                            child: Text('Video',
                                style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold)),
                          ),
                          ..._formats[0]['Video']!
                              .map((format) => DropdownMenuItem(
                                    value: format,
                                    child: Text(format),
                                  )),
                          const DropdownMenuItem<String>(
                            enabled: false,
                            child: Text('Audio',
                                style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold)),
                          ),
                          ..._formats[0]['Audio']!
                              .map((format) => DropdownMenuItem(
                                    value: format,
                                    child: Text(format),
                                  )),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFormat = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAdvancedDialog,
                  icon: const Icon(Icons.tune, size: 20),
                  label: const Text('Advanced'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final outputPath = await FileManager.getOutputPath(
                      originalFileName: widget.fileName,
                      targetExtension: _selectedFormat!.toLowerCase(),
                    );

                    final command =
                        _buildFFmpegCommand(widget.filePath, outputPath);
                    print('FFmpeg command: $command');

                    // Start conversion state
                    widget.onConversionStateChanged(
                      isConverting: true,
                      progress: 0.0,
                      currentFile: 1,
                      totalFiles: 1,
                    );

                    // Create FFmpeg session with progress callback
                    final session = await FFmpegKit.executeAsync(
                      command,
                      (session) async {
                        // Completion callback
                        final returnCode = await session.getReturnCode();

                        final logs = await session.getLogs();
                        final failStackTrace =
                            await session.getFailStackTrace();
                        final duration = await session.getDuration();

                        final String logsText =
                            logs.map((log) => log.getMessage()).join('\n');
                        // Reset conversion state
                        widget.onConversionStateChanged(
                          isConverting: false,
                          progress: 1.0,
                          currentFile: 1,
                          totalFiles: 1,
                        );

                        if (ReturnCode.isSuccess(returnCode)) {
                          if (mounted) {
                            final scaffoldMessenger =
                                ScaffoldMessenger.of(context);

                            // Clear any existing snackbars
                            scaffoldMessenger.clearSnackBars();

                            // Show custom snackbar
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Colors.teal,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Conversion Complete',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'All files converted successfully',
                                              style: TextStyle(
                                                color: Colors.grey[300],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                backgroundColor: Colors.grey[900],
                                duration: const Duration(seconds: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey[800]!,
                                    width: 1,
                                  ),
                                ),       
                                elevation: 6,
                              ),
                            );
                          }
                        } else {
                          // ... error handling code ...
                          String errorMessage = 'Conversion failed';
                          if (logsText.isNotEmpty) {
                            // Look for common error patterns in FFmpeg logs
                            final errorLines = logsText
                                .split('\n')
                                .where((line) =>
                                    line.contains('Error') ||
                                    line.contains('Failed') ||
                                    line.contains('Invalid') ||
                                    line.contains('No such file'))
                                .toList();

                            if (errorLines.isNotEmpty) {
                              errorMessage =
                                  errorLines.last; // Get the last error message
                            }
                          }

                          if (mounted) {
                            // Show error in a dialog for better visibility
                            // showDialog(
                            //   context: context,
                            //   builder: (BuildContext context) {
                            //     return AlertDialog(
                            //       title: const Text('Conversion Failed'),
                            //       content: SingleChildScrollView(
                            //         child: Column(
                            //           crossAxisAlignment:
                            //               CrossAxisAlignment.start,
                            //           mainAxisSize: MainAxisSize.min,
                            //           children: [
                            //             Text(errorMessage),
                            //             const SizedBox(height: 16),
                            //             const Text('Debug Information:',
                            //                 style: TextStyle(
                            //                     fontWeight: FontWeight.bold)),
                            //             const SizedBox(height: 8),
                            //             Text('Command: $command'),
                            //             const SizedBox(height: 8),
                            //             Text('Return Code: $returnCode'),
                            //             const SizedBox(height: 16),
                            //             const Text('Full Logs:',
                            //                 style: TextStyle(
                            //                     fontWeight: FontWeight.bold)),
                            //             const SizedBox(height: 8),
                            //             Container(
                            //               padding: const EdgeInsets.all(8),
                            //               decoration: BoxDecoration(
                            //                 color: Colors.grey[900],
                            //                 borderRadius:
                            //                     BorderRadius.circular(4),
                            //               ),
                            //               child: SelectableText(
                            //                 logsText,
                            //                 style: TextStyle(
                            //                   fontFamily: 'monospace',
                            //                   fontSize: 12,
                            //                   color: Colors.grey[300],
                            //                 ),
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //       actions: [
                            //         TextButton(
                            //           onPressed: () {
                            //             Navigator.of(context).pop();
                            //           },
                            //           child: const Text('Close'),
                            //         ),
                            //       ],
                            //     );
                            //   },
                            // );
                          }
                        }
                      },
                      (Log log) {
                        print(log.getMessage());
                      },
                      (statistics) {
                        if (statistics.getTime() < 0) return;

                        // Calculate progress
                        final double timeInMillis =
                            statistics.getTime().toDouble();
                        final double durationInMillis =
                            double.parse(_duration) * 1000;
                        final double progress = timeInMillis / durationInMillis;

                        // Update conversion state with progress
                        widget.onConversionStateChanged(
                          isConverting: true,
                          progress: progress.clamp(0.0, 1.0),
                          currentFile: 1,
                          totalFiles: 1,
                        );
                      },
                    );

                    // Handle cancellation and errors
                    final logs = await session.getLogs();
                    final failStackTrace = await session.getFailStackTrace();

                    if (failStackTrace != null) {
                      print('FFmpeg Failure Stack Trace:');
                      print(failStackTrace);

                      // Reset conversion state on error
                      widget.onConversionStateChanged(
                        isConverting: false,
                        progress: 0.0,
                        currentFile: 1,
                        totalFiles: 1,
                      );
                    }
                  } catch (e, stackTrace) {
                    print('Exception during conversion: $e');
                    print('Stack trace: $stackTrace');

                    // Reset conversion state on error
                    widget.onConversionStateChanged(
                      isConverting: false,
                      progress: 0.0,
                      currentFile: 1,
                      totalFiles: 1,
                    );

                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: SingleChildScrollView(
                              child: Text(
                                  'Error during conversion:\n\n$e\n\n$stackTrace'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Convert Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileListView extends StatelessWidget {
  final List<FileListItem> files;

  const FileListView({
    Key? key,
    required this.files,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) => files[index],
    );
  }
}
