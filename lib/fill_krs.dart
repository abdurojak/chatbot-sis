import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:chatbot/schedule_krs.dart';
import 'package:chatbot/services/krs_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:chatbot/submit_krs.dart';
import 'package:flutter/material.dart';

class PengisianKrsPage extends StatefulWidget {
  final String idSemester;

  const PengisianKrsPage({super.key, required this.idSemester});

  static Color get primaryBlue => AppThemePalette.primary;

  @override
  State<PengisianKrsPage> createState() => _PengisianKrsPageState();
}

class _PengisianKrsPageState extends State<PengisianKrsPage> {
  bool _isLoading = true;
  String? _error;

  List<Subject> _subjects = const [];
  List<SemesterInfo> _semesters = const [];

  String? _selectedSemesterId;
  String? _expandedSubjectId;

  int maxSks = 0;
  int totalSks = 0;

  final Map<String, List<SubjectClassOption>> _subjectClassesCache = {};
  final Map<String, String> _selectedClassPerSubject = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<(String?, String?)> _getAuth() async {
    final session = await SessionService.loadSession();
    return (session?.token, session?.idLogin);
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _fetchSemesters();
      await _fetchRequirement();
      await _fetchKrs();

      if (_selectedSemesterId != null) {
        await _fetchSubjects();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSemesters() async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    final semesters = await KrsService.getSemesters(
      idLogin: idLogin,
      token: token,
    );

    if (!mounted) return;

    setState(() {
      _semesters = semesters;

      final matched = semesters.where(
        (semester) => semester.idSemesterMaster == widget.idSemester,
      );

      _selectedSemesterId = matched.isNotEmpty
          ? matched.first.idSemesterMaster
          : semesters.isNotEmpty
          ? semesters.first.idSemesterMaster
          : null;
    });
  }

  Future<void> _fetchRequirement() async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    try {
      final requirement = await KrsService.getRequirements(
        idLogin: idLogin,
        token: token,
      );

      if (!mounted) return;
      setState(() => maxSks = requirement.maxSks);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (maxSks == 0) {
          maxSks = 24;
        }
      });
    }
  }

  Future<void> _fetchKrs() async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    final semesterId = _selectedSemesterId ?? widget.idSemester;
    final items = await KrsService.getKrs(
      idLogin: idLogin,
      token: token,
      idSemester: semesterId,
    );

    if (!mounted) return;
    setState(() {
      totalSks = items.fold<int>(0, (sum, item) => sum + item.creditsValue);
    });
  }

  Future<void> _fetchSubjects() async {
    if (_selectedSemesterId == null) {
      return;
    }

    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    final subjects = await KrsService.getSubjects(
      idLogin: idLogin,
      token: token,
      idSemester: _selectedSemesterId!,
    );

    if (!mounted) return;
    setState(() => _subjects = subjects);
  }

  Future<void> _fetchSubjectClasses(String subjectId) async {
    if (_subjectClassesCache.containsKey(subjectId) ||
        _selectedSemesterId == null) {
      return;
    }

    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    final classes = await KrsService.getCourseSchedules(
      idLogin: idLogin,
      token: token,
      idSemester: _selectedSemesterId!,
      idSubject: subjectId,
    );

    if (!mounted) return;
    setState(() => _subjectClassesCache[subjectId] = classes);
  }

  Future<void> _registerKrs({required String idCourse}) async {
    try {
      final (token, idLogin) = await _getAuth();
      if (token == null || idLogin == null) {
        return;
      }

      final result = await KrsService.registerCourse(
        idLogin: idLogin,
        token: token,
        idCourse: idCourse,
        maxSks: maxSks == 0 ? 24 : maxSks,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mata kuliah berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );

        await _init();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isNotEmpty ? result.message : 'Gagal menyimpan',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final semesterLevel = _semesters.length;
    final selectedSemester = _semesters.where(
      (semester) => semester.idSemesterMaster == _selectedSemesterId,
    );

    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Pengisian KRS'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: TextStyle(color: AppThemePalette.textPrimary),
              ),
            )
          : Column(
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
                            : _semesters.isNotEmpty
                            ? _semesters.first.semesterMainName
                            : '-',
                      ),
                      _infoRow('Semester Level', semesterLevel.toString()),
                      _infoRow('Total Credit', '$totalSks/$maxSks'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final subjectId = subject.idSubject;
                      final isExpanded = _expandedSubjectId == subjectId;
                      final classes = _subjectClassesCache[subjectId];
                      final disabled = !subject.isAvailable;
                      final statusMsg = subject.statusMessage;

                      return Opacity(
                        opacity: disabled ? 0.5 : 1,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppThemePalette.surface,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppThemePalette.divider),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        subject.namaMk,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: PengisianKrsPage.primaryBlue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    if (disabled && statusMsg != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusMsg == 'Kelas Penuh'
                                              ? Colors.red
                                              : Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          statusMsg,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  subject.kodeMk,
                                  style: TextStyle(
                                    color: AppThemePalette.textSecondary,
                                  ),
                                ),
                                trailing: Text(
                                  '${subject.sks} SKS',
                                  style: TextStyle(
                                    color: AppThemePalette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onTap: disabled
                                    ? null
                                    : () async {
                                        if (isExpanded) {
                                          setState(
                                            () => _expandedSubjectId = null,
                                          );
                                          return;
                                        }

                                        setState(
                                          () => _expandedSubjectId = subjectId,
                                        );
                                        await _fetchSubjectClasses(subjectId);
                                      },
                              ),
                              if (!disabled && isExpanded) ...[
                                Divider(color: AppThemePalette.divider),
                                if (classes == null)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: RadioGroup<String>(
                                      groupValue:
                                          _selectedClassPerSubject[subjectId],
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == null) {
                                            _selectedClassPerSubject.remove(
                                              subjectId,
                                            );
                                          } else {
                                            _selectedClassPerSubject[subjectId] =
                                                value;
                                          }
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          ...classes.map((item) {
                                            final classId = item.idCourse;
                                            return RadioListTile<String>(
                                              value: classId,
                                              enabled: !item.isFull,
                                              title: Text(
                                                '${item.className} ($classId)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppThemePalette
                                                      .textPrimary,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ...item.schedules.map(
                                                    (schedule) => Text(
                                                      '${schedule.day} - ${schedule.startTimeShort} - ${schedule.endTimeShort} | ${schedule.room}',
                                                      style: TextStyle(
                                                        color: AppThemePalette
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Kapasitas: ${item.enrolled}/${item.capacity}',
                                                    style: TextStyle(
                                                      color: item.isFull
                                                          ? Colors.red
                                                          : AppThemePalette
                                                                .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: OutlinedButton(
                                              onPressed:
                                                  _selectedClassPerSubject[subjectId] ==
                                                      null
                                                  ? null
                                                  : () async {
                                                      await _registerKrs(
                                                        idCourse:
                                                            _selectedClassPerSubject[subjectId]!,
                                                      );
                                                    },
                                              child: const Text('Save'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SubmitKrsScreen(
                                        idSemester: _selectedSemesterId ?? '',
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PengisianKrsPage.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lihat KRS',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JadwalKrsScreen(
                                        idSemester: _selectedSemesterId ?? '',
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PengisianKrsPage.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lihat Jadwal',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
