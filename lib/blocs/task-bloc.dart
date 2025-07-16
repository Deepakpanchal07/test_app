import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/models/task-model.dart';

import '../services/task-service.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskService _taskService;

  TaskBloc(this._taskService) : super(TaskLoading()) {
    on<LoadTasks>((event, emit) {
      emit(TaskLoading());
      _taskService.getTasks().listen((tasks) {
        add(TasksUpdated(tasks)); // for live update
      });
    });

    on<AddTask>((event, emit) async {
      await _taskService.addTask(event.task);
    });

    on<UpdateTask>((event, emit) async {
      await _taskService.updateTask(event.task);
    });

    on<DeleteTask>((event, emit) async {
      await _taskService.deleteTask(event.taskId);
    });

    on<ToggleCompleteTask>((event, emit) async {
      final updatedTask = event.task.copyWith(isCompleted: true);
      await _taskService.updateTask(updatedTask);
    });

    on<TasksUpdated>((event, emit) {
      emit(TaskLoaded(event.tasks));
    });
  }
}

abstract class TaskEvent {}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final TaskModel task;

  AddTask(this.task);
}

class UpdateTask extends TaskEvent {
  final TaskModel task;

  UpdateTask(this.task);
}

class DeleteTask extends TaskEvent {
  final String taskId;

  DeleteTask(this.taskId);
}

class ToggleCompleteTask extends TaskEvent {
  final TaskModel task;

  ToggleCompleteTask(this.task);
}

class TasksUpdated extends TaskEvent {
  final List<TaskModel> tasks;

  TasksUpdated(this.tasks);
}

abstract class TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;

  TaskLoaded(this.tasks);
}
