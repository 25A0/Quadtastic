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
