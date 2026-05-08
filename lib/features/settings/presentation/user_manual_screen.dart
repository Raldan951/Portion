import 'package:flutter/material.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3F2E1F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'User Manual',
          style: TextStyle(
            color: Color(0xFF3F2E1F),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: const [
          _ManualSection(
            title: 'WHAT IS THIS?',
            body:
                'A quiet reading companion built around the M\'Cheyne plan — four passages a day, calibrated to the church calendar. Open it, read, write what moves you, close it. That\'s the whole idea.\n\nThink of it as a desk you return to each morning.',
          ),
          _ManualSection(
            title: 'GETTING STARTED',
            body:
                'Your reading plan and translation are set and waiting on the main screen. The passages for today are already there.\n\nTo switch plans or adjust where you are in a plan, tap the plan name — the small italic line just beneath the word Reading.\n\nYou can also choose your Bible translation there: KJV, BSB, or Logos if you have it installed.',
          ),
          _ManualSection(
            title: 'READING AT YOUR OWN PACE',
            body:
                'Portion doesn\'t track streaks or mark you absent. Come back after a week away — your plan is right where you left it, no guilt attached.\n\nUse the arrows on either side of the date to move forward or back. Read ahead if you\'re on a roll. Catch up when life settles. When you\'re ready to return to today, a "Return to Today" pill will appear — one tap brings you home.\n\nWelcome back. Just read.',
          ),
          _ManualSection(
            title: 'PICKING UP WHERE YOU LEFT OFF',
            body:
                'Been away for a few days? Navigate back to the last day you read and tap Sync Plan at the bottom of the reading card — you\'ll land on today with those readings waiting.',
          ),
          _ManualSection(
            title: 'CLIPPING VERSES',
            body:
                'Open any passage from the reading card. Tap a verse number to anchor a selection — tap a second to extend the range. A Clip pill floats up at the bottom; tap it and the selected verses are formatted as a block quote, attributed with the reference and translation, and sent straight to your journal entry.\n\nClipped verses land at the cursor in your journal. From there, use the standard copy, cut, and paste to arrange them however you like.',
          ),
          _ManualSection(
            title: 'LISTEN TO A PASSAGE',
            body:
                'Check the Read Aloud box at the top of any passage to enable listening mode. Tap the play button to begin — the passage is read verse by verse, with the current verse highlighted in blue.\n\nTap any verse to jump to that point. Use the Speed slider to slow things down or speed them up. Tip: Turning the screen sideways allows easier speed adjustment. Tap Voice to choose from any English voice installed on your device.\n\nThe default system voices are serviceable but thin. The enhanced and premium voices are dramatically better — natural pacing, clear diction, easy to follow. Worth the download.\n\nOn iPhone or iPad:\nSettings → Accessibility → Spoken Content → Voices → English → tap a voice → Download.\nLook for voices marked Enhanced or Premium. Siri voices (where available) are excellent.\n\nOn Mac:\nSystem Settings → Accessibility → Spoken Content → System Voice → Manage Voices → download any Enhanced voice under English.\n\nOnce downloaded, they appear immediately in the Voice picker inside Portion. No restart needed.',
          ),
          _ManualSection(
            title: 'THE JOURNAL',
            body:
                'Tap Open journal to write. It saves automatically as you type — there\'s no save button, nothing to lose.\n\nWhen you want a copy for yourself, tap the share icon in the upper right. The first time, it will ask whether you prefer Email or Messages — your entry lands wherever you already look for things.',
          ),
          _ManualSection(
            title: 'FOUNDING DOCUMENTS (OPTIONAL)',
            body:
                'Settings → Show Founding Documents adds a daily reading from the Federalist Papers, the Declaration of Independence, or the Constitution below your Scripture card. Toggle it off to hide.',
          ),
          _ManualSection(
            title: 'SENDING FEEDBACK',
            body:
                'Take a screenshot of anything that confuses you or breaks. TestFlight will offer to attach it to a feedback report — that comes straight to us with your device information included. No email, no form to find.\n\nIf something delights you, that\'s worth a screenshot too.',
          ),
        ],
      ),
    );
  }
}

class _ManualSection extends StatelessWidget {
  final String title;
  final String body;

  const _ManualSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5C6B4A),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF3F2E1F),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
