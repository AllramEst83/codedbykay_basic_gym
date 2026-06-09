import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/workout_store.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/squish.dart';

/// Screen for creating a new [Routine] or editing an existing one.
///
/// Pass [editRoutine] to pre-populate the form for editing; omit it to start
/// a blank create flow. Optionally supply [defaultCategory] to pre-select a
/// category when creating.
class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({
    super.key,
    this.defaultCategory,
    this.editRoutine,
  });

  /// When launched from [RoutineManagementScreen] the category is pre-set.
  final WorkoutCategory? defaultCategory;

  /// When non-null the screen runs in edit mode and pre-fills all fields.
  final Routine? editRoutine;

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  late WorkoutCategory _category;
  final List<_ExerciseDraft> _exercises = [];
  final _formKey = GlobalKey<FormState>();

  bool get _isCardio => _category == WorkoutCategory.cardio;

  @override
  void initState() {
    super.initState();
    final edit = widget.editRoutine;
    if (edit != null) {
      _nameController.text = edit.name;
      _category = edit.category;
      if (edit.targetKm != null) {
        _distanceController.text = edit.targetKm!.toString();
      }
      for (final e in edit.exercises) {
        final draft = _ExerciseDraft();
        draft.nameController.text = e.name;
        draft.setsController.text = '${e.sets}';
        draft.repsController.text = e.repsLabel;
        _exercises.add(draft);
      }
    } else {
      _category = widget.defaultCategory ?? WorkoutCategory.strength;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _distanceController.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() => _exercises.add(_ExerciseDraft()));
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises[index].dispose();
      _exercises.removeAt(index);
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isCardio && _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise.')),
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final exercises = _isCardio
        ? <ExerciseTemplate>[]
        : [
            for (var i = 0; i < _exercises.length; i++)
              ExerciseTemplate(
                id: 'ex_${now}_$i',
                name: _exercises[i].nameController.text.trim(),
                sets: int.tryParse(_exercises[i].setsController.text) ?? 1,
                repsLabel: _exercises[i].repsController.text.trim(),
              ),
          ];

    final targetKm = _isCardio
        ? double.tryParse(_distanceController.text.trim())
        : null;

    final edit = widget.editRoutine;
    if (edit != null) {
      WorkoutStore.instance.updateRoutine(
        Routine(
          id: edit.id,
          name: _nameController.text.trim(),
          category: _category,
          exercises: exercises,
          targetKm: targetKm,
        ),
      );
    } else {
      final id = 'routine_${DateTime.now().millisecondsSinceEpoch}';
      WorkoutStore.instance.addRoutine(
        Routine(
          id: id,
          name: _nameController.text.trim(),
          category: _category,
          exercises: exercises,
          targetKm: targetKm,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.editRoutine != null ? 'Edit Workout' : 'Create Workout',
          style: AppTextStyles.headlineMd,
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: Squish(
          onTap: () => Navigator.of(context).maybePop(),
          child: const Icon(Icons.close_rounded),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Squish(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.base,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Save',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.gutter,
              AppSpacing.containerMargin,
              AppSpacing.lg,
            ),
            children: [
              _SectionLabel('Workout Details'),
              const SizedBox(height: AppSpacing.base),
              _WorkoutNameField(controller: _nameController),
              const SizedBox(height: AppSpacing.md),
              _CategorySelector(
                selected: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isCardio) ...[
                _SectionLabel('Running Details'),
                const SizedBox(height: AppSpacing.base),
                _DistanceField(controller: _distanceController),
              ] else ...[
                _ExercisesHeader(onAdd: _addExercise),
                const SizedBox(height: AppSpacing.base),
                if (_exercises.isEmpty)
                  _NoExercisesPlaceholder(onAdd: _addExercise),
                for (var i = 0; i < _exercises.length; i++) ...[
                  _ExerciseRow(
                    index: i,
                    draft: _exercises[i],
                    onRemove: () => _removeExercise(i),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (_exercises.isNotEmpty)
                  _AddExerciseButton(onPressed: _addExercise),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Mutable draft for a single exercise being edited
// ────────────────────────────────────────────────────────────────────────

class _ExerciseDraft {
  final nameController = TextEditingController();
  final setsController = TextEditingController(text: '3');
  final repsController = TextEditingController(text: '10');

  void dispose() {
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
  }
}

// ────────────────────────────────────────────────────────────────────────
// Section widgets
// ────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelBold.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _WorkoutNameField extends StatelessWidget {
  const _WorkoutNameField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Workout name',
        hintText: 'e.g. Push Day',
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Enter a workout name' : null,
    );
  }
}

class _DistanceField extends StatelessWidget {
  const _DistanceField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Target distance (km)',
        hintText: 'e.g. 5.0',
        suffixText: 'km',
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter a target distance';
        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
        if ((double.tryParse(v.trim()) ?? 0) <= 0) {
          return 'Distance must be greater than 0';
        }
        return null;
      },
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  final WorkoutCategory selected;
  final ValueChanged<WorkoutCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [WorkoutCategory.strength, WorkoutCategory.cardio];
    return Row(
      children: options.map((c) {
        final isSelected = c == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: c == options.last ? 0 : AppSpacing.sm,
            ),
            child: Squish(
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      c.icon,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Text(
                      c.label,
                      style: AppTextStyles.labelBold.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ExercisesHeader extends StatelessWidget {
  const _ExercisesHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Exercises', style: AppTextStyles.headlineMd),
        Squish(
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(Icons.add_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Add',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoExercisesPlaceholder extends StatelessWidget {
  const _NoExercisesPlaceholder({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onAdd,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.onSurfaceVariant, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap to add an exercise',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  final int index;
  final _ExerciseDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Text(
                  'Exercise ${index + 1}',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Squish(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: draft.nameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration('Exercise name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.setsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration('Sets'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  controller: draft.repsController,
                  decoration: _inputDecoration('Reps / Duration'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.base),
            Text(
              'Add Another Exercise',
              style: AppTextStyles.labelBold.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
