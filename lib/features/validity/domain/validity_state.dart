import 'validity_model.dart';

sealed class ValidityState {}

class ValidityInitial extends ValidityState {}

class ValidityLoading extends ValidityState {}

class ValidityLoaded extends ValidityState {
  ValidityLoaded(this.items);
  final List<ValidityModel> items;
}

class ValidityError extends ValidityState {
  ValidityError(this.message);
  final String message;
}
