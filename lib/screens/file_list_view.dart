import 'package:flutter/material.dart';
import '../models/file_list_item.dart';
import 'package:file_picker/file_picker.dart';
import 'convert_screen.dart';

abstract class FileConverterScreenStateInterface
    extends State<FileConverterScreen> {
  void setConversionStatus(
      bool isConverting, double progress, int currentFile, int totalFiles);
}

class FileListViewScreen extends StatefulWidget {
  final List<PlatformFile> files;

  const FileListViewScreen({
    Key? key,
    required this.files,
  }) : super(key: key);

  @override
  State<FileListViewScreen> createState() => _FileListViewScreenState();
}

class _FileListViewScreenState extends State<FileListViewScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.files.length,
      itemBuilder: (context, index) => Dismissible(
        key:
            Key(widget.files[index].name), // Provide a unique key for each item
        direction: DismissDirection
            .horizontal, // Specify the direction of the dismissible
        background: Container(
          color: Colors.red, // Color of the background when dismissing
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 16.0),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ),
        ),
        onDismissed: (direction) {
          setState(() {
            widget.files.removeAt(index);
            if (widget.files.isEmpty) {
              print("The List is Empty");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FileConverterScreen()),
              );
            }
          });
        },
        child: FileListItem(
          fileName: widget.files[index].name,
          fileFormat: widget.files[index].extension ?? '',
          filePath: widget.files[index].path ?? '',
          onConversionStateChanged: ({
            required bool isConverting,
            required double progress,
            required int currentFile,
            required int totalFiles,
          }) {
            // Find the FileConverterScreen ancestor and update its state
            final state = context
                .findAncestorStateOfType<FileConverterScreenStateInterface>();
            state?.setConversionStatus(
                isConverting, progress, currentFile, totalFiles);
          },
        ),
      ),
    );
  }
}
