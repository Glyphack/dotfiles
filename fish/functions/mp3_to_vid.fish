function mp3_to_vid
    ffmpeg -f lavfi -i color=c=blue:s=1280x720 -i $argv -shortest -fflags +shortest output.mp4
end
