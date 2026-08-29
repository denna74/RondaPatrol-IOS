extends TouchScreenButton

var item_id: String = ""
var _amount_label: Label
var _is_disabled := false

const ICONS := {
	"senter": preload("res://assets/buttons/skill_flashlight.png"),
	"kopi": preload("res://assets/buttons/skill_coffee.png"),
	"balsem": preload("res://assets/buttons/skill_balm.png"),
	"kacang": preload("res://assets/buttons/skill_peanut.png"),
	"cassava": preload("res://assets/buttons/skill_cassava.png"),
	"sajen": preload("res://assets/buttons/skill_sajen.png"),
}

const GRAY_SHADER := preload("res://shaders/grayscale.gdshader")
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")

func setup(id: String) -> void:
	item_id = id
	_amount_label = $AmountLabel
	var tex = ICONS.get(id)
	texture_normal = tex
	texture_pressed = ButtonBuilder.darken_texture(tex) if tex else null
	var s = tex.get_size()
	scale = Vector2(100.0 / s.x, 100.0 / s.y) if tex else Vector2.ONE
	_update_disabled()

func _process(_delta: float) -> void:
	_update_disabled()

func _update_disabled() -> void:
	var count = SaveManager.get_item_count(item_id)
	_amount_label.text = str(count)

	var should = count <= 0
	if should == _is_disabled:
		return
	_is_disabled = should
	if _is_disabled:
		var mat = ShaderMaterial.new()
		mat.shader = GRAY_SHADER
		material = mat
	else:
		material = null
