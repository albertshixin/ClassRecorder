import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../data/models/course.dart';

class CourseCreatePage extends StatefulWidget {
  const CourseCreatePage({super.key});

  static const routeName = '/course/create';

  @override
  State<CourseCreatePage> createState() => _CourseCreatePageState();
}

class _CourseCreatePageState extends State<CourseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalController = TextEditingController(text: '20');
  final _consumedController = TextEditingController(text: '0');
  final _durationController = TextEditingController(text: '60');

  String _category = '学科辅导';

  DateTime? _initialSession;
  CourseRepeatPattern _repeatPattern = CourseRepeatPattern.none;
  CourseMakeUpMethod _makeUpMethod = CourseMakeUpMethod.autoPostpone;

  final List<WeeklyCourseTime> _weeklySlots = [];
  final List<MonthlyCourseTime> _monthlySlots = [];

  String? _scheduleError;

  @override
  void dispose() {
    _titleController.dispose();
    _totalController.dispose();
    _consumedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('新建课程'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '课程名称',
                      hintText: '例如：钢琴课 / 英语一对一',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) {
                        return '请输入课程名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('create-cat-$_category'),
                    initialValue: _category,
                    items: const [
                      DropdownMenuItem(value: '学科辅导', child: Text('学科辅导')),
                      DropdownMenuItem(value: '艺术素养', child: Text('艺术素养')),
                      DropdownMenuItem(value: '体育训练', child: Text('体育训练')),
                      DropdownMenuItem(value: '科技编程', child: Text('科技编程')),
                      DropdownMenuItem(value: '综合素养', child: Text('综合素养')),
                      DropdownMenuItem(value: '语言文化', child: Text('语言文化')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _category = v);
                    },
                    decoration: const InputDecoration(
                      labelText: '类型标签',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _totalController,
                          decoration: const InputDecoration(
                            labelText: '总课时',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final value = double.tryParse((v ?? '').trim());
                            if (value == null) return '请输入数字';
                            if (value <= 0) return '必须大于 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _consumedController,
                          decoration: const InputDecoration(
                            labelText: '已上课时（可选）',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final value = double.tryParse((v ?? '').trim());
                            if (value == null) return '请输入数字';
                            if (value < 0) return '不能小于 0';
                            final total =
                                double.tryParse(_totalController.text.trim());
                            if (total != null && value > total) {
                              return '不能大于总课时';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: '课程时长（分钟）',
                      hintText: '默认 60',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    validator: (v) {
                      final value = int.tryParse((v ?? '').trim());
                      if (value == null) return '请输入整数分钟';
                      if (value <= 0) return '必须大于 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(icon: Icons.schedule, title: '开始上课日期'),
                  const SizedBox(height: 8),
                  _buildInitialSessionTile(theme),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CourseRepeatPattern>(
                    key: ValueKey('create-repeat-$_repeatPattern'),
                    initialValue: _repeatPattern,
                    items: CourseRepeatPattern.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _repeatPattern = v;
                        _scheduleError = null;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: '重复模式',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_repeatPattern == CourseRepeatPattern.weekly) ...[
                    _buildWeeklySlots(theme),
                    const SizedBox(height: 12),
                  ],
                  if (_repeatPattern == CourseRepeatPattern.monthly) ...[
                    _buildMonthlySlots(theme),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<CourseMakeUpMethod>(
                    key: ValueKey('create-makeup-$_makeUpMethod'),
                    initialValue: _makeUpMethod,
                    items: CourseMakeUpMethod.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _makeUpMethod = v);
                    },
                    validator: (v) => v == null ? '请选择补课方式' : null,
                    decoration: const InputDecoration(
                      labelText: '补课方式',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey(_computeEndDateLabel()),
                    enabled: false,
                    initialValue: _computeEndDateLabel() ?? '无法计算',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: '预计结束日期',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                      border: const OutlineInputBorder(),
                      hintText: '根据课时与排课自动计算',
                      suffixIcon: _computeEndDateLabel() == null
                          ? const Icon(Icons.error_outline, color: Colors.orange)
                          : const Icon(Icons.event_available),
                    ),
                  ),
                  if (_scheduleError != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _scheduleError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _onSubmit,
                      icon: const Icon(Icons.check),
                      label: const Text('创建'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialSessionTile(ThemeData theme) {
    final label =
        _initialSession == null ? '未设置' : _formatDate(_initialSession!);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickInitialSession,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.event),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '日历选择（只选日期）',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '选择',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySlots(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '按周时间（可多个）',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: _addWeeklySlot,
              icon: const Icon(Icons.add),
              label: const Text('添加'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_weeklySlots.isEmpty)
          Text(
            '未添加（示例：周一 14:00、周五 10:00）',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          Column(
            children: List.generate(_weeklySlots.length, (index) {
              final slot = _weeklySlots[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: slot.weekday,
                        items: kCourseWeekdayOrder
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(courseWeekdayLabel(d)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _weeklySlots[index] = WeeklyCourseTime(
                              weekday: v,
                              time: slot.time,
                            );
                            _scheduleError = null;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: '星期',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickWeeklySlotTime(index),
                        icon: const Icon(Icons.access_time),
                        label: Text(slot.time.format24h()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _weeklySlots.removeAt(index);
                          _scheduleError = null;
                        });
                      },
                      tooltip: '删除',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildMonthlySlots(ThemeData theme) {
    final days = List<int>.generate(31, (i) => i + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '按月时间（可多个）',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: _addMonthlySlot,
              icon: const Icon(Icons.add),
              label: const Text('添加'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_monthlySlots.isEmpty)
          Text(
            '未添加（示例：10号 18:00、16号 16:00）',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          Column(
            children: List.generate(_monthlySlots.length, (index) {
              final slot = _monthlySlots[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: slot.day,
                        items: days
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text('$d号'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _monthlySlots[index] = MonthlyCourseTime(
                              day: v,
                              time: slot.time,
                            );
                            _scheduleError = null;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: '日期',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickMonthlySlotTime(index),
                        icon: const Icon(Icons.access_time),
                        label: Text(slot.time.format24h()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _monthlySlots.removeAt(index);
                          _scheduleError = null;
                        });
                      },
                      tooltip: '删除',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  Future<void> _pickInitialSession() async {
    final now = DateTime.now();
    final initialDate = _initialSession ?? now;
    final firstDate = DateTime(2000, 1, 1);
    final lastDate = DateTime(2100, 12, 31);
    final safeInitial = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate.isAfter(lastDate)
            ? lastDate
            : initialDate;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(safeInitial.year, safeInitial.month, safeInitial.day),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '选择开始上课日期',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return Stack(
          children: [
            child,
            Positioned(
              right: 8,
              top: 8,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(DateTime.now()),
                icon: const Icon(Icons.today),
                label: const Text('回到今天'),
              ),
            ),
          ],
        );
      },
    );
    if (date == null) return;

    if (!mounted) return;

    setState(() {
      // 时间统一置 00:00，表示仅记录日期。
      _initialSession = DateTime(date.year, date.month, date.day);
      _scheduleError = null;
    });
  }


  void _addWeeklySlot() {
    setState(() {
      _weeklySlots.add(
        const WeeklyCourseTime(
          weekday: DateTime.monday,
          time: ClassTimeOfDay(hour: 14, minute: 0),
        ),
      );
      _scheduleError = null;
    });
  }

  void _addMonthlySlot() {
    setState(() {
      _monthlySlots.add(
        const MonthlyCourseTime(
          day: 10,
          time: ClassTimeOfDay(hour: 18, minute: 0),
        ),
      );
      _scheduleError = null;
    });
  }

  Future<void> _pickWeeklySlotTime(int index) async {
    final slot = _weeklySlots[index];
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: slot.time.hour, minute: slot.time.minute),
      helpText: '选择时间',
    );
    if (time == null) return;

    if (!mounted) return;

    setState(() {
      _weeklySlots[index] = WeeklyCourseTime(
        weekday: slot.weekday,
        time: ClassTimeOfDay(hour: time.hour, minute: time.minute),
      );
      _scheduleError = null;
    });
  }

  Future<void> _pickMonthlySlotTime(int index) async {
    final slot = _monthlySlots[index];
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: slot.time.hour, minute: slot.time.minute),
      helpText: '选择时间',
    );
    if (time == null) return;

    if (!mounted) return;

    setState(() {
      _monthlySlots[index] = MonthlyCourseTime(
        day: slot.day,
        time: ClassTimeOfDay(hour: time.hour, minute: time.minute),
      );
      _scheduleError = null;
    });
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_validateSchedule()) return;

    final title = _titleController.text.trim();
    final total = double.parse(_totalController.text.trim());
    final consumed = double.parse(_consumedController.text.trim());
    final duration = int.parse(_durationController.text.trim());

    final schedule = _currentDraftSchedule();

    final store = AppScope.of(context);
    final endDate = _computeEndDate();
    await store.create(
      CourseDraft(
        title: title,
        category: _category,
        totalLessons: total,
        consumedLessons: consumed,
        lessonDurationMinutes: duration,
        startDate: _initialSession,
        endDate: endDate,
        schedule: schedule,
      ),
    );

    Navigator.of(context).pop();
  }

  CourseSchedule _currentDraftSchedule() {
    return CourseSchedule(
      initialSession: _initialSession,
      repeatPattern: _repeatPattern,
      weeklySlots: List<WeeklyCourseTime>.from(_weeklySlots),
      monthlySlots: List<MonthlyCourseTime>.from(_monthlySlots),
      makeUpMethod: _makeUpMethod,
    );
  }

  String? _computeEndDateLabel() {
    final date = _computeEndDate();
    if (date == null) return null;
    return '${date.year}\u5e74${date.month}\u6708${date.day}\u65e5';
  }

  DateTime? _computeEndDate() {
    final total = double.tryParse(_totalController.text.trim());
    final consumed = double.tryParse(_consumedController.text.trim());
    if (total == null || consumed == null) return null;
    final remaining = (total - consumed).ceil();
    if (remaining <= 0) return DateTime.now();

    final schedule = _currentDraftSchedule();
    DateTime reference = _initialSession ?? DateTime.now();
    DateTime? next = schedule.nextSession(reference);
    if (next == null) return null;
    DateTime last = next;
    for (int i = 1; i < remaining; i++) {
      next = schedule.nextSession(last.add(const Duration(minutes: 1)));
      if (next == null) break;
      last = next;
    }
    return last;
  }

  bool _validateSchedule() {
    String? error;

    if (_initialSession == null) {
      error = '请设置开始上课日期';
    } else if (_repeatPattern == CourseRepeatPattern.weekly &&
        _weeklySlots.isEmpty) {
      error = '请选择按周的上课时间（可多个，如：周一 14:00 / 周五 10:00）';
    } else if (_repeatPattern == CourseRepeatPattern.monthly &&
        _monthlySlots.isEmpty) {
      error = '请选择按月的上课时间（可多个，如：10号 18:00 / 16号 16:00）';
    }

    setState(() => _scheduleError = error);
    return error == null;
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}月${dt.day}日';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          title,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}


