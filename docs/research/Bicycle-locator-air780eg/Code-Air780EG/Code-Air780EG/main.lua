PROJECT = "FairyCloud"
VERSION = "1.0.0"

_G.sys = require("sys")
_G.sysplus = require("sysplus")
require"projectConfig"


-----------必选 以下四选一---------------

--精灵云：加载MQTT功能模块 
require "s_mqtt_fariycloud"

--阿里云：加载MQTT功能模块
-- require "s_mqtt_aliyuncs"
 
 --ONENET：加载MQTT功能模块
-- require "s_mqtt_onenet"
 
--自建服务器：加载HTTP功能模块
--require "s_http_privatecloud"


-- wifi定位
-- require "wifi"

-- 地图定位
require "gnss"
-- 休眠唤醒
require "sleep"
-- 电压检测
require "vbat_adc"
-- FOTA升级
require "fota"
-- SHT30
-- require "SHT30"


require("mqttInMsg")


sys.taskInit(function()

    while 1 do
        sys.wait(500)
    end
end)


sys.run()
