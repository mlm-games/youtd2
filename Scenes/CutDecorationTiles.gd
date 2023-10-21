extends MainLoop


# Script to take a decoration tileset and transform into 3 variations:
# 1. original
# 2. cut version to place above and left of floor2
# 3. cut version to place above and right of floor2
# Note that this script adds +20 to height because it
# assumes that floor2 tiles are the full height brick
# versions. If floor2 tiles are "short" dirt tiles, then
# there will be a gap.

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scenes/CutDecorationTiles.gd" -- foo.png

const ARG_COUNT: int = 1

const CELL_WIDTH: int = 256
const CELL_HEIGHT: int = 512
const MARGIN: int = 4
const CELL_WIDTH_WITH_MARGIN: int = CELL_WIDTH + MARGIN * 2
const CELL_HEIGHT_WITH_MARGIN: int = CELL_HEIGHT + MARGIN * 2

const above_and_left_of_wall: PackedVector2Array = [Vector2(0, 429), Vector2(256, 299), Vector2(256, 0), Vector2(0, 0)]
const above_and_right_of_wall: PackedVector2Array = [Vector2(0, 299), Vector2(256, 429), Vector2(256, 0), Vector2(0, 0)]


func _initialize():
	print("CutDecorationTiles.gd begin")
	run()
	print("CutDecorationTiles.gd end")


# NOTE: returning true from _process() is the only way to
# quit from MainLoop.
func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	var arg_list: Array = OS.get_cmdline_user_args()

	print("Argument list: ", arg_list)

	if arg_list.size() != ARG_COUNT:
		print("Incorrect args provided. Expected 1 args: path to tileset.")
		print(arg_list)

		return

	var path: String = arg_list[0]

	process_path(path)


func process_path(path: String):
	print("Processing path:", path)

	var original_image: Image = Image.load_from_file(path)

	var column_count: int = int(original_image.get_width() / CELL_WIDTH_WITH_MARGIN)
	var row_count: int = int(original_image.get_height() / CELL_HEIGHT_WITH_MARGIN)
	var new_row_count: int = row_count * 3
	var new_column_count: int = column_count
	var new_tilesheet_width: int = new_column_count * CELL_WIDTH_WITH_MARGIN
	var new_tilesheet_height: int = new_row_count * CELL_HEIGHT_WITH_MARGIN

	var atlas_image: = Image.create(new_tilesheet_width, new_tilesheet_height, false, Image.FORMAT_RGBA8)

	for column in range(0, column_count):
		for row in range(0, row_count):
			for cell_x in range(0, CELL_WIDTH):
				for cell_y in range(0, CELL_HEIGHT):
					var cell_pos: Vector2 = Vector2(cell_x, cell_y)
					var tilesheet_x: int = cell_x + MARGIN + CELL_WIDTH_WITH_MARGIN * column
					var tilesheet_y: int = cell_y + MARGIN + CELL_HEIGHT_WITH_MARGIN * row
					var pixel: Color = original_image.get_pixel(tilesheet_x, tilesheet_y)

					var is_part_of_section_2: bool = need_to_copy_pixel(cell_pos, above_and_left_of_wall)
					var is_part_of_section_3: bool = need_to_copy_pixel(cell_pos, above_and_right_of_wall)

					var new_tilesheet_y_1: int = cell_y + MARGIN + CELL_HEIGHT_WITH_MARGIN * row * 3
					var new_tilesheet_y_2: int = new_tilesheet_y_1 + CELL_HEIGHT_WITH_MARGIN
					var new_tilesheet_y_3: int = new_tilesheet_y_2 + CELL_HEIGHT_WITH_MARGIN

					atlas_image.set_pixel(tilesheet_x, new_tilesheet_y_1, pixel)

					if is_part_of_section_2:
						atlas_image.set_pixel(tilesheet_x, new_tilesheet_y_2, pixel)

					if is_part_of_section_3:
						atlas_image.set_pixel(tilesheet_x, new_tilesheet_y_3, pixel)


	var original_filename: String = path.get_file()
	var new_path: String = path.replace(".png", "-cut.png")
	atlas_image.save_png(new_path)


func need_to_copy_pixel(pos: Vector2, polygon: PackedVector2Array):
	var pixel_is_in_poly: bool = Geometry2D.is_point_in_polygon(pos, polygon)
	
	return pixel_is_in_poly
