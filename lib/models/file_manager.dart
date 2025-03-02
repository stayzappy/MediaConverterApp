import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileManager {
  static const String _appFolderName = 'ZapMediaConverter';
  
  /// Gets the device's Documents directory path
  static Future<String> get _documentPath async {
    if (Platform.isAndroid) {
      final List<Directory>? externalStorageDirectories = await getExternalStorageDirectories();
      if (externalStorageDirectories != null && externalStorageDirectories.isNotEmpty) {
        // Navigate up to get to the root of external storage
        String path = externalStorageDirectories[0].path;
        final List<String> paths = path.split("/");
        final int androidFolderIndex = paths.indexOf("Android");
        if (androidFolderIndex != -1) {
          paths.removeRange(androidFolderIndex, paths.length);
          path = paths.join("/");
          return "$path/Documents";
        }
      }
      throw Exception("Could not access external storage");
    } else if (Platform.isIOS) {
      // On iOS, we'll use the device's Documents directory
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir.path;
    }
    throw Exception("Platform not supported");
  }
  
  /// Creates and gets the app's specific directory in device Documents
  static Future<Directory> get appDirectory async {
    final String docPath = await _documentPath;
    final Directory appDir = Directory(path.join(docPath, _appFolderName));
    
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return appDir;
  }
  
  /// Gets the absolute path of where the converted file will be saved
  static Future<String> getOutputPath({
    required String originalFileName,
    required String targetExtension,
  }) async {
    final Directory directory = await appDirectory;
    final String fileNameWithoutExt = path.basenameWithoutExtension(originalFileName);
    final String newFileName = '${fileNameWithoutExt}_converted.$targetExtension';
    return path.join(directory.path, newFileName);
  }
  
  /// Get all converted files
  static Future<List<File>> getConvertedFiles() async {
    try {
      final Directory directory = await appDirectory;
      if (!await directory.exists()) {
        return [];
      }
      final List<FileSystemEntity> entities = await directory.list().toList();
      return entities.whereType<File>().toList();
    } catch (e) {
      print('Error getting converted files: $e');
      return [];
    }
  }
  
  /// Delete a converted file
  static Future<bool> deleteConvertedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
  
  /// Clear all converted files
  static Future<bool> clearConvertedFiles() async {
    try {
      final Directory directory = await appDirectory;
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        await directory.create();
      }
      return true;
    } catch (e) {
      print('Error clearing files: $e');
      return false;
    }
  }

  /// Print the current directory path (for debugging)
  static Future<void> printCurrentPath() async {
    try {
      final Directory directory = await appDirectory;
      print('Current directory path: ${directory.path}');
    } catch (e) {
      print('Error getting path: $e');
    }
  }
}