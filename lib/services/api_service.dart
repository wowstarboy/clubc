 import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();

  // 1. URL YA IMAGEKIT (Endpoint yako)
  static const String imageKitUrl = "https://ik.imagekit.io/h1f0bebahz"; 

  // 2. KEYS MUHIMU (Zimeingizwa hapa chini)
  static const String publicKey = "public_JE+6dCVwt/X7iqy0qbMG9npjwEs="; 
  static const String privateKey = "private_7wiEoS08closJDK+IV7ZJYx4qkU="; 

  /// KAZI: Kupandisha file moja kwa moja ImageKit (Badala ya S3)
  Future<String?> uploadToImageKit(File file, {required String folder}) async {
    try {
      // ImageKit inahitaji "Authentication Header" kwa kutumia Base64 ya Private Key
      String auth = base64Encode(utf8.encode("$privateKey:"));

      // Jina la file kwa ajili ya ImageKit
      String fileName = "IMG_${DateTime.now().millisecondsSinceEpoch}.webp";
      if (file.path.endsWith('.mp4')) fileName = "VID_${DateTime.now().millisecondsSinceEpoch}.mp4";

      // Tunatengeneza Form Data (Hii ndio 'Upload with API' setup)
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
        "fileName": fileName,
        "folder": folder, // Hapa ndipo itatofautisha /avatars, /uploads, au /stories
        "useUniqueFileName": "true",
      });

      final response = await _dio.post(
        "https://upload.imagekit.io/api/v1/files/upload",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Basic $auth", // Hapa ndipo ImageKit inatambua ni akaunti yako
          },
        ),
      );

      if (response.statusCode == 200) {
        // ImageKit inarudisha 'filePath' (mfano: /uploads/picha_123.webp)
        // Hii ndiyo tunayohifadhi kwenye Database yetu
        return response.data['filePath']; 
      }
      return null;
    } catch (e) {
      print("ImageKit Upload Error: $e");
      return null;
    }
  }

  // Hii haina haja ya kubadilika, inatumia fileName kurudisha URL kamili
  String getImageUrl(String fileName) {
    return "$imageKitUrl$fileName";
  }
}
