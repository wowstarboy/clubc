import 'package:flutter/material.dart';

class TemplateStoryPage extends StatefulWidget {
  const TemplateStoryPage({super.key});

  @override
  State<TemplateStoryPage> createState() => _TemplateStoryPageState();
}

class _TemplateStoryPageState extends State<TemplateStoryPage> {
  // List ya templates (Rangi na Gradients)
  final List<dynamic> _templates = [
    Colors.black,
    Colors.red[800],
    Colors.blue[800],
    const LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
    const LinearGradient(colors: [Colors.orange, Colors.red]),
    Colors.green[800],
    const LinearGradient(colors: [Colors.teal, Colors.cyan]),
    Colors.pink[700],
    const LinearGradient(colors: [Colors.indigo, Colors.blue]),
    Colors.grey[900],
  ];

  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _selectedIndex) {
        setState(() {
          _selectedIndex = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background inayobadilika kwa ku-swipe
          PageView.builder(
            controller: _pageController,
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: _templates[index] is Color ? _templates[index] : null,
                  gradient: _templates[index] is Gradient ? _templates[index] : null,
                ),
              );
            },
          ),

          // 2. Sehemu ya Kuandika Maandishi (Center)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: TextField(
                textAlign: TextAlign.center,
                maxLines: null, // Inaruhusu mistari mingi
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type something...',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ),

          // 3. Vifungo vya Juu (Top Right)
          Positioned(
            top: 50,
            right: 15,
            child: Row(
              children: [
                 _buildOutlineIconButton(icon: Icons.tag_faces_outlined, onTap: () {}),
                 const SizedBox(width: 15),
                 _buildOutlineIconButton(icon: Icons.music_note_outlined, onTap: () {}),
              ],
            ),
          ),
          
          // X button to close
          Positioned(
            top: 50,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // 4. UI ya Chini (Templates na Share button)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Orodha ya Templates
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _templates.length,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _templates[index] is Color ? _templates[index] : null,
                            gradient: _templates[index] is Gradient ? _templates[index] : null,
                            border: _selectedIndex == index
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Share Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                  ),
                  child: const Text(
                    'Share',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.4),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
