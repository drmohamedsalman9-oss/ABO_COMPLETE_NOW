extends Node3D
## عدة مناطق ملاحة تغطي المركز + الجهات

func _ready() -> void:
	var centers := [
		Vector3(0, 0, 0),
		Vector3(200, 0, 0),
		Vector3(-200, 0, 0),
		Vector3(0, 0, 200),
		Vector3(0, 0, -200),
	]
	for i in range(centers.size()):
		_add_region("NavRegion_%d" % i, centers[i], Vector2(220, 220))
	print("[CityNavigation] ", centers.size(), " مناطق NavMesh (create_from_mesh)")

func _add_region(nm: String, center: Vector3, size: Vector2) -> void:
	var region := NavigationRegion3D.new()
	region.name = nm
	region.position = center
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.4
	nav_mesh.agent_height = 1.7
	nav_mesh.agent_max_climb = 0.5
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 6
	plane.subdivide_depth = 6
	nav_mesh.create_from_mesh(plane)
	region.navigation_mesh = nav_mesh
	add_child(region)
