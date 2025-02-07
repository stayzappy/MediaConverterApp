import 'dart:io';
import 'package:flutter/material.dart';
//import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:nyx_converter/nyx_converter.dart';


class VideoResolution {
  final String resolution;
  final String description;
  
  const VideoResolution(this.resolution, this.description);
}

class AudioBitrate {
  final int bitrate;
  final String description;
  
  const AudioBitrate(this.bitrate, this.description);
}

class SampleRate {
  final int rate;
  final String description;
  
  const SampleRate(this.rate, this.description);
}

class VideoBitrate {
  final int bitrate;
  final String description;
  
  const VideoBitrate(this.bitrate, this.description);
}
class VideoCodec {
  final String name;
  final String description;
  
  const VideoCodec(this.name, this.description);
}

class AudioCodec {
  final String name;
  final String description;
  
  const AudioCodec(this.name, this.description);
}
class FileListItem extends StatefulWidget {
  final String fileName;
  final String fileFormat;
  final String filePath;

  const FileListItem({
    Key? key,
    required this.fileName,
    required this.fileFormat,
    required this.filePath
  }) : super(key: key);

  @override
  State<FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<FileListItem> {
  String _duration = '';
  String? _selectedFormat = 'MP4';
  final _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;

   VideoCodec _selectedVideoCodec = videoCodecs[0];
  AudioCodec _selectedAudioCodec = audioCodecs[0];
  VideoResolution _selectedResolution = resolutions[1]; // Default to 1080p
  AudioBitrate _selectedAudioBitrate = audioBitrates[1]; // Default to 128kbps
  SampleRate _selectedSampleRate = sampleRates[1]; // Default to 44.1kHz
  VideoBitrate _selectedVideoBitrate = videoBitrates[1]; // Default to 2.5Mbps

  // Add constants for settings options
static const resolutions = [
    VideoResolution('3840x2160', '4K Ultra HD - Highest quality, best for large screens'),
    VideoResolution('1920x1080', 'Full HD - Great quality, standard for most devices'),
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
      for (var codec in NyxAudioCodec.values) {
        print("This is a codec: $codec");
        
      }
      
     
      // Check if the file is an audio format
      if (['mp3', 'wav', 'm4a', 'aac','opus',''].contains(widget.fileFormat.toLowerCase())) {
        await _getAudioDuration();
      } 
      // Check if the file is a video format
      else if (['mp4', 'mov', 'avi', 'mkv'].contains(widget.fileFormat.toLowerCase())) {
        await _getVideoDuration();
      }
    } catch (e) {
      print('Error getting duration: $e');
      setState(() {
        _duration = '0';
      });
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

  AudioCodec _getSelectedAudioCodec() {
  return audioCodecs.firstWhere((codec) => codec.name == _selectedAudioCodec);
}

VideoCodec _getSelectedVideoCodec() {
  return videoCodecs.firstWhere((codec) => codec.name == _selectedVideoCodec);
}

String _getAudioCodecDescription(String codecName) {
  return audioCodecs.firstWhere((codec) => codec.name == codecName).description;
}

String _getVideoCodecDescription(String codecName) {
  return videoCodecs.firstWhere((codec) => codec.name == codecName).description;
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
                  ...options.map((option) => _buildOptionTile(
                    option: option,
                    isSelected: option == selectedValue,
                    onSelect: (selectedOption) {
                      onSelect(selectedOption);
                      Navigator.of(context).pop();
                    },
                    formatOption: formatOption,
                    subtitleOption: subtitleOption,
                  )).toList(),
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
            color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
void _showAdvancedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                            setState(() {
                              _selectedVideoCodec = codec;
                            });
                          },
                          formatOption: (codec) => codec.name,
                          subtitleOption: (codec) => codec.description,
                        ),
                      ),
                      
                      _buildSettingsTile(
                        'Resolution: ${_selectedResolution.resolution}',
                        subtitle: _selectedResolution.description,
                        icon: Icons.high_quality,
                        onTap: () => _showSettingsPicker(
                          title: 'Resolution',
                          options: resolutions,
                          selectedValue: _selectedResolution,
                          onSelect: (VideoResolution res) {
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
                      _buildSettingsTile(
                        'Audio Codec: ${_selectedAudioCodec.name}',
                        subtitle: _selectedAudioCodec.description,
                        icon: Icons.audiotrack,
                        onTap: () => _showSettingsPicker(
                          title: 'Audio Codec',
                          options: audioCodecs,
                          selectedValue: _selectedAudioCodec,
                          onSelect: (AudioCodec codec) {
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
                            setState(() {
                              _selectedSampleRate = rate;
                            });
                          },
                          formatOption: (rate) => '${rate.rate} Hz',
                          subtitleOption: (rate) => rate.description,
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

  
  Widget _buildSettingsTile(String title, {
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
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: DropdownButton<String>(
                    value: _selectedFormat,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    underline: Container(),
                    items: <String>['MP4', 'MOV', 'AVI', 'MKV']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFormat = newValue;
                      });
                    },
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
                onPressed: () {
                  // Conversion logic will be implemented later
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