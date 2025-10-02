-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "OwnTracks_MQTT"
VERSION = "1.0.0"

_G.sys = require("sys")
_G.sysplus = require("sysplus")

-- Air780E的AT固件默认会为开机键防抖, 导致部分用户刷机很麻烦
if rtos.bsp() == "EC618" and pm and pm.PWK_MODE then
    pm.power(pm.PWK_MODE, false)
end

-- MQTT тохиргоо
local mqtt_host = "broker.emqx.io"
local mqtt_port = 1883
local mqtt_isssl = false
local client_id = "moped1_tracker"
local user_name = "samdanjamts.su@gmail.com"
local password = "MqttBroker2025#"

-- OwnTracks topic
local pub_topic = "owntracks/Samka/moped1"
local sub_topic = "owntracks/Samka/moped1/control"

local mqttc = nil

-- GPS мэдээллийг хадгалах хувьсагчид (гарын утгаар)
local gps_data = {
    lat = 47.9154236,    -- Өргөрөг
    lon = 106.9214149,   -- Уртраг
    tst = os.time(),     -- Одоогийн timestamp
    tid = "MP"           -- Төхөөрөмжийн ID
}

-- GPS координатыг гарын утгаар шинэчлэх
function update_gps_coordinates(new_lat, new_lon)
    if new_lat and new_lon then
        gps_data.lat = new_lat
        gps_data.lon = new_lon
        gps_data.tst = os.time()

        log.info("GPS", "Координат шинэчлэгдлээ:",
                 "lat:", gps_data.lat,
                 "lon:", gps_data.lon,
                 "tst:", gps_data.tst)
        return true
    end
    return false
end

-- OwnTracks JSON үүсгэх
function generate_owntracks_json()
    if not gps_data.lat or not gps_data.lon or not gps_data.tst then
        return nil
    end

    local json = string.format(
        '{"_type":"location","lat":%.6f,"lon":%.6f,"tst":%d,"tid":"%s"}',
        gps_data.lat, gps_data.lon, gps_data.tst, gps_data.tid
    )

    return json
end

-- GPS мэдээлэл илгээх
function publish_gps_data()
    if not mqttc or not mqttc:ready() then
        log.warn("MQTT", "MQTT холболт бэлэн биш")
        return false
    end

    local json_data = generate_owntracks_json()
    if not json_data then
        log.warn("GPS", "GPS мэдээлэл бэлэн биш")
        return false
    end

    local result = mqttc:publish(pub_topic, json_data, 1)
    if result then
        log.info("MQTT", "Илгээгдлээ:", json_data)
        return true
    else
        log.error("MQTT", "Илгээх амжилтгүй")
        return false
    end
end

-- 统一联网函数
sys.taskInit(function()
    local device_id = "moped1"

    if wlan and wlan.connect then
        -- wifi 联网, ESP32系列均支持
        local ssid = "Samka"
        local password = "lcqq1655"
        log.info("wifi", ssid, password)
        wlan.init()
        wlan.setMode(wlan.STATION)
        device_id = wlan.getMac()
        wlan.connect(ssid, password, 1)
    elseif mobile then
        -- Air780E/Air600E系列
        device_id = mobile.imei()
        log.info("MOBILE", "IMEI:", device_id)
    elseif w5500 then
        -- w5500 以太网, 当前仅Air105支持
        w5500.init(spi.HSPI_0, 24000000, pin.PC14, pin.PC01, pin.PC00)
        w5500.config()
        w5500.bind(socket.ETH0)
    elseif socket or mqtt then
        -- 适配的socket库也OK
    else
        while 1 do
            sys.wait(1000)
            log.info("bsp", "本bsp可能未适配网络层, 请查证")
        end
    end

    sys.publish("net_ready", device_id)
end)

-- MQTT үндсэн task
sys.taskInit(function()
    -- 等待联网
    local ret, device_id = sys.waitUntil("net_ready")

    log.info("MQTT", "Pub Topic:", pub_topic)
    log.info("MQTT", "Sub Topic:", sub_topic)

    if mqtt == nil then
        while 1 do
            sys.wait(1000)
            log.info("bsp", "本bsp未适配mqtt库, 请查证")
        end
    end

    -- MQTT клиент үүсгэх
    mqttc = mqtt.create(nil, mqtt_host, mqtt_port, mqtt_isssl)

    mqttc:auth(client_id, user_name, password)
    mqttc:autoreconn(true, 3000) -- 自动重连机制

    -- Will message тохиргоо
    local will_topic = pub_topic .. "/will"
    local will_data = '{"_type":"location","tid":"MP","status":"offline"}'
    mqttc:will(will_topic, will_data)

    mqttc:on(function(mqtt_client, event, data, payload)
        log.info("mqtt", "event", event, data, payload)
        if event == "conack" then
            -- Холболт амжилттай
            sys.publish("mqtt_conack")
            -- Control topic subscribe хийх
            mqtt_client:subscribe(sub_topic)

        elseif event == "recv" then
            log.info("MQTT_CTRL", "topic:", data, "payload:", payload)
            -- Хяналтын мессеж ирвэл координат шинэчлэх боломжтой
            if data == sub_topic then
                -- Жишээ нь: {"lat":47.915, "lon":106.921}
                local success, coord_table = pcall(function()
                    return json.decode(payload)
                end)
                if success and coord_table then
                    if coord_table.lat and coord_table.lon then
                        update_gps_coordinates(coord_table.lat, coord_table.lon)
                        publish_gps_data() -- Шууд илгээх
                    end
                end
            end

        elseif event == "sent" then
            log.info("MQTT", "sent pkgid:", data)
        end
    end)

    -- MQTT холбогдох
    mqttc:connect()
    sys.waitUntil("mqtt_conack")

    -- Анхны GPS мэдээлэл илгээх
    sys.wait(2000)
    publish_gps_data()

    -- Үндсэн давталт - 5 минут тутамд илгээх
    while true do
        -- Тimestamp шинэчлэх
        gps_data.tst = os.time()

        -- GPS мэдээлэл илгээх
        publish_gps_data()

        -- 5 минут хүлээх
        log.info("SYSTEM", "Дараагийн илгээлт 5 минутын дараа...")
        sys.wait(300000) -- 300000 ms = 5 минут
    end
end)

-- Координат өөрчлөх жишээ task (тестийн зориулалтаар)
sys.taskInit(function()
    -- 30 секунд хүлээгээд координат өөрчлөх жишээ
    sys.wait(30000)

    -- Координат өөрчлөх жишээ 1
    log.info("TEST", "Координат өөрчлөгдөж байна...")
    update_gps_coordinates(47.9160000, 106.9220000)
    publish_gps_data()

    -- 60 секунд хүлээгээд дахин өөрчлөх
    sys.wait(60000)

    -- Координат өөрчлөх жишээ 2
    log.info("TEST", "Координат дахин өөрчлөгдөж байна...")
    update_gps_coordinates(47.9170000, 106.9230000)
    publish_gps_data()
end)

-- GPS мэдээллийг хэвлэх (1 минут тутамд)
sys.timerLoopStart(function()
    log.info("CURRENT_GPS",
        "lat:", gps_data.lat,
        "lon:", gps_data.lon,
        "tst:", gps_data.tst,
        "tid:", gps_data.tid
    )
end, 60000)

-- Координат өөрчлөх функцийг global болгох (гаднаас дуудах боломжтой)
_G.update_gps_coordinates = update_gps_coordinates
_G.publish_gps_data = publish_gps_data
_G.get_gps_data = function() return gps_data end

sys.run()
