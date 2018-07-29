function between(value, min, max) if value >= min and value <= max then return true end end
function signe(num) if num >= 0 then return 1 elseif num < 0 then return 0 end end
function sl(x1, y1, x2, y2) return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 ) end -- segment lengh
function slt(p1, p2) return math.sqrt( (p2.x - p1.x)^2 + (p2.y - p1.y)^2 ) end -- segment lengh using 2 tables
function round(num, decimals) return math.floor(num * 10^(decimals or 0) + 0.5) / 10^(decimals or 0) end
function rf(min, max, decimals) return math.random(min * decimals, max * decimals) / decimals end -- random float
function percent(chance) return math.random(0, 100) <= chance end -- return true if value < chance