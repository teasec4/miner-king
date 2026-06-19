import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/course_catalog.dart';
import 'package:crypto_king/presentation/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InstitutePage extends StatelessWidget {
  const InstitutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = GameViewModel(context.watch<GameState>());
    final activeCourse = vm.activeCourseId != null
        ? CourseCatalog.byId(vm.activeCourseId!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Institute'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active course
            if (activeCourse != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.school,
                            color: Colors.blue,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeCourse.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Studying... ${vm.courseTicksLeft}s remaining',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:
                              1 -
                              (vm.courseTicksLeft / activeCourse.durationTicks),
                          minHeight: 8,
                          backgroundColor: Colors.blue.shade100,
                          valueColor: const AlwaysStoppedAnimation(Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              'Available Courses',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...CourseCatalog.all.map((c) {
              final completed = vm.completedCourses.contains(c.id);
              final hasReqs = c.requiresCourse.every(
                (r) => vm.completedCourses.contains(r),
              );
              final canEnroll =
                  !completed &&
                  vm.activeCourseId == null &&
                  vm.money >= c.price &&
                  hasReqs;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: completed ? Colors.green.shade50 : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        completed ? Icons.check_circle : Icons.menu_book,
                        color: completed ? Colors.green : Colors.blue,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              c.unlocks,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '\$${c.price}  •  ${c.durationLabel}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (!hasReqs && !completed)
                              Text(
                                'Prerequisites: ${c.requiresCourse.map((r) => CourseCatalog.byId(r)?.name ?? r).join(", ")}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: completed
                              ? Colors.green
                              : canEnroll
                              ? Colors.blue
                              : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: canEnroll
                            ? () => vm.enrollCourse(c.id)
                            : null,
                        child: Text(
                          completed
                              ? 'Done'
                              : canEnroll
                              ? 'Enroll'
                              : 'Locked',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
