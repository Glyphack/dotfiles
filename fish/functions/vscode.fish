function vscode --description "Open Visual Studio Code"
	switch (uname)
		case Linux
			code $argv
		case '*'
			/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code $argv
	end
end
