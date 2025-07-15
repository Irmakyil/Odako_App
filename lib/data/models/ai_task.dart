import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_task.freezed.dart';
part 'ai_task.g.dart';

@freezed
class AITask with _$AITask {
  const factory AITask({
    required String text,
    required String priority,
  }) = _AITask;

  factory AITask.fromJson(Map<String, dynamic> json) => _$AITaskFromJson(json);
} 