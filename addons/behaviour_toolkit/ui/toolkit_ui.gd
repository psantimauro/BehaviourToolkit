@tool
extends Control


enum PlacementMode {
	CHILD,
	SIBLING,
	PARENT,
	REPLACE
}


const CONFIG_URL = "https://raw.githubusercontent.com/ThePat02/BehaviourToolkit/main/addons/behaviour_toolkit/plugin.cfg"


@export var update_manager: UpdateManager


var current_selection: Node
var undo_redo: EditorUndoRedoManager


@onready var dialog_blackboard: FileDialog = $FileDialogNewBlackboard
@onready var toolbox: Control = %Toolbox
@onready var toolbox_fsm = %FiniteStateMachine
@onready var toolbox_bt = %BehaviourTree


func _ready():
	# Hide SearchBar by default
	%SearchBar.hide()

	# Connect buttons
	%ButtonState.connect("pressed", _on_button_pressed.bind(FSMState, "FSMState"))
	%ButtonTransition.connect("pressed", _on_button_pressed.bind(FSMTransition, "FSMTransition"))
	%ButtonStateIntegratedBT.connect("pressed", _on_button_pressed.bind(FSMStateIntegratedBT, "FSMStateIntegratedBT"))
	%ButtonStateIntegrationReturn.connect("pressed", _on_button_pressed.bind(FSMStateIntegrationReturn, "FSMStateIntegrationReturn"))

	%ButtonLeaf.connect("pressed", _on_button_pressed.bind(BTLeaf, "BTLeaf"))
	%ButtonPrint.connect("pressed", _on_button_pressed.bind(LeafPrint, "LeafPrint"))
	%ButtonWait.connect("pressed", _on_button_pressed.bind(LeafWait, "LeafWait"))
	%ButtonCondition.connect("pressed", _on_button_pressed.bind(LeafCondition, "LeafCondition"))
	%ButtonCall.connect("pressed", _on_button_pressed.bind(LeafCall, "LeafCall"))
	%ButtonTween.connect("pressed", _on_button_pressed.bind(LeafTween, "LeafTween"))
	%ButtonFSMEvent.connect("pressed", _on_button_pressed.bind(LeafFSMEvent, "LeafFSMEvent"))

	%ButtonComposite.connect("pressed", _on_button_pressed.bind(BTComposite, "BTComposite"))
	%ButtonSequence.connect("pressed", _on_button_pressed.bind(BTSequence, "BTSequence"))
	%ButtonSelector.connect("pressed", _on_button_pressed.bind(BTSelector, "BTSelector"))
	%ButtonSimpleParallel.connect("pressed", _on_button_pressed.bind(BTSimpleParallel, "BTSimpleParallel"))
	%ButtonRandom.connect("pressed", _on_button_pressed.bind(BTRandom, "BTRandom"))
	%ButtonRandomSequence.connect("pressed", _on_button_pressed.bind(BTRandomSequence, "BTRandomSequence"))
	%ButtonRandomSelector.connect("pressed", _on_button_pressed.bind(BTRandomSelector, "BTRandomSelector"))
	%ButtonIntegratedFSM.connect("pressed", _on_button_pressed.bind(BTIntegratedFSM, "BTIntegratedFSM"))

	%ButtonDecorator.connect("pressed", _on_button_pressed.bind(BTDecorator, "BTDecorator"))
	%ButtonAlwaysFail.connect("pressed", _on_button_pressed.bind(BTAlwaysFail, "BTAlwaysFail"))
	%ButtonAlwaysSucceed.connect("pressed", _on_button_pressed.bind(BTAlwaysSucceed, "BTAlwaysSucceed"))
	%ButtonLimiter.connect("pressed", _on_button_pressed.bind(BTLimiter, "BTLimiter"))
	%ButtonInverter.connect("pressed", _on_button_pressed.bind(BTInverter, "BTInverter"))
	%ButtonRepeat.connect("pressed", _on_button_pressed.bind(BTRepeat, "BTRepeat"))


func set_current_selection(new_selection):
	current_selection = new_selection


func update_version_text():
	%Version.text = "BehaviourToolkit v" + str(%UpdateManager.current_version)

