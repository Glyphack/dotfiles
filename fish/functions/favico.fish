function favico --description "Convert image to 32x32 favicon with transparent background"
convert $argv -background transparent -gravity Center -extent 1:1# -scale 32 file-32px.png
end
