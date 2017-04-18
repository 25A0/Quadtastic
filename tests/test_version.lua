local Version = require("Quadtastic.Version")

-- Check simple format
do
	local s = "v1.2.4"
	local v = Version(s)
	assert(type(v.major) == "number")
	assert(v.major == 1)
	assert(type(v.minor) == "number")
	assert(v.minor == 2)
	assert(type(v.patch) == "number")
	assert(v.patch == 4)
end

-- Check format that includes `git decribe` information
do
	local s = "v1.2.4-12-aszxc123"
	local v = Version(s)
	assert(v.major == 1)
	assert(v.minor == 2)
	assert(v.patch == 4)
end

-- Check that parsing fails if no patch version is given
do
	local s = "v1.2"
	local success, more = pcall(Version, s)
	assert(not success)
end

-- Check that parsing fails if no patch or minor version is given
do
	local s = "v1"
	local success, more = pcall(Version, s)
	assert(not success)
end

-- Check to_string method
do
	local s = "v1.2.4"
	local v = Version(s)
	assert("1.2.4" == Version.to_string(v))
	assert("1.2.4" == string.format("%s", v))
end

-- Check equality
do
	local s1 = "v1.2.4"
	local s2 = "1.2.4-123-zxc"
	local v1 = Version(s1)
	local v2 = Version(s2)
	assert(v1 == v2)
	assert(Version.equals(v1, v2))
end

-- Check inequality
do
	local s1 = "v1.2.4"
	local s2 = "1.2.5-123-zxc"
	local s3 = "1.3.4-123-zxc"
	local s4 = "v2.2.4"
	local v1 = Version(s1)
	local v2 = Version(s2)
	local v3 = Version(s3)
	local v4 = Version(s4)
	assert(v1 ~= v2)
	assert(v1 ~= v3)
	assert(v1 ~= v4)

	assert(v2 ~= v3)
	assert(v2 ~= v4)

	assert(v3 ~= v4)
end

-- Check comparator
do
	local s1 = "v1.2.4"
	local s2 = "1.2.5-123-zxc"
	local s3 = "1.3.4-123-zxc"
	local s4 = "v2.2.4"
	local v1 = Version(s1)
	local v2 = Version(s2)
	local v3 = Version(s3)
	local v4 = Version(s4)
	assert(v1 < v2)
	assert(v2 > v1)
	assert(v1 <= v2)
	assert(v2 >= v1)

	assert(v1 < v3)
	assert(v3 > v1)
	assert(v1 <= v3)
	assert(v3 >= v1)

	assert(v1 < v4)
	assert(v4 > v1)
	assert(v1 <= v4)
	assert(v4 >= v1)

	assert(v2 < v3)
	assert(v3 > v2)
	assert(v2 <= v3)
	assert(v3 >= v2)

	assert(v2 < v4)
	assert(v4 > v2)
	assert(v2 <= v4)
	assert(v4 >= v2)

	assert(v3 < v4)
	assert(v4 > v3)
	assert(v3 <= v4)
	assert(v4 >= v3)
end
