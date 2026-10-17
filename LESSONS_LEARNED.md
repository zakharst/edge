# Lessons Learned & Architecture Guidelines: Next-Gen MVP & Edge UI 2.0

## 1. UI 2.0 Design Tokens & Guardrails (`lib/ui2/`)
- **Strict Token Compliance:** Never use raw hex colors (`Color(0x...)`), explicit `fontSize:`, numeric `BorderRadius.circular()`, or ungated animation durations in `lib/ui2/`. Always resolve through `P.of(context)` (palette), `F.*` (typography), `R.*` (radii), `S.*` (spacing), and `C.*` (semantic colors).
- **Calendar Date Arithmetic:** Never use `dayDt.subtract(Duration(days: i))` in `lib/ui2/` because `Duration(` triggers the animation duration token guard in `test/ui2_tokens_test.dart`. Instead, use calendar date constructors: `DateTime(dayDt.year, dayDt.month, dayDt.day - i)`.
- **Layout & Overflow Discipline:**
  - Never use `Spacer()` or `Expanded` inside a `Row(mainAxisSize: MainAxisSize.min)`: this causes unbounded horizontal constraints and triggers `RenderFlex` overflows.
  - In compact Bento grid cards (~150–178 pt wide), large numeral strings (e.g. `'8h 20m'` at 34 pt) wrap into multiple lines if not constrained. Always specify `maxLines: 1` and use scaled styles (`F.t1` or `F.n24`) to guarantee baseline alignment and avoid multi-line column overflows.
  - Pin card header heights (`SizedBox(height: 28)`) and card heights (e.g. `154 pt`) so that adjacent columns have identical cross-column baselines.

---

## 2. Dynamic Cross-Day Health Calculations
- **Day-Specific Slicing:** When the user navigates between days in the UI, all rolling baseline metrics (RHR, HRV, VO₂ Max, Sleep regularity) must be filtered to `dayEndSec` (`DateTime(y, m, d, 23, 59, 59).millisecondsSinceEpoch ~/ 1000`). Never evaluate today's latest data on past dates.
- **7-Day Longevity Dynamics:** Users need immediate feedback on whether their lifestyle is reversing biological age or accelerating strain. Calculating a rolling 7-day trajectory (`bioTrajectory`) up to the selected date allows showing real-time pace chips (`↗ 7d: +0.8 yrs strain` / `↘ 7d: -0.3 yrs`) and a daily breakdown table in the detail sheet.
- **Contextual Badges:**
  - Today: `STRESS · LIVE`, `Tonight’s Target`, `100 Hz Live IMU`.
  - Past dates: `STRESS · DAY RECORD`, `Night’s Target` (with actual vs target sleep delta), `RAM Kinematics`.

---

## 3. iOS Xcode Archive & TestFlight Deployment
- **Extension Version Synchronization:**
  - Bumping `version: 0.2.0+XX` in `pubspec.yaml` does not automatically update `OpenStrapWidgetExtension` and `OpenStrapWatch Watch App` targets in `ios/Runner.xcodeproj/project.pbxproj`.
  - Always bump `CURRENT_PROJECT_VERSION` across all targets in `project.pbxproj`.
  - Run `flutter build ios --config-only` to update `Generated.xcconfig` with the new `FLUTTER_BUILD_NUMBER` prior to `xcodebuild archive` to avoid CFBundleVersion mismatch warnings.
- **Export Options:** Use `destination: upload` in `UploadTestFlight.plist` with `teamID: 328Z89V4J7` and `-allowProvisioningUpdates` for headless command-line delivery to App Store Connect.

---

## 4. Engineering Workflow & Communication
- **Show Before Shipping:** Always capture simulator/golden screenshots and present visual changes to the product owner before triggering a TestFlight release, ensuring design consensus and avoiding redundant deployment cycles.
