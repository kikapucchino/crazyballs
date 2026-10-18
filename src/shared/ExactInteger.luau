-- Exact signed decimal arithmetic for bonus calculations. Never convert large values to doubles.
-- 1024 digits is a storage/resource guard, NOT a Go CRazy prize-design cap.
local Exact = { MaxDigits = 1024 }
function Exact.normalize(value)
	assert(type(value) == "string" and #value <= Exact.MaxDigits + 1, "Decimal string required (up to 1024 digits)")
	assert(string.match(value, "^%-?%d+$"), "Integer multiplier required; fractional rules are not configured")
	local negative = string.sub(value, 1, 1) == "-"
	local digits = if negative then string.sub(value, 2) else value
	digits = string.gsub(digits, "^0+", "")
	if digits == "" then return "0" end
	assert(#digits <= Exact.MaxDigits, "Decimal resource limit exceeded")
	return (if negative then "-" else "") .. digits
end
function Exact.multiplySmall(value, factor)
	value = Exact.normalize(value)
	assert(type(factor) == "number" and factor % 1 == 0 and factor >= 0 and factor <= 1000000, "Invalid base amount")
	local negative = string.sub(value, 1, 1) == "-"
	local digits = if negative then string.sub(value, 2) else value
	local result, carry = {}, 0
	for index = #digits, 1, -1 do
		local product = tonumber(string.sub(digits, index, index)) * factor + carry
		table.insert(result, tostring(product % 10))
		carry = math.floor(product / 10)
	end
	while carry > 0 do table.insert(result, tostring(carry % 10)); carry = math.floor(carry / 10) end
	local reversed = {}
	for index = #result, 1, -1 do table.insert(reversed, result[index]) end
	return Exact.normalize((if negative then "-" else "") .. table.concat(reversed))
end
function Exact.format(value)
	value = Exact.normalize(value)
	local sign = if string.sub(value, 1, 1) == "-" then "−" else ""
	local digits = if sign ~= "" then string.sub(value, 2) else value
	if #digits > 15 then return sign .. string.sub(digits, 1, 1) .. "." .. string.sub(digits, 2, 4) .. "e+" .. (#digits - 1) end
	local reversed = string.reverse(digits)
	local groups = string.gsub(reversed, "(%d%d%d)", "%1,")
	return sign .. string.gsub(string.reverse(groups), "^,", "")
end
return Exact
