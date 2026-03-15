function ,unzip --description "Unzip archive into a directory named after it"
    set -l archive $argv[1]
    set -l dir (basename $archive .zip)
    unzip $archive -d $dir
end
