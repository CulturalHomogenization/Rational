# SceneManager.gd - AutoLoad singleton
extends Node

# Scene references
var current_scene = null
var game_scene_instance = null
var upgrade_menu_instance = null

# Scene paths
const GAME_SCENE_PATH = "res://Scenes/kitchen.tscn"
const UPGRADE_MENU_PATH = "res://Scenes/upgrade_menu.tscn"

func _ready():
	# Get the current scene (whatever was set as main scene)
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func switch_to_game_scene():
	call_deferred("_deferred_switch_to_game")

func switch_to_upgrade_menu():
	call_deferred("_deferred_switch_to_upgrade")

func _deferred_switch_to_game():
	# If we don't have a game scene instance, use the current one if it's the game scene
	if not game_scene_instance:
		if current_scene and current_scene.scene_file_path == GAME_SCENE_PATH:
			# Current scene IS the game scene, so preserve it
			game_scene_instance = current_scene
		else:
			# Create new game scene
			var game_scene = load(GAME_SCENE_PATH)
			game_scene_instance = game_scene.instantiate()
	
	# Remove current scene from tree but don't free it
	if current_scene and current_scene != game_scene_instance:
		current_scene.get_parent().remove_child(current_scene)
	
	# Add game scene to tree (only if not already there)
	if game_scene_instance.get_parent() == null:
		get_tree().root.add_child(game_scene_instance)
	
	get_tree().current_scene = game_scene_instance
	current_scene = game_scene_instance
	
	print("Switched to game scene")

func _deferred_switch_to_upgrade():
	# If we don't have an upgrade menu instance, use current one if it's the upgrade menu
	if not upgrade_menu_instance:
		if current_scene and current_scene.scene_file_path == UPGRADE_MENU_PATH:
			# Current scene IS the upgrade menu, so preserve it
			upgrade_menu_instance = current_scene
		else:
			# Create new upgrade menu
			var upgrade_scene = load(UPGRADE_MENU_PATH)
			upgrade_menu_instance = upgrade_scene.instantiate()
			
			# Connect back button if it exists
			if upgrade_menu_instance.has_signal("back_to_game"):
				upgrade_menu_instance.back_to_game.connect(switch_to_game_scene)
	
	# Remove current scene from tree but don't free it
	if current_scene and current_scene != upgrade_menu_instance:
		current_scene.get_parent().remove_child(current_scene)
	
	# Add upgrade menu to tree (only if not already there)
	if upgrade_menu_instance.get_parent() == null:
		get_tree().root.add_child(upgrade_menu_instance)
	
	get_tree().current_scene = upgrade_menu_instance
	current_scene = upgrade_menu_instance
	
	print("Switched to upgrade menu")

# Call this when you want to properly quit and clean up
func cleanup_scenes():
	if game_scene_instance:
		game_scene_instance.queue_free()
		game_scene_instance = null
	if upgrade_menu_instance:
		upgrade_menu_instance.queue_free()
		upgrade_menu_instance = null
