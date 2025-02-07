import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'listviewscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      themeAnimationCurve: Curves.bounceInOut,
      home: const FileConverterScreen(),
    );
  }
}

class DashedBorder extends StatelessWidget {
  final Widget child;
  const DashedBorder({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromRGBO(158, 158, 158, 0.5)  // Using grey with 0.5 opacity
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5;
    const double dashSpace = 5;
    double currentX = 0;

    // Top line
    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX + dashWidth, 0),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }

    // Right line
    double currentY = 0;
    while (currentY < size.height) {
      canvas.drawLine(
        Offset(size.width, currentY),
        Offset(size.width, currentY + dashWidth),
        paint,
      );
      currentY += dashWidth + dashSpace;
    }

    // Bottom line
    currentX = 0;
    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, size.height),
        Offset(currentX + dashWidth, size.height),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }

    // Left line
    currentY = 0;
    while (currentY < size.height) {
      canvas.drawLine(
        Offset(0, currentY),
        Offset(0, currentY + dashWidth),
        paint,
      );
      currentY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FileConverterScreen extends StatefulWidget {
  const FileConverterScreen({Key? key}) : super(key: key);

  @override
  State<FileConverterScreen> createState() => _FileConverterScreenState();
}

class _FileConverterScreenState extends State<FileConverterScreen> {
  int _selectedIndex = 0;
  int _selectedFilesNum = 0;
  List<PlatformFile> _selectedFiles = [];

  void _navigateToFileList() {
    setState(() {
      _selectedFilesNum = 1;
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media, // Allows audio and video files
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });
        _navigateToFileList();
      }
    } catch (e) {
      // Handle any errors during file picking
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              ///////If Selected index is 0 or at start show Screen1/////////////
              child: _selectedIndex == 0 ? 
              //////If the user has not selected any files Show this
              _selectedFilesNum == 0 ?
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: _pickFiles,
                      child: DashedBorder(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              size: 40,
                              color: Color.fromRGBO(158, 158, 158, 0.7),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select File(s)',
                              style: const TextStyle(
                                color: Color.fromRGBO(158, 158, 158, 0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )  
                /////If the User has selected a file Show this////////////
              : Expanded(
                child: FileListView(
                  files: _selectedFiles.map((file) => FileListItem(
                    fileName: file.name,
                    fileFormat: file.extension ?? '',
                    filePath: file.path ?? '',
                      // Replace with actual duration
                  )).toList(),
                ),
              )
              ////If the User Clicks the "Converted" Part of the bottomNavBar Show this//////////
              : Expanded(
                child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Converted Files',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Files you have converted will appear here.',
                              style: TextStyle(
                                color: Color.fromRGBO(158, 158, 158, 0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            )        
          ],
        ),
      ),

      ////////Bottom Navigation Bar Area Of the App/////////
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(
              color: const Color.fromRGBO(158, 158, 158, 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.black,
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
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
      ),
    );
  }
}