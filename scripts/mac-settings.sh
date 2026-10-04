#!/usr/bin/env bash

# Bigger mouse pointer
defaults write com.apple.universalaccess mouseDriverCursorSize -float 4.0

defaults write NSGlobalDomain AppleLanguages -array en
defaults write NSGlobalDomain AppleLocale -string en_US@currency=USD
defaults write NSGlobalDomain AppleMeasurementUnits -string Centimeters
defaults write NSGlobalDomain AppleMetricUnits -bool true

duti -s dev.zed.Zed public.text all

# Turn off "Automatically adjust brightness" (System Settings > Displays).
# Displays without a light sensor are skipped.
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
