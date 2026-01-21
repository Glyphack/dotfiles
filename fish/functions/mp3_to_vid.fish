function mp3_to_vid --description "Convert MP3 audio to video with blue background (1280x720)"
    ffmpeg -f lavfi -i color=c=blue:s=1280x720 -i $argv -shortest -fflags +shortest output.mp4
end
