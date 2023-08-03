extends Node
var peers = []
var game_reset_count : int = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	if not User.is_host:
		set_process(false)
	
	await get_tree().create_timer(3).timeout
	peers.push_back(get_node("../player_character"))
	peers.push_back(get_node("../player_character2"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	for peer in peers:
		if peer.dead:
			await get_tree().create_timer(3).timeout
			reset_game.rpc()
			reset_dead_player.rpc()

@rpc("any_peer","call_local","reliable")
func reset_dead_player():
	for peer in peers:
		if peer.dead:
			if peer.get_multiplayer_authority() == (1 if User.is_host else 2):
				peer.dead = false
				peer.health.value = 100
				peer.original_anim_tree.set_active(true)
				peer.anim_tree.travel("Idle")
				peer.set_physics_process(true)
				peer.set_process(true)
				print("I am the player")
			else:
				peer.dead = false
				peer.health.value = 100
				peer.original_anim_tree.set_active(true)
				peer.anim_tree.travel("Idle")

@rpc("any_peer","call_local","reliable")
func reset_game():
		for peer in peers:
			if peer.multiplayer.get_unique_id() == 1:
				peer.global_position = Vector2(-344,41)
			if peer.multiplayer.get_unique_id() == 2:
				peer.global_position = Vector2(347,37)
