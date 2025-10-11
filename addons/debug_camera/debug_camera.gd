extends Camera3D
## A camera controller similar to the one used in the Godot 3D editor.
## Source: https://github.com/godotengine/godot/blob/4.5/editor/scene/3d/node_3d_editor_plugin.cpp

const PITCH_MAX = PI/2.0 * 0.992
const DEFAULT_ORBIT_DISTANCE = 4.0

@export_category('Navigation Feel')
@export_group('Freelook')
## The mouse sensitivity to use while freelook mode is active.
@export_range(0.01, 20, 0.001, 'hide_slider', 'radians_as_degrees') var freelook_sensitivity := deg_to_rad(0.25)
## The inertia to use while freelook mode is active. Higher values make the camera start and stop slower, which looks smoother but adds latency.
@export_range(0, 1, 0.001, 'hide_slider') var freelook_inertia := 0.0
## The base freelook speed in units per second. This can be adjusted by using the mouse wheel while in freelook mode, or by holding down the "fast" or "slow" modifier keys ([kbd]Shift[/kbd] and [kbd]Alt[/kbd] by default, respectively).
@export_range(0, 10, 0.01, 'hide_slider', 'suffix:m/s') var freelook_base_speed := 5.0

@export_group('Orbit')
## The mouse sensitivity to use when orbiting.
@export_range(0.01, 20, 0.001, 'hide_slider', 'radians_as_degrees') var orbit_sensitivity := deg_to_rad(0.25)
## The inertia to use when orbiting. Higher values make the camera start and stop slower, which looks smoother but adds latency.
@export_range(0, 1, 0.001, 'hide_slider') var orbit_inertia := 0.0

@export_group('Panning')
## The mouse sensitivity to use when panning.
@export_range(0.01, 20, 0.001, 'hide_slider') var pan_sensitivity := 1.0
## The inertia to use when panning. Higher values make the camera start and stop slower, which looks smoother but adds latency.
@export_range(0, 1, 0.001, 'hide_slider') var pan_inertia := 0.05

@export_group('Zoom')
## The mouse sensitivity to use when zooming.
@export_range(0.01, 20, 0.001, 'hide_slider') var zoom_sensitivity := 1.0
## The inertia to use when zooming. Higher values make the camera start and stop slower, which looks smoother but adds latency.
@export_range(0, 1, 0.001, 'hide_slider') var zoom_inertia := 0.05

## The current movement mode. Mode prescedence is based on enum int value.
enum Mode { MODE_IDLE, MODE_ORBIT, MODE_ZOOM, MODE_PAN, MODE_FREELOOK }

var _smoothed_orbit_distance := DEFAULT_ORBIT_DISTANCE
var _orbit_distance := DEFAULT_ORBIT_DISTANCE :
	set(value): _orbit_distance = clampf(value, get_min_speed(), get_max_speed())
var _speed := freelook_base_speed :
	set(value): _speed = clampf(value, get_min_speed(), get_max_speed())

var _mouse_motion: Vector2
var _smoothed_position: Vector3
var _smoothed_rotation: Vector3 :
	set(value):
		value.y = rotation.x - clamp(rotation.x - value.y, -PITCH_MAX, PITCH_MAX) # Clamp pitch to (-pi/2..pi/2)
		_smoothed_rotation = value
var _current_mode: Mode :
	set(new_mode):
		# Side effects when mode is changed
		if _current_mode == Mode.MODE_FREELOOK or new_mode == Mode.MODE_FREELOOK:
			_smoothed_rotation = Vector3.ZERO
			_smoothed_position = Vector3.ZERO
			_orbit_distance = _smoothed_orbit_distance

		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if new_mode != Mode.MODE_IDLE else Input.CURSOR_ARROW)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if new_mode == Mode.MODE_FREELOOK else Input.MOUSE_MODE_VISIBLE)
		_current_mode = new_mode

func get_min_speed() -> float:
	return minf(self.near * 4.0, self.far / 4.0)

func get_max_speed() -> float:
	return maxf(self.near * 4.0, self.far / 4.0)


func _refresh_current_mode() -> void:
	var new_mode := Mode.MODE_IDLE
	if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_RIGHT):
		new_mode = Mode.MODE_FREELOOK
	elif Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_MIDDLE):
		new_mode = Mode.MODE_ORBIT
		if Input.is_key_pressed(Key.KEY_SHIFT):
			new_mode = Mode.MODE_PAN
		elif Input.is_key_pressed(Key.KEY_CTRL):
			new_mode = Mode.MODE_ZOOM

	if new_mode != _current_mode:
		_current_mode = new_mode


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MouseButton.MOUSE_BUTTON_RIGHT, MouseButton.MOUSE_BUTTON_MIDDLE:
				_refresh_current_mode()
			MouseButton.MOUSE_BUTTON_WHEEL_UP, MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
				var factor := 1.08 if int(event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN) ^ int(_current_mode == Mode.MODE_FREELOOK) else 1.0 / 1.08

				if _current_mode != Mode.MODE_FREELOOK:
					_orbit_distance *= factor
				else:
					_speed *= factor

	elif event is InputEventKey:
		match event.keycode:
			Key.KEY_SHIFT, Key.KEY_CTRL:
				_refresh_current_mode()

	elif event is InputEventMouseMotion:
		if _current_mode == Mode.MODE_IDLE: return

		var viewport := get_viewport()
		var viewport_size_wrapped := viewport.get_visible_rect().size - Vector2.ONE*2.0
		var mouse_pos := viewport.get_mouse_position()
		var mouse_pos_wrapped := (mouse_pos - Vector2.ONE).posmodv(viewport_size_wrapped) + Vector2.ONE

		# Reasonable check to filter out input events caused by the cursor wrapping around viewport.
		var has_warped_check: Vector2 = event.screen_relative.abs() / viewport_size_wrapped

		if mouse_pos != mouse_pos_wrapped:
			# Wrap cursor around to otherside of viewport if it reaches the end (infinite drag).
			Input.warp_mouse(mouse_pos_wrapped)
		elif has_warped_check.x < 0.5 and has_warped_check.y < 0.5:
			_mouse_motion += event.screen_relative


