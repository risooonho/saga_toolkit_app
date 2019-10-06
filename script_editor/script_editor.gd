extends HSplitContainer

const Errors = preload("res://util/errors.gd")
const ScriptParser = preload("res://script_parser.gd")
const HtmlExporter = preload("res://html_exporter/html_exporter.gd")

signal script_parsed(path, result)

onready var _file_list = get_node("VSplitContainer/ScriptList")
onready var _text_editor = get_node("TextEditor")
onready var _scene_list = get_node("VSplitContainer/VBoxContainer/SceneList")


var _scripts_data = {}


func _ready():
	_text_editor.syntax_highlighting = true
	var comment_color = Color(0.5, 0.5, 0.5)
	_text_editor.add_color_override("number_color", _text_editor.get_color("font_color"))
	_text_editor.add_color_override("function_color", _text_editor.get_color("font_color"))
	_text_editor.add_color_region("<", ">", comment_color)
	_text_editor.add_color_region("(", ")", comment_color)
	_text_editor.add_color_region("/*", "*/", comment_color)
	_text_editor.add_color_region("//", "", comment_color, false)


func open_script(path):
	
	if _scripts_data.has(path):
		print("Script ", path, " is already open")
		return
	
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not load file ", path, ", ", Errors.get_message(err))
		return
	var text = f.get_as_text()
	f.close()
	
	var filename = path.get_file()
	var i = _file_list.get_item_count()
	_file_list.add_item(filename)
	_file_list.set_item_metadata(i, path)
	
	var res = ScriptParser.parse_text(text)
	
	_scripts_data[path] = res.data
	_file_list.select(i)
	_set_current_script(path)
	
	emit_signal("script_parsed", path, res)


func _set_current_script(path):
	var data = _scripts_data[path]
	
	_text_editor.text = data.text
	
	_scene_list.clear()
	for scene in data.scenes:
		var i = _scene_list.get_item_count()
		_scene_list.add_item(scene.title)
		_scene_list.set_item_metadata(i, scene)


func _on_SceneList_item_selected(index):
	var scene = _scene_list.get_item_metadata(index)
	
	# TODO Need a function to center that line
	# Hack: scroll to bottom first
	_text_editor.cursor_set_line(_text_editor.get_line_count() - 1)
	
	_text_editor.cursor_set_line(scene.line_index)


func _get_current_script_path():
	var selection = _file_list.get_selected_items()
	if len(selection) == 0:
		return null
	return _file_list.get_item_metadata(selection[0])


func export_as_html():
	var script_path = _get_current_script_path()
	if script_path == null:
		printerr("No selected script")
		return
	var data = _scripts_data[script_path]
	var exporter = HtmlExporter.new()
	var output_path = script_path.get_basename() + ".html"
	exporter.export_script(data, output_path)
	OS.shell_open(output_path)


func _on_ScriptList_item_selected(index):
	var path = _file_list.get_item_metadata(index)
	_set_current_script(path)


