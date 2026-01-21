function compress_vid --description "Compress video file using H.265 codec to MP4"
    ffmpeg -i $argv -vcodec libx265 -crf 28 -preset medium  -acodec aac -b 128k $argv.mp4
end
