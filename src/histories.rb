#---------------------------------------------------------------------
# Histories class
#
# This class stores up various histories, such as search term history,
# command history, and folding history. It saves and loads histories
# from the history file.
#---------------------------------------------------------------------

class Histories

	require 'yaml'

	attr_accessor :file, :search, :replace, :line_number, \
	:command, :script, :start_folding, :end_folding

	def initialize
		@file = $histories_file
		@search = []
		@replace = []
		@line_number = []
		@script = []
		@command = []
		@start_folding = []
		@end_folding = []
		read
	end

	# Save histories to the file.
	def save
		return if @file.nil?
		# If file exists, read first so we can append changes.
		read if File.exist?(@file)
		# Only save some of them.
		hists = {
			"search" => @search.last(1000),
			"replace" => @replace.last(1000),
			"command" => @command.last(1000),
			"script" => @script.last(1000),
			"start_folding" => @start_folding.last(1000),
			"end_folding" => @end_folding.last(1000)
		}
		begin
			File.open(@file,"w"){|file|
				YAML.dump(hists,file)
			}
		rescue
			$screen.write_message("Unable to save histories.")
		end
	end

	# Read histories from the file.
	def read
		if (@file.nil?) || (!File.exist?(@file))
			return
		end
		hists = YAML.load_file(@file)
		if !hists
			return
		end
		hists.default = []
		@search = @search.reverse.concat(hists["search"].reverse).uniq.reverse
		@replace = @replace.reverse.concat(hists["replace"].reverse).uniq.reverse
		@command = @command.reverse.concat(hists["command"].reverse).uniq.reverse
		@script = @script.reverse.concat(hists["script"].reverse).uniq.reverse
		@start_folding = @start_folding.reverse.concat(hists["start_folding"].reverse).uniq.reverse
		@end_folding = @end_folding.reverse.concat(hists["end_folding"].reverse).uniq.reverse
	end

end

# end of Histories class
#---------------------------------------------------------------------

