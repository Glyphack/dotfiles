#!/usr/bin/env bash

set -euo pipefail

# Bigger mouse pointer
defaults write com.apple.universalaccess mouseDriverCursorSize -float 4.0

defaults write NSGlobalDomain AppleLanguages -array en
defaults write NSGlobalDomain AppleLocale -string en_US@currency=USD
defaults write NSGlobalDomain AppleMeasurementUnits -string Centimeters
defaults write NSGlobalDomain AppleMetricUnits -bool true

# Turn off Automatically adjust brightness
osascript -l JavaScript >/dev/null <<'JXA'
ObjC.import('AppKit');
ObjC.bindFunction('dlopen', ['void *', ['char *', 'int']]);
$.dlopen('/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices', 1);
ObjC.bindFunction('DisplayServicesHasAmbientLightCompensation', ['bool', ['uint32']]);
ObjC.bindFunction('DisplayServicesEnableAmbientLightCompensation', ['int', ['uint32', 'bool']]);
var screens = $.NSScreen.screens;
for (var i = 0; i < screens.count; i++) {
  var id = ObjC.unwrap(screens.objectAtIndex(i).deviceDescription.objectForKey('NSScreenNumber'));
  if ($.DisplayServicesHasAmbientLightCompensation(id)) {
    $.DisplayServicesEnableAmbientLightCompensation(id, false);
  }
}
JXA

for t in public.plain-text public.text public.source-code public.script public.shell-script public.python-script public.ruby-script public.json public.yaml public.xml com.apple.log public.comma-separated-values-text public.css public.c-source public.c-header public.c-plus-plus-source public.c-plus-plus-header public.swift-source com.sun.java-source com.netscape.javascript-source com.microsoft.typescript; do duti -s dev.zed.Zed $t all; done
duti -s md.obsidian net.daringfireball.markdown all
