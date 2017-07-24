local Path = require ("Quadtastic.Path")

-- test toString
do
  local tests = {
    "/",
    "/dev/null",
    "/foo/bar/file.c",
    "C:/windows/path",
  }
  for _,test in ipairs(tests) do
    assert(tostring(Path(test)) == test,
           "Serialization of " .. test .. "did not match")
  end
end

-- test concatenation
do
  local path = Path("/")
  assert(tostring(path .. "foo") == "/foo")
  assert(tostring(path) == "/", "Concatenation changed the original path")
  assert(tostring(path .. "foo" .. "bar" .. "code.c" == "/foo/bar/code.c"))
end

-- test compacting paths
do
  assert(tostring(Path("/foo/./bar"):compact()) == "/foo/bar")
  assert(tostring(Path("/foo/../bar"):compact()) == "/bar")
  assert(tostring(Path("/foo/../../bar"):compact()) == "/bar")
end

-- test relative paths
do
  local basepath = Path("/foo/bar/some/nested/path")
  assert(Path("/foo/bar/some/other/path"):get_relative_to(basepath) ==
         "./../../other/path")
  assert(Path("/foo/bar/some/nested/path/file"):get_relative_to(basepath) ==
         "./file")
  assert(Path("/foo/bar/"):get_relative_to(basepath) ==
         "./../../..")
end

-- test constructing the parent of a path
do
  local basepath = Path("/foo/bar/some/file.lua")
  assert(tostring(basepath:parent()) == "/foo/bar/some")
  assert(tostring(basepath:parent() .. "other_file.lua") ==
         "/foo/bar/some/other_file.lua")
  assert(tostring(Path("/"):parent()) == "/")
end

-- test basename and dirname
do
  assert(tostring(Path("/foo/bar/file.c"):dirname()) == "/foo/bar")
  assert(tostring(Path("/foo/bar/file.c"):basename()) == "file.c")
  assert(tostring(Path("/"):dirname()) == "/")
  assert(tostring(Path("/"):basename()) == "")
end

-- test splitting off the extension
do
  do
    local fname, ext = Path.split_extension(Path("/foo/bar/file.c"):basename())
    assert(fname == "file")
    assert(ext == "c")
  end
  do
    local fname, ext = Path.split_extension(Path("/foo/bar/file.c.old"):basename())
    assert(fname == "file.c")
    assert(ext == "old")
  end
  do
    local fname, ext = Path.split_extension(Path("/foo/bar/filec"):basename())
    assert(fname == "filec")
    assert(ext == "")
  end
end

-- test detecting absolute paths
do
  assert(Path.is_absolute_path("/"))
  assert(Path.is_absolute_path("/foo/./"))
  assert(Path.is_absolute_path("C:/foo/./"))

  assert(not Path.is_absolute_path("Drive:/foo/./"))
  assert(not Path.is_absolute_path("./foo/./"))
  assert(not Path.is_absolute_path("../foo/./"))
  assert(not Path.is_absolute_path("../C:/./"))
  assert(not Path.is_absolute_path("foo/./"))
end

-- test detecting relative paths
do
  assert(Path.is_relative_path("./"))
  assert(Path.is_relative_path("./foo/./"))

  assert(not Path.is_relative_path("Drive:/foo/./"))
  assert(not Path.is_relative_path("/foo/./"))
  assert(not Path.is_relative_path("C:/foo/./"))
  assert(not Path.is_relative_path(".././foo/./"))
  assert(not Path.is_relative_path("../C:/./"))
  assert(not Path.is_relative_path("foo/./"))
end
