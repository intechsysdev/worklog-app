// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeDto _$MeDtoFromJson(Map<String, dynamic> json) => MeDto(
  memberId: json['memberId'] as String,
  tenantId: json['tenantId'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  tenantName: json['tenantName'] as String?,
  initials: json['initials'] as String?,
  roleName: json['roleName'] as String?,
  roleKey: json['roleKey'] as String?,
  usage: json['usage'] as String?,
  permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
  branchId: json['branchId'] as String?,
  branchName: json['branchName'] as String?,
  policyVersion: json['policyVersion'] as String?,
  policyAcceptedAt: json['policyAcceptedAt'] == null ? null : DateTime.parse(json['policyAcceptedAt'] as String),
  supervisorName: json['supervisorName'] as String?,
  workGroupName: json['workGroupName'] as String?,
  deviceModel: json['deviceModel'] as String?,
);

Map<String, dynamic> _$MeDtoToJson(MeDto instance) => <String, dynamic>{
  'memberId': instance.memberId,
  'tenantId': instance.tenantId,
  'tenantName': ?instance.tenantName,
  'fullName': instance.fullName,
  'initials': ?instance.initials,
  'email': instance.email,
  'roleName': ?instance.roleName,
  'roleKey': ?instance.roleKey,
  'usage': ?instance.usage,
  'permissions': instance.permissions,
  'branchId': ?instance.branchId,
  'branchName': ?instance.branchName,
  'policyVersion': ?instance.policyVersion,
  'policyAcceptedAt': ?instance.policyAcceptedAt?.toIso8601String(),
  'supervisorName': ?instance.supervisorName,
  'workGroupName': ?instance.workGroupName,
  'deviceModel': ?instance.deviceModel,
};

TenantDto _$TenantDtoFromJson(Map<String, dynamic> json) => TenantDto(
  tenantId: json['tenantId'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String?,
  role: json['role'] as String?,
  canAdministrate: json['canAdministrate'] as bool? ?? false,
);

Map<String, dynamic> _$TenantDtoToJson(TenantDto instance) => <String, dynamic>{
  'tenantId': instance.tenantId,
  'name': instance.name,
  'slug': ?instance.slug,
  'role': ?instance.role,
  'canAdministrate': instance.canAdministrate,
};

PrivacyPolicyDto _$PrivacyPolicyDtoFromJson(Map<String, dynamic> json) => PrivacyPolicyDto(
  version: json['version'] as String,
  effectiveFrom: json['effectiveFrom'] as String,
  summary: (json['summary'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
  fullTextUrl: json['fullTextUrl'] as String?,
  accepted: json['accepted'] as bool? ?? false,
  acceptedAt: json['acceptedAt'] == null ? null : DateTime.parse(json['acceptedAt'] as String),
);

Map<String, dynamic> _$PrivacyPolicyDtoToJson(PrivacyPolicyDto instance) => <String, dynamic>{
  'version': instance.version,
  'effectiveFrom': instance.effectiveFrom,
  'summary': instance.summary,
  'fullTextUrl': ?instance.fullTextUrl,
  'accepted': instance.accepted,
  'acceptedAt': ?instance.acceptedAt?.toIso8601String(),
};
