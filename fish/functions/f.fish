function f
    set -l tmp_file (mktemp)
    file-manager.sh $tmp_file
    set -l dest_dir (cat $tmp_file)
    rm -f $tmp_file
    if test -n "$dest_dir"; and test -d "$dest_dir"
        cd $dest_dir
    end
end
