
PROJECT = "GPS_Converter"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

sys = require("sys")


local gps_data = {
raw_lat = nil,
raw_lon = nil,
latitude = nil,
longitude = nil,
speed = nil,
altitude = nil,
satellites = nil,
fix_status = false,
last_update = nil
}


sys.taskInit(function()
log.info("GPS", "GNSS эхлүүлж байна...")
pm.power(pm.GPS, true)
uart.setup(2, 115200)
libgnss.bind(2)
libgnss.debug(true)
log.info("GPS", "GPS систем идэвхжсэн")
end)


function convert_gps_coordinate(coord_string, is_longitude)
if not coord_string then return nil end

local coord = tonumber(coord_string)
if not coord then return nil end


local degrees = math.floor(coord / 100)
local minutes = coord - (degrees * 100)


local decimal_degrees = degrees + (minutes / 60)

log.info("GPS_CONVERT",
"Түүхий утга:", coord_string,
"Градус:", degrees,
"Минут:", minutes,
"Хөрвүүлсэн:", decimal_degrees
)

return decimal_degrees
end


function update_gps_data()
local locStr = libgnss.locStr()
log.info("GPS_RAW", "locStr():", locStr)

if locStr then

local parts = {}
for part in locStr:gmatch("([^,]+)") do
table.insert(parts, part)
end

log.info("GPS_PARTS", "Хэсгүүдийн тоо:", #parts)
for i, part in ipairs(parts) do
log.info("GPS_PART", i.."-р хэсэг:", part)
end

if #parts >= 2 then

gps_data.raw_lat = parts[1]
gps_data.raw_lon = parts[2]


gps_data.latitude = convert_gps_coordinate(parts[1], false)
gps_data.longitude = convert_gps_coordinate(parts[2], true)

gps_data.last_update = os.time()

log.info("GPS_COORD",
"Түүхий өргөрөг:", gps_data.raw_lat,
"Түүхий уртраг:", gps_data.raw_lon
)
log.info("GPS_COORD",
"Хөрвүүлсэн өргөрөг:", gps_data.latitude and string.format("%.6f", gps_data.latitude) or "nil",
"Хөрвүүлсэн уртраг:", gps_data.longitude and string.format("%.6f", gps_data.longitude) or "nil"
)
else
log.warn("GPS", "Координатын хэсгүүд хангалтгүй")
end


get_additional_gps_info()
return true
else
log.info("GPS", "locStr() nil буцааж байна")
return false
end
end


function get_additional_gps_info()

if libgnss.getLocation then
local location = libgnss.getLocation()
if location then

if location.speed then
gps_data.speed = location.speed
log.info("GPS_EXTRA", "Хурд:", gps_data.speed, "км/ц")
end


if location.alt then
gps_data.altitude = location.alt
log.info("GPS_EXTRA", "Өндөр:", gps_data.altitude, "метр")
end


if location.num then
gps_data.satellites = location.num
log.info("GPS_EXTRA", "Сансрын хөлгүүд:", gps_data.satellites)
end
else
log.info("GPS", "libgnss.getLocation() nil буцааж байна")
end
else
log.info("GPS", "libgnss.getLocation() функц байхгүй")
end
end


function print_gps_data()
log.info("=== GPS МЭДЭЭЛЭЛ ===")
log.info("Төлөв:", gps_data.fix_status and "ТОГТСОН" or "ТОГТООГҮЙ")

if gps_data.fix_status then
log.info("Түүхий өргөрөг:", gps_data.raw_lat or "N/A")
log.info("Түүхий уртраг:", gps_data.raw_lon or "N/A")

if gps_data.latitude then
log.info("Өргөрөг (DD.DDDDDD):", string.format("%.6f", gps_data.latitude))
else
log.info("Өргөрөг: Тодорхойгүй")
end

if gps_data.longitude then
log.info("Уртраг (DDD.DDDDDD):", string.format("%.6f", gps_data.longitude))
else
log.info("Уртраг: Тодорхойгүй")
end

if gps_data.speed then
log.info("Хурд:", gps_data.speed, "км/ц")
else
log.info("Хурд: Тодорхойгүй")
end

if gps_data.altitude then
log.info("Өндөр:", gps_data.altitude, "метр")
else
log.info("Өндөр: Тодорхойгүй")
end

if gps_data.satellites then
log.info("Сансрын хөлгүүд:", gps_data.satellites)
end

if gps_data.last_update then
log.info("Шинэчлэгдсэн:", os.date("%Y-%m-%d %H:%M:%S", gps_data.last_update))
end
else
log.info("Байршил тогтоогүй байна")
end
log.info("====================")
end


sys.subscribe("GNSS_STATE", function(event, ticks)
log.info("GNSS", "Төлөв:", event)

if event == "FIXED" then
gps_data.fix_status = true
log.info("GPS", "Байршил тогтсон!")
update_gps_data()

elseif event == "LOSE" then
gps_data.fix_status = false
log.info("GPS", "Байршил алдагдсан")
end
end)


sys.timerLoopStart(function()
if gps_data.fix_status then
update_gps_data()
end
end, 5000)


sys.timerLoopStart(function()
print_gps_data()
end, 15000)


sys.taskInit(function()
sys.wait(5000)
log.info("SYSTEM", "GPS координат хөрвүүлэгч систем идэвхтэй")
log.info("SYSTEM", "Гадаа нээлттэй газар байршил тогтоно")
end)


if wdt then
wdt.init(9000)
sys.timerLoopStart(wdt.feed, 3000)
end

sys.run()
