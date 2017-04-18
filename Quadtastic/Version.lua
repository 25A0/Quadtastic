local Version = {}

function Version.equals(v1, v2)
  return v1.major == v2.major and
         v1.minor == v2.minor and
         v1.patch == v2.patch
end

function Version.older_than(v1, v2)
  return v1.major < v2.major or v1.major == v2.major and
                                (v1.minor < v2.minor or v1.minor == v2.minor and
                                                        v1.patch < v2.patch)
end

function Version.newer_than(v1, v2)
  return not Version.equals(v1, v2) and Version.older_than(v2, v1)
end

function Version.to_string(v)
  return string.format("%d.%d.%d", v.major, v.minor, v.patch)
end

function Version.new(version_string)
  local v = {}
  local major, minor, patch = string.gmatch(version_string,
                                            "v?(%d+)%.(%d+)%.(%d+).*")()
  if not (major and minor and patch) then
    error(string.format("Cannot parse version from version string %s",
                        version_string))
  end
  v.major = tonumber(major)
  v.minor = tonumber(minor)
  v.patch = tonumber(patch)
  setmetatable(v, {
    __eq = Version.equals,
    __lt = Version.older_than,
    __tostring = Version.to_string,
  })

  return v
end

setmetatable(Version, {
  __call = function(_, ...) return Version.new(...) end,
})


return Version
