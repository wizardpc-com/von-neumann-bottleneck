extends RefCounted
## Candidate navigation adapts paths only; no campaign or completion authority.
const FILES := {"representation":"representation-session.json", "service":"service-session.json"}

static func resolve_path(domain: String, primary: String, profile: String, user_directory: String) -> String:
	if not FILES.has(domain): return ""
	var fallback: String = "user://" + str(FILES[domain])
	if not FILES.has(primary) or profile.is_empty() or profile.length() > 40: return fallback
	for character: String in profile:
		if not character in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-": return fallback
	var directory := user_directory.replace("\\", "/").simplify_path()
	if not directory.ends_with("/VonNeumannBottleneckCandidates/" + primary + "/" + profile): return fallback
	if domain == primary: return fallback
	return directory.get_base_dir().get_base_dir().path_join(domain).path_join(profile).path_join(str(FILES[domain]))

static func save_path(domain: String) -> String:
	var resolved := resolve_path(domain, str(ProjectSettings.get_setting("candidate/primary_domain", "")),
		str(ProjectSettings.get_setting("candidate/profile", "")), OS.get_user_data_dir())
	if not resolved.begins_with("user://") and not resolved.is_empty():
		# Only the explicitly selected sibling candidate profile; never a campaign path.
		DirAccess.make_dir_recursive_absolute(resolved.get_base_dir())
	return resolved

# A packaged candidate may opt in without command-line flags, but never in an
# unbound/campaign directory. Path validation stays pure and shares the adapter.
static func configured_journey_for(enabled: Variant, primary: String, profile: String, user_directory: String) -> bool:
	if not enabled is bool or not enabled: return false
	var other: String = "service" if primary == "representation" else "representation"
	var sibling: String = resolve_path(other,primary,profile,user_directory)
	return not sibling.is_empty() and not sibling.begins_with("user://")

static func configured_journey() -> bool:
	return configured_journey_for(ProjectSettings.get_setting("candidate/journey_enabled",false),
		str(ProjectSettings.get_setting("candidate/primary_domain","")),
		str(ProjectSettings.get_setting("candidate/profile","")),OS.get_user_data_dir())
