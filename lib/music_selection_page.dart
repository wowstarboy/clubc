 import 'package:flutter/material.dart';
// import 'services/media_manager.dart'; // Utatumia getUrl kama utahifadhi nyimbo zako

class MusicSelectionPage extends StatefulWidget {
  final String? initialMusic;
  const MusicSelectionPage({super.key, this.initialMusic});

  @override
  State<MusicSelectionPage> createState() => _MusicSelectionPageState();
}

class _MusicSelectionPageState extends State<MusicSelectionPage> {
  String? selectedMusicUrl;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  // Mfano wa data (Baadaye tutavuta kutoka API ya Pixabay au Database yako)
  final List<Map<String, String>> musicList = [
    {"id": "1", "title": "Lo-fi Hip Hop", "artist": "Chill Beats", "url": "https://example.com/music1.mp3"},
    {"id": "2", "title": "Cinematic News", "artist": "Media Audio", "url": "https://example.com/music2.mp3"},
    {"id": "3", "title": "Acoustic Vibe", "artist": "Jamii Audio", "url": "https://example.com/music3.mp3"},
  ];

  @override
  void initState() {
    super.initState();
    selectedMusicUrl = widget.initialMusic;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context, widget.initialMusic),
        ),
        title: Text(
          'Select Music',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Search Bar (Match TagUsersPage style)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  hintText: "Search music...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Music List
          Expanded(
            child: ListView.builder(
              itemCount: musicList.length,
              itemBuilder: (context, index) {
                final music = musicList[index];
                final isSelected = selectedMusicUrl == music['url'];

                return ListTile(
                  onTap: () => setState(() => selectedMusicUrl = music['url']),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.blue),
                  ),
                  title: Text(music['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(music['artist']!, style: const TextStyle(color: Colors.grey)),
                  trailing: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.blue : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected 
                        ? const Icon(Icons.check, size: 16, color: Colors.white) 
                        : null,
                  ),
                );
              },
            ),
          ),

          // 3. Bottom Button (Match TagUsersPage)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedMusicUrl != null 
                    ? () => Navigator.pop(context, selectedMusicUrl) 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
