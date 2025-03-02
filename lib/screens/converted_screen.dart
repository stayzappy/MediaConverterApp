import 'package:flutter/material.dart';
import 'dart:io';
import '../models/file_manager.dart';
import 'package:path/path.dart' as path;
import 'convert_screen.dart';
import 'package:share_plus/share_plus.dart';

class ConvertedScreen extends StatefulWidget {
  const ConvertedScreen({Key? key}) : super(key: key);

  @override
  State<ConvertedScreen> createState() => _ConvertedScreenState();
}

class _ConvertedScreenState extends State<ConvertedScreen> {
  List<File> _convertedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConvertedFiles();
  }

  Future<void> _loadConvertedFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await FileManager.getConvertedFiles();
      setState(() {
        _convertedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading files: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Delete File',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this file?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FileManager.deleteConvertedFile(file.path);
      _loadConvertedFiles();
    }
  }

  Future<void> _clearAllFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Clear All Files',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete all converted files?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FileManager.clearConvertedFiles();
      _loadConvertedFiles();
    }
  }

  String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    int unit = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }

    return '${size.toStringAsFixed(2)} ${units[unit]}';
  }

  DateTime? _lastBackPressed;
  //bool _doubleBackToExit = false;

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: 50,
          right: 20,
          left: 20,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 12.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Add this method to handle back press
  Future<bool> _onWillPop() async {
    return true;
  }

  Widget buildChild() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      );
    }

    if (_convertedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Converted Files',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Files you convert will appear here',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Converted Files',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: _clearAllFiles,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
            child: ListView.builder(
          itemCount: _convertedFiles.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final file = _convertedFiles[index];
            final fileName = path.basename(file.path);
            final fileDir = path.dirname(file.path);
            final fileSize = _formatFileSize(file.lengthSync());
            final fileExt =
                path.extension(file.path).toUpperCase().replaceAll('.', '');
            final conversionTime = file.lastModifiedSync().toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.teal.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            fileExt,
                            style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          fileSize,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.share_rounded,
                            size: 16,
                          ),
                          color: Colors.grey[400],
                          onPressed: () async {
                            try {
                              final result = await Share.shareXFiles(
                                [XFile(file.path)],
                                subject: 'Share $fileName',
                              );

                              if (result.status ==
                                  ShareResultStatus.dismissed) {
                                _showToast('Share cancelled');
                              }
                            } catch (e) {
                              _showToast('Error sharing file: $e');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 16, // Reduced icon size
                          ),
                          color: Colors.red[300],
                          onPressed: () => _deleteFile(file),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0),
                    Text(
                      fileDir,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Converted on: $conversionTime',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )),
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
        final FileConverterScreenState? parentState =
            context.findAncestorStateOfType<FileConverterScreenState>();
        if (parentState != null) {
          parentState.setState(() {
            parentState.switchToConvertTab();
          });
        } else {
          Navigator.of(context).pop();
        }
      },
      child: buildChild(),
    );
  }
}
