/// Modelo de domínio de uma Região.
class RegionModel {
  const RegionModel({
    required this.id,
    required this.name,
    required this.cityCount,
    required this.isActive,
  });

  final String id;
  final String name;
  final int cityCount;
  final bool isActive;

  /// Converte resposta da RPC `list_regions_by_agency_exhibition`.
  factory RegionModel.fromRpc(Map<String, dynamic> map) {
    return RegionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      cityCount: (map['city_count'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
