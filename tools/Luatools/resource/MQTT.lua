PROJECT = "MQTT_GPS"
VERSION = "1.0.0"

sys = require("sys")
require "mqtt"

-- MQTT тохиргоо
local MQTT_HOST = "broker.emqx.io"
local MQTT_PORT = 1883
local MQTT_CLIENT_ID = "air780eg_" .. mobile.imei()
local MQTT_USERNAME = "samdanjamts.su@gmail.com"
local MQTT_PASSWORD = "MqttBroker2025#"
local MQTT_TOPIC = "gps/" .. mobile.imei()

-- GPS хувьсагчид
local current_lat = nil
local current_lon = nil
local mqtt_inited = false
local mqtt_client = nil

-- Watchdog тохируулах
if wdt then
    wdt.init(9000)
    sys.timerLoopStart(wdt.feed, 3000)
end

-- GPS эхлүүлэх
sys.taskInit(function()
    log.info("GPS", "GNSS эхлүүлж байна...")
    pm.power(pm.GPS, true)
    uart.setup(2, 115200)
    libgnss.bind(2)
    libgnss.debug(true)
end)

-- GNSS төлөв өөрчлөгдөх үед
sys.subscribe("GNSS_STATE", function(event, ticks)
    log.info("GNSS", "Төлөв:", event)

    if event == "FIXED" then
        local locStr = libgnss.locStr()
        if locStr then
            local lat_str, lon_str = locStr:match("([%d%.]+),([%d%.]+)")
            if lat_str and lon_str then
                current_lat = tonumber(lat_str)
                current_lon = tonumber(lon_str)
                log.info("COORD", "Өргөрөг:", current_lat, "Уртраг:", current_lon)

                -- MQTT клиент бэлэн бол координатыг илгээх
                if mqtt_inited and mqtt_client then
                    send_gps_data()
                end
            end
        end
    elseif event == "LOSE" then
        current_lat = nil
        current_lon = nil
        log.info("GPS", "Байршил алдагдсан")
    end
end)

-- GPS өгөгдлийг MQTT ашиглан илгээх
function send_gps_data()
    if current_lat and current_lon then
        local data = string.format('{"lat":%.6f,"lon":%.6f}', current_lat, current_lon)
        local result = mqtt_client:publish(MQTT_TOPIC, data, 1)
        if result then
            log.info("MQTT", "Координат илгээгдлээ:", data)
        else
            log.error("MQTT", "Илгээхэд алдаа гарлаа")
        end
    end
end

-- MQTT клиент эхлүүлэх
sys.taskInit(function()
    -- Сүлжээ бэлэн болохыг хүлээх
    log.info("NET", "Сүлжээг хүлээж байна...")
    sim.waitForSimReady()
    net.waitForNetReady()
    log.info("NET", "Сүлжээ бэлэн")

    -- MQTT клиент тохируулах
    mqtt_client = mqtt.create(nil, MQTT_HOST, MQTT_PORT, nil, MQTT_USERNAME, MQTT_PASSWORD, nil, nil, 240)

    mqtt_client:on("connect", function()
        log.info("MQTT", "Брокерт амжилттай холбогдлоо")
        mqtt_inited = true
        -- Холбогдсон үед GPS өгөгдөл илгээх
        if current_lat and current_lon then
            send_gps_data()
        end
    end)

    mqtt_client:on("reconnect", function()
        log.info("MQTT", "Брокерт дахин холбогдох гэж байна")
    end)

    mqtt_client:on("error", function(error)
        log.error("MQTT", "Алдаа:", error)
    end)

    -- MQTT холболт эхлүүлэх
    mqtt_client:connect()

    -- Тогтмол GPS өгөгдөл илгээх (30 секунд тутамд)
    while true do
        sys.wait(30000)
        if mqtt_inited and current_lat and current_lon then
            send_gps_data()
        end
    end
end)

-- Координатыг 5 секунд тутамд хэвлэх
sys.timerLoopStart(function()
    if current_lat and current_lon then
        log.info("CURRENT_COORD", "Өргөрөг:", current_lat, "Уртраг:", current_lon)
    else
        log.info("GPS", "Координат хүлээж байна...")
    end
end, 5000)

sys.run()
