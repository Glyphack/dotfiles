function uninstall-appgate --description "Remove AppGate package and reset DNS resolver (macOS)"
  sudo pkgutil --forget com.github.munki.pkg.AppGate
  sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache
end
