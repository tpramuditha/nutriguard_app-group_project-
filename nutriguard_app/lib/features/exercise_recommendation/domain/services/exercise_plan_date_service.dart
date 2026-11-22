class ExercisePlanDateService {
  const ExercisePlanDateService();

  DateTime dateForWeekday({
    required DateTime referenceDate,
    required int weekday,
  }) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        'Weekday must be between 1 and 7.',
      );
    }

    // Find Monday of the reference week.
    final monday = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day - referenceDate.weekday + 1,
    );

    // Return the selected weekday at midnight.
    return DateTime(monday.year, monday.month, monday.day + weekday - 1);
  }
}
