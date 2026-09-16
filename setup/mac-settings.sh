#!/usr/bin/env bash

# Bigger mouse pointer
defaults write com.apple.universalaccess mouseDriverCursorSize -float 4.0

defaults write NSGlobalDomain AppleLanguages -array en
defaults write NSGlobalDomain AppleLocale -string en_US@currency=USD
defaults write NSGlobalDomain AppleMeasurementUnits -string Centimeters
defaults write NSGlobalDomain AppleMetricUnits -bool true
