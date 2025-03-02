import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io';


class AudioChannel {
  final String name;
  final int channels;
  final String description;

  const AudioChannel(this.name, this.channels, this.description);
}

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
class PermissionManager {
  static const String _permissionKey = 'storage_permission_granted';

  static Future<bool> checkAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPermission = prefs.getBool(_permissionKey) ?? false;

    if (!hasPermission && Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        await prefs.setBool(_permissionKey, true);
        return true;
      }
      return false;
    }
    return true;
  }
}

class DurationFormatter {
  static String? formatDurationInSeconds(String durationInSeconds) {
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
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromRGBO(158, 158, 158, 0.5)
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



class TrimPreviewPainter extends CustomPainter {
  final double start;
  final double end;
  final Color activeColor;
  final Color inactiveColor;

  TrimPreviewPainter({
    required this.start,
    required this.end,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullWidth = size.width;  
    // Draw the inactive sections
    Paint inactivePaint = Paint()..color = inactiveColor;  
    // Left inactive section
    if (start > 0.0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, start * fullWidth, size.height),
        inactivePaint,
      );
    }  
    // Right inactive section
    if (end < 1.0) {
      canvas.drawRect(
        Rect.fromLTWH(end * fullWidth, 0, (1 - end) * fullWidth, size.height),
        inactivePaint,
      );
    }
    
    // Draw the active segment
    Paint activePaint = Paint()..color = activeColor;
    canvas.drawRect(
      Rect.fromLTWH(start * fullWidth, 0, (end - start) * fullWidth, size.height),
      activePaint,
    );  
    // Draw markers for start and end positions
    Paint markerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;   
    // Start marker
    canvas.drawLine(
      Offset(start * fullWidth, 0),
      Offset(start * fullWidth, size.height),
      markerPaint,
    );   
    // End marker
    canvas.drawLine(
      Offset(end * fullWidth, 0),
      Offset(end * fullWidth, size.height),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(TrimPreviewPainter oldDelegate) {
    return oldDelegate.start != start || 
           oldDelegate.end != end || 
           oldDelegate.activeColor != activeColor || 
           oldDelegate.inactiveColor != inactiveColor;
  }
}


class MyRoundRangeSliderThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;
  
  const MyRoundRangeSliderThumbShape({
    this.enabledThumbRadius = 10.0,
  });
  
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }
  
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool isOnTop = false,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;
    
    final Paint thumbPaint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.teal
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, enabledThumbRadius, thumbPaint);
    canvas.drawCircle(center, enabledThumbRadius, borderPaint);
  }
}