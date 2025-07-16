import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:test_app/services/auth-service.dart';
import 'package:test_app/utils/app_constant.dart';
import '../blocs/task-bloc.dart';
import '../models/task-model.dart';
import '../widgets/task-tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEAFE),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: AppConstant.appMainColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Today, ${DateFormat('d MMMM').format(DateTime.now())}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "My Tasks",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔍 Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Search tasks...",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),


                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () async {
                        await AuthService().logout();
                        Navigator.pushReplacementNamed(context, "/login");
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TaskLoaded) {
                    final today = DateTime.now();
                    final tomorrow = today.add(const Duration(days: 1));

                    final todayTasks = state.tasks
                        .where((task) => isSameDay(task.dueDate, today) && !task.isCompleted)
                        .toList();

                    final tomorrowTasks = state.tasks
                        .where((task) => isSameDay(task.dueDate, tomorrow) && !task.isCompleted)
                        .toList();

                    final thisWeekTasks = state.tasks.where((task) {
                      final now = DateTime.now();
                      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                      final endOfWeek = startOfWeek.add(const Duration(days: 6));
                      return task.dueDate.isAfter(now) &&
                          task.dueDate.isBefore(endOfWeek) &&
                          !isSameDay(task.dueDate, today) &&
                          !isSameDay(task.dueDate, tomorrow) &&
                          !task.isCompleted;
                    }).toList();

                    return ListView(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 16),
                      children: [
                        TaskSection(title: "Today", tasks: todayTasks),
                        TaskSection(title: "Tomorrow", tasks: tomorrowTasks),
                        TaskSection(title: "This Week", tasks: thisWeekTasks),
                      ],
                    );
                  } else {
                    return const Center(child: Text("Something went wrong"));
                  }
                },
              ),
            ),
          ],
        ),
      ),
      //  +(add task) icon
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final _formKey = GlobalKey<FormState>();
          final _titleController = TextEditingController();
          final _descController = TextEditingController();
          DateTime _selectedDate = DateTime.now();
          String _priority = 'Medium';

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 20,
                ),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Add New Task",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            // Title
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(labelText: "Title"),
                              validator: (value) =>
                              value!.isEmpty ? "Please enter a title" : null,
                            ),

                            // Description
                            TextFormField(
                              controller: _descController,
                              decoration: const InputDecoration(labelText: "Description"),
                            ),

                            const SizedBox(height: 12),

                            // Date Picker
                            Row(
                              children: [
                                const Text("Due Date: "),
                                Text(DateFormat.yMMMd().format(_selectedDate)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      setState(() => _selectedDate = pickedDate);
                                    }
                                  },
                                  child: const Text("Pick Date"),
                                )
                              ],
                            ),

                            // Priority Dropdown
                            DropdownButtonFormField<String>(
                              value: _priority,
                              items: ['Low', 'Medium', 'High']
                                  .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ))
                                  .toList(),
                              onChanged: (val) => setState(() => _priority = val!),
                              decoration: const InputDecoration(labelText: "Priority"),
                            ),

                            const SizedBox(height: 16),

                            // Submit
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final newTask = TaskModel(
                                    id: '',
                                    title: _titleController.text,
                                    description: _descController.text,
                                    dueDate: _selectedDate,
                                    priority: _priority,
                                    isCompleted: false,
                                  );

                                  context.read<TaskBloc>().add(AddTask(newTask));
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Add Task"),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        backgroundColor: AppConstant.appMainColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.menu),
              Icon(Icons.calendar_today),
            ],
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class TaskSection extends StatelessWidget {
  final String title;
  final List<TaskModel> tasks;

  const TaskSection({super.key, required this.title, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...tasks.map((task) => TaskTile(
          task: task,
          onDelete: () {
            context.read<TaskBloc>().add(DeleteTask(task.id));
          },
          onUpdate: () {},
        )),
      ],
    );
  }
}
