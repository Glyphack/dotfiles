return {
	name = "spotless apply",
	builder = function()
		return {
			cmd = { "./gradlew" },
			args = { "spotlessApply" },
		}
	end,
	condition = {
		filetype = { "kotlin" },
	},
}
