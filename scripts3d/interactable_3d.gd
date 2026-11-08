class_name Interactable3D
extends Area3D
## 3D counterpart of Interactable. The player's InteractArea finds these; the
## district shows the "[E] ..." prompt at full resolution on the HUD.
## `realm` makes an object exist in only one world.

enum Realm { BOTH, PHYSICAL, DIGITAL }

const INTERACTABLE_LAYER_BIT: int = 1 << 3  # 3D physics layer 4: interactable

@export var realm: Realm = Realm.BOTH
@export var prompt_text: String = "INTERACT"

var is_in_current_world: bool = true


func _ready() -> void:
	collision_layer = INTERACTABLE_LAYER_BIT
	collision_mask = 0
	monitoring = false
	add_to_group("interactable3d")
	GameState.layer_changed.connect(func(_layer: GameState.WorldLayer) -> void: _refresh_realm())
	_refresh_realm()


func interact(_player: Node3D) -> void:
	pass


func exists_in(layer: GameState.WorldLayer) -> bool:
	return realm_active(realm, layer)


## True if something with this realm exists while `layer` is the active world.
static func realm_active(object_realm: Realm, layer: GameState.WorldLayer) -> bool:
	match object_realm:
		Realm.PHYSICAL:
			return layer == GameState.WorldLayer.PHYSICAL
		Realm.DIGITAL:
			return layer == GameState.WorldLayer.DIGITAL
	return true


func _refresh_realm() -> void:
	is_in_current_world = exists_in(GameState.current_layer)
	visible = is_in_current_world
	set_deferred("monitorable", is_in_current_world)


## Size of one sprite pixel in metres. The 3D sprites are drawn so that an 80 px
## character is 2 m tall, which renders 1:1 on the low-resolution viewport.
const SPRITE_PIXEL: float = 0.025


## Build an upright billboard sprite standing on the ground. `frames` and `rows` are
## the sprite-sheet grid; the sprite's feet sit at the node's origin.
static func make_billboard(texture: Texture2D, frames: int, rows: int = 1) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.hframes = frames
	sprite.vframes = rows
	sprite.pixel_size = SPRITE_PIXEL
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = false
	sprite.position.y = float(texture.get_height()) / float(rows) * SPRITE_PIXEL / 2.0
	return sprite
