extends Area3D
class_name MaskPortal

enum PortalType { HELL, PURGATORY, HEAVEN }

@export var portal_type: PortalType = PortalType.HELL

var mesh_inst: MeshInstance3D
var label: Label3D
var active := true

signal portal_entered(type: int)

func _ready() -> void:
	_build()
	body_entered.connect(_on_body_entered)

func _build() -> void:
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.4, 3.5, 1.2)
	col.shape = shape
	col.position.y = 1.5
	add_child(col)

	mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.2, 3.2, 0.4)
	mesh_inst.mesh = box
	var mat = StandardMaterial3D.new()
	mat.emission_enabled = true
	match portal_type:
		PortalType.HELL:
			mat.albedo_color = Color(0.6, 0.1, 0.05)
			mat.emission = Color(0.9, 0.2, 0.05) * 0.7
		PortalType.PURGATORY:
			mat.albedo_color = Color(0.2, 0.2, 0.35)
			mat.emission = Color(0.4, 0.4, 0.7) * 0.5
		PortalType.HEAVEN:
			mat.albedo_color = Color(0.9, 0.9, 0.7)
			mat.emission = Color(1.0, 0.95, 0.6) * 0.6
	mesh_inst.material_override = mat
	mesh_inst.position.y = 1.6
	add_child(mesh_inst)

	label = Label3D.new()
	label.text = _type_name()
	label.font_size = 42
	label.position = Vector3(0, 3.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

	# Frame pillars
	for x in [-1.3, 1.3]:
		var pillar = MeshInstance3D.new()
		var pmesh = BoxMesh.new()
		pmesh.size = Vector3(0.4, 3.4, 0.4)
		pillar.mesh = pmesh
		var pmat = StandardMaterial3D.new()
		pmat.albedo_color = Color(0.25, 0.15, 0.35)
		pillar.material_override = pmat
		pillar.position = Vector3(x, 1.7, 0)
		add_child(pillar)

func _type_name() -> String:
	match portal_type:
		PortalType.HELL: return "HELL PORTAL"
		PortalType.PURGATORY: return "PURGATORY PORTAL"
		PortalType.HEAVEN: return "HEAVEN PORTAL"
	return "PORTAL"

func _on_body_entered(body: Node3D) -> void:
	if not active:
		return
	if body is CharacterBody3D and body.has_method("_try_enter_dimension"):
		emit_signal("portal_entered", portal_type)
