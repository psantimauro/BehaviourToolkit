extends EditorInspectorPlugin


var SelectTweenValue = preload("res://addons/behaviour_toolkit/inspector/select_tween_value.gd")


func _can_handle(object):
	return true


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	# Leaf Tween
	if object is LeafTween:
		var tween_value_type: LeafTween.TweenValueType = object.tween_value_type
		if name == "tween_value_int":
			return not tween_value_type == LeafTween.TweenValueType.INT
		
		if name == "tween_value_float":
			return not tween_value_type == LeafTween.TweenValueType.FLOAT
		
		if name == "tween_value_vector2":
			return not tween_value_type == LeafTween.TweenValueType.VECTOR2
		
		if name == "tween_value_vector3":
			return not tween_value_type == LeafTween.TweenValueType.VECTOR3
		
		if name == "tween_value_color":
			return not tween_value_type == LeafTween.TweenValueType.COLOR


	return false
