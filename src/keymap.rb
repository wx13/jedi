#---------------------------------------------------------------------
# KeyMap class
#
# This class defines the keymapping.
# There are 5 sections:
#     1. commandlist -- universal keymapping
#     2. editmode_commandlist -- keymappings when in edit mode
#     3. viewmode_commandlist -- keymappings in view mode
#     4. extra_commandlist -- ones that don't fit
#     5. togglelist -- for toggling states on/off
#     	 These get run when buffer.toggle is run.
#---------------------------------------------------------------------

class KeyMap

	attr_accessor \
		:commandlist, :editmode_commandlist, :extramode_commandlist, \
		:viewmode_commandlist, :togglelist

	def initialize

		@commandlist = {
			:ctrl_q => "buffer = $buffers.close",
			:up => "buffer.cursor_up",
			:down => "buffer.cursor_down",
			:right => "buffer.cursor_right",
			:left => "buffer.cursor_left",
			:pagedown => "buffer.page_down",
			:pageup => "buffer.page_up",
			:home => "buffer.goto_line(0)",
			:home2 => "buffer.goto_line(0)",
			:end => "buffer.goto_line(-1)",
			:end2 => "buffer.goto_line(-1)",
			:ctrl_v => "buffer.page_down",
			:ctrl_y => "buffer.page_up",
			:ctrl_e => "buffer.cursor_eol",
			:ctrl_a => "buffer.cursor_sol",
			:ctrl_n => "buffer = $buffers.next_page",
			:ctrl_b => "buffer = $buffers.prev_page",
			:ctrl_x => "buffer.mark",
			:ctrl_p => "buffer.copy",
			:ctrl_w => "buffer.search",
			:ctrl_g => "buffer.goto_line",
			:ctrl_o => "buffer.save",
			:ctrl_f => "buffer = $buffers.open",
			:ctrl_z => "$buffers.suspend",
			:ctrl_t => "buffer.toggle",
			:ctrl_6 => "buffer.extramode = true",
			:ctrl_s => "enter_command",
			:ctrl_l => "$buffers.next_buffer",
			:shift_up => "buffer.screen_down",
			:shift_down => "buffer.screen_up",
			:shift_right => "buffer.screen_right",
			:shift_left => "buffer.screen_left",
			:ctrl_up => "$buffers.screen_down",
			:ctrl_down => "$buffers.screen_up",
			:ctrl_left => "buffer.undo",
			:ctrl_right => "buffer.redo",
			:ctrlshift_left => "buffer.revert_to_saved",
			:ctrlshift_right => "buffer.unrevert_to_saved",
			:left_click => "$buffers.mouse_select",
			:middle_click => "$buffers.mouse_mark",
			:scroll_up => "buffer.screen_up(4)",
			:scroll_down => "buffer.screen_down(4)",
			:ctrl_scroll_up => "$buffers.screen_up(4)",
			:ctrl_scroll_down => "$buffers.screen_down(4)",
		}
		@commandlist.default = ""

		@extramode_commandlist = {
			"b" => "buffer.bookmark",
			"g" => "buffer.goto_bookmark",
			"c" => "buffer.center_screen",
			"0" => "$buffers.all_on_one_page",
			"1" => "$buffers.move_to_page(1)",
			"2" => "$buffers.move_to_page(2)",
			"3" => "$buffers.move_to_page(3)",
			"4" => "$buffers.move_to_page(4)",
			"5" => "$buffers.move_to_page(5)",
			"6" => "$buffers.move_to_page(6)",
			"7" => "$buffers.move_to_page(7)",
			"8" => "$buffers.move_to_page(8)",
			"9" => "$buffers.move_to_page(9)",
			"[" => "buffer.undo",
			"]" => "buffer.redo",
			"{" => "buffer.revert_to_saved",
			"}" => "buffer.unrevert_to_saved",
			"l" => "buffer.justify",
			"s" => "run_script",
			"h" => "buffer.hide_lines",
			"u" => "buffer.unhide_lines",
			"U" => "buffer.unhide_all",
			"H" => "buffer.hide_by_pattern",
			"R" => "buffer.reload",
			"r" => "$screen.update_screen_size; $buffers.update_screen_size",
			"f" => "buffer = $buffers.duplicate",
			"i" => "buffer.indentation_facade",
			"I" => "buffer.indentation_real",
			"x" => "buffer.multimark",
			"C" => "$screen.set_cursor_color",
			:ctrl_n => "$buffers.menu",
			:up => "buffer.cursor_up",
			:down => "buffer.cursor_down",
			:right => "buffer.cursor_right",
			:left => "buffer.cursor_left",
			:pagedown => "buffer.page_down",
			:pageup => "buffer.page_up",
			:home => "buffer.goto_line(0)",
			:end => "buffer.goto_line(-1)",
			:home2 => "buffer.goto_line(0)",
			:end2 => "buffer.goto_line(-1)",
			:ctrl_x => "buffer.mark",
			:ctrl_6 => "buffer.sticky_extramode ^= true",
			:ctrl_u => "$copy_buffer.menu",
			:tab => "eval(buffer.menu($keymap.extramode_commandlist,'extramode').last)"
		}
		@extramode_commandlist.default = ""

		@editmode_commandlist = {
			:backspace => "buffer.backspace",
			:backspace2 => "buffer.backspace",
			:ctrl_h => "buffer.backspace",
			:enter => "buffer.newline",
			:ctrl_k => "buffer.cut",
			:ctrl_u => "buffer.paste",
			:ctrl_m => "buffer.newline",
			:ctrl_j => "buffer.newline",
			:ctrl_d => "buffer.delete",
			:ctrl_r => "buffer.search_and_replace",
			:tab => "buffer.addchar(c)",
		}
		@editmode_commandlist.default = ""

		@viewmode_commandlist = {
			"q" => "buffer = $buffers.close",
			"k" => "buffer.cursor_up(1)",
			"j" => "buffer.cursor_down(1)",
			"l" => "buffer.cursor_right",
			"h" => "buffer.cursor_left",
			" " => "buffer.page_down",
			"b" => "buffer.page_up",
			"." => "buffer = $buffers.next_buffer",
			"," => "buffer = $buffers.prev_buffer",
			"/" => "buffer.search",
			"n" => "buffer.search(:forward)",
			"N" => "buffer.search(:backward)",
			"g" => "buffer.goto_line",
			"i" => "buffer.toggle_editmode",
			"[" => "buffer.undo",
			"]" => "buffer.redo",
			"{" => "buffer.revert_to_saved",
			"}" => "buffer.unrevert_to_saved",
			"J" => "buffer.screen_up",
			"K" => "buffer.screen_down",
			"H" => "buffer.screen_left",
			"L" => "buffer.screen_right",
			":" => "enter_command"
		}
		@viewmode_commandlist.default = ""

		@togglelist = {
			"E" => "@editmode = :edit",
			"e" => "@editmode = :view",
			"A" => "@autoindent = true",
			"a" => "@autoindent = false",
			"I" => "@insertmode = true",
			"i" => "@insertmode = false",
			"W" => "@linewrap = true",
			"w" => "@linewrap = false",
			"c" => "@cursormode = :col",
			"C" => "@cursormode = :loc",
			"r" => "@cursormode = :row",
			"f" => "@cursormode = :multi",
			"S" => "@syntax_color = true",
			"s" => "@syntax_color = false",
			"-" => "$buffers.vstack",
			"|" => "$buffers.hstack",
			"M" => "$screen.toggle_mouse(true)",
			"m" => "$screen.toggle_mouse(false)",
			"D" => "@enforce_ascii = true",
			"d" => "@enforce_ascii = false",
			"B" => "@backups = $backup_prefix",
			"b" => "@backups = false",
		}
		@togglelist.default = ""

	end


	def extramode_command(keycode)
		cmd = @extramode_commandlist[keycode]
		return(cmd)
	end

	# First try the normal command list.  If that returns nothing,
	# then try the edit/view command list.
	def command(keycode, editmode)
		cmd = @commandlist[keycode]
		if cmd == ""
			case editmode
				when :edit then cmd = @editmode_commandlist[keycode]
				when :view then cmd = @viewmode_commandlist[keycode]
			end
		end
		if cmd == ""
			return nil
		else
			return cmd
		end
	end

end

# end of KeyMap class
#---------------------------------------------------------------------

