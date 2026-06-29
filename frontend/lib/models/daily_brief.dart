class DailyBrief {
  final String greeting;
  final String userName;
  final int totalEmails;
  final int urgentEmails;
  final int normalEmails;
  final int ignoredEmails;
  final int estimatedTimeSavedMinutes;
  final TopPriorityEmail? topPriorityEmail;
  final String suggestedAction;
  final String productivityMessage;

  DailyBrief({
    required this.greeting,
    required this.userName,
    required this.totalEmails,
    required this.urgentEmails,
    required this.normalEmails,
    required this.ignoredEmails,
    required this.estimatedTimeSavedMinutes,
    required this.topPriorityEmail,
    required this.suggestedAction,
    required this.productivityMessage,
  });

  factory DailyBrief.fromJson(Map<String, dynamic> json) {
    final topPriority = json['top_priority_email'];
    return DailyBrief(
      greeting: json['greeting'] as String? ?? 'Good morning',
      userName: json['user_name'] as String? ?? 'User',
      totalEmails: json['total_emails'] as int? ?? 0,
      urgentEmails: json['urgent_emails'] as int? ?? 0,
      normalEmails: json['normal_emails'] as int? ?? 0,
      ignoredEmails: json['ignored_emails'] as int? ?? 0,
      estimatedTimeSavedMinutes:
          json['estimated_time_saved_minutes'] as int? ?? 0,
      topPriorityEmail: topPriority is Map<String, dynamic>
          ? TopPriorityEmail.fromJson(topPriority)
          : null,
      suggestedAction:
          json['suggested_action'] as String? ??
          'Your inbox looks stable today.',
      productivityMessage:
          json['productivity_message'] as String? ??
          'SmartInbox AI helped you focus on the most important messages first.',
    );
  }
}

class TopPriorityEmail {
  final int id;
  final String subject;
  final String sender;
  final String category;
  final double confidence;
  final String summary;

  TopPriorityEmail({
    required this.id,
    required this.subject,
    required this.sender,
    required this.category,
    required this.confidence,
    required this.summary,
  });

  factory TopPriorityEmail.fromJson(Map<String, dynamic> json) {
    return TopPriorityEmail(
      id: json['id'] as int? ?? 0,
      subject: json['subject'] as String? ?? '(no subject)',
      sender: json['sender'] as String? ?? 'unknown@example.com',
      category: json['category'] as String? ?? 'Important',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      summary: json['summary'] as String? ?? '',
    );
  }
}
