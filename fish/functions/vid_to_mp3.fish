function vid_to_mp3
    set output_file (path change-extension 'mp3' $argv)
    ffmpeg -i  $argv -vn -acodec mp3 $output_file
end
