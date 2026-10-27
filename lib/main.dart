import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const BreathingApp());

/// ألوان التطبيق (مطابقة للتصميم)
class AppColors {
  static const bg = Color(0xFF0F2A2E);
  static const ring = Color(0xFF2A5A5F);
  static const mid = Color(0xFF1B4A4F);
  static const accent = Color(0xFF7FD1C7);
  static const text = Color(0xFFE8F5F3);
  static const muted = Color(0xFFA9CFC9);
}

class BreathingApp extends StatelessWidget {
  const BreathingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تمرين التنفس',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorSchemeSeed: AppColors.accent,
      ),
      // اتجاه الواجهة من اليمين لليسار
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeScreen(),
    );
  }
}

/// الشاشة الرئيسية: الدخول للتمرين ثم الرجوع منه يستدعي dispose
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.air, size: 96, color: AppColors.accent),
              const SizedBox(height: 16),
              const Text('تمرين التنفس',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('شهيق - حبس - زفير',
                  style: TextStyle(fontSize: 16, color: AppColors.muted)),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.bg,
                  minimumSize: const Size(220, 56),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BreathingScreen()),
                ),
                child: const Text('ابدأ التمرين',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum BreathPhase { inhale, hold, exhale }

/// شاشة التمرين (StatefulWidget)
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({
    super.key,
    this.totalCycles = 6,
    this.phaseSeconds = 4,
  });

  final int totalCycles; // عدد الدورات
  final int phaseSeconds; // مدة كل مرحلة بالثواني

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller; // أنيميشن الدائرة
  Timer? _timer; // مؤقت العدّ كل ثانية

  BreathPhase _phase = BreathPhase.inhale;
  late int _secondsLeft;
  int _cycle = 1;
  bool _paused = false;
  bool _finished = false;

  // ---------------- دورة الحياة ----------------

  @override
  void initState() {
    super.initState();
    debugPrint('initState() -> تجهيز الـ AnimationController وبدء المؤقت');
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.phaseSeconds),
    );
    _secondsLeft = widget.phaseSeconds;
    _startSession(); // التمرين يبدأ تلقائياً عند فتح الشاشة
  }

  @override
  void dispose() {
    debugPrint('dispose() -> إلغاء المؤقت والتخلص من الـ AnimationController');
    _timer?.cancel(); // إيقاف المؤقت لمنع تسريب الذاكرة
    _timer = null;
    _controller.dispose(); // تحرير موارد الأنيميشن
    super.dispose();
  }

  // ---------------- منطق التمرين ----------------

  void _startSession() {
    _phase = BreathPhase.inhale;
    _secondsLeft = widget.phaseSeconds;
    _cycle = 1;
    _paused = false;
    _finished = false;
    _controller.forward(from: 0); // الدائرة تكبر مع الشهيق
    _timer?.cancel(); // نتأكد أنه لا يوجد مؤقت قديم
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!mounted || _paused) return; // حماية من setState بعد dispose
    setState(() {
      if (_secondsLeft > 1) {
        _secondsLeft--;
      } else {
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    switch (_phase) {
      case BreathPhase.inhale:
        _phase = BreathPhase.hold;
        _secondsLeft = widget.phaseSeconds;
        break;
      case BreathPhase.hold:
        _phase = BreathPhase.exhale;
        _secondsLeft = widget.phaseSeconds;
        _controller.reverse(from: 1); // الدائرة تصغر مع الزفير
        break;
      case BreathPhase.exhale:
        if (_cycle >= widget.totalCycles) {
          _finish();
        } else {
          _cycle++;
          _phase = BreathPhase.inhale;
          _secondsLeft = widget.phaseSeconds;
          _controller.forward(from: 0);
        }
        break;
    }
  }

  void _finish() {
    _finished = true;
    _timer?.cancel();
    _timer = null;
    _controller.stop();
    debugPrint('انتهى التمرين وتم إيقاف المؤقت');
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _controller.stop();
      } else if (_phase == BreathPhase.inhale) {
        _controller.forward();
      } else if (_phase == BreathPhase.exhale) {
        _controller.reverse();
      }
    });
  }

  void _restart() => setState(_startSession);

  // ---------------- مساعدات الواجهة ----------------

  String get _title {
    if (_finished) return 'أحسنت';
    switch (_phase) {
      case BreathPhase.inhale:
        return 'شهيق';
      case BreathPhase.hold:
        return 'حبس';
      case BreathPhase.exhale:
        return 'زفير';
    }
  }

  String get _hint {
    if (_finished) return 'أكملت ${widget.totalCycles} دورات من التنفس';
    switch (_phase) {
      case BreathPhase.inhale:
        return 'املأ صدرك بالهواء ببطء';
      case BreathPhase.hold:
        return 'ثبّت نفسك بهدوء';
      case BreathPhase.exhale:
        return 'أخرج الهواء ببطء';
    }
  }

  String _phaseName(BreathPhase p) {
    switch (p) {
      case BreathPhase.inhale:
        return 'شهيق';
      case BreathPhase.hold:
        return 'حبس';
      case BreathPhase.exhale:
        return 'زفير';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تمرين التنفس',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('الدورة $_cycle من ${widget.totalCycles}',
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 32),
              Text(_title,
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent)),
              const SizedBox(height: 6),
              Text(_hint,
                  style:
                      const TextStyle(fontSize: 16, color: AppColors.muted)),
              const SizedBox(height: 32),
              _buildCircle(),
              const SizedBox(height: 32),
              _buildPhaseBars(),
              const Spacer(),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircle() {
    return SizedBox(
      width: 300,
      height: 300,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          final inner = 130 + 100 * t; // من 130 إلى 230
          final mid = inner + 40;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ring, width: 2),
                ),
              ),
              Container(
                width: mid,
                height: mid,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.mid),
              ),
              Container(
                width: inner,
                height: inner,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.accent),
              ),
              _finished
                  ? const Icon(Icons.check, size: 80, color: AppColors.bg)
                  : Text('$_secondsLeft',
                      style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: AppColors.bg)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhaseBars() {
    return Row(
      children: [
        for (final p in BreathPhase.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: (p == _phase && !_finished)
                          ? AppColors.accent
                          : AppColors.ring,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${_phaseName(p)} ${widget.phaseSeconds}',
                      style: TextStyle(
                          fontSize: 14,
                          color: (p == _phase && !_finished)
                              ? AppColors.text
                              : AppColors.muted)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    final primaryLabel =
        _finished ? 'إعادة' : (_paused ? 'استئناف' : 'إيقاف مؤقت');
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.bg,
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
            ),
            onPressed: _finished ? _restart : _togglePause,
            child: Text(primaryLabel,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.ring, width: 2),
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
            ),
            // الرجوع للشاشة السابقة يستدعي dispose()
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إنهاء', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}