 import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String pollId;
  final String question;
  final List<PollOption> options;
  final List<String> voters;
  final DateTime createdAt;

  PollModel({
    required this.pollId,
    required this.question,
    required this.options,
    required this.voters,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'pollId': pollId,
        'question': question,
        'options': options.map((e) => e.toJson()).toList(),
        'voters': voters,
        'createdAt': createdAt,
      };
}

class PollOption {
  final String text;
  final int votesCount;

  PollOption({required this.text, this.votesCount = 0});

  Map<String, dynamic> toJson() => {
        'text': text,
        'votesCount': votesCount,
      };
}
