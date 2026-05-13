import 'dart:convert';
import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatefulWidget {
  final String base64Image;
  final String title;

  const PhotoViewerScreen({
    super.key,
    required this.base64Image,
    required this.title,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  final TransformationController _transformationController =
      TransformationController();

  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = base64Decode(widget.base64Image);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          // ✅ Bouton reset zoom
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            tooltip: "Réinitialiser le zoom",
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ Image zoomable avec InteractiveViewer
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              onInteractionUpdate: (details) {
                setState(() {
                  _currentScale = _transformationController.value.getMaxScaleOnAxis();
                });
              },
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ✅ Indicateur de zoom en bas
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _currentScale != 1.0 ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Zoom : x${_currentScale.toStringAsFixed(1)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ✅ Hint "pincez pour zoomer" au démarrage
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: _currentScale == 1.0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pinch, color: Colors.white54, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "Pincez pour zoomer",
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}