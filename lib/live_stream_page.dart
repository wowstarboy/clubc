import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera({int cameraIndex = 0}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    setState(() {
      _selectedCameraIndex = cameraIndex;
    });

    _cameraController = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: true, // Muhimu kwa live stream
    );

    await _cameraController.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _flipCamera() {
    final newIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _initializeCamera(cameraIndex: newIndex);
  }

  void _toggleFlash() {
    if (_cameraController.value.flashMode == FlashMode.torch) {
      _cameraController.setFlashMode(FlashMode.off);
      setState(() => _isFlashOn = false);
    } else {
      _cameraController.setFlashMode(FlashMode.torch);
      setState(() => _isFlashOn = true);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview (Full Screen)
          if (_isCameraInitialized)
            Positioned.fill(child: CameraPreview(_cameraController))
          else
            const Center(child: CircularProgressIndicator()),

          // 2. Back Button (Top Left)
          Positioned(
            top: 50,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // 3. Vifungo vya pembeni (Bottom Right)
          Positioned(
            bottom: 120,
            right: 15,
            child: Column(
              children: [
                _buildOutlineButton(icon: _isFlashOn ? Icons.flash_on : Icons.flash_off, onTap: _toggleFlash),
                const SizedBox(height: 20),
                _buildOutlineButton(icon: Icons.flip_camera_ios_outlined, onTap: _flipCamera),
                const SizedBox(height: 20),
                _buildOutlineButton(icon: Icons.tag_faces_outlined, onTap: () {}),
              ],
            ),
          ),

          // 4. Description Input na Go Live Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Description Input
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Describe your stream...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                const SizedBox(height: 15),
                // Go Live Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  ),
                  child: const Text(
                    'Go Live',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper widget ya kutengeneza vifungo vya outline
  Widget _buildOutlineButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.4),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
