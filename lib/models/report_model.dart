import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reporterId;
  final String reportedId;
  final String reason;
  final String contentId;
  final String contentType;
  final Timestamp createdAt;

  ReportModel({
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    required this.contentId,
    required this.contentType,
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      reporterId: data['reporterId'],
      reportedId: data['reportedId'],
      reason: data['reason'],
      contentId: data['contentId'],
      contentType: data['contentType'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': reason,
      'contentId': contentId,
      'contentType': contentType,
      'createdAt': createdAt,
    };
  }
}
