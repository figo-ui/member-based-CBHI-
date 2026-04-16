import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cbhi_localizations.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    _Faq(
      question: 'How do I register my household?',
      questionAm: 'ቤተሰቤን እንዴት መመዝገብ እችላለሁ?',
      answer:
          'Tap "Register" on the welcome screen. Complete the steps: personal information (with ID document), review, identity and employment, membership type, and — if you choose indigent membership — supporting documents. You can register offline; data syncs when you connect.',
      answerAm:
          'በእንኳን ደህና መጡ ማያ ላይ "ምዝገባ" ን ይጫኑ። የግል መረጃ፣ ማረጋገጫ፣ መታወቂያ እና ሥራ፣ የአባልነት አይነት እና (ለድሆች) ማረጋገጫ ሰነዶችን ያጠናቅቁ። ከኢንተርኔት ውጭም ሊመዘገቡ ይችላሉ።',
    ),
    _Faq(
      question: 'What is a FAN Number?',
      questionAm: 'FAN ቁጥር ምንድን ነው?',
      answer:
          'FAN stands for Fayda Authentication Number — your 12-digit Ethiopian National ID number. You can find it on your Fayda ID card.',
      answerAm:
          'FAN ማለት የፋይዳ ማረጋገጫ ቁጥር ነው — 12 አሃዝ ያለው የኢትዮጵያ ብሔራዊ መታወቂያ ቁጥርዎ። በፋይዳ መታወቂያ ካርድዎ ላይ ያገኙታል።',
    ),
    _Faq(
      question: 'How do I pay my premium?',
      questionAm: 'ፕሪሚየሜን እንዴት እከፍላለሁ?',
      answer:
          'Tap "Renew Coverage" on the Home screen. You can pay via Telebirr, CBE Birr, Amole, HelloCash, or bank transfer through the Chapa payment page.',
      answerAm:
          'በዋናው ማያ ላይ "ሽፋን አድስ" ን ይጫኑ። በቴሌብር፣ CBE ብር፣ አሞሌ፣ ሄሎካሽ ወይም ባንክ ዝውውር መክፈል ይችላሉ።',
    ),
    _Faq(
      question: 'How do I add family members?',
      questionAm: 'የቤተሰብ አባላትን እንዴት ማከል እችላለሁ?',
      answer:
          'Go to the Family tab and tap "Add beneficiary". You need to capture a photo and provide basic details. Non-child members need a phone number for independent access.',
      answerAm:
          'ወደ ቤተሰብ ትር ሂደው "ተጠቃሚ ጨምር" ን ይጫኑ። ፎቶ ማንሳት እና መሰረታዊ መረጃ መስጠት ያስፈልጋል።',
    ),
    _Faq(
      question: 'How do I use my digital CBHI card?',
      questionAm: 'ዲጂታል CBHI ካርዴን እንዴት እጠቀማለሁ?',
      answer:
          'Go to the Card tab to view your digital membership card with QR code. Show this to health facility staff to verify your eligibility for services.',
      answerAm:
          'ወደ ካርድ ትር ሂደው QR ኮድ ያለው ዲጂታል የአባልነት ካርድዎን ይመልከቱ። ለጤና ተቋም ሰራተኞች ያሳዩ።',
    ),
    _Faq(
      question: 'What if I have no internet connection?',
      questionAm: 'ኢንተርኔት ከሌለ ምን ማድረግ አለብኝ?',
      answer:
          'The app works offline. Registration and changes are saved locally and sync automatically when you reconnect. Look for the "Offline queue active" indicator on the Home screen.',
      answerAm:
          'መተግበሪያው ያለ ኢንተርኔት ይሰራል። ምዝገባ እና ለውጦች በአካባቢ ይቀመጣሉ እና ሲገናኙ ይሰናዳሉ።',
    ),
    _Faq(
      question: 'How do I track my claims?',
      questionAm: 'ክሌሞቼን እንዴት መከታተል እችላለሁ?',
      answer:
          'Go to the Claims tab to see all claims submitted by health facilities on your behalf. You will see the status (Submitted, Under Review, Approved, Paid, or Rejected).',
      answerAm:
          'ወደ ክሌም ትር ሂደው ሁሉንም ክሌሞች ይመልከቱ። ሁኔታውን (ቀርቧል፣ በግምገማ ላይ፣ ፀድቋል፣ ተከፍሏል ወይም ተቀባይነት አላገኘም) ያያሉ።',
    ),
    _Faq(
      question: 'How do I find accredited health facilities?',
      questionAm: 'ተፈቅዶ ጤና ተቋሞችን እንዴት ማግኘት እችላለሁ?',
      answer:
          'Go to the Facilities tab and search by name. All listed facilities are accredited by EHIA and accept your CBHI membership card.',
      answerAm: 'ወደ ተቋሞች ትር ሂደው በስም ይፈልጉ። ሁሉም ተዘርዝረው ያሉ ተቋሞች በEHIA ተፈቅደዋል።',
    ),
    _Faq(
      question: 'Who do I contact for help?',
      questionAm: 'ለእርዳታ ማን ጋር ማነጋገር አለብኝ?',
      answer:
          'Contact the Ethiopian Health Insurance Agency (EHIA) at info@ehia.gov.et or visit your local CBHI office. You can also call the EHIA helpline.',
      answerAm:
          'የኢትዮጵያ ጤና ኢንሹራንስ ኤጀንሲ (EHIA) ን info@ehia.gov.et ላይ ያነጋግሩ ወይም የአካባቢ CBHI ቢሮዎን ይጎብኙ።',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('helpAndFaq'))),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.t('helpAndFaq'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.t('appTitle'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // Contact card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.t('ehiaHelpline'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        strings.t('ehiaContact'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 20),

          // FAQ list
          ..._faqs.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FaqCard(faq: entry.value)
                  .animate()
                  .fadeIn(duration: 350.ms, delay: (150 + entry.key * 50).ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 350.ms,
                    delay: (150 + entry.key * 50).ms,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.faq});
  final _Faq faq;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: AppTheme.primary,
              size: 18,
            ),
          ),
          title: Text(
            widget.faq.question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
          subtitle: Text(
            widget.faq.questionAm,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          onExpansionChanged: (_) {},
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(
              widget.faq.answer,
              style: const TextStyle(
                color: AppTheme.textDark,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.faq.answerAm,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  const _Faq({
    required this.question,
    required this.questionAm,
    required this.answer,
    required this.answerAm,
  });
  final String question;
  final String questionAm;
  final String answer;
  final String answerAm;
}
