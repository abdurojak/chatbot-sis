import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:chatbot/services/krs_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

@visibleForTesting
Widget buildScheduleCourseCodeBadgeForTest(KrsEnrollment course) {
  return _ScheduleCourseCodeBadge(course: course);
}

class JadwalKrsScreen extends StatefulWidget {
  final String idSemester;

  const JadwalKrsScreen({super.key, required this.idSemester});

  @override
  State<JadwalKrsScreen> createState() => _JadwalKrsScreenState();
}

class _JadwalKrsScreenState extends State<JadwalKrsScreen> {
  static const double _timeColumnWidth = 80;
  static const double _dayColumnWidth = 100;
  static const double _headerHeight = 42;
  static const double _rowHeight = 56;
  static const double _scheduleTableWidth =
      _timeColumnWidth + 6 * _dayColumnWidth;

  Color get primaryBlue => AppThemePalette.primary;

  bool _loading = true;
  String? _error;

  List<KrsEnrollment> kelas = const [];
  List<SemesterInfo> semesters = const [];
  int maxSks = 0;

  final List<String> days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> timeSlots = const [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<(String?, String?)> _getAuth() async {
    final session = await SessionService.loadSession();
    return (session?.token, session?.idLogin);
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final (token, idLogin) = await _getAuth();
      if (token == null || idLogin == null) {
        return;
      }

      final results = await Future.wait([
        KrsService.getKrs(
          idLogin: idLogin,
          token: token,
          idSemester: widget.idSemester,
        ),
        KrsService.getRequirements(idLogin: idLogin, token: token),
        KrsService.getSemesters(idLogin: idLogin, token: token),
      ]);

      final krsList = results[0] as List<KrsEnrollment>;
      final requirement = results[1] as KrsRequirementResponse;
      final semesterList = results[2] as List<SemesterInfo>;

      if (!mounted) return;
      setState(() {
        kelas = krsList;
        maxSks = requirement.maxSks;
        semesters = semesterList;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int get totalSks {
    return kelas.fold<int>(0, (sum, item) => sum + item.creditsValue);
  }

  KrsEnrollment? getCourseForSlot(String day, String time) {
    for (final mk in kelas) {
      for (final jadwal in mk.schedules) {
        if (jadwal.day != day) {
          continue;
        }

        final slotHour = int.tryParse(time.substring(0, 2));
        final startHour = int.tryParse(jadwal.startTime.substring(0, 2));
        final endHour = int.tryParse(jadwal.endTime.substring(0, 2));

        if (slotHour == null || startHour == null || endHour == null) {
          continue;
        }

        if (slotHour >= startHour && slotHour < endHour) {
          return mk;
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppThemePalette.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppThemePalette.background,
        body: Center(
          child: Text(
            _error!,
            style: TextStyle(color: AppThemePalette.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final semesterLevel = semesters.length;
    final selectedSemester = semesters.where(
      (semester) => semester.idSemesterMaster == widget.idSemester,
    );

    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Jadwal KRS'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppThemePalette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppThemePalette.divider),
              boxShadow: [
                BoxShadow(
                  color: AppThemePalette.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _infoRow(
                  'Semester to Register',
                  selectedSemester.isNotEmpty
                      ? selectedSemester.first.semesterMainName
                      : semesters.isNotEmpty
                      ? semesters.first.semesterMainName
                      : '-',
                ),
                _infoRow('Semester Level', semesterLevel.toString()),
                _infoRow('Total Credit', '$totalSks/$maxSks'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Schedule',
                style: TextStyle(
                  color: AppThemePalette.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppThemePalette.divider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    width: _scheduleTableWidth,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _headerCell('Time', width: _timeColumnWidth),
                            ...days.map(
                              (day) => _headerCell(
                                day.substring(0, 3),
                                width: _dayColumnWidth,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: timeSlots.length,
                            itemBuilder: (context, index) {
                              final time = timeSlots[index];

                              return Row(
                                children: [
                                  _timeCell(time),
                                  ...days.map((day) {
                                    final course = getCourseForSlot(day, time);
                                    return _courseCell(course);
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppThemePalette.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppThemePalette.accentAvatar,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required double width}) {
    return Container(
      width: width,
      height: _headerHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryBlue,
        border: Border(
          right: BorderSide(color: AppThemePalette.background),
          bottom: BorderSide(color: AppThemePalette.background),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppThemePalette.onPrimary(primaryBlue),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _timeCell(String text) {
    return Container(
      width: _timeColumnWidth,
      height: _rowHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppThemePalette.surfaceAlt,
        border: Border(
          right: BorderSide(color: AppThemePalette.divider),
          bottom: BorderSide(color: AppThemePalette.divider),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppThemePalette.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _courseCell(KrsEnrollment? course) {
    return Container(
      width: _dayColumnWidth,
      height: _rowHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        border: Border(
          right: BorderSide(color: AppThemePalette.divider),
          bottom: BorderSide(color: AppThemePalette.divider),
        ),
      ),
      child: course == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(4),
              child: _ScheduleCourseCodeBadge(course: course),
            ),
    );
  }
}

class _ScheduleCourseCodeBadge extends StatelessWidget {
  final KrsEnrollment course;

  const _ScheduleCourseCodeBadge({required this.course});

  @override
  Widget build(BuildContext context) {
    final badgeColor = AppThemePalette.negative();

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        course.code,
        style: TextStyle(
          color: AppThemePalette.onPrimary(badgeColor),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
