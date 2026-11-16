import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../settings/settings_provider.dart';

class AppStrings {
  AppStrings._();

  static const _filipino = <String, String>{
    'Courses': 'Mga Kurso',
    'Flashcards': 'Mga Flashcard',
    'Quiz': 'Pagsusulit',
    'Progress': 'Pag-unlad',
    'Settings': 'Mga Setting',
    'New course': 'Bagong kurso',
    'Edit course': 'I-edit ang kurso',
    'Edit': 'I-edit',
    'Delete': 'Burahin',
    'No courses yet. Create one to get started.':
        'Wala pang kurso. Gumawa ng isa para magsimula.',
    'New topic': 'Bagong paksa',
    'Edit topic': 'I-edit ang paksa',
    'Topics': 'Mga Paksa',
    'No topics yet. Add one to organize this course.':
        'Wala pang paksa. Magdagdag para maisaayos ang kursong ito.',
    'Delete topic?': 'Burahin ang paksa?',
    'Delete course?': 'Burahin ang kurso?',
    'Delete flashcard?': 'Burahin ang flashcard?',
    'This flashcard will be permanently deleted.':
        'Permanenteng mabubura ang flashcard na ito.',
    'New flashcard': 'Bagong flashcard',
    'Quick add': 'Mabilisang pagdagdag',
    'Course / topic': 'Kurso / paksa',
    'Save & Add Another': 'I-save at magdagdag pa',
    'Save & Close': 'I-save at isara',
    'Topics could not be loaded:': 'Hindi mabuksan ang mga paksa:',
    'Card saved, but the last-used topic could not be saved:':
        'Na-save ang card ngunit hindi na-save ang huling paksang ginamit:',
    'Edit flashcard': 'I-edit ang flashcard',
    'Front (question)': 'Harap (tanong)',
    'Back (answer)': 'Likod (sagot)',
    'Tags (optional)': 'Mga tag (opsyonal)',
    'Add': 'Idagdag',
    'Save': 'I-save',
    'Cancel': 'Kanselahin',
    'Review': 'Mag-aral',
    'New card': 'Bagong card',
    'Search card text or tags': 'Maghanap sa tanong, sagot, o mga tag',
    'All tags': 'Lahat ng tag',
    'No flashcards yet. Add one to start studying.':
        'Wala pang flashcard. Magdagdag para makapagsimula.',
    'No flashcards match your current filters.':
        'Walang flashcard na tumutugma sa mga filter.',
    'Clear filters': 'I-clear ang mga filter',
    'Study cards': 'Mga card sa pag-aaral',
    'Tap a card to reveal its answer.':
        'Pindutin ang card para makita ang sagot.',
    'Question': 'Tanong',
    'Answer': 'Sagot',
    'See answer': 'Tingnan ang sagot',
    'Tap to reveal the answer': 'Pindutin para makita ang sagot',
    'Choose how well you remembered': 'Piliin kung gaano mo ito naalala',
    'Space: show answer · ←: missed · →: got it':
        'Space: ipakita ang sagot · ←: hindi alam · →: alam ko',
    'Show answer': 'Ipakita ang sagot',
    'Missed': 'Hindi alam',
    'Got it': 'Alam ko',
    'Nothing due right now. Check back later.':
        'Walang kailangang aralin ngayon. Bumalik mamaya.',
    'Review all cards': 'Aralin ang lahat ng card',
    'Session complete': 'Tapos na ang sesyon',
    'Cards reviewed': 'Mga card na inaral',
    'Unique cards reviewed': 'Natatanging mga card na inaral',
    'Total attempts': 'Kabuuang pagsubok',
    'Accuracy': 'Katumpakan',
    'Time spent': 'Oras na ginugol',
    'Missed cards': 'Mga hindi naalala',
    'Study Again': 'Mag-aral muli',
    'Undo': 'I-undo',
    'Undo last response': 'I-undo ang huling sagot',
    'Response undone': 'Na-undo ang sagot',
    'Reviewing again': 'Inaaral muli',
    'Repeat missed cards': 'Ulitin ang mga hindi naalala',
    'Immediately': 'Agad',
    'After 2 cards': 'Pagkalipas ng 2 card',
    'After 5 cards': 'Pagkalipas ng 5 card',
    'Restart': 'Ulitin',
    'Done': 'Tapos',
    'Appearance': 'Hitsura',
    'Theme': 'Tema',
    'Language': 'Wika',
    'System': 'Sundin ang system',
    'Light': 'Maliwanag',
    'Dark': 'Madilim',
    'English': 'English',
    'Filipino (Tagalog)': 'Filipino (Tagalog)',
    'Choose what to be quizzed on': 'Piliin ang paksa ng pagsusulit',
    'Course': 'Kurso',
    'Topic (optional)': 'Paksa (opsyonal)',
    'All topics': 'Lahat ng paksa',
    'Start quiz': 'Simulan ang pagsusulit',
    'Back': 'Bumalik',
    'Next': 'Susunod',
    'Finish': 'Tapusin',
    'Quiz complete': 'Tapos na ang pagsusulit',
    'Try again': 'Subukan ulit',
    'Overall mastery': 'Pangkalahatang kaalaman',
    'Daily goal': 'Pang-araw-araw na layunin',
    'Study analytics': 'Mga istatistika sa pag-aaral',
    'Reviewed today': 'Inaral ngayong araw',
    'Due today': 'Dapat aralin ngayon',
    'Overdue cards': 'Mga lampas na sa takdang-aralin',
    'Recent quizzes': 'Mga kamakailang pagsusulit',
    'Export backup': 'I-export ang backup',
    'Restore backup': 'Ibalik ang backup',
    'Backup exported to': 'Na-export ang backup sa',
    'No courses yet.': 'Wala pang kurso.',
    'No quizzes taken yet.': 'Wala pang nasagutang pagsusulit.',
    'No cards': 'Walang card',
    'Something went wrong:': 'Nagkaproblema:',
    'Cards in box 4 or higher count as mastered.':
        'Itinuturing na alam na ang mga card na nasa kahon 4 pataas.',
    'Name': 'Pangalan',
    'Description (optional)': 'Paglalarawan (opsyonal)',
    'Enter a course name': 'Maglagay ng pangalan ng kurso',
    'Enter a topic name': 'Maglagay ng pangalan ng paksa',
    'Required': 'Kailangan ito',
    'A course with this name already exists':
        'Mayroon nang kursong may ganitong pangalan',
    'This course already has a topic with this name':
        'Mayroon nang paksang may ganitong pangalan sa kursong ito',
    'Create a course and add topics to get started.':
        'Gumawa ng kurso at magdagdag ng mga paksa para magsimula.',
    'Choose a course to see its topics.':
        'Pumili ng kurso para makita ang mga paksa nito.',
    'No topics in this course yet. Add one in the Courses tab.':
        'Wala pang paksa sa kursong ito. Magdagdag sa tab na Mga Kurso.',
    'Create a course and add flashcards to start a quiz.': 'Gumawa ng kurso at magdagdag ng flashcard para magsimula ng pagsusulit.',
    'Settings could not be saved or loaded:':
        'Hindi ma-save o mabuksan ang mga setting:',
    'There aren\'t enough flashcards with different answers to build a quiz. Add more flashcards and try again.': 'Kulang ang mga flashcard na may magkakaibang sagot para makagawa ng pagsusulit. Magdagdag pa at subukan muli.',
    'Adjust your daily target to keep momentum.':
        'Baguhin ang pang-araw-araw na target para magpatuloy.',
    'Latest backup restored.': 'Naibalik ang pinakabagong backup.',
    'No backup file was found in your Documents folder.':
        'Walang nahanap na backup file sa Documents folder.',
    'Permanently delete this course, including its topics, flashcards, and quiz history?': 'Permanenteng burahin ang kursong ito kasama ang mga paksa, flashcard, at kasaysayan ng pagsusulit?',
    'Delete this topic and all its flashcards? Past quiz results will be kept.': 'Burahin ang paksang ito at lahat ng flashcard nito? Ititira ang mga resulta ng pagsusulit.',
  };

