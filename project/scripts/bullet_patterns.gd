extends RefCounted
## Projectile pattern recipes for Shinobi Boss Rush.
## Design inspired by the independent bullet emitter / manager / patterns in
## foosel/pew-pew-pew-danger-zone (MIT). New implementation, no copied assets.

static func ring(origin: Vector2, count: int, speed: float, rotation: float, tint: Color, size: float = 8.0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(count):
		var a: float = rotation + TAU * float(i) / float(maxi(1, count))
		result.append(_shot(origin, Vector2.from_angle(a) * speed, tint, size))
	return result

static func fan(origin: Vector2, target: Vector2, count: int, spread: float, speed: float, tint: Color, size: float = 8.0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var base: float = (target - origin).angle()
	for i in range(count):
		var f: float = (float(i) / float(maxi(1, count - 1))) - 0.5
		result.append(_shot(origin, Vector2.from_angle(base + f * spread) * speed, tint, size))
	return result

static func aimed(origin: Vector2, target: Vector2, speed: float, tint: Color, size: float = 8.0) -> Array[Dictionary]:
	return [_shot(origin, (target - origin).normalized() * speed, tint, size)]

static func spiral(origin: Vector2, spokes: int, turns: float, speed: float, tint: Color, size: float = 7.0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(spokes):
		var angle: float = float(i) * TAU / float(maxi(1, spokes)) + turns
		var b := _shot(origin, Vector2.from_angle(angle) * speed, tint, size)
		b["curve"] = 0.45 if i % 2 == 0 else -0.45
		result.append(b)
	return result

static func wave(origin: Vector2, direction: Vector2, speed: float, tint: Color) -> Dictionary:
	var b := _shot(origin, direction.normalized() * speed, tint, 13.0)
	b["wave"] = true
	return b

static func _shot(origin: Vector2, velocity: Vector2, tint: Color, size: float) -> Dictionary:
	return {"p": origin, "v": velocity, "c": tint, "r": size, "age": 0.0, "graze": false, "curve": 0.0, "wave": false}
