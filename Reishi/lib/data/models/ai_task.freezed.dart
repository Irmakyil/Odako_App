// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AITask _$AITaskFromJson(Map<String, dynamic> json) {
  return _AITask.fromJson(json);
}

/// @nodoc
mixin _$AITask {
  String get text => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;

  /// Serializes this AITask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AITaskCopyWith<AITask> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AITaskCopyWith<$Res> {
  factory $AITaskCopyWith(AITask value, $Res Function(AITask) then) =
      _$AITaskCopyWithImpl<$Res, AITask>;
  @useResult
  $Res call({String text, String priority});
}

/// @nodoc
class _$AITaskCopyWithImpl<$Res, $Val extends AITask>
    implements $AITaskCopyWith<$Res> {
  _$AITaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null, Object? priority = null}) {
    return _then(
      _value.copyWith(
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AITaskImplCopyWith<$Res> implements $AITaskCopyWith<$Res> {
  factory _$$AITaskImplCopyWith(
    _$AITaskImpl value,
    $Res Function(_$AITaskImpl) then,
  ) = __$$AITaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, String priority});
}

/// @nodoc
class __$$AITaskImplCopyWithImpl<$Res>
    extends _$AITaskCopyWithImpl<$Res, _$AITaskImpl>
    implements _$$AITaskImplCopyWith<$Res> {
  __$$AITaskImplCopyWithImpl(
    _$AITaskImpl _value,
    $Res Function(_$AITaskImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null, Object? priority = null}) {
    return _then(
      _$AITaskImpl(
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AITaskImpl implements _AITask {
  const _$AITaskImpl({required this.text, required this.priority});

  factory _$AITaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$AITaskImplFromJson(json);

  @override
  final String text;
  @override
  final String priority;

  @override
  String toString() {
    return 'AITask(text: $text, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AITaskImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, priority);

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AITaskImplCopyWith<_$AITaskImpl> get copyWith =>
      __$$AITaskImplCopyWithImpl<_$AITaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AITaskImplToJson(this);
  }
}

abstract class _AITask implements AITask {
  const factory _AITask({
    required final String text,
    required final String priority,
  }) = _$AITaskImpl;

  factory _AITask.fromJson(Map<String, dynamic> json) = _$AITaskImpl.fromJson;

  @override
  String get text;
  @override
  String get priority;

  /// Create a copy of AITask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AITaskImplCopyWith<_$AITaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
