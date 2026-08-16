 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth/collections.dart';
import 'services/media_manager.dart'; // Import MediaManager yako

class TagUsersPage extends StatefulWidget {
  final List<String> initialTags;
  const TagUsersPage({super.key, this.initialTags = const []});

  @override
  State<TagUsersPage> createState() => _TagUsersPageState();
}

class _TagUsersPageState extends State<TagUsersPage> {
  List<String> selectedUserIds = [];
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedUserIds = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void toggleUser(String uid) {
    setState(() {
      if (selectedUserIds.contains(uid)) {
        selectedUserIds.remove(uid);
      } else {
        if (selectedUserIds.length < 20) {
          selectedUserIds.add(uid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final bool canContinue = selectedUserIds.isNotEmpty;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          // Imerudishwa arrow_back_ios ili ilingane na PostDetailPage
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context, widget.initialTags),
        ),
        // Style ya title inalingana na PostDetailPage (bold na center)
        title: Text(
          'Tag People', 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Search Bar
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
                  hintText: "Search users...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Real-time User List
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(FirestoreCollections.users)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                var users = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String username = data[FirestoreCollections.username]?.toString().toLowerCase() ?? "";
                  return username.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var userData = users[index].data() as Map<String, dynamic>;
                    String uid = userData[FirestoreCollections.uid];
                    String username = userData[FirestoreCollections.username] ?? "";
                    String displayName = userData[FirestoreCollections.displayName] ?? "";
                    String profilePhoto = userData[FirestoreCollections.profilePhotoUrl] ?? "";
                    bool isSelected = selectedUserIds.contains(uid);

                    String finalImageUrl = profilePhoto.isNotEmpty 
                        ? MediaManager().getUrl(profilePhoto) 
                        : "";

                    return ListTile(
                      onTap: () => toggleUser(uid),
                      leading: CircleAvatar(
                        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                        backgroundImage: finalImageUrl.isNotEmpty 
                            ? NetworkImage(finalImageUrl) 
                            : null,
                        child: finalImageUrl.isEmpty 
                            ? Icon(Icons.person, color: isDarkMode ? Colors.white70 : Colors.black54) 
                            : null,
                      ),
                      title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("@$username", style: const TextStyle(color: Colors.grey)),
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
                );
              },
            ),
          ),

          // 3. Bottom Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canContinue 
                    ? () => Navigator.pop(context, selectedUserIds) 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Continue (${selectedUserIds.length}/20)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
