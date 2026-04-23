import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';

class PremiumCalendarWidget extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDaySelected;
  final List<DateTime> markedDates;
  final DateTime? today;

  const PremiumCalendarWidget({
    super.key,
    this.initialDate,
    required this.onDaySelected,
    this.markedDates = const [],
    this.today,
  });

  @override
  State<PremiumCalendarWidget> createState() => _PremiumCalendarWidgetState();
}

class _PremiumCalendarWidgetState extends State<PremiumCalendarWidget> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late final DateTime _today;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _today = widget.today ?? DateTime.now();
    // Normalizar a media noche
    _selectedDate = widget.initialDate ?? DateTime(_today.year, _today.month, _today.day);
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    
    // PageController basado en un offset arbitrario de meses para permitir deslizamiento infinito (simulado)
    _pageController = PageController(initialPage: 1000); 
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDayTapped(DateTime day) {
    if (day.isAfter(_today)) return; // Restricción funcional: No fechas futuras

    setState(() {
      _selectedDate = day;
    });
    
    // Emitir emitir a las 00:00:00 exactas
    widget.onDaySelected(DateTime(day.year, day.month, day.day));
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasMark(DateTime day) {
    return widget.markedDates.any((markedDay) => _isSameDay(markedDay, day));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.calendarSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: context.colors.glassShadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildDaysOfWeek(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String monthName = DateFormat('MMMM', 'es').format(_currentMonth);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            _changeMonth(-1);
          },
          icon: Icon(Icons.chevron_left_rounded, size: 28, color: context.colors.textSecondary),
        ),
        Text(
          '${monthName[0].toUpperCase()}${monthName.substring(1)} ${_currentMonth.year}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: context.colors.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () {
            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            _changeMonth(1);
          },
          icon: Icon(Icons.chevron_right_rounded, size: 28, color: context.colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek() {
    const List<String> days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.textDisabled,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    return SizedBox(
      height: 250, // Altura fija para evitar rebotes al cambiar meses con más/menos filas
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          final offset = index - 1000;
          setState(() {
            _currentMonth = DateTime(_today.year, _today.month + offset, 1);
          });
        },
        itemBuilder: (context, index) {
          final offset = index - 1000;
          final targetMonth = DateTime(_today.year, _today.month + offset, 1);
          return _buildMonthGrid(targetMonth);
        },
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final int firstWeekday = DateTime(month.year, month.month, 1).weekday;

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(), // El scroll es del PageView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: daysInMonth + firstWeekday - 1, // Fill blank spaces
      itemBuilder: (context, index) {
        if (index < firstWeekday - 1) {
          return const SizedBox.shrink(); // Espacio vacío antes del día 1
        }

        final int dayNumber = index - (firstWeekday - 1) + 1;
        final DateTime dateToBuild = DateTime(month.year, month.month, dayNumber);
        
        final bool isSelected = _isSameDay(_selectedDate, dateToBuild);
        final bool isToday = _isSameDay(_today, dateToBuild);
        final bool isFuture = dateToBuild.isAfter(_today);
        final bool hasData = _hasMark(dateToBuild);

        return GestureDetector(
          onTap: () => _onDayTapped(dateToBuild),
          child: Container(
            margin: const EdgeInsets.all(4),
            child: ImplicitlyAnimatedWidgetBuilder(
              isSelected: isSelected,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? context.colors.primaryAccent 
                      : (isToday ? context.colors.primaryAccent.withOpacity(0.1) : Colors.transparent),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: context.colors.primaryAccent.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : (isFuture ? context.colors.calendarDayFuture : context.colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ImplicitlyAnimatedWidgetBuilder extends StatelessWidget {
  final bool isSelected;
  final Widget child;

  const ImplicitlyAnimatedWidgetBuilder({super.key, required this.isSelected, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: child,
    );
  }
}
