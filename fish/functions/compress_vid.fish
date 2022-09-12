function compress_vid
    ffmpeg -i $argv -vcodec h264 -acodec aac -strict -2 output.mp4
end