  static String text(String english, AppLanguage language) {
    if (language == AppLanguage.english) return english;
    final translated = _filipino[english];
    if (translated != null) return translated;
    final cardProgress = RegExp(r'^Card (\d+) of (\d+)$').firstMatch(english);
    if (cardProgress != null) {
      return 'Card ${cardProgress[1]} sa ${cardProgress[2]}';
    }
    final motivational = RegExp(r'^Nice work — (\d+)% accuracy!$')
        .firstMatch(english);
    if (motivational != null) {
      return 'Magaling — ${motivational[1]}% ang katumpakan!';
    }
    final reviewSummary = RegExp(r'^(\d+) remembered · (\d+) missed$')
        .firstMatch(english);
    if (reviewSummary != null) {
      return '${reviewSummary[1]} naalala · ${reviewSummary[2]} hindi alam';
    }
    final dailyStats = RegExp(
      r'^Overdue cards: (\d+) · Goal progress: (\d+) / (\d+)$',
    ).firstMatch(english);
    if (dailyStats != null) {
      return 'Lampas na sa takdang-aralin: ${dailyStats[1]} · '
          'Pag-usad sa layunin: ${dailyStats[2]} / ${dailyStats[3]}';
    }
    final countCards = RegExp(r'^(\d+) of (\d+) cards mastered$')
        .firstMatch(english);
    if (countCards != null) {
      return 'Alam na ang ${countCards[1]} sa ${countCards[2]} card';
    }
    final reviewAccuracy = RegExp(
      r'^Recent quiz accuracy: (\d+%) \(last (\d+) quizzes\)$',
    ).firstMatch(english);
    if (reviewAccuracy != null) {
      return 'Katumpakan sa kamakailang pagsusulit: ${reviewAccuracy[1]} '
          '(huling ${reviewAccuracy[2]} pagsusulit)';
    }
    final dailyGoal = RegExp(r'^(\d+) / (\d+) cards reviewed today$')
        .firstMatch(english);
    if (dailyGoal != null) {
      return '${dailyGoal[1]} / ${dailyGoal[2]} card ang inaral ngayong araw';
    }
    final courseMastery = RegExp(r'^(\d+) / (\d+) mastered$')
        .firstMatch(english);
    if (courseMastery != null) {
      return '${courseMastery[1]} / ${courseMastery[2]} alam na';
    }
    final goalLabel = RegExp(r'^(\d+) cards$').firstMatch(english);
    if (goalLabel != null) return '${goalLabel[1]} card';
    final questionProgress = RegExp(r'^Question (\d+) of (\d+)$')
        .firstMatch(english);
    if (questionProgress != null) {
      return 'Tanong ${questionProgress[1]} sa ${questionProgress[2]}';
    }
    final score = RegExp(r'^(\d+%) correct$').firstMatch(english);
    if (score != null) return '${score[1]} tama';
    final quizSetupCount = RegExp(
      r'^(\d+) flashcards available \(up to 10 questions\)$',
    ).firstMatch(english);
    if (quizSetupCount != null) {
      return 'May ${quizSetupCount[1]} flashcard (hanggang 10 tanong)';
    }
    final quizSetupNeed = RegExp(
      r'^Need at least (\d+) flashcards to start a quiz \((\d+) available\)$',
    ).firstMatch(english);
    if (quizSetupNeed != null) {
      return 'Kailangan ng hindi bababa sa ${quizSetupNeed[1]} flashcard '
          'para magsimula ng pagsusulit (${quizSetupNeed[2]} ang mayroon)';
    }
    final quizKeyboard = RegExp(r'^Press 1-(\d+) to answer  ·  Enter for next$')
        .firstMatch(english);
    if (quizKeyboard != null) {
      return 'Pindutin ang 1-${quizKeyboard[1]} para sumagot · Enter para magpatuloy';
    }
    if (english.startsWith('Something went wrong: ')) {
      return 'Nagkaproblema: ${english.substring('Something went wrong: '.length)}';
    }
    if (english.startsWith('"') &&
        english.endsWith(
          'and everything in it will be permanently deleted: its topics, flashcards and quiz history.',
        )) {
      return 'Permanenteng burahin ang kursong ito kasama ang mga paksa, '
          'flashcard, at kasaysayan ng pagsusulit?';
    }
    if (english.startsWith('"') &&
        english.contains(
          'and all of its flashcards will be permanently deleted.',
        )) {
      return 'Burahin ang paksang ito at lahat ng flashcard nito? '
          'Ititira ang mga resulta ng pagsusulit.';
    }
    if (english.startsWith('Backup exported to ')) {
      return 'Na-export ang backup sa '
          '${english.substring('Backup exported to '.length)}';
    }
    return english;
  }

  static String of(BuildContext context, String english) {
    return text(english, context.watch<SettingsProvider>().language);
  }
}
