function vid_to_mp3
    set input_file $argv
    
    # Check if input starts with https
    if string match -q 'https*' $input_file
        # Download with yt-dlp to /tmp
        set temp_video "/tmp/vid_to_mp3_"(random)
        yt-dlp -o $temp_video "$input_file" >/dev/null 2>&1
        
        if test $status -ne 0
            echo "Error: Download failed" >&2
            return 1
        end
        
        # Find the actual downloaded file (yt-dlp may add extension)
        set downloaded_file (ls $temp_video.* 2>/dev/null | head -n 1)
        
        if test -z "$downloaded_file"
            echo "Error: Download failed" >&2
            return 1
        end
        
        # Use the downloaded file as input
        set input_file $downloaded_file
        
        # Create output filename based on video title
        set output_file (yt-dlp --get-filename -o '%(title)s.mp3' "$argv" 2>/dev/null)
    else
        # Use the provided file path
        set output_file (path change-extension 'mp3' $input_file)
    end
    
    # Convert to mp3
    ffmpeg -i $input_file -vn -acodec mp3 $output_file >/dev/null 2>&1
    
    if test $status -ne 0
        echo "Error: Conversion failed" >&2
        # Clean up temp file if we downloaded one
        if test -n "$downloaded_file"
            rm -f $downloaded_file
        end
        return 1
    end
    
    # Clean up temp file if we downloaded one
    if test -n "$downloaded_file"
        rm -f $downloaded_file
    end
    
    # Print only the output filename on success
    echo $output_file
end
