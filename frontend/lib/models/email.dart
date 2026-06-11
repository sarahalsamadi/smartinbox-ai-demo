class Email {
  final int id;
  final String sender;
  final String subject;
  final String category;
  final double confidence;
  final String summary;
  final String? preview;
  final String? body;

  Email({
    required this.id,
    required this.sender,
    required this.subject,
    required this.category,
    required this.confidence,
    required this.summary,
    this.preview,
    this.body,
  });

  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['id'] as int,
      sender: json['sender'] as String? ?? 'unknown@example.com',
      subject: json['subject'] as String? ?? '(no subject)',
      category: json['category'] as String? ?? 'Normal',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      summary: json['summary'] as String? ?? '',
      preview: json['preview'] as String?,
      body: json['body'] as String?,
    );
  }
}
