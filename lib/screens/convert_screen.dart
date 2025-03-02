import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:zapmediaconverter/models/file_manager.dart';
import 'package:zapmediaconverter/screens/file_list_view.dart';
import 'package:zapmediaconverter/screens/converted_screen.dart';
import 'package:zapmediaconverter/models/notification_service.dart';
import 'package:path/path.dart' as path;

class FileConverterScreen extends StatefulWidget {
  const FileConverterScreen({Key? key}) : super(key: key);

  @override
  State<FileConverterScreen> createState() => FileConverterScreenState();
}

class FileConverterScreenState extends State<FileConverterScreen>
    implements FileConverterScreenStateInterface {
  bool _isConverting = false;
  double _conversionProgress = 0.0;
  int _currentFileIndex = 1;
  int _totalFiles = 1;

  int _selectedIndex = 0;
  int _selectedFilesNum = 0;
  List<PlatformFile> _selectedFiles = [];

  void switchToConvertTab() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex == 0) {
      bool? exitConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          title: const Text(
            'Exit App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to exit?',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => SystemNavigator.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Exit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        ),
      );
      return exitConfirmed ?? false;
    }
    return true;
  }

  @override
  void setConversionStatus(
      bool isConverting, double progress, int currentFile, int totalFiles) {
    setState(() {
      _isConverting = isConverting;
      _conversionProgress = progress;
      _currentFileIndex = currentFile;
      _totalFiles = totalFiles;
    });

    // Update notification
    if (isConverting) {
      NotificationService.showProgressNotification(
        progress: (_conversionProgress * 100).toInt(),
        currentFile: currentFile,
        totalFiles: totalFiles,
      );
    } else {
      if (_conversionProgress >= 1.0) {
        NotificationService.showProgressNotification(
          progress: 100,
          currentFile: totalFiles,
          totalFiles: totalFiles,
          isComplete: true,
        );
      } else {
        NotificationService.cancelNotification();
      }
    }
  }

  void _navigateToFileList() {
    setState(() {
      _selectedFilesNum = 1;
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Audio formats
          'mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg', 'wma', 'opus',
          // Video formats
          'mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm', '3gp', 'ts', 'm4v'
        ],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });
        _navigateToFileList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    }
  }

  Widget buildInitialScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo or app name section
          Padding(
            padding: const EdgeInsets.only(bottom: 48.0),
            child: Column(
              children: [
                Icon(
                  Icons.audio_file,
                  size: 64,
                  color: Colors.teal[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'ZAP Media Converter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Convert your media files quickly and easily',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // File selection area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: _pickFiles,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 48,
                        color: Colors.teal[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Select Files to Convert',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to browse or drag & drop your files here',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFormatChip('Audio'),
                        _buildFormatChip('Video'),
                        _buildFormatChip('Images'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Feature highlights
          Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureItem(
                  Icons.speed_rounded,
                  'Fast Conversion',
                ),
                const SizedBox(width: 32),
                _buildFeatureItem(
                  Icons.high_quality_rounded,
                  'High Quality',
                ),
                const SizedBox(width: 32),
                _buildFeatureItem(
                  Icons.lock_rounded,
                  'Secure',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionProgress() {
    if (!_isConverting) return const SizedBox.shrink();

    return Stack(
      children: [
        // Full screen semi-transparent overlay to block ALL interaction
        Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.7),
          ),
        ),
        // Centered progress indicator
        Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: Stack(
            children: [
              Card(
                elevation: 8,
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Converting $_currentFileIndex of $_totalFiles',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${(_conversionProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _conversionProgress,
                          backgroundColor: Colors.grey[800],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.teal),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cancel button
              Positioned(
                top: -8,
                right: -8,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldCancel = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text(
                            'Cancel Conversion',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to cancel the conversion?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Continue',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );

                      if (shouldCancel == true) {
                        // First cancel the FFmpeg processing
                        await FFmpegKit.cancel();
                        await NotificationService.cancelNotification();

                        // Find and delete any partially converted files
                        try {
                          // Get the app directory where converted files are stored
                          final directory = await FileManager.appDirectory;

                          // Get all files in that directory
                          final files = await directory
                              .list()
                              .where((entity) =>
                                  entity is File &&
                                  path
                                      .basename(entity.path)
                                      .contains('_converted'))
                              .toList();
                          final now = DateTime.now();
                          for (var entity in files) {
                            if (entity is File) {
                              final fileStats = await entity.stat();
                              final fileModTime = fileStats.modified;
                              if (now.difference(fileModTime).inMinutes < 1) {
                                await entity.delete();
                                print(
                                    'Deleted partially converted file: ${entity.path}');
                              }
                            }
                          }
                        } catch (e) {
                          print('Error deleting partially converted files: $e');
                        }
                        setState(() {
                          _isConverting = false;
                          _conversionProgress = 0.0;
                        });

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: const Text(
                                'Operation Cancelled',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Conversion has been cancelled by user.',
                                style: TextStyle(color: Colors.grey),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(color: Colors.teal),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Color.fromRGBO(158, 158, 158, 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _isConverting
            ? null // This disables tab navigation completely when converting
            : (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
        backgroundColor: Colors.black,
        selectedItemColor: _isConverting
            ? Colors.grey
            : Colors.teal, // Visually indicate disabled state
        unselectedItemColor: Colors.grey
            .withOpacity(_isConverting ? 0.5 : 1.0), // Dim tabs when converting
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Convert',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Converted',
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.teal[400],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        if (_isConverting) {
          return;
        }
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _selectedIndex == 0
                        ? _selectedFilesNum == 0
                            ? buildInitialScreen()
                            : FileListViewScreen(files: _selectedFiles)
                        : const ConvertedScreen(),
                  ),
                ],
              ),
            ),
            if (_isConverting) _buildConversionProgress(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }
}
