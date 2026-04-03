import 'region_model.dart';

sealed class RegionState {}

class RegionInitial extends RegionState {}

class RegionLoading extends RegionState {}

class RegionLoaded extends RegionState {
  RegionLoaded(this.regions);
  final List<RegionModel> regions;
}

class RegionError extends RegionState {
  RegionError(this.message);
  final String message;
}
