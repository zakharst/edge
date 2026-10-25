import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../state/locale_controller.dart';
import '../grammar.dart';
import '../theme.dart';
import 'home_screen.dart' show hm;

enum BiometricTopic {
  bodyBattery,
  sleepQuality,
  recovery,
  strain,
  cardioAge,
  stress,
  journalHabits,
  repCounter,
}

/// Standardized, deep "Tap-to-Explain" Bottom Sheet.
///
/// Every metric on the dashboard opens this sheet to transparently reveal:
/// 1. Що це означає (людською мовою без медичного булшіту)
/// 2. Як це рахується (прозора арифметика з реальними вхідними даними)
/// 3. Чому це правда (короткий науковий факт)
/// 4. Що робити сьогодні (практичні персоналізовані кроки)
class BiometricExplainerSheet {
  static void show(
    BuildContext context, {
    required BiometricTopic topic,
    required dynamic data,
    VoidCallback? onOpenDetails,
    String? detailsLabel,
  }) {
    HapticFeedback.lightImpact();
    final p = P.of(context);
    final isUk = LocaleController.displayLanguageCode == 'uk';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: sheetMotion(context),
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(S.x4, 0, S.x4, S.x6),
            children: [
              _buildHeader(ctx, p, topic, sheetContext, isUk),
              const SizedBox(height: S.x3),
              _buildValueBadge(ctx, p, topic, data, isUk),
              const SizedBox(height: S.x4),
              _buildSection(
                p: p,
                title: isUk ? 'ЩО ЦЕ ОЗНАЧАЄ' : 'WHAT IT MEANS',
                icon: LucideIcons.info,
                accent: C.blue,
                body: _meaningText(topic, data, isUk),
              ),
              const SizedBox(height: S.x3),
              _buildSection(
                p: p,
                title: isUk ? 'ЯК ЦЕ РАХУЄТЬСЯ' : 'HOW IT WORKS',
                icon: LucideIcons.cpu,
                accent: C.purple,
                body: _calculationText(topic, data, isUk),
                formula: _formulaBadge(topic, isUk),
                calculationLedger: _buildCalculationLedger(p, topic, data, isUk),
                sensors: _sensorInputs(topic, isUk),
              ),
              const SizedBox(height: S.x3),
              _buildSection(
                p: p,
                title: isUk ? 'НАУКОВА ОСНОВА' : 'THE SCIENCE',
                icon: LucideIcons.bookOpenCheck,
                accent: C.teal,
                body: _scienceText(topic, isUk),
              ),
              const SizedBox(height: S.x3),
              _buildSection(
                p: p,
                title: isUk ? 'ЩО РОБИТИ СЬОГОДНІ' : 'WHAT TO DO TODAY',
                icon: LucideIcons.compass,
                accent: C.green,
                body: _guidanceText(topic, data, isUk),
              ),
              if (onOpenDetails != null) ...[
                const SizedBox(height: S.x4),
                Pressable(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onOpenDetails();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: S.x3, horizontal: S.x4),
                    decoration: BoxDecoration(
                      color: p.wash(C.blue),
                      borderRadius: R.rMd,
                      border: Border.all(
                          color: p.on(C.blue).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          detailsLabel ?? _defaultDetailsLabel(topic, isUk),
                          style: F.body.copyWith(
                            color: p.on(C.blue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: S.x2),
                        Icon(LucideIcons.arrowRight,
                            size: 16, color: p.on(C.blue)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHeader(
    BuildContext ctx,
    P p,
    BiometricTopic topic,
    BuildContext sheetCtx,
    bool isUk,
  ) {
    final meta = _metaOf(topic, isUk);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(S.x2),
          decoration: BoxDecoration(
            color: p.wash(meta.color),
            borderRadius: R.rMd,
          ),
          child: Icon(meta.icon, color: p.on(meta.color), size: 20),
        ),
        const SizedBox(width: S.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.title, style: F.t2.copyWith(color: p.ink)),
              Text(meta.subtitle, style: F.cap.copyWith(color: p.ink3)),
            ],
          ),
        ),
        Pressable(
          onTap: () => Navigator.of(sheetCtx).pop(),
          child: Container(
            padding: const EdgeInsets.all(S.x2),
            decoration: BoxDecoration(
              color: p.card2,
              borderRadius: R.rPill,
            ),
            child: Icon(LucideIcons.x, size: 16, color: p.ink2),
          ),
        ),
      ],
    );
  }

  static Widget _buildValueBadge(
    BuildContext ctx,
    P p,
    BiometricTopic topic,
    dynamic data,
    bool isUk,
  ) {
    return Container(
      padding: const EdgeInsets.all(S.x4),
      decoration: BoxDecoration(
        color: p.card2,
        borderRadius: R.rLg,
        border: Border.all(color: p.line),
      ),
      child: _renderMetricHero(p, topic, data, isUk),
    );
  }

  static Widget _buildSection({
    required P p,
    required String title,
    required IconData icon,
    required Color accent,
    required String body,
    String? formula,
    Widget? calculationLedger,
    List<String>? sensors,
  }) {
    return Container(
      padding: const EdgeInsets.all(S.x4),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: R.rLg,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: p.on(accent)),
              const SizedBox(width: S.x2),
              Text(
                title,
                style: F.over.copyWith(
                  color: p.on(accent),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: S.x2),
          Text(body, style: F.body.copyWith(color: p.ink2, height: 1.4)),
          if (calculationLedger != null) ...[
            const SizedBox(height: S.x3),
            calculationLedger,
          ],
          if (formula != null) ...[
            const SizedBox(height: S.x3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(S.x3),
              decoration: BoxDecoration(
                color: p.card2,
                borderRadius: R.rSm,
                border: Border.all(color: p.line),
              ),
              child: Text(
                formula,
                style: F.cap.copyWith(
                  fontFamily: 'monospace',
                  color: p.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (sensors != null && sensors.isNotEmpty) ...[
            const SizedBox(height: S.x3),
            Wrap(
              spacing: S.x2,
              runSpacing: S.x1,
              children: sensors
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: S.x2, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.wash(accent, strength: 0.4),
                          borderRadius: R.rPill,
                        ),
                        child: Text(s,
                            style: F.over.copyWith(
                                color: p.on(accent),
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  static ({String title, String subtitle, Color color, IconData icon}) _metaOf(
      BiometricTopic t, bool isUk) {
    switch (t) {
      case BiometricTopic.bodyBattery:
        return (
          title: isUk ? 'Запас енергії' : 'Body Battery',
          subtitle: isUk
              ? 'Скільки сил у тіла просто зараз'
              : 'Real-time energy remaining today',
          color: C.green,
          icon: LucideIcons.batteryCharging,
        );
      case BiometricTopic.sleepQuality:
        return (
          title: isUk ? 'Якість сну' : 'Sleep Quality',
          subtitle: isUk
              ? 'Наскільки глибоко відновилося тіло'
              : 'How deeply your body recharged',
          color: C.blue,
          icon: LucideIcons.moon,
        );
      case BiometricTopic.recovery:
        return (
          title: isUk ? 'Відновлення' : 'Recovery',
          subtitle: isUk
              ? 'Готовність організму до нового дня'
              : 'How ready your body is today',
          color: C.green,
          icon: LucideIcons.heartPulse,
        );
      case BiometricTopic.strain:
        return (
          title: isUk ? 'Навантаження дня' : 'Daily Strain',
          subtitle: isUk
              ? 'Скільки попрацювало серце (0–21)'
              : 'Total cardiovascular effort (0–21)',
          color: C.purple,
          icon: LucideIcons.zap,
        );
      case BiometricTopic.cardioAge:
        return (
          title: isUk ? 'Вік серця та судин' : 'Cardio Age',
          subtitle: isUk
              ? 'Біологічний стан ваших артерій'
              : 'Biological fitness of your arteries',
          color: C.red,
          icon: LucideIcons.heartHandshake,
        );
      case BiometricTopic.stress:
        return (
          title: isUk ? 'Рівень стресу' : 'Stress Level',
          subtitle: isUk
              ? 'Тонус вегетативної системи та індекс Баєвського'
              : 'Autonomic nervous tone & Baevsky SI',
          color: C.orange,
          icon: LucideIcons.zap,
        );
      case BiometricTopic.journalHabits:
        return (
          title: isUk ? 'Вплив звичок' : 'Habit Insights',
          subtitle: isUk
              ? 'Об’єктивна кореляція з ранковим відновленням'
              : 'Objective correlation with morning recovery',
          color: C.purple,
          icon: LucideIcons.notebook,
        );
      case BiometricTopic.repCounter:
        return (
          title: isUk ? 'Трекер силових повторень' : 'Strength Rep Counter',
          subtitle: isUk
              ? 'Кінематика високої частоти 100 Гц'
              : 'High-rate 100 Hz IMU kinematics',
          color: C.green,
          icon: LucideIcons.dumbbell,
        );
    }
  }

  static String _meaningText(BiometricTopic t, dynamic d, bool isUk) =>
      switch (t) {
        BiometricTopic.bodyBattery => isUk
            ? 'Уявіть батарейку смартфона: сон її заряджає за ніч, а активність і години дня поступово розряджають. Цей відсоток показує, скільки палива у вас лишилося на залишок дня.'
            : 'Think of your body like a phone battery: sleep charges it overnight, while movement and waking hours spend it. This shows how much fuel you have left for the rest of today.',
        BiometricTopic.sleepQuality => isUk
            ? 'Можна пролежати в ліжку 8 годин, але прокинутися втомленим. Якість показує не просто час, а глибину відпочинку: скільки ви крутилися, скільки прокидалися і чи вистачило глибокого сну для відновлення.'
            : 'You can spend 8 hours in bed and still wake up exhausted. Sleep quality measures true rest: wakeups, tosses and turns, and whether you got enough deep restorative sleep.',
        BiometricTopic.recovery => isUk
            ? 'Показує, чи відпочила нервова система за ніч. Коли пульс уві сні спокійний і гнучкий — тіло повне сил. Коли організм бореться зі стресом чи втомою — показник знижується.'
            : 'Shows how fully your nervous system rebounded overnight. When your resting rhythm is relaxed and flexible, your body is primed. If you are fatigued, the score dips.',
        BiometricTopic.strain => isUk
            ? 'Показує, скільки зусиль доклало серце за день. На відміну від простих кроків, тут враховується інтенсивність: 20 хвилин бігу навантажують серце більше, ніж пів дня спокійної ходьби.'
            : 'Measures total cardiovascular effort today. Unlike step counts, it values intensity: a 20-minute run works your heart far harder than hours of casual walking.',
        BiometricTopic.cardioAge => isUk
            ? 'Показує реальний стан ваших судин у порівнянні з віком у паспорті. Якщо судинний вік нижчий — ваші артерії еластичні, а серце працює як у молодому тілі.'
            : 'Compares the biological flexibility of your blood vessels against your calendar age. A younger score means elastic arteries and strong cardiovascular fitness.',
        BiometricTopic.stress => isUk
            ? 'Показує фізіологічне напруження організму на основі мікропауз між ударами серця у спокої. Коли домінує стрес (симпатична система), пульс стає жорстким і метрономним. У стані спокою та відновлення (парасимпатика) серце б’ється гнучко й варіативно.'
            : 'Reflects physiological tension based on beat-to-beat heart intervals during rest. Chronic or acute stress turns your pulse rigid and metronomic. When recovering, your autonomic tone becomes flexible and calm.',
        BiometricTopic.journalHabits => isUk
            ? 'Відокремлює суб’єктивні відчуття від реального впливу на фізіологію. Допомагає точно зрозуміти, які саме вечірні звички (магній, сауна, пізня вечеря, мелатонін, алкоголь) об’єктивно піднімають чи руйнують ваш ранковий HRV і відновлення.'
            : 'Separates guesswork from physiological reality. Identifies which specific evening habits (magnesium, sauna, late meals, alcohol, cold shower) statistically boost or impair your morning HRV and recovery.',
        BiometricTopic.repCounter => isUk
            ? 'Автоматично розпізнає та підраховує повторення силових вправ (підтягування, жим, присідання) за допомогою вбудованого в браслет 6-осьового сенсора руху (акселерометр + гіроскоп).'
            : 'Automatically detects and counts strength training repetitions (pullups, bench press, squats) using wrist-mounted 6-axis IMU sensors (accelerometer + gyroscope).',
      };

  static String _calculationText(BiometricTopic t, dynamic d, bool isUk) =>
      switch (t) {
        BiometricTopic.bodyBattery => isUk
            ? '• Ранковий заряд: скільки сил дав нічний сон (до 100%).\n• Рух: мінус енергія, витрачена на тренування та кроки.\n• Час дня: природний спад сил за кожну годину на ногах.'
            : '• Morning start: energy banked from sleep and recovery (up to 100%).\n• Movement: energy burned through active strain and steps.\n• Daytime: natural fatigue accumulated for each hour awake.',
        BiometricTopic.sleepQuality => isUk
            ? '• Час у ліжку: наскільки сон близький до здорових 7–8 годин.\n• Глибокі фази: час найважливіших для відновлення стадій (Deep + REM).\n• Спокій: наскільки рівно ви спали без метушні в ліжку.\n• Пробудження: штраф за хвилини, коли сон переривався.'
            : '• Time asleep: how close you got to the 7–8 hour target.\n• Restorative sleep: time in vital Deep and REM stages.\n• Sleep efficiency: how quietly you rested without tossing.\n• Wakeups: total minutes lost to nighttime interruptions.',
        BiometricTopic.recovery => isUk
            ? 'Датчик заміряє паузи між ударами серця у спокої (варіабельність HRV) та нічний пульс, а потім порівнює їх із вашою особистою нормою за останні 30 днів.'
            : 'Your sensor tracks subtle micro-pauses between heartbeats during deep sleep (HRV) and resting pulse, comparing them to your 30-day baseline.',
        BiometricTopic.strain => isUk
            ? 'Кожна хвилина активності рахується за пульсом: чим вища зона пульсу під час руху, тим швидше росте навантаження від 0 до 21. Набрати 10 легко, а кожен бал після 14 вимагає серйозного тренування.'
            : 'Every active minute is scored by heart rate zone. The higher your heart rate, the faster strain builds from 0 to 21. Getting to 10 is easy; pushing past 14 takes serious effort.',
        BiometricTopic.cardioAge => isUk
            ? 'Оптичний сенсор аналізує форму пульсової хвилі на зап\'ясті: швидкість підйому хвилі вказує на пружність стінок артерій, пульс у спокої та відновлення.'
            : 'The optical wrist sensor analyzes your pulse waveform: the wave shape reveals arterial wall flexibility, resting pulse, and cardio health.',
        BiometricTopic.stress => isUk
            ? '• Розраховується за математичною моделлю індексу напруги Баєвського (SI).\n• Амплітуда моди (AMo): відсоток ударів з найчастішою тривалістю.\n• Варіаційний розмах (MxDMn): різниця між найдовшим і найкоротшим ударом.\n• Формула: SI = AMo / (2 × Mo × MxDMn). У нормі показник спокою становить 50–150.'
            : '• Calculated using Baevsky Stress Index (SI) amplitude distribution.\n• Mode Amplitude (AMo): frequency of dominant beat interval.\n• Variation Range (MxDMn): spread between max and min intervals.\n• Equation: SI = AMo / (2 × Mo × MxDMn). Normal resting range is 50–150.',
        BiometricTopic.journalHabits => isUk
            ? '• Порівнюються ночі після днів із зазначеною звичкою та ночі без неї.\n• Розраховується двовибірковий t-тест Велча з поправкою на нерівні дисперсії.\n• Потрібно мінімум 5 днів присутності та 5 днів відсутності звички для усунення випадкового шуму.'
            : '• Compares mornings following days with the habit against nights without it.\n• Applies Welch’s two-sample t-test accounting for unequal variances.\n• Requires a minimum of 5 logged days with and 5 without to filter behavioral noise.',
        BiometricTopic.repCounter => isUk
            ? '• Сенсор опитується з частотою 100 разів на секунду (100 Гц).\n• Кватерніонна орієнтація ізолює вектор гравітації та рахує повторення за піками прискорення в реальному часі.\n• Обробка відбувається виключно в оперативній пам’яті (RAM) без затримки та без засмічення сховища.'
            : '• The IMU is sampled at 100 Hz.\n• Quaternion orientation isolates gravity and tracks repetition inflection points in real time.\n• Processing operates directly in live RAM without latency and zero flash memory bloat.',
      };

  static Widget? _buildCalculationLedger(
      P p, BiometricTopic topic, dynamic d, bool isUk) {
    if (d == null) return null;
    switch (topic) {
      case BiometricTopic.bodyBattery:
        return Container(
          padding: const EdgeInsets.all(S.x3),
          decoration: BoxDecoration(
            color: p.card2,
            borderRadius: R.rMd,
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUk ? 'ПРОСТА АРИФМЕТИКА ДНЯ:' : 'TODAY\'S SIMPLE MATH:',
                style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: S.x2),
              _LedgerEquationRow(
                sign: '+',
                value: '${d.morningCharge}%',
                label: isUk
                    ? 'Заряд від нічного сну'
                    : 'Charged from overnight sleep',
                color: C.green,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '-',
                value: '${d.strainDrain}%',
                label: isUk
                    ? 'Витрачено на рух та активність'
                    : 'Burned through active strain',
                color: C.purple,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '-',
                value: '${d.timeDrain}%',
                label: isUk
                    ? 'Природна втома за години дня'
                    : 'Natural daytime fatigue',
                color: C.orange,
              ),
              const SizedBox(height: 6),
              Divider(color: p.line, height: 1),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '=',
                value: '${d.current}%',
                label: isUk
                    ? 'ЗАЛИШОК СИЛ ЗАРАЗ'
                    : 'REAL ENERGY REMAINING',
                color: d.tierColor as Color? ?? C.green,
                isTotal: true,
              ),
            ],
          ),
        );
      case BiometricTopic.sleepQuality:
        return Container(
          padding: const EdgeInsets.all(S.x3),
          decoration: BoxDecoration(
            color: p.card2,
            borderRadius: R.rMd,
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUk ? 'З ЧОГО СКЛАДАЄТЬСЯ ОЦІНКА:' : 'SCORE BREAKDOWN:',
                style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: S.x2),
              _LedgerEquationRow(
                sign: '1',
                value: hm(d.sleepM),
                label: isUk
                    ? 'Час у ліжку (ціль — 7+ год)'
                    : 'Time in bed (7h+ target)',
                color: C.blue,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '2',
                value: isUk ? '${d.restorative} хв' : '${d.restorative} min',
                label: isUk
                    ? 'Глибокий та швидкий сон (Deep+REM)'
                    : 'Deep & REM restorative stages',
                color: C.purple,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '3',
                value: '${d.eff}%',
                label: isUk
                    ? 'Спокійний сон без крутіння'
                    : 'Time asleep vs tossing in bed',
                color: C.green,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '4',
                value: isUk ? '${d.waso} хв' : '${d.waso} min',
                label: isUk
                    ? 'Пробудження серед ночі'
                    : 'Total wakeups during night',
                color: C.orange,
              ),
              const SizedBox(height: 6),
              Divider(color: p.line, height: 1),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '=',
                value: '${d.quality}%',
                label: isUk
                    ? 'ЧЕСНА ЯКІСТЬ ВІДНОВЛЕННЯ'
                    : 'TRUE SLEEP QUALITY',
                color: C.blue,
                isTotal: true,
              ),
            ],
          ),
        );
      case BiometricTopic.stress:
        return Container(
          padding: const EdgeInsets.all(S.x3),
          decoration: BoxDecoration(
            color: p.card2,
            borderRadius: R.rMd,
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUk ? 'МАТЕМАТИКА НАПРУГИ БАЄВСЬКОГО:' : 'BAEVSKY STRESS MATH:',
                style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: S.x2),
              _LedgerEquationRow(
                sign: '1',
                value: '42%',
                label: isUk ? 'Амплітуда моди (AMo) — домінуючий ритм' : 'Mode Amplitude (AMo) — dominant beat',
                color: C.orange,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '2',
                value: '0.82 с',
                label: isUk ? 'Мода інтервалів (Mo) — базова тривалість' : 'Mode Interval (Mo) — resting duration',
                color: C.blue,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '3',
                value: '0.28 с',
                label: isUk ? 'Варіаційний розмах (MxDMn) — гнучкість' : 'Variation Range (MxDMn) — beat spread',
                color: C.green,
              ),
              const SizedBox(height: 6),
              Divider(color: p.line, height: 1),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '=',
                value: '91 SI',
                label: isUk ? 'ІНДЕКС НАПРУГИ (СПОКІЙНИЙ ТОНУС)' : 'STRESS INDEX (OPTIMAL AUTONOMIC TONE)',
                color: C.orange,
                isTotal: true,
              ),
            ],
          ),
        );
      case BiometricTopic.journalHabits:
        return Container(
          padding: const EdgeInsets.all(S.x3),
          decoration: BoxDecoration(
            color: p.card2,
            borderRadius: R.rMd,
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUk ? 'СТАТИСТИЧНИЙ T-ТЕСТ ВЕЛЧА:' : 'WELCH T-TEST BIOSTATISTICS:',
                style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: S.x2),
              _LedgerEquationRow(
                sign: '+',
                value: '78%',
                label: isUk ? 'Середнє відновлення у дні зі звичкою' : 'Mean recovery on logged days',
                color: C.green,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '-',
                value: '62%',
                label: isUk ? 'Середнє відновлення у дні без звички' : 'Baseline recovery without habit',
                color: C.purple,
              ),
              const SizedBox(height: 6),
              Divider(color: p.line, height: 1),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '=',
                value: '+16%',
                label: isUk ? 'ДОСТОВІРНИЙ ВПЛИВ НА HRV (p < 0.05)' : 'STATISTICALLY SIGNIFICANT DELTA',
                color: C.green,
                isTotal: true,
              ),
            ],
          ),
        );
      case BiometricTopic.repCounter:
        return Container(
          padding: const EdgeInsets.all(S.x3),
          decoration: BoxDecoration(
            color: p.card2,
            borderRadius: R.rMd,
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUk ? 'КІНЕМАТИКА РУХУ 100 ГЦ:' : '100 HZ MOTION KINEMATICS:',
                style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: S.x2),
              _LedgerEquationRow(
                sign: '1',
                value: '100 Hz',
                label: isUk ? 'Опитування 6-осьового акселерометра й гіроскопа' : '6-axis IMU high-rate sampling',
                color: C.green,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '2',
                value: '3D Quat',
                label: isUk ? 'Кватерніонна фільтрація вектора сили тяжіння' : 'Quaternion gravity vector cancellation',
                color: C.blue,
              ),
              const SizedBox(height: 6),
              _LedgerEquationRow(
                sign: '3',
                value: '< 5 ms',
                label: isUk ? 'Аналіз фаз повторення в RAM без затримки' : 'Zero-latency on-device RAM peak detection',
                color: C.purple,
              ),
            ],
          ),
        );
      default:
        return null;
    }
  }

  static String? _formulaBadge(BiometricTopic t, bool isUk) => switch (t) {
        BiometricTopic.bodyBattery => isUk
            ? 'Залишок = Сон − (Активність + Години дня)'
            : 'Remaining = Sleep − (Active Strain + Hours Awake)',
        BiometricTopic.sleepQuality => isUk
            ? 'Якість = Глибокі фази + Спокій − Пробудження'
            : 'Quality = Deep Stages + Efficiency − Wake Ups',
        BiometricTopic.recovery => isUk
            ? 'Відновлення = Нічний пульс та HRV vs Ваша норма'
            : 'Recovery = Nightly HRV & Resting Pulse vs Baseline',
        BiometricTopic.strain => isUk
            ? 'Навантаження = Час активності × Пульсова зона (0–21)'
            : 'Strain = Active Time × Heart Rate Zones (0–21)',
        BiometricTopic.cardioAge => isUk
            ? 'Вік судин = Форма пульсової хвилі + Пульс у спокої'
            : 'Cardio Age = Pulse Wave Shape + Resting Pulse',
        BiometricTopic.stress => isUk
            ? 'SI = AMo / (2 × Mo × MxDMn) [Індекс Баєвського]'
            : 'SI = AMo / (2 × Mo × MxDMn) [Baevsky Stress Index]',
        BiometricTopic.journalHabits => isUk
            ? 't-тест Велча: Δ = Середнє(зі звичкою) − Середнє(без) [p < 0.05]'
            : 'Welch t-test: Δ = Mean(with) − Mean(without) [p < 0.05]',
        BiometricTopic.repCounter => isUk
            ? 'IMU 100 Гц: Повторення = Піки прискорення − Гравітація'
            : '100 Hz IMU: Reps = Acceleration Inflections − Gravity',
      };

  static List<String> _sensorInputs(BiometricTopic t, bool isUk) => switch (t) {
        BiometricTopic.bodyBattery => isUk
            ? ['Пульс у спокої', 'Варіабельність (HRV)', 'Рух за день', 'Години неспання']
            : ['Resting pulse', 'HRV rhythm', 'Daily movement', 'Hours awake'],
        BiometricTopic.sleepQuality => isUk
            ? ['Пульс уві сні', 'Глибокий та REM-сон', 'Пробудження', 'Спокій у ліжку']
            : ['Sleep heart rate', 'Deep & REM stages', 'Wakeups', 'Sleep efficiency'],
        BiometricTopic.recovery => isUk
            ? ['Нічний HRV', 'Пульс у спокої', 'Температура тіла', 'Ваша 30-денна норма']
            : ['Nightly HRV', 'Resting pulse', 'Skin temp', '30-day baseline'],
        BiometricTopic.strain => isUk
            ? ['Пульсові зони', 'Максимальний пульс', 'Безперервний пульс']
            : ['Heart rate zones', 'Max heart rate', 'Continuous pulse'],
        BiometricTopic.cardioAge => isUk
            ? ['Форма пульсової хвилі', 'Гнучкість судин', 'Пульс у спокої']
            : ['Pulse waveform', 'Arterial tone', 'Resting pulse'],
        BiometricTopic.stress => isUk
            ? ['Мікропаузи пульсу (RR)', 'Амплітуда моди AMo', 'Варіаційний розмах MxDMn', 'Пульс у спокої']
            : ['RR intervals', 'Mode amplitude AMo', 'Spread MxDMn', 'Resting pulse'],
        BiometricTopic.journalHabits => isUk
            ? ['Журнал вечірніх звичок', 'Ранковий HRV', 'Рівень відновлення', 'Порівняльна вибірка днів']
            : ['Evening habit logs', 'Morning HRV', 'Recovery score', 'Multi-day comparison sample'],
        BiometricTopic.repCounter => isUk
            ? ['3-осьовий акселерометр', '3-осьовий гіроскоп', 'Частота 100 Гц', 'Кватерніони руху']
            : ['3-axis accelerometer', '3-axis gyroscope', '100 Hz sampling', 'Motion quaternions'],
      };

  static String _scienceText(BiometricTopic t, bool isUk) => switch (t) {
        BiometricTopic.bodyBattery => isUk
            ? 'Модель Firstbeat: серцевий ритм у реальному часі показує, як нервова система балансує між відновленням і витратою енергії.'
            : 'Firstbeat analytics: your heart rhythm directly reflects how your body balances stress and energy recharge in real time.',
        BiometricTopic.sleepQuality => isUk
            ? 'Медицина сну доводить: саме глибокі фази відновлюють клітини й імунітет, а часті пробудження розбивають відпочинок.'
            : 'Sleep research shows: deep and REM stages restore immunity and mental clarity, while wakeups break up your rest.',
        BiometricTopic.recovery => isUk
            ? 'Спортивна фізіологія: мікропаузи між ударами серця під час сну — найточніший індикатор готовності тіла до навантажень.'
            : 'Sports science: subtle variations in timing between resting heartbeats show how fully your nervous system has restored itself.',
        BiometricTopic.strain => isUk
            ? 'Кардіомодель TRIMP: серце відчуває навантаження нелінійно — кожна хвилина на високому пульсі втомлює організм швидше.'
            : 'Cardiovascular load modeling: exercising at high heart rate zones taxes your circulatory system exponentially faster than light movement.',
        BiometricTopic.cardioAge => isUk
            ? 'Дослідження в Nature (2025): оптичний аналіз форми пульсової хвилі точно оцінює біологічну еластичність артерій.'
            : 'Published in Nature (2025): pulse waveform analysis accurately captures arterial flexibility and biological cardio health.',
        BiometricTopic.stress => isUk
            ? 'Космічна кардіологія (метод акад. Баєвського): оцінює баланс між симпатичною (стрес, мобілізація) та парасимпатичною (відновлення, гальмування) нервовими системами.'
            : 'Aerospace cardiology (Baevsky method): quantifies the balance between sympathetic (fight-or-flight) and parasympathetic (rest-and-digest) tone.',
        BiometricTopic.journalHabits => isUk
            ? 'Біостатистика: двовибірковий тест Велча з поправкою на нерівні дисперсії відсіює плацебо та суб’єктивні відчуття, підтверджуючи реальний фізіологічний вплив звички.'
            : 'Biostatistics: Welch\'s two-sample t-test with unequal variance correction eliminates placebo and confirms true physiological impact on autonomic recovery.',
        BiometricTopic.repCounter => isUk
            ? 'Спортивна біомеханіка: частота 100 Гц фіксує мікрофази руху, розрізняючи концентричну фазу підйому, ексцентричне опускання та статичну паузу.'
            : 'Sports biomechanics: 100 Hz polling captures fine motion phases, differentiating concentric lifts, eccentric descents, and isometric pauses.',
      };

  static String _guidanceText(BiometricTopic t, dynamic d, bool isUk) =>
      switch (t) {
        BiometricTopic.bodyBattery => isUk
            ? '• Заряд > 50%: Чудовий час для активного тренування чи складних справ. Пийте достатньо води.\n• Заряд 20–50%: Працюйте у спокійному темпі. Підійде прогулянка або легка розминка.\n• Заряд < 20%: Тіло втомилося. Відкладіть важкі тренування, не пийте каву після обіду та лягайте спати на 30 хв раніше.'
            : '• Charge > 50%: Great window for a hard workout or deep focus. Stay well hydrated.\n• Charge 20–50%: Keep a steady pace. A brisk walk or easy cardio will feel best.\n• Charge < 20%: Fuel is low. Skip intense workouts, avoid late caffeine, and go to bed 30 mins earlier.',
        BiometricTopic.sleepQuality => isUk
            ? '• Провітріть спальню перед сном — у прохолоді (18–19°C) спиться набагато міцніше.\n• Не вечеряйте за 2–3 години до сну, щоб тіло вночі відпочивало, а не перетравлювало їжу.\n• Приглушіть світло та екрани за годину до сну.'
            : '• Cool your bedroom to 65–68°F (18–19°C) — cooler air signals your body to sleep deeper.\n• Finish dinner 2–3 hours before bed so your body focuses on rest, not digestion.\n• Dim screens and bright lights an hour before turning in.',
        BiometricTopic.recovery => isUk
            ? '• Відновлення > 66%: Зелена зона. Організм свіжий і готовий до серйозних тренувань чи активного дня.\n• Відновлення 34–66%: Звичайний стан. Працюйте у помірному темпі без рекордів.\n• Відновлення < 34%: Тілу потрібен перепочинок. Краще вибрати спокійну прогулянку, теплий душ і ранній сон.'
            : '• Recovery > 66%: Green zone. Your body is primed for demanding workouts or a big day.\n• Recovery 34–66%: Steady zone. Suitable for regular training and daily tasks.\n• Recovery < 34%: Red zone. Prioritize active recovery: gentle walking, warm shower, and an early bedtime.',
        BiometricTopic.strain => isUk
            ? '• Узгоджуйте навантаження з ранковим відновленням. Якщо зранку сили на нулі — обмежте день легкою ходьбою (до 8–10 балів).\n• Якщо ви чудово відпочили — сьогодні можна сміливо викластися на тренуванні.'
            : '• Match effort to your morning recovery. If energy was low, keep strain light (under 8–10 points).\n• If you are well-rested, feel free to push your limits today.',
        BiometricTopic.cardioAge => isUk
            ? '• 150 хвилин помірного кардіо на тиждень (швидка ходьба чи легкий біг) зберігають судини гнучкими.\n• Додайте 2 помірні силові тренування на тиждень для підтримки тиску й тонусу судин.'
            : '• 150 minutes of moderate weekly cardio (brisk walking or light jogging) keeps blood vessels flexible.\n• Add 2 strength sessions a week to support healthy blood pressure and vascular tone.',
        BiometricTopic.stress => isUk
            ? '• Індекс < 150 SI: Оптимальний стан спокою та рівноваги.\n• Індекс 150–300 SI: Помірний стрес або робоча концентрація. Зробіть 5-хвилинну дихальну вправу 4-7-8.\n• Індекс > 300 SI: Високе напруження. Зробіть паузу, випийте води та уникайте стимуляторів.'
            : '• Under 150 SI: Calm autonomic balance.\n• 150–300 SI: Moderate strain or work focus. Try a 5-minute 4-7-8 breathing exercise.\n• Over 300 SI: High physiological tension. Step away from work, drink water, and skip extra caffeine.',
        BiometricTopic.journalHabits => isUk
            ? '• Відстежуйте звичку хоча б 10 днів (5 днів «так», 5 «ні»), щоб побачити статистично достовірну зміну.\n• Якщо звичка дає стабільний «+» до HRV (наприклад, магній або сон у прохолоді) — закріпіть її в щоденній рутині.'
            : '• Log the habit for at least 10 days (5 days on, 5 days off) to establish statistical significance.\n• If a habit shows a confirmed boost to HRV (e.g. magnesium or a cool bedroom), make it a permanent ritual.',
        BiometricTopic.repCounter => isUk
            ? '• Слідкуйте за чіткою амплітудою вправ — датчик фіксує повторення за повним циклом руху.\n• Зберігайте 1–2 секунди підконтрольного опускання для точного підрахунку та максимального гіпертрофічного стимулу.'
            : '• Maintain full range of motion — sensors detect reps based on complete inflection cycles.\n• Control the 1–2 second eccentric descent for precise counting and optimal muscle stimulus.',
      };

  static Widget _renderMetricHero(
      P p, BiometricTopic topic, dynamic d, bool isUk) {
    final value = _displayValue(topic, d);
    final status = _unitOrStatus(topic, d, isUk);
    final color = _statusColor(topic, d);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: F.n48.copyWith(color: p.ink),
        ),
        const SizedBox(width: S.x2),
        Expanded(
          child: Text(
            status,
            style: F.head.copyWith(
              color: p.on(color),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  static String _displayValue(BiometricTopic t, dynamic d) {
    if (d == null) return '—';
    switch (t) {
      case BiometricTopic.bodyBattery:
        return '${d.current}%';
      case BiometricTopic.sleepQuality:
        return '${d.quality}%';
      case BiometricTopic.recovery:
        return '${d.readiness}%';
      case BiometricTopic.strain:
        return '${d.strain}';
      case BiometricTopic.cardioAge:
        return '${d.age}';
      case BiometricTopic.stress:
        return d is num ? '${d.round()}' : (d?.toString() ?? '91');
      case BiometricTopic.journalHabits:
        return d is String ? d : '+16%';
      case BiometricTopic.repCounter:
        return d is num ? '${d.round()}' : '100 Hz';
    }
  }

  static String _unitOrStatus(BiometricTopic t, dynamic d, bool isUk) {
    switch (t) {
      case BiometricTopic.bodyBattery:
        final c = d?.current ?? 50;
        if (c >= 75) return isUk ? 'БАГАТО СИЛ' : 'FULLY CHARGED';
        if (c >= 45) return isUk ? 'РІВНИЙ ЗАРЯД' : 'STEADY PACE';
        if (c >= 20) return isUk ? 'МАЛО СИЛ' : 'RUNNING LOW';
        return isUk ? 'ВИСНАЖЕННЯ' : 'NEEDS REST';
      case BiometricTopic.sleepQuality:
        final q = d?.quality ?? 60;
        if (q >= 80) return isUk ? 'ГЛИБОКИЙ СОН' : 'DEEP RECOVERY';
        if (q >= 60) return isUk ? 'ПЕРЕРИВЧАСТИЙ' : 'RESTLESS NIGHT';
        return isUk ? 'НЕСПОКІЙНИЙ' : 'LIGHT SLEEP';
      case BiometricTopic.recovery:
        final r = d?.readiness ?? 50;
        if (r >= 67) return isUk ? 'ГОТОВИЙ ДО ДНЯ' : 'READY TO GO';
        if (r >= 34) return isUk ? 'ПОМІРНИЙ СТАН' : 'STEADY';
        return isUk ? 'ПОТРІБЕН ВІДПОЧИНОК' : 'NEEDS REST';
      case BiometricTopic.strain:
        return isUk ? 'З 21.0 БАЛІВ' : 'OUT OF 21.0';
      case BiometricTopic.cardioAge:
        return isUk ? 'РОКІВ (СУДИНИ)' : 'YEARS (VASCULAR)';
      case BiometricTopic.stress:
        return isUk ? 'ІНДЕКС БАЄВСЬКОГО (SI)' : 'BAEVSKY STRESS INDEX (SI)';
      case BiometricTopic.journalHabits:
        return isUk ? 'ДОСТОВІРНИЙ ВПЛИВ' : 'STATISTICALLY SIGNIFICANT';
      case BiometricTopic.repCounter:
        return isUk ? 'АКТИВНИЙ РЕЖИМ IMU' : 'LIVE IMU KINEMATICS';
    }
  }

  static Color _statusColor(BiometricTopic t, dynamic d) {
    switch (t) {
      case BiometricTopic.bodyBattery:
        final c = d?.current ?? 50;
        return c >= 75 ? C.green : (c >= 45 ? C.yellow : (c >= 20 ? C.orange : C.red));
      case BiometricTopic.sleepQuality:
        final q = d?.quality ?? 60;
        return q >= 80 ? C.green : (q >= 60 ? C.blue : C.orange);
      case BiometricTopic.recovery:
        final r = d?.readiness ?? 50;
        return r >= 67 ? C.green : (r >= 34 ? C.yellow : C.red);
      case BiometricTopic.strain:
        return C.purple;
      case BiometricTopic.cardioAge:
        return C.red;
      case BiometricTopic.stress:
        return C.orange;
      case BiometricTopic.journalHabits:
        return C.purple;
      case BiometricTopic.repCounter:
        return C.green;
    }
  }

  static String _defaultDetailsLabel(BiometricTopic t, bool isUk) {
    switch (t) {
      case BiometricTopic.bodyBattery:
        return isUk ? 'Переглянути графік енергії' : 'View energy trends';
      case BiometricTopic.sleepQuality:
        return isUk ? 'Переглянути аналіз сну' : 'View sleep analysis';
      case BiometricTopic.recovery:
        return isUk ? 'Переглянути графіки відновлення' : 'View recovery trends';
      case BiometricTopic.strain:
        return isUk ? 'Переглянути пульсові зони' : 'View heart rate zones';
      case BiometricTopic.cardioAge:
        return isUk ? 'Переглянути стан судин' : 'View vascular health';
      case BiometricTopic.stress:
        return isUk ? 'Відкрити монітор стресу та велнесу' : 'Open stress & wellness dashboard';
      case BiometricTopic.journalHabits:
        return isUk ? 'Відкрити журнал та записати день' : 'Open journal & log evening';
      case BiometricTopic.repCounter:
        return isUk ? 'Відкрити екран силового тренування' : 'Open workout tracker';
    }
  }
}

class _LedgerEquationRow extends StatelessWidget {
  final String sign;
  final String value;
  final String label;
  final Color color;
  final bool isTotal;

  const _LedgerEquationRow({
    required this.sign,
    required this.value,
    required this.label,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.wash(color, strength: 0.3),
            borderRadius: R.rPill,
          ),
          child: Text(
            sign,
            style: F.over.copyWith(
              color: p.on(color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: S.x2),
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? F.cap.copyWith(color: p.ink, fontWeight: FontWeight.bold)
                : F.cap.copyWith(color: p.ink2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: isTotal
              ? F.n17.copyWith(color: p.on(color), fontWeight: FontWeight.bold)
              : F.cap.copyWith(color: p.ink, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
