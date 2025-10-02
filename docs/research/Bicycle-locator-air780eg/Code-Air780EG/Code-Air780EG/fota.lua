PROJECT = "fota"
VERSION = "1.0.0"
PRODUCT_KEY = "666"

sys = require "sys"
libfota2 = require "libfota2"
require"projectConfig"



-- 升级结果的回调函数
local function fota_cb(ret)

    if ret == 0 then
        log.info("升级成功，即将重启：", ret)

        local tmm1 = os.date()
        local tmm2 = os.date("%Y-%m-%d %H:%M:%S")
        local tmm3 = os.date("*t")

        local tm = rtc.get()
        local tjsondata,result,errinfo = json.decode(REPORT_DATA_TEMPLATE)
        if result and type(tjsondata)=="table" then
        
            local reporttime=os.date("%Y-%m-%d %H:%M:%S")
            local times=os.date("%Y-%m-%d %H:%M:%S")
            tjsondata["reporttime"] = reporttime;


            tjsondata["cmdtype"] = "cmd_fotaack";
            tjsondata["loadingmaxtime"] = 5;
            tjsondata["toastmsg"] = "升级完成";
            tjsondata["loading"] = "show" ;
            tjsondata["progress"] = "100";
            tjsondata["fotastatus"] = "fota_progress";
            tjsondata["cid"] = SRCCID;
            tjsondata["imei"] = aliyuncs_imei;

            sys.publish("CLIEND_SEND_FOTA", json.encode(tjsondata))

        else
            log.info("testJson error",errinfo)
        end


        sys.wait(200)
        log.info("即将重启");
        -- 断开MQTT
        mqttc:close()
        sys.wait(200)

        rtos.reboot()

    else
            log.info("升级失败：", ret)

        local tmm1 = os.date()
        local tmm2 = os.date("%Y-%m-%d %H:%M:%S")
        local tmm3 = os.date("*t")

        local tm = rtc.get()
        local tjsondata,result,errinfo = json.decode(REPORT_DATA_TEMPLATE)
        if result and type(tjsondata)=="table" then
        
            local reporttime=os.date("%Y-%m-%d %H:%M:%S")
            local times=os.date("%Y-%m-%d %H:%M:%S")
            tjsondata["reporttime"] = reporttime;


            tjsondata["cmdtype"] = "cmd_fotaack";
            tjsondata["loadingmaxtime"] = 0;
            tjsondata["toastmsg"] = "升级失败";
            tjsondata["loading"] = "hiden" ;
            tjsondata["progress"] = "--";
            tjsondata["fotastatus"] = "fota_error";
            tjsondata["cid"] = SRCCID;
            tjsondata["imei"] = aliyuncs_imei;

            sys.publish("CLIEND_SEND_FOTA", json.encode(tjsondata))

        else
            log.info("testJson error",errinfo)
        end


    end

end

--- 升级订阅
function SERVER_SEND_FOTA(urls,updateversion)

    local ota_opts = {
        url= urls,
    }

    log.info("开始升级 SERVER_SEND_FOTA urls", urls);

    if  updateversion ~= version  then

        local tmm1 = os.date()
        local tmm2 = os.date("%Y-%m-%d %H:%M:%S")
        local tmm3 = os.date("*t")

        local tm = rtc.get()
        local tjsondata,result,errinfo = json.decode(REPORT_DATA_TEMPLATE)
        if result and type(tjsondata)=="table" then
        
            local reporttime=os.date("%Y-%m-%d %H:%M:%S")
            local times=os.date("%Y-%m-%d %H:%M:%S")
            tjsondata["reporttime"] = reporttime;

         
            tjsondata["cmdtype"] = "cmd_fotaack";
            tjsondata["loadingmaxtime"] = 5;
            tjsondata["toastmsg"] = "升级开始";
            tjsondata["loading"] = "show" ;
            tjsondata["progress"] = "--";
            tjsondata["fotastatus"] = "fota_started";
            tjsondata["cid"] = SRCCID;
            tjsondata["imei"] = aliyuncs_imei;

            sys.publish("CLIEND_SEND_FOTA", json.encode(tjsondata))

        else
            log.info("testJson error",errinfo)
        end


        libfota2.request(fota_cb, ota_opts)
   else

        local tmm1 = os.date()
        local tmm2 = os.date("%Y-%m-%d %H:%M:%S")
        local tmm3 = os.date("*t")

        local tm = rtc.get()
        local tjsondata,result,errinfo = json.decode(REPORT_DATA_TEMPLATE)
        if result and type(tjsondata)=="table" then
        
            local reporttime=os.date("%Y-%m-%d %H:%M:%S")
            local times=os.date("%Y-%m-%d %H:%M:%S")
            tjsondata["reporttime"] = reporttime;

         
            tjsondata["cmdtype"] = "cmd_fotaack";
            tjsondata["loadingmaxtime"] = 0;
            tjsondata["toastmsg"] = "已是最新版本";
            tjsondata["loading"] = "hiden" ;
            tjsondata["progress"] = "--";
            tjsondata["fotastatus"] = "fota_checked";
            tjsondata["cid"] = SRCCID;
            tjsondata["imei"] = aliyuncs_imei;

            sys.publish("CLIEND_SEND_FOTA", json.encode(tjsondata))

        else
            log.info("testJson error",errinfo)
        end



   end
end


-- 订阅服务器发送的推送升级链接
sys.subscribe("SERVER_SEND_FOTA",SERVER_SEND_FOTA)


-- 自动升级, 每隔4小时自动检查一次
-- sys.timerLoopStart(libfota2.request, 4*3600000, fota_cb, ota_opts)


