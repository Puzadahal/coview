import 'package:flutter/material.dart';

import '../widgets/legal_document_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'Privacy Policy',
      subtitle:
          'Your privacy matters. This policy explains what SyncView collects, why it is needed, and how it supports shared watching, room sync, and profile features.',
      lastUpdated: 'May 12, 2026',
      icon: Icons.privacy_tip_outlined,
      sections: [
        LegalSection(
          title: '1. Information We Collect',
          paragraphs: [
            'We collect only the information needed to provide authentication, synchronized rooms, chat, playback state, profile display, and account preferences.',
          ],
          bullets: [
            'Account details such as name, email address, user ID, profile photo, and sign-in provider.',
            'Room data such as room name, invite code, host ID, participant settings, and video source metadata.',
            'Sync data such as playback position, play/pause state, timestamps, and room activity needed to keep viewers aligned.',
            'Messages and room interactions that you send while using chat or collaboration features.',
            'App preferences such as theme, notification settings, recent rooms, and basic device information.',
          ],
        ),
        LegalSection(
          title: '2. How We Use Your Information',
          paragraphs: [
            'SyncView uses your information to run the app reliably and to keep your shared viewing experience consistent across devices.',
          ],
          bullets: [
            'To sign you in and show your profile information across home, room, and profile screens.',
            'To create, join, manage, and synchronize watch rooms.',
            'To keep playback state, chat, and room settings updated for all participants.',
            'To save user preferences so the app behaves consistently the next time you open it.',
            'To protect rooms from unauthorized changes and help diagnose technical issues.',
          ],
        ),
        LegalSection(
          title: '3. Profile Photos and Uploaded Files',
          paragraphs: [
            'When you choose a profile photo, the image is uploaded to cloud storage and linked to your account profile. The image may be visible to other users in rooms where your profile is shown.',
          ],
        ),
        LegalSection(
          title: '4. Data Sharing',
          paragraphs: [
            'We do not sell your personal information. Some profile and room information is shared with other room participants only when required for the app experience.',
          ],
          bullets: [
            'Your display name and avatar can be shown to people in rooms you join.',
            'Room chat and playback activity can be visible to room participants.',
            'Service providers such as Firebase may process data to support authentication, storage, and real-time sync.',
          ],
        ),
        LegalSection(
          title: '5. Data Retention and Deletion',
          paragraphs: [
            'We keep account and room data while your account is active or while it is needed for app functionality. You may request account or data deletion through support or future in-app account controls.',
          ],
        ),
        LegalSection(
          title: '6. Security',
          paragraphs: [
            'We use Firebase authentication, cloud storage, and database security rules to protect account and room data. No system is perfect, so you should avoid sharing sensitive personal information inside rooms or chats.',
          ],
        ),
        LegalSection(
          title: '7. Changes to This Policy',
          paragraphs: [
            'We may update this Privacy Policy when SyncView changes features, storage behavior, or legal requirements. Continued use of the app after updates means you accept the revised policy.',
          ],
        ),
      ],
    );
  }
}
