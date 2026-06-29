import 'package:flutter/material.dart';
import '../models/email.dart';
import '../core/app_theme.dart';
import 'ai_widgets.dart';

class EmailCard extends StatelessWidget {
  final Email email;
  final VoidCallback onTap;

  const EmailCard({
    super.key,
    required this.email,
    required this.onTap,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return AppTheme.important;
      case 'normal':
        return AppTheme.success;
      case 'ignored':
        return AppTheme.ignored;
      default:
        return AppTheme.normal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return Icons.priority_high;
      case 'normal':
        return Icons.check_circle_outline;
      case 'ignored':
        return Icons.remove_circle_outline;
      default:
        return Icons.mail_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(email.category);
    final catIcon = _getCategoryIcon(email.category);
    final initials = email.sender.isNotEmpty
        ? email.sender.trim()[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: email.category.toLowerCase() == 'important'
                    ? catColor.withOpacity(0.25)
                    : Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: catColor.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: avatar + sender + category badge
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: catColor.withOpacity(0.1),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: catColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          email.sender,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category + confidence badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: catColor.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(catIcon, size: 11, color: catColor),
                            const SizedBox(width: 4),
                            Text(
                              email.category,
                              style: TextStyle(
                                color: catColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(email.confidence * 100).toInt()}%',
                              style: TextStyle(
                                color: catColor.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Subject
                  Text(
                    email.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // AI Summary
                  if (email.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.secondary.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AiBadge.summary(),
                          const SizedBox(height: 4),
                          Text(
                            email.summary,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Preview text
                  if (email.preview != null && email.preview!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      email.preview!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
