import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data'; // For Uint8List

/// A simple screen to host the PDF preview widget
class PreviewScreen extends StatelessWidget {
  final Uint8List pdfData;

  const PreviewScreen({super.key, required this.pdfData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
      ),
      body: PdfPreview(
        build: (format) => pdfData,
      ),
    );
  }
}
