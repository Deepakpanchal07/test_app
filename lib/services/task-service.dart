import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task-model.dart';

class TaskService {
  final taskCollection = FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(TaskModel task) async {
    await taskCollection.add(task.toMap());
  }

  Stream<List<TaskModel>> getTasks() {
    return taskCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> deleteTask(String id) async {
    await taskCollection.doc(id).delete();
  }
  Future<void> updateTask(TaskModel task) async {
    await taskCollection.doc(task.id).update(task.toMap());
  }


}
