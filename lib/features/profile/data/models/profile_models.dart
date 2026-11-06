import 'package:json_annotation/json_annotation.dart';

part 'profile_models.g.dart';

/// `GET /me`.
@JsonSerializable()
class MeDto {
  const MeDto({
    required this.memberId,
    required this.tenantId,
    required this.fullName,
    required this.email,
    this.tenantName,
    this.initials,
    this.roleName,
    this.roleKey,
    this.usage,
    this.permissions = const [],
    this.branchId,
    this.branchName,
    this.policyVersion,
    this.policyAcceptedAt,
    this.supervisorName,
    this.workGroupName,
    this.deviceModel,
  });

  factory MeDto.fromJson(Map<String, dynamic> json) => _$MeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MeDtoToJson(this);

  final String memberId;
  final String tenantId;
  final String? tenantName;
  final String fullName;
  final String? initials;
  final String email;
  final String? roleName;
  final String? roleKey;

  /// `Mobile` or `WebOnly`.
  final String? usage;
  final List<String> permissions;
  final String? branchId;
  final String? branchName;
  final String? policyVersion;
  final DateTime? policyAcceptedAt;
  final String? supervisorName;
  final String? workGroupName;
  final String? deviceModel;

  bool get isMobileUser => usage == null || usage == 'Mobile';
}

/// `GET /me/tenants`: companies where the user has WorkLog.
@JsonSerializable()
class TenantDto {
  const TenantDto({required this.tenantId, required this.name, this.slug, this.role, this.canAdministrate = false});

  factory TenantDto.fromJson(Map<String, dynamic> json) => _$TenantDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TenantDtoToJson(this);

  final String tenantId;
  final String name;
  final String? slug;
  final String? role;
  final bool canAdministrate;
}

/// `GET /me/privacy-policy`.
@JsonSerializable()
class PrivacyPolicyDto {
  const PrivacyPolicyDto({
    required this.version,
    required this.effectiveFrom,
    this.summary = const [],
    this.fullTextUrl,
    this.accepted = false,
    this.acceptedAt,
  });

  factory PrivacyPolicyDto.fromJson(Map<String, dynamic> json) => _$PrivacyPolicyDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PrivacyPolicyDtoToJson(this);

  final String version;

  /// DateOnly `yyyy-MM-dd`.
  final String effectiveFrom;
  final List<String> summary;
  final String? fullTextUrl;
  final bool accepted;
  final DateTime? acceptedAt;
}
