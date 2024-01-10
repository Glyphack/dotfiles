#!/usr/bin/env bash

JAVA_V="corretto-21.0.1.12.1"
asdf plugin-add java https://github.com/halcyon/asdf-java.git
asdf install java $JAVA_V
asdf global java JAVA_V

export ASDF_NODEJS_LEGACY_FILE_DYNAMIC_STRATEGY latest_available
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs 18.17.1
asdf install nodejs latest
asdf global nodejs latest


asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf install ruby 2.7.7
asdf install ruby "$(asdf latest ruby)"
