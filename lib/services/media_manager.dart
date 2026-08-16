 import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:jamiiclub/services/api_service.dart';

class MediaManager {
  static final MediaManager _instance = MediaManager._internal();
  factory MediaManager() => _instance;
  MediaManager._internal();

  final ApiService _api = ApiService();

  // 1. KUPUNGUZA PICHA (Inatengeneza WebP ndogo)
  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = "${tempDir.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.webp";
    var result = await FlutterImageCompress.compressAndGetFile(
      file.path, 
      targetPath, 
      format: CompressFormat.webp, 
      quality: 70,
    );
    return result != null ? File(result.path) : null;
  }

  // 2. KUPUNGUZA VIDEO (Inatengeneza MP4 ya saizi ya kati)
  Future<File?> _compressVideo(File file) async {
    MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );
    return mediaInfo?.file;
  }

  // 3. MFUMO WA UPLOAD (ImageKit Direct)
  Future<String?> uploadMedia(File originalFile, {required bool isVideo, bool isStory = false}) async {
    // Kwenye ImageKit, folder prefix huanza na '/'
    String folder = isStory ? "/stories" : "/uploads";
    File? fileToUpload;

    if (isVideo) {
      fileToUpload = await _compressVideo(originalFile);
    } else {
      fileToUpload = await _compressImage(originalFile);
    }

    if (fileToUpload == null) return null;

    // Tuma file moja kwa moja ImageKit kupitia API yetu mpya
    // 'uploadedPath' itarudisha jina la file au path kamili kutoka ImageKit
    String? uploadedPath = await _api.uploadToImageKit(fileToUpload, folder: folder);
    
    // USAFI: Futa files za muda zilizotengenezwa wakati wa compress
    if (isVideo) {
      await VideoCompress.deleteAllCache();
    } else {
      if (await fileToUpload.exists()) {
        await fileToUpload.delete();
      }
    }
    
    return uploadedPath;
  }

  // 4. GENERATOR YA URL (Inaokoa Bandwidth ya ImageKit)
  // width: 400 ni saizi nzuri kwa simu nyingi, quality: 60 inapunguza uzito bila kuharibu picha
  String getUrl(String fileName, {int width = 400, int quality = 60}) {
    if (fileName.isEmpty) return "";

    // Kama ni video, tunairudisha link tupu bila image transformations
    if (fileName.toLowerCase().endsWith('.mp4') || fileName.toLowerCase().endsWith('.mov')) {
      return "${ApiService.imageKitUrl}$fileName";
    }

    // Kwa picha, tunapachika 'Transformation Parameters' kuokoa bando (Bandwidth)
    // Mfano wa matokeo: https://ik.imagekit.io/ID/uploads/picha.webp?tr=w-400,q-60
    return "${ApiService.imageKitUrl}$fileName?tr=w-$width,q-$quality";
  }
}