func _on_button_pressed(type, name: String):
	# Determine placement mode
	var is_pressed_ctrl: bool = Input.is_key_pressed(KEY_CTRL)
	var is_pressed_shift: bool = Input.is_key_pressed(KEY_SHIFT)
	var is_pressed_alt: bool = Input.is_key_pressed(KEY_ALT)

	var placement_mode: PlacementMode

	if is_pressed_ctrl and is_pressed_alt:
		placement_mode = PlacementMode.REPLACE
	elif is_pressed_ctrl:
		placement_mode = PlacementMode.PARENT
	elif is_pressed_shift:
		placement_mode = PlacementMode.SIBLING
	else:
		placement_mode = PlacementMode.CHILD


	var new_node: BehaviourToolkit = type.new()

	# Check if name already exists
	var already_exists = false
	var count = 0
	for child in current_selection.get_children():
		if child.name.begins_with(name):
			count += 1
			already_exists = true

	if not already_exists:
		new_node.name = name
	else:
		new_node.name = name + str(count + 1)

	# Add new node to scene
	match placement_mode:
		# Add new node as child
		PlacementMode.CHILD:
			undo_redo.create_action("Add new Behaviour Node as child")

			undo_redo.add_do_method(current_selection, "add_child", new_node)
			undo_redo.add_undo_method(current_selection, "remove_child", new_node)

			undo_redo.add_do_method(new_node, "set_owner", current_selection.get_tree().edited_scene_root)

			undo_redo.commit_action()

		# Add new node as sibling
		PlacementMode.SIBLING:
			var current_selection_index = current_selection.get_index()

			undo_redo.create_action("Add new Behaviour Node as sibling")

			undo_redo.add_do_method(current_selection.get_parent(), "add_child", new_node)
			undo_redo.add_do_method(current_selection.get_parent(), "move_child", new_node, current_selection_index + 1)
			undo_redo.add_undo_method(current_selection.get_parent(), "remove_child", new_node)
		
			undo_redo.add_do_method(new_node, "set_owner", current_selection.get_tree().edited_scene_root)

			undo_redo.commit_action()

		# Add new node as parent
		PlacementMode.PARENT:
			undo_redo.create_action("Add new Behaviour Node as parent")

			undo_redo.add_do_method(current_selection, "replace_by", new_node)

			undo_redo.add_undo_method(new_node, "remove_child", current_selection)
			undo_redo.add_undo_method(new_node, "replace_by", current_selection)

			undo_redo.add_do_method(new_node, "add_child", current_selection)
			undo_redo.add_do_method(current_selection, "set_owner", current_selection.get_tree().edited_scene_root)

			undo_redo.commit_action()

		# Replace current node with new node
		PlacementMode.REPLACE:
			undo_redo.create_action("Replace Behaviour Node")

			undo_redo.add_do_method(current_selection, "replace_by", new_node)
			undo_redo.add_undo_method(new_node, "replace_by", current_selection)

			undo_redo.commit_action()



func _on_button_blackboard_pressed():
	dialog_blackboard.popup_centered()


func _on_file_dialog_new_blackboard_file_selected(path:String):
	var new_blackboard := Blackboard.new()
	ResourceSaver.save(new_blackboard, path)
		

func _on_update_manager_update_available():
	%LinkGithub.show()


func _on_update_manager_update_request_completed():
	update_version_text()


func search_change_visbility(node: Node, query: String):
	for child in node.get_children():
		search_change_visbility(child, query)

		if not child is Button:
			continue
		
		if query == "":
			child.show()
			continue

		if query.to_lower() in child.text.to_lower():
			child.show()
		else:
			child.hide()


func _on_search_bar_text_changed(new_text:String):
	search_change_visbility(toolbox, new_text)


func _on_toggle_search_bar_toggled(button_pressed:bool):
	%SearchBar.text = ""
	%SearchBar.emit_signal("text_changed", "")
	%SearchBar.visible = button_pressed

	# Focus search bar
	%SearchBar.grab_focus()


func _on_toggle_bt_toggled(button_pressed:bool):
	toolbox_bt.visible = button_pressed


func _on_toggle_fsm_toggled(button_pressed:bool):
	toolbox_fsm.visible = button_pressed
