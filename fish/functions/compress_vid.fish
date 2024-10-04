function compress_vid
    ffmpeg -i $argv -vcodec libx264 -crf 23 -preset medium -vf "scale=-1:600" -acodec aac -b:a 128k output.mp4

end
