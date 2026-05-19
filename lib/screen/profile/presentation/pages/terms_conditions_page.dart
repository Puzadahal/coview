import 'package:flutter/material.dart';

import '../widgets/legal_document_page.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'Terms of Service',
      subtitle:
          'These terms explain the rules for using SyncView, including shared rooms, profile features, chat, uploaded files, and synchronized playback.',
      lastUpdated: 'May 12, 2026',
      icon: Icons.description_outlined,
      sections: [
        LegalSection(
          title: '1. Acceptance of Terms',
          paragraphs: [
            'By creating an account, joining a room, or using SyncView, you agree to follow these Terms of Service and any policies referenced inside the app.',
          ],
        ),
        LegalSection(
          title: '2. Account Responsibility',
          paragraphs: [
            'You are responsible for activity that happens from your account, including rooms you create, profile information you publish, messages you send, and files you upload.',
          ],
          bullets: [
            'Keep your sign-in method secure and do not share access to your account.',
            'Use a display name and avatar that do not impersonate another person or organization.',
            'Notify support if you believe your account or room has been accessed without permission.',
          ],
        ),
        LegalSection(
          title: '3. Acceptable Use',
          paragraphs: [
            'SyncView is designed for shared watching and collaboration. You agree to use the app responsibly and follow all applicable laws.',
          ],
          bullets: [
            'Do not upload, share, or stream illegal, harmful, abusive, or infringing content.',
            'Do not harass, threaten, spam, or abuse other users through chat or room features.',
            'Do not attempt to bypass security rules, disrupt sync services, or access rooms without permission.',
            'Do not use SyncView to distribute malware, phishing links, or deceptive content.',
          ],
        ),
        LegalSection(
          title: '4. Content and Media',
          paragraphs: [
            'You keep ownership of content you provide, but you grant SyncView permission to store, process, display, and synchronize that content as needed to operate the app.',
            'You are responsible for ensuring you have the rights to share video sources, profile photos, messages, and other content used in rooms.',
          ],
        ),
        LegalSection(
          title: '5. Shared Rooms and Sync Behavior',
          paragraphs: [
            'Room hosts may control playback, room settings, participant limits, and collaboration features. SyncView may store playback state and room metadata so participants can stay aligned.',
          ],
          bullets: [
            'Room playback can change based on host actions or synchronized room state.',
            'Network issues may temporarily affect playback accuracy, chat delivery, or room updates.',
            'Deleted rooms or uploaded room files may not be recoverable.',
          ],
        ),
        LegalSection(
          title: '6. Service Changes',
          paragraphs: [
            'We may add, change, suspend, or remove features to improve reliability, security, or user experience. Some changes may require app updates or new permissions.',
          ],
        ),
        LegalSection(
          title: '7. Limitation of Liability',
          paragraphs: [
            'SyncView is provided as-is. To the fullest extent allowed by law, we are not responsible for indirect losses, interrupted sync, lost room data, third-party content, or issues caused by external services.',
          ],
        ),
        LegalSection(
          title: '8. Updates to These Terms',
          paragraphs: [
            'We may update these Terms of Service when features, legal requirements, or business needs change. Continued use of SyncView after updates means you accept the revised terms.',
          ],
        ),
      ],
    );
  }
}
