extends RefCounted
## تجنب عوائق بـ Raycast — بديل عملي لما NavMesh مش مخبوز على المباني

static func steer_dir(body: Node3D, desired: Vector3, speed: float, delta: float) -> Vector3:
	desired.y = 0.0
	if desired.length_squared() < 0.0001:
		return Vector3.ZERO
	desired = desired.normalized()
	var space := body.get_world_3d().direct_space_state
	if space == null:
		return desired
	var from := body.global_position + Vector3(0, 0.8, 0)
	var probe_len := 2.5 + speed * 0.15
	# أمام
	if _blocked(space, from, desired, probe_len, body):
		# جرّب يمين وشمال
		var right := desired.cross(Vector3.UP).normalized()
		var left := -right
		var ok_r := not _blocked(space, from, (desired + right).normalized(), probe_len, body)
		var ok_l := not _blocked(space, from, (desired + left).normalized(), probe_len, body)
		if ok_r and not ok_l:
			desired = (desired + right * 1.4).normalized()
		elif ok_l and not ok_r:
			desired = (desired + left * 1.4).normalized()
		elif ok_r and ok_l:
			desired = (desired + right * 0.8).normalized()
		else:
			# التفاف حاد
			desired = right if randf() > 0.5 else left
	return desired

static func _blocked(space: PhysicsDirectSpaceState3D, from: Vector3, dir: Vector3, length: float, exclude: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * length)
	q.exclude = [exclude.get_rid()] if exclude else []
	q.collision_mask = 1  # عالم ثابت
	var hit := space.intersect_ray(q)
	return not hit.is_empty()
