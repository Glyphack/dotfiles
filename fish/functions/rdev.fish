function rdev_kube_config --description 'Set up kube config for rdev'
  fx rdev assume-role > /tmp/role
  envsource /tmp/role
end

function rdev --wraps='fx rdev'
  fx rdev $argv
end
