import 'package:flutter/material.dart';

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final _cutOutSize = cutOutSize < width || cutOutSize < height
        ? (width < height ? width * 0.8 : height * 0.8)
        : cutOutSize;
    final _left = (width - _cutOutSize) / 2;
    final _top = (height - _cutOutSize) / 2;
    final _cutOutRect = Rect.fromLTWH(_left, _top, _cutOutSize, _cutOutSize);

    // Draw overlay
    final _paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(0, 0, width, height))
        ..addRRect(
          RRect.fromRectAndRadius(
            _cutOutRect,
            Radius.circular(borderRadius),
          ),
        ),
      _paint,
    );

    // Draw border
    final _borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final _path = Path()
      ..moveTo(_cutOutRect.left, _cutOutRect.top + borderLength)
      ..lineTo(_cutOutRect.left, _cutOutRect.top + borderRadius)
      ..quadraticBezierTo(
        _cutOutRect.left,
        _cutOutRect.top,
        _cutOutRect.left + borderRadius,
        _cutOutRect.top,
      )
      ..lineTo(_cutOutRect.left + borderLength, _cutOutRect.top)
      ..moveTo(_cutOutRect.right - borderLength, _cutOutRect.top)
      ..lineTo(_cutOutRect.right - borderRadius, _cutOutRect.top)
      ..quadraticBezierTo(
        _cutOutRect.right,
        _cutOutRect.top,
        _cutOutRect.right,
        _cutOutRect.top + borderRadius,
      )
      ..lineTo(_cutOutRect.right, _cutOutRect.top + borderLength)
      ..moveTo(_cutOutRect.right, _cutOutRect.bottom - borderLength)
      ..lineTo(_cutOutRect.right, _cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(
        _cutOutRect.right,
        _cutOutRect.bottom,
        _cutOutRect.right - borderRadius,
        _cutOutRect.bottom,
      )
      ..lineTo(_cutOutRect.right - borderLength, _cutOutRect.bottom)
      ..moveTo(_cutOutRect.left + borderLength, _cutOutRect.bottom)
      ..lineTo(_cutOutRect.left + borderRadius, _cutOutRect.bottom)
      ..quadraticBezierTo(
        _cutOutRect.left,
        _cutOutRect.bottom,
        _cutOutRect.left,
        _cutOutRect.bottom - borderRadius,
      )
      ..lineTo(_cutOutRect.left, _cutOutRect.bottom - borderLength);

    canvas.drawPath(_path, _borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

