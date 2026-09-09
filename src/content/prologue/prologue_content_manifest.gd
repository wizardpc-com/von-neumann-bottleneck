extends RefCounted

const FoundationsPackType = preload("res://src/content/prologue/foundations_content_pack.gd")
const ArithmeticPackType = preload("res://src/content/prologue/arithmetic_content_pack.gd")
const StoragePackType = preload("res://src/content/prologue/storage_content_pack.gd")
const ExplorationPackType = preload("res://src/content/prologue/exploration_content_pack.gd")
const IntegrationPackType = preload("res://src/content/prologue/integration_content_pack.gd")


func register_into(registry) -> void:
	for pack: RefCounted in [
		FoundationsPackType.new(),
		ArithmeticPackType.new(),
		StoragePackType.new(),
		IntegrationPackType.new(),
		ExplorationPackType.new(),
	]:
		registry.retain_provider(pack)
		pack.call("register_into", registry, {})
