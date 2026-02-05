function cpf --description "Copy file to clipboard (not content)"
    osascript -e "set the clipboard to (POSIX file "$PWD/$argv")"
end
