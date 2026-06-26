import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Help & FAQ screen with expandable sections.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _Faq(
        q: 'Does the app upload my photos?',
        a: 'No. Smart Photo Cleaner processes everything 100% on your device. '
           'Your photos never leave your phone and no data is sent to any server.',
      ),
      _Faq(
        q: 'How does duplicate detection work?',
        a: 'The app uses two methods:\n\n'
           '• MD5 hashing to find exact byte-for-byte duplicates.\n'
           '• Perceptual hashing (pHash) to find visually similar photos, '
           'even if they have been resized, re-saved by WhatsApp, or lightly edited.',
      ),
      _Faq(
        q: 'How does the AI quality scoring work?',
        a: 'The app analyzes each photo using Google ML Kit and image processing algorithms:\n\n'
           '• Sharpness via Laplacian variance\n'
           '• Blur and motion blur via directional gradients\n'
           '• Exposure via brightness histogram\n'
           '• Noise via local standard deviation\n'
           '• Face quality, eye openness, smile, and head pose via ML Kit Face Detection\n'
           '• Composition via rule-of-thirds heuristic',
      ),
      _Faq(
        q: 'What is the "Best Photo" badge?',
        a: 'When multiple similar photos are found, the app picks the highest-scoring '
           'one and marks it with a "Best Photo" badge. The others are suggested '
           'for deletion with reasons explaining why they scored lower.',
      ),
      _Faq(
        q: 'Can the app delete photos automatically?',
        a: 'No. The app never deletes anything automatically. You must manually '
           'review suggested photos, select them, and confirm deletion. '
           'Deleted photos go to Android Trash and can be restored within 30 days.',
      ),
      _Faq(
        q: 'Why is the scan slow on a large library?',
        a: 'AI quality analysis (face detection, sharpness, exposure) is computationally '
           'intensive and runs on every photo. You can pause and resume at any time. '
           'The scan only needs to run once — results are kept until you re-scan.',
      ),
      _Faq(
        q: 'What categories does the app detect?',
        a: '• Exact Duplicates — identical byte-for-byte copies\n'
           '• Similar Photos — visually similar shots from the same scene\n'
           '• Burst Photos — rapid-fire shots taken within seconds\n'
           '• WhatsApp Duplicates — re-saved WhatsApp images\n'
           '• Screenshots — captured from your screen\n'
           '• Downloads — images downloaded from the web\n'
           '• Resized Copies — same photo at different resolutions\n'
           '• Edited Copies — lightly edited versions of the same shot',
      ),
      _Faq(
        q: 'How do I change the theme?',
        a: 'Go to Settings → Appearance → Theme. You can choose Light, Dark, '
           'or System default.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const Divider(indent: 16, endIndent: 16, height: 1),
        itemBuilder: (ctx, i) => _FaqTile(faq: faqs[i])
            .animate(delay: Duration(milliseconds: i * 50))
            .slideX(begin: 0.1, end: 0, duration: 300.ms)
            .fade(duration: 300.ms),
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExpansionTile(
      leading: Icon(Icons.help_outline_rounded, color: cs.primary),
      title: Text(
        faq.q,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(faq.a, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