func _process(delta: float) -> void:
	if _current_mode == Mode.MODE_FREELOOK:
		_nav_freelook(delta)
	else:
		if _current_mode == Mode.MODE_PAN or not _smoothed_position.is_equal_approx(Vector3.ZERO):
			_nav_pan(delta)
		if _current_mode == Mode.MODE_ZOOM or not is_equal_approx(_smoothed_orbit_distance, _orbit_distance):
			_nav_zoom(delta)
		if _current_mode == Mode.MODE_ORBIT or not _smoothed_rotation.is_equal_approx(Vector3.ZERO):
			_nav_orbit(delta)

	_mouse_motion = Vector2.ZERO


func _nav_freelook(delta: float) -> void:
	var mouse_motion := _mouse_motion * freelook_sensitivity if _current_mode == Mode.MODE_FREELOOK else Vector2.ZERO
	var displacement_modifier := 3.0 if Input.is_key_pressed(Key.KEY_SHIFT) else 1.0/3.0 if Input.is_key_pressed(Key.KEY_ALT) else 1.0
	var displacement := Vector3(
		int(Input.is_key_pressed(Key.KEY_D)) - int(Input.is_key_pressed(Key.KEY_A)),
		int(Input.is_key_pressed(Key.KEY_E)) - int(Input.is_key_pressed(Key.KEY_Q)),
		int(Input.is_key_pressed(Key.KEY_S)) - int(Input.is_key_pressed(Key.KEY_W)),
	).normalized() * displacement_modifier

	_smoothed_position = _smoothed_position.lerp(global_basis * displacement * _speed * delta, _get_inertia_factor(freelook_inertia, delta))
	_smoothed_rotation = _smoothed_rotation.lerp(Vector3(mouse_motion.x, mouse_motion.y, 0), _get_inertia_factor(orbit_inertia, delta))

	global_position += _smoothed_position
	quaternion = Quaternion(Vector3.UP, -_smoothed_rotation.x) * Quaternion(basis.x, -_smoothed_rotation.y) * quaternion


func _nav_pan(delta: float) -> void:
	var mouse_motion := _mouse_motion * (pan_sensitivity / 150.0) * (_smoothed_orbit_distance / DEFAULT_ORBIT_DISTANCE) if _current_mode == Mode.MODE_PAN else Vector2.ZERO

	_smoothed_position = _smoothed_position.lerp(global_basis * Vector3(-mouse_motion.x, mouse_motion.y, 0), _get_inertia_factor(pan_inertia, delta))

	global_position += _smoothed_position


func _nav_zoom(delta: float) -> void:
	var mouse_motion := _mouse_motion * (zoom_sensitivity / 80.0) if _current_mode == Mode.MODE_ZOOM else Vector2.ZERO

	var factor := 1.0 + mouse_motion.y if mouse_motion.y >= 0.0 else 1.0 / (1.0 - mouse_motion.y)
	_orbit_distance *= factor

	var previous_orbit_distance := _smoothed_orbit_distance
	_smoothed_orbit_distance = lerpf(_smoothed_orbit_distance, _orbit_distance, _get_inertia_factor(zoom_inertia, delta));
	global_position += global_basis.z * (_smoothed_orbit_distance - previous_orbit_distance)


func _nav_orbit(delta: float) -> void:
	var mouse_motion := _mouse_motion * orbit_sensitivity if _current_mode == Mode.MODE_ORBIT else Vector2.ZERO

	_smoothed_rotation = _smoothed_rotation.lerp(Vector3(mouse_motion.x, mouse_motion.y, 0), _get_inertia_factor(orbit_inertia, delta))

	var orbit_offset := global_basis.z * _smoothed_orbit_distance
	var rotated_offset := Quaternion(Vector3.UP, -_smoothed_rotation.x) * Quaternion(global_basis.x, -_smoothed_rotation.y) * orbit_offset
	var pivot := global_position - orbit_offset
	look_at_from_position(pivot + rotated_offset, pivot, Vector3.UP)


func _get_inertia_factor(inertia: float, delta: float) -> float:
	const DECAY_RATE = 7.0
	return maxf(0.01, 1.0 - pow(inertia, delta*DECAY_RATE))
