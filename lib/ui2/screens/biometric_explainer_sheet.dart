import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../grammar.dart';
import '../theme.dart';

enum BiometricTopic {
  bodyBattery,
  sleepQuality,
  recovery,
  strain,
  cardioAge,
}

/// Standardized, deep "Tap-to-Explain" Bottom Sheet.
///
/// Every metric on the dashboard opens this sheet to transparently reveal:
/// 1. Що це означає (людською мовою без медичного булшіту)
/// 2. Як це рахується (прозора математика з реальними вхідними даними)
/// 3. Наукова база (клінічні дослідження AASM, Firstbeat, Nature 2025)
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
              _buildHeader(ctx, p, topic, sheetContext),
              const SizedBox(height: S.x3),
              _buildValueBadge(ctx, p, topic, data),
              const SizedBox(height: S.x4),
              _buildSection(
                p: p,
                title: 'ЩО ЦЕ ОЗНАЧАЄ',
                icon: LucideIcons.info,
                accent: C.blue,
                body: _meaningText(topic, data),
              ),
              const SizedBox(height: S.x3),
              _buildSection(
                p: p,
                title: 'ЯК ЦЕ РАХУЄТЬСЯ',
                icon: LucideIcons.cpu,
                accent: C.purple,
                body: _calculationText(topic, data),
                formula: _formulaBadge(topic),
                sensors: _sensorInputs(topic),
              ),
              const SizedBox(height: S.x3),
              _buildSection(
                p: p,
                title: 'НАУКОВА БАЗА',
                icon: LucideIcons.bookOpenCheck,
                accent: C.teal,
                body: _scienceText(topic),
              ),
              const SizedBox(height: S.x3),
              _buildSection(
                p: p,
                title: 'ЩО РОБИТИ СЬОГОДНІ',
                icon: LucideIcons.compass,
                accent: C.green,
                body: _guidanceText(topic, data),
              ),
              if (onOpenDetails != null) ...[
                const SizedBox(height: S.x4),
                Pressable(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onOpenDetails();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: S.x3, horizontal: S.x4),
                    decoration: BoxDecoration(
                      color: p.wash(C.blue),
                      borderRadius: R.rMd,
                      border: Border.all(color: p.on(C.blue).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          detailsLabel ?? 'Переглянути графіки та історію',
                          style: F.body.copyWith(
                            color: p.on(C.blue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: S.x2),
                        Icon(LucideIcons.arrowRight, size: 16, color: p.on(C.blue)),
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
  ) {
    final meta = _metaOf(topic);
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
  ) {
    return Container(
      padding: const EdgeInsets.all(S.x4),
      decoration: BoxDecoration(
        color: p.card2,
        borderRadius: R.rLg,
        border: Border.all(color: p.line),
      ),
      child: _renderMetricHero(p, topic, data),
    );
  }

  static Widget _buildSection({
    required P p,
    required String title,
    required IconData icon,
    required Color accent,
    required String body,
    String? formula,
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
      BiometricTopic t) {
    switch (t) {
      case BiometricTopic.bodyBattery:
        return (
          title: 'Рівень життєвої енергії',
          subtitle: 'Динамічний баланс відновлення та втоми (Body Battery)',
          color: C.green,
          icon: LucideIcons.batteryCharging,
        );
      case BiometricTopic.sleepQuality:
        return (
          title: 'Якість сну (Sleep Quality)',
          subtitle: '4-факторна оцінка відновлення нервової системи',
          color: C.blue,
          icon: LucideIcons.moon,
        );
      case BiometricTopic.recovery:
        return (
          title: 'Готовність організму (Recovery)',
          subtitle: 'Парасимпатичний тонус за нічним rMSSD (HRV)',
          color: C.green,
          icon: LucideIcons.heartPulse,
        );
      case BiometricTopic.strain:
        return (
          title: 'Денне кардіонавантаження (Strain)',
          subtitle: 'Логарифмічний стрес серцево-судинної системи (0–21)',
          color: C.purple,
          icon: LucideIcons.zap,
        );
      case BiometricTopic.cardioAge:
        return (
          title: 'Серцево-судинний вік (Cardio Age)',
          subtitle: 'Еластичність артерій за моделлю PpgAge (Nature 2025)',
          color: C.red,
          icon: LucideIcons.heartHandshake,
        );
    }
  }

  static String _meaningText(BiometricTopic t, dynamic d) => switch (t) {
        BiometricTopic.bodyBattery =>
          'Показує ваш реальний запас фізіологічних сил прямо зараз (за шкалою 5–100%). Це аналог акумулятора: вранці організм заряджається від сну та відновлення нервової системи, а вдень енергія спалюється тренуваннями, фізичною активністю та метаболічним стресом від годин неспання.',
        BiometricTopic.sleepQuality =>
          'Сон — це не просто години в ліжку. Справжнє відновлення відбувається у фазах глибокого (Deep) та швидкого (REM) сну при високій ефективності та відсутності довгих пробуджень. Якщо якість 60%, це означає, що сон був фрагментованим, навіть якщо за часом ви були в ліжку 7–8 годин.',
        BiometricTopic.recovery =>
          'Готовність вашої вегетативної нервової системи до навантажень. Базується на тому, наскільки блукаючий нерв (парасимпатична система) зміг заспокоїти серце під час нічного сну. Високий бал = тіло адаптоване і готове до рекордів; низький бал = тіло ще бореться з втомою.',
        BiometricTopic.strain =>
          'Сумарний обсяг роботи серця за добу. На відміну від звичайних калорій чи кроків, Strain вимірює навантаження на серцево-судинну систему: 20 хвилин бігу в 4-й зоні дадуть більше навантаження, ніж 4 години повільної ходьби.',
        BiometricTopic.cardioAge =>
          'Фізіологічний вік ваших артерій та серця порівняно з паспортним віком. Якщо ваш судинний вік нижчий за календарний, судини еластичні, капілярне русло здорове, а кардіоваскулярний резерв високий.',
      };

  static String _calculationText(BiometricTopic t, dynamic d) => switch (t) {
        BiometricTopic.bodyBattery =>
          '• Ранковий заряд = 60% Recovery (HRV) + 40% Sleep Quality.\n• Витрати на навантаження = Strain × 3.0 (інтенсивність роботи серця).\n• Метаболічні витрати = ~1.8% за кожну годину після пробудження.\n• Поточний заряд = Ранковий старт - Витрати на рух - Метаболічні витрати.',
        BiometricTopic.sleepQuality =>
          'Клінічна модель AASM на базі 4 стовпів:\n• 35% ваги: Частка відновлювальних фаз (Deep + REM sleep, норма >35%).\n• 35% ваги: Ефективність сну (фактичний сон до часу в ліжку, норма >85%).\n• 15% ваги: Відсутність нічних пробуджень (WASO, штраф за кожні 15 хв неспання).\n• 15% ваги: Досягнення мінімуму тривалості (7 год).',
        BiometricTopic.recovery =>
          'Нічний показник rMSSD (корінь із середньоквадратичної різниці послідовних R-R інтервалів) під час повільнохвильового сну (SWS) порівнюється з вашим 30-денним індивідуальним бейзлайном через сигмоїдний z-score.',
        BiometricTopic.strain =>
          'Логарифмічна шкала від 0 до 21.0. Кожна хвилина в пульсових зонах (1..5) множиться на експоненційний коефіцієнт втоми. Набрати від 0 до 10 легко, але підняти бал з 14 до 18 вимагає екстремального зусилля.',
        BiometricTopic.cardioAge =>
          'Нейромережевий аналіз форми пульсової хвилі (PPG 25Hz): кут наростання систолічного фронту, амплітуда дикротичної хвилі, 14-денний тренд пульсу спокою (RHR) та нічний HRV, стратифіковані за статтю.',
      };

  static String? _formulaBadge(BiometricTopic t) => switch (t) {
        BiometricTopic.bodyBattery =>
          'Battery = (Recovery×0.6 + Sleep×0.4) - (Strain×3.0 + HoursAwake×1.8)',
        BiometricTopic.sleepQuality =>
          'Quality = 0.35·Restorative + 0.35·Efficiency + 0.15·WASO + 0.15·Duration',
        BiometricTopic.recovery =>
          'Recovery% = 100 / (1 + exp(-1.702 · z_score(rMSSD_sws)))',
        BiometricTopic.strain =>
          'Strain = 21.0 · [ 1 - exp(-0.0005 · Σ (Minutes × ZoneWeight)) ]',
        BiometricTopic.cardioAge =>
          'PpgAge = NeuralNet(PPG_waveform, Baseline_RHR, Night_HRV, Sex)',
      };

  static List<String> _sensorInputs(BiometricTopic t) => switch (t) {
        BiometricTopic.bodyBattery => [
            'Оптичний PPG',
            'R-R інтервали',
            'Пульсові зони',
            'Години неспання'
          ],
        BiometricTopic.sleepQuality => [
            'Нічний PPG',
            'Фази сну (Deep/REM/Core)',
            'WASO пробудження',
            'Ефективність у ліжку'
          ],
        BiometricTopic.recovery => [
            'rMSSD під час SWS',
            'Пульс спокою (RHR)',
            'Температура зап’ястя',
            '14-денний тренд'
          ],
        BiometricTopic.strain => [
            'Хвилинні пульсові зони',
            'Індивідуальний HR_max',
            'Безперервний пульс'
          ],
        BiometricTopic.cardioAge => [
            'Морфологія PPG хвилі',
            'Жорсткість судинної стінки',
            'Пульс спокою',
            'VO₂ Max тренд'
          ],
      };

  static String _scienceText(BiometricTopic t) => switch (t) {
        BiometricTopic.bodyBattery =>
          'Firstbeat Analytics (Garmin Energy Model), двопроцесна модель циркадного та гомеостатичного тиску сну Олександра Борбелі (Borbély Two-Process Model). Баланс симпатичної та парасимпатичної нервової системи.',
        BiometricTopic.sleepQuality =>
          'American Academy of Sleep Medicine (AASM Scoring Manual v2.6) та консенсусні рекомендації Sleep Research Society (Watson et al.). Дослідження доводять: фазова глибина сну критичніша для імунітету та нейропластичності, ніж загальний час у ліжку.',
        BiometricTopic.recovery =>
          'Міжнародні стандарти Task Force of ESC & NASPE щодо аналізу HRV; спортивні дослідження Plews et al. щодо балансу вегетативної системи в професійних атлетів.',
        BiometricTopic.strain =>
          'Шкала сприйманого напруження Гуннара Борга (Borg Scale); математична модель імпульсу тренувань Еріка Беністера (Banister TRIMP model).',
        BiometricTopic.cardioAge =>
          'Nature Communications (2025): "Photoplethysmography-based vascular aging and biological age prediction using continuous wearable sensing" (дослідження на 100,000+ суб\'єктів).',
      };

  static String _guidanceText(BiometricTopic t, dynamic d) => switch (t) {
        BiometricTopic.bodyBattery =>
          '• Заряд > 50%: Ідеальне вікно для високих інтелектуальних навантажень або інтенсивних кардіотренувань.\n• Заряд 20–50%: Працюйте в помірному темпі (Зона 2, прогулянки). Уникайте перевантажень.\n• Заряд < 20%: Організм виснажений і працює на гормонах стресу (кортизол). Уникайте важких тренувань, кофеїну після 14:00 та лягайте спати на 45 хвилин раніше.',
        BiometricTopic.sleepQuality =>
          '• Для підвищення фаз Deep/REM: не вживайте їжу та алкоголь за 3 год до сну.\n• Провітріть спальню до 18–19°C — терморегуляція тіла прямо запускає повільнохвильовий сон.\n• За 60 хв до сну вимкніть яскраві екрани та приглушіть освітлення.',
        BiometricTopic.recovery =>
          '• Recovery > 66%: Зелена зона. Тіло повністю готове до важких фізичних навантажень.\n• Recovery 34–66%: Жовта зона. Нормальний рівень, підходить помірна активність (Cross-fit або кардіо середньої важкості).\n• Recovery < 34%: Червона зона. Віддайте перевагу відновлювальній ходьбі, сауні та сну.',
        BiometricTopic.strain =>
          '• Тримайте навантаження у балансі з Recovery. Якщо ранкове відновлення низьке (жовта або червона зона), намагайтеся не перевищувати 8–10 балів Strain за день.',
        BiometricTopic.cardioAge =>
          '• Найефективніший спосіб омолодити судини — накопичувати не менше 150 хвилин на тиждень кардіотренувань у Зоні 2 (пульс 60–70% від максимуму).\n• Силові тренування 2 рази на тиждень покращують чутливість до інсуліну та артеріальний тонус.',
      };

  static Widget _renderMetricHero(P p, BiometricTopic topic, dynamic d) {
    final value = _displayValue(topic, d);
    final status = _unitOrStatus(topic, d);
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
    }
  }

  static String _unitOrStatus(BiometricTopic t, dynamic d) {
    switch (t) {
      case BiometricTopic.bodyBattery:
        final c = d?.current ?? 50;
        return c >= 75
            ? 'ОПТИМАЛЬНИЙ РЕЗЕРВ'
            : (c >= 45 ? 'ПОМІРНИЙ РЕЗЕРВ' : (c >= 20 ? 'НИЗЬКИЙ РЕЗЕРВ' : 'ВИСНАЖЕННЯ'));
      case BiometricTopic.sleepQuality:
        final q = d?.quality ?? 60;
        return q >= 80 ? 'ВІДМІННА ЯКІСТЬ' : (q >= 60 ? 'ПОМІРНА ЯКІСТЬ' : 'НИЗЬКА ЯКІСТЬ');
      case BiometricTopic.recovery:
        final r = d?.readiness ?? 50;
        return r >= 67 ? 'ОПТИМАЛЬНЕ' : (r >= 34 ? 'ПОМІРНЕ' : 'ПОТРІБЕН ВІДПОЧИНОК');
      case BiometricTopic.strain:
        return 'З 21.0 БАЛІВ';
      case BiometricTopic.cardioAge:
        return 'РОКІВ (СУДИНИ)';
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
    }
  }
}
