-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "GPS_Data_Logger"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

sys = require("sys")

-- GPS мэдээллийг хадгалах хувьсагчид
local gps_data = {
    latitude = nil,      -- Өргөрөг
    longitude = nil,     -- Уртраг
    speed = nil,         -- Хурд (км/ц)
    altitude = nil,      -- Өндөр (метр)
    satellites = nil,    -- Сансрын хөлгүүдийн тоо
    fix_status = false,  -- Байршил тогтсон эсэх
    last_update = nil    -- Сүүлийн шинэчлэлтийн хугацаа
}

-- GPS эхлүүлэх
sys.taskInit(function()
    log.info("GPS", "GNSS эхлүүлж байна...")
    pm.power(pm.GPS, true)
    uart.setup(2, 115200)
    libgnss.bind(2)
    libgnss.debug(false)
    log.info("GPS", "GPS систем идэвхжсэн. Гадаа нээлттэй газар байршил тогтоно.")
end)

-- GPS мэдээлэл шинэчлэх функц
function update_gps_data()
    local locStr = libgnss.locStr()
    if locStr then
        -- Координатыг задлах
        local parts = {}
        for part in locStr:gmatch("[^,]+") do
            table.insert(parts, part)
        end

        if #parts >= 2 then
            gps_data.latitude = tonumber(parts[1])
            gps_data.longitude = tonumber(parts[2])
            gps_data.last_update = os.time()

            log.info("GPS_COORD", "Өргөрөг:", gps_data.latitude, "Уртраг:", gps_data.longitude)
        end

        -- Нэмэлт мэдээлэл авах
        get_additional_gps_info()
        return true
    end
    return false
end

-- Нэмэлт GPS мэдээлэл авах (хурд, өндөр)
function get_additional_gps_info()
    -- Төрөл бүрийн аргуудыг турших
    local location = nil

    -- Эхний арга
    if libgnss.getLocation then
        location = libgnss.getLocation()
    -- Хоёр дахь арга
    elseif libgnss.getGps then
        location = libgnss.getGps()
    end

    if location then
        -- Хурд
        if location.speed then
            gps_data.speed = location.speed
            log.info("GPS_SPEED", "Хурд:", gps_data.speed, "км/ц")
        end

        -- Өндөр
        if location.alt then
            gps_data.altitude = location.alt
            log.info("GPS_ALT", "Өндөр:", gps_data.altitude, "метр")
        end

        -- Сансрын хөлгүүд
        if location.num then
            gps_data.satellites = location.num
            log.info("GPS_SAT", "Сансрын хөлгүүд:", gps_data.satellites)
        end
    else
        log.info("GPS", "Нэмэлт мэдээлэл авах боломжгүй")
    end
end

-- GPS мэдээллийг хэвлэх функц
function print_gps_data()
    log.info("=== GPS МЭДЭЭЛЭЛ ===")
    log.info("Төлөв:", gps_data.fix_status and "ТОГТСОН" or "ТОГТООГҮЙ")

    if gps_data.fix_status then
        log.info("Өргөрөг:", gps_data.latitude)
        log.info("Уртраг:", gps_data.longitude)

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
        log.info("Гадаа нээлттэй газар байршил тогтоно")
    end
    log.info("====================")
end

-- GNSS төлөв өөрчлөгдөх үед
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

-- GPS мэдээлэл автоматаар шинэчлэх (10 секунд тутамд)
sys.timerLoopStart(function()
    if gps_data.fix_status then
        update_gps_data()
    end
end, 10000)

-- GPS мэдээллийг хэвлэх (30 секунд тутамд)
sys.timerLoopStart(function()
    print_gps_data()
end, 30000)

-- GPS мэдээллийг авах жишээ
sys.taskInit(function()
    sys.wait(10000) -- 10 секунд хүлээх

    while true do
        sys.wait(5000)

        if gps_data.fix_status then
            -- GPS мэдээллийг ашиглах
            log.info("GPS_USAGE",
                "Байршил: ", gps_data.latitude, ", ", gps_data.longitude,
                " | Хурд: ", gps_data.speed or "N/A", " км/ц",
                " | Өндөр: ", gps_data.altitude or "N/A", " м"
            )
        else
            log.info("GPS", "Байршил хайж байна...")
        end
    end
end)

-- Watchdog тохиргоо
if wdt then
    wdt.init(9000)
    sys.timerLoopStart(wdt.feed, 3000)
end

sys.run()
