function compress_vid
    ffmpeg -i $argv -vcodec libx265 -crf 28 -preset medium  -acodec aac -b 128k $argv.mp4
end
