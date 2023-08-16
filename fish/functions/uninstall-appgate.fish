function uninstall-appgate
  sudo pkgutil --forget com.github.munki.pkg.AppGate                                                                                  │
  sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache                                       │
end
