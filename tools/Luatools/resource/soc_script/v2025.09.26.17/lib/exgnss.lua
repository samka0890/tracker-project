--[[
@module exgnss
@summary exgnss扩展库
@version 1.0
@date    2025.07.16
@author  李源龙
@usage
-- 用法实例
-- 注意：exgnss.lua适用的产品范围，只能用于合宙内部集成GNSS功能的产品，目前有Air780EGH，Air8000系列
-- 提醒: 本库输出的坐标,均为 WGS84 坐标系
-- 如需要在国内地图使用, 要转换成对应地图的坐标系, 例如 GCJ02 BD09
-- 相关链接: https://lbsyun.baidu.com/index.php?title=coordinate
-- 相关链接: https://www.openluat.com/GPS-Offset.html

--关于exgnss的三种应用场景：
exgnss.DEFAULT:
--- exgnss应用模式1.
-- 打开gnss后，gnss定位成功时，如果有回调函数，会调用回调函数
-- 使用此应用模式调用exgnss.open打开的“gnss应用”，必须主动调用exgnss.close
-- 或者exgnss.close_all才能关闭此“gnss应用”,主动关闭时，即使有回调函数，也不会调用回调函数
-- 通俗点说就是一直打开，除非自己手动关闭掉

exgnss.TIMERORSUC:
--- exgnss应用模式2.
-- 打开gnss后，如果在gnss开启最大时长到达时，没有定位成功，如果有回调函数，
-- 会调用回调函数，然后自动关闭此“gnss应用”
-- 打开gnss后，如果在gnss开启最大时长内，定位成功，如果有回调函数，
-- 会调用回调函数，然后自动关闭此“gnss应用”
-- 打开gnss后，在自动关闭此“gnss应用”前，可以调用exgnss.close或者
-- exgnss.close_all主动关闭此“gnss应用”，主动关闭时，即使有回调函数，也不会调用回调函数
-- 通俗点说就是设置规定时间打开，如果规定时间内定位成功就会自动关闭此应用，
-- 如果没有定位成功，时间到了也会自动关闭此应用

exgnss.TIMER:
--- exgnss应用模式3.
-- 打开gnss后，在gnss开启最大时长时间到达时，无论是否定位成功，如果有回调函数，
-- 会调用回调函数，然后自动关闭此“gnss应用”
-- 打开gnss后，在自动关闭此“gnss应用”前，可以调用exgnss.close或者exgnss.close_all
-- 主动关闭此“gnss应用”，主动关闭时，即使有回调函数，也不会调用回调函数
-- 通俗点说就是设置规定时间打开，无论是否定位成功，到了时间都会自动关闭此应用，
-- 和第二种的区别在于定位成功之后不会自动关闭，到时间之后才会自动关闭

exgnss=require("exgnss")    

local function mode1_cb(tag)
    log.info("TAGmode1_cb+++++++++",tag)
    log.info("nmea", "rmc", json.encode(exgnss.rmc(2)))
end

local function mode2_cb(tag)
    log.info("TAGmode2_cb+++++++++",tag)
    log.info("nmea", "rmc", json.encode(exgnss.rmc(2)))
end

local function mode3_cb(tag)
    log.info("TAGmode3_cb+++++++++",tag)
    log.info("nmea", "rmc", json.encode(exgnss.rmc(2)))
end

local function gnss_fnc()
    local gnssotps={
        gnssmode=1, --1为卫星全定位，2为单北斗
        agps_enable=true,    --是否使用AGPS，开启AGPS后定位速度更快，会访问服务器下载星历，星历时效性为北斗1小时，GPS4小时，默认下载星历的时间为1小时，即一小时内只会下载一次
        debug=true,    --是否输出调试信息
        -- uart=2,    --使用的串口,780EGH和8000默认串口2
        -- uartbaud=115200,    --串口波特率，780EGH和8000默认115200
        -- bind=1, --绑定uart端口进行GNSS数据读取，是否设置串口转发，指定串口号
        -- rtc=false    --定位成功后自动设置RTC true开启，flase关闭
         ----因为GNSS使用辅助定位的逻辑，是模块下载星历文件，然后把数据发送给GNSS芯片，
        ----芯片解析星历文件需要10-30s，默认GNSS会开启20s，该逻辑如果不执行，会导致下一次GNSS开启定位是冷启动，
        ----定位速度慢，大概35S左右，所以默认开启，如果可以接受下一次定位是冷启动，可以把auto_open设置成false
        ----需要注意的是热启动在定位成功之后，需要再开启3s左右才能保证本次的星历获取完成，如果对定位速度有要求，建议这么处理
        -- auto_open=false 
    }
    --设置gnss参数
    exgnss.setup(gnssotps)
    --开启gnss应用
    exgnss.open(exgnss.TIMER,{tag="MODE1",val=60,cb=mode1_cb})
    exgnss.open(exgnss.DEFAULT,{tag="MODE2",cb=mode2_cb})
    exgnss.open(exgnss.TIMERORSUC,{tag="MODE3",val=60,cb=mode3_cb})
    sys.wait(40000)
    log.info("关闭一个gnss应用，然后查看下所有应用的状态")
    --关闭一个gnss应用
    exgnss.close(exgnss.TIMER,{tag="MODE1"})
    --查询3个gnss应用状态
    log.info("gnss应用状态1",exgnss.is_active(exgnss.TIMER,{tag="MODE1"}))
    log.info("gnss应用状态2",exgnss.is_active(exgnss.DEFAULT,{tag="MODE2"}))
    log.info("gnss应用状态3",exgnss.is_active(exgnss.TIMERORSUC,{tag="MODE3"}))
    sys.wait(10000)
    --关闭所有gnss应用
    exgnss.close_all()
    --查询3个gnss应用状态
    log.info("gnss应用状态1",exgnss.is_active(exgnss.TIMER,{tag="MODE1"}))
    log.info("gnss应用状态2",exgnss.is_active(exgnss.DEFAULT,{tag="MODE2"}))
    log.info("gnss应用状态3",exgnss.is_active(exgnss.TIMERORSUC,{tag="MODE3"}))
    --查询最后一次定位结果
    local loc= exgnss.last_loc()
    if loc then
        log.info("lastloc", loc.lat,loc.lng)
    end
end

sys.taskInit(gnss_fnc)


--GNSS定位状态的消息处理函数：
local function gnss_state(event, ticks)
    -- event取值有
    -- "FIXED"：string类型 定位成功
    -- "LOSE"： string类型 定位丢失
    -- "CLOSE": string类型 GNSS关闭，仅配合使用gnss.lua有效

    -- ticks number类型 是事件发生的时间,一般可以忽略
    log.info("exgnss", "state", event)
end
sys.subscribe("GNSS_STATE",gnss_state)

]]
local exgnss = {}
--gnss开启标志，true表示开启状态，false或者nil表示关闭状态
local openFlag
--gnss定位标志，true表示，其余表示未定位
local fixFlag=nil

--串口配置
local uart_baudrate = 115200
local uart_id = 2

--gnss 的串口线程是否在工作；
local taskFlag=false

local agpsFlag=false

local timeres=false

--保存经纬度到文件区
local function save_loc(lat,lng)
    if not lat or not lng then
        if libgnss.isFix() then
            local rmc = libgnss.getRmc(0)
            if rmc then
                lat, lng = rmc.lat, rmc.lng
            end
        end
    end
    if lat and lng then
        -- log.info("待保存的GPS位置", lat, lng)
        local locStr = string.format('{"lat":%.5f,"lng":%.5f}', lat, lng)
        -- log.info("gnss", "保存GPS位置", locStr)
        io.writeFile("/hxxtloc", locStr)
    end
    if timeres then
        local now = os.time()
        io.writeFile("/hxxt_tm", tostring(now))
        timeres=false
        -- log.info("now", now)
    end
end

local tid
local timetid
local function timer_fnc()
    timeres=true
    local now = os.time()
    io.writeFile("/hxxt_tm", tostring(now))
end

sys.subscribe("GNSS_STATE", function(event)
    -- log.info("libagps","libagps is "..event)
    if event == "FIXED" then
        save_loc()
        tid=sys.timerLoopStart(save_loc,600000)
        timetid=sys.timerStart(timer_fnc,10000)
        if exgnss.opts.rtc==true then
            sys.publish("NTP_UPDATE")
        end
    elseif event == "LOSE" or event == "CLOSE" then
        -- log.info("libagps","libagps is close")
        sys.timerStop(tid)
        sys.timerStop(timetid)
    end
end)

--agps操作，联网访问服务器获取星历数据
local function agps()
    local lat, lng

    --此逻辑在agps定位成功之后，还会继续开启10s-15s，
    --原因是因为如果第一次冷启动之后，定位成功之后，
    --如果直接关闭gnss会导致gnss芯片的星历没有解析完毕，会影响下一次的定位为冷启动
    --如果对功耗有需求，需要定位快，可以每次都使用agps，不需要这句，直接屏蔽掉即可
    --代价是每次定位都会进行基站定位，
    if exgnss.opts.auto_open~= false then
        log.info("libagps","libagps is open")
        exgnss.open(exgnss.TIMER,{tag="libagps",val=20}) 
    else

    end
    -- 判断星历时间和下载星历   
    local now = os.time()
    local agps_time = tonumber(io.readFile("/hxxt_tm") or "0") or 0
    log.info("os.time",now)
    log.info("agps_time",agps_time)
    if now - agps_time > 3600 or io.fileSize("/hxxt.dat") < 1024 then
        local url = exgnss.opts.url
        if not exgnss.opts.url then
            if exgnss.opts.gnssmode and 2 == exgnss.opts.gnssmode then
                -- 单北斗
                url = "http://download.openluat.com/9501-xingli/HXXT_BDS_AGNSS_DATA.dat"
            else
                url = "http://download.openluat.com/9501-xingli/HXXT_GPS_BDS_AGNSS_DATA.dat"
            end
        end
        local code = http.request("GET", url, nil, nil, {dst="/hxxt.dat"}).wait()
        if code and code == 200 then
            log.info("exgnss.opts", "下载星历成功", url)
            io.writeFile("/hxxt_tm", tostring(now))
        else
            log.info("exgnss.opts", "下载星历失败", code)
        end
    else
        log.info("exgnss.opts", "星历不需要更新", now - agps_time)
    end
    --进行基站定位，给到gnss芯片一个大概的位置
    if mobile then
        local lbsLoc2 = require("lbsLoc2")
        lat, lng = lbsLoc2.request(5000)
        -- local lat, lng, t = lbsLoc2.request(5000, "bs.openluat.com")
        -- log.info("lbsLoc2", lat, lng)
        if lat and lng then
            lat = tonumber(lat)
            lng = tonumber(lng)
            log.info("lbsLoc2", lat, lng)
            -- 转换单位
            local lat_dd,lat_mm = math.modf(lat)
            local lng_dd,lng_mm = math.modf(lng)
            lat = lat_dd * 100 + lat_mm * 60
            lng = lng_dd * 100 + lng_mm * 60
        end
    elseif wlan then
        -- wlan.scan()
        -- sys.waitUntil("WLAN_SCAN_DONE", 5000)
    end
    --获取基站定位失败则使用本地之前保存的位置
    if not lat then
        -- 获取最后的本地位置
        local locStr = io.readFile("/hxxtloc")
        if locStr then
            local jdata = json.decode(locStr)
            if jdata and jdata.lat then
                lat = jdata.lat
                lng = jdata.lng
            end
        end
    end
    local gps_uart_id = uart_id

    -- 写入星历
    local agps_data = io.readFile("/hxxt.dat")
    if agps_data and #agps_data > 1024 then
        log.info("exgnss.opts", "写入星历数据", "长度", #agps_data)
        for offset=1,#agps_data,512 do
            log.info("exgnss", "AGNSS", "write >>>", #agps_data:sub(offset, offset + 511))
            uart.write(gps_uart_id, agps_data:sub(offset, offset + 511))
            sys.wait(100) -- 等100ms反而更成功
        end
        -- uart.write(gps_uart_id, agps_data)
    else
        log.info("exgnss.opts", "没有星历数据")
        return
    end
    -- "lat":23.4068813,"min":27,"valid":true,"day":27,"lng":113.2317505
    --如果没有经纬度的话，定位时间会变长，大概10-20s左右
    if not lat or not lng then
        -- lat, lng = 23.4068813, 113.2317505
        log.info("exgnss.opts", "没有GPS坐标", lat, lng)
        return --暂时不写入参考位置
    else
        log.info("exgnss.opts", "写入GPS坐标", lat, lng)
    end
    --写入时间
    local date = os.date("!*t")
    if date.year > 2023 then
        local str = string.format("$AIDTIME,%d,%d,%d,%d,%d,%d,000", date["year"], date["month"], date["day"],
            date["hour"], date["min"], date["sec"])
        log.info("exgnss.opts", "参考时间", str)
        uart.write(gps_uart_id, str .. "\r\n")
        sys.wait(20)
    end
    -- 写入参考位置
    local str = string.format("$AIDPOS,%.7f,%s,%.7f,%s,1.0\r\n",
    lat > 0 and lat or (0 - lat), lat > 0 and 'N' or 'S',
    lng > 0 and lng or (0 - lng), lng > 0 and 'E' or 'W')
    log.info("exgnss.opts", "写入AGPS参考位置", str)
    uart.write(gps_uart_id, str)

    -- 结束
    exgnss.opts.agps_tm = now
    agpsFlag=true
end

--执行agps操作判断
local function is_agps()
    -- 如果不是强制写入AGPS信息, 而且是已经定位成功的状态,那就没必要了
    if libgnss.isFix() then return end
    -- 先判断一下时间
    while not socket.adapter() do
        log.warn("gnss_agps", "wait IP_READY")
        -- 在此处阻塞等待WIFI连接成功的消息"IP_READY"
        -- 或者等待30秒超时退出阻塞等待状态
        local result=sys.waitUntil("IP_READY", 30000)
        if result == false then
            log.warn("gnss_agps", "wait IP_READY timeout")
            return
        end
    end
    if not exgnss.opts.agps_tm then
        socket.sntp()
        sys.waitUntil("NTP_UPDATE", 5000)
    end
    local now = os.time()
    local agps_time = tonumber(io.readFile("/hxxt_tm") or "0") or 0
    -- if ((not exgnss.opts.agps_tm) and (now - agps_time > 300))  or  now - agps_time > 3600 then
    if not exgnss.opts.agps_tm  or  now - agps_time > 3600 then
        -- 执行AGPS
        log.info("exgnss.opts", "开始执行AGPS")
        sys.taskInit(agps)
    else
        log.info("exgnss.opts", "暂不需要写入AGPS")
    end
end


--打开gnss，内部函数使用，不推荐给脚本层使用
local function fnc_open()
    if openFlag then return end
    libgnss.clear() -- 清空数据,兼初始化
    uart.setup(uart_id, uart_baudrate)
    -- pm.power(pm.GPS, false)
    pm.power(pm.GPS, true)
    if exgnss.opts.gnssmode==1 then
        --默认全开启
        log.info("全卫星开启")
        elseif exgnss.opts.gnssmode==2 then
        --默认开启单北斗
        sys.timerStart(function()
            uart.write(uart_id, "$CFGSYS,h10\r\n")
        end,200)
        log.info("单北斗开启")
    end
    if exgnss.opts.debug==true then
        log.info("debug开启")
        libgnss.debug(true)
    end
    if type(exgnss.opts.bind)=="number"  then
        log.info("绑定bind事件")
        libgnss.bind(uart_id,exgnss.opts.bind)
    else
        libgnss.bind(uart_id)
    end
    if exgnss.opts.rtc==true then
        log.info("rtc开启")
        libgnss.rtcAuto(true)
    end
    if exgnss.opts.agps_enable==true then
        log.info("agps开启")
        sys.taskInit(is_agps)
    end
    --设置输出VTG内容
    sys.timerStart(function()
        uart.write(uart_id,"$CFGMSG,0,5,1,1\r\n")
    end,800)
     --设置输出ZDA内容
     sys.timerStart(function()
        uart.write(uart_id,"$CFGMSG,0,6,1,1\r\n")
    end,900)
    openFlag = true
    sys.publish("GNSS_STATE","OPEN")
    log.info("exgnss._open")
end

--关闭gnss，内部函数使用，不推荐给脚本层使用
local function fnc_close()
    if not openFlag then return end
    save_loc()
    pm.power(pm.GPS, false)
    uart.close(uart_id)
    openFlag = false
    fixFlag = false
    timeres=false
    sys.publish("GNSS_STATE","CLOSE",fixFlag)    
    log.info("exgnss._close")
    libgnss.clear()
end


--- gnss应用模式1.
--
-- 打开gnss后，gnss定位成功时，如果有回调函数，会调用回调函数
--
-- 使用此应用模式调用gnss.open打开的“gnss应用”，必须主动调用gnss.close或者gnss.close_all才能关闭此“gnss应用”,主动关闭时，即使有回调函数，也不会调用回调函数
exgnss.DEFAULT = 1
--- gnss应用模式2.
--
-- 打开gnss后，如果在gnss开启最大时长到达时，没有定位成功，如果有回调函数，会调用回调函数，然后自动关闭此“gnss应用”
--
-- 打开gnss后，如果在gnss开启最大时长内，定位成功，如果有回调函数，会调用回调函数，然后自动关闭此“gnss应用”
--
-- 打开gnss后，在自动关闭此“gnss应用”前，可以调用gnss.close或者gnss.close_all主动关闭此“gnss应用”，主动关闭时，即使有回调函数，也不会调用回调函数
exgnss.TIMERORSUC = 2
--- gnss应用模式3.
--
-- 打开gnss后，在gnss开启最大时长时间到达时，无论是否定位成功，如果有回调函数，会调用回调函数，然后自动关闭此“gnss应用”
--
-- 打开gnss后，在自动关闭此“gnss应用”前，可以调用gnss.close或者gnss.close_all主动关闭此“gnss应用”，主动关闭时，即使有回调函数，也不会调用回调函数
exgnss.TIMER = 3

--“gnss应用”表
local tList = {}

--[[
函数名：delItem
功能  ：从“gnss应用”表中删除一项“gnss应用”，并不是真正的删除，只是设置一个无效标志
参数  ：
        mode：gnss应用模式
        para：
            para.tag：“gnss应用”标记
            para.val：gnss开启最大时长
            para.cb：回调函数
返回值：无
]]
local function delItem(mode,para)
    for i=1,#tList do
        --标志有效 并且 gnss应用模式相同 并且 “gnss应用”标记相同
        if tList[i].flag and tList[i].mode==mode and tList[i].para.tag==para.tag then
            --设置无效标志
            tList[i].flag,tList[i].delay = false
            break
        end
    end
end


--[[
函数名：addItem
功能  ：新增一项“gnss应用”到“gnss应用”表
参数  ：
        mode：gnss应用模式
        para：
            para.tag：“gnss应用”标记
            para.val：gnss开启最大时长
            para.cb：回调函数
返回值：无
]]
local function addItem(mode,para)
    --删除相同的“gnss应用”
    delItem(mode,para)
    local item,i,fnd = {flag=true, mode=mode, para=para}
    --如果是TIMERORSUC或者TIMER模式，初始化gnss工作剩余时间
    if mode==exgnss.TIMERORSUC or mode==exgnss.TIMER then item.para.remain = para.val end
    for i=1,#tList do
        --如果存在无效的“gnss应用”项，直接使用此位置
        if not tList[i].flag then
            tList[i] = item
            fnd = true
            break
        end
    end
    --新增一项
    if not fnd then table.insert(tList,item) end
end

--退出GNSS定时器
local function existTimerItem()
    for i=1,#tList do
        if tList[i].flag and (tList[i].mode==exgnss.TIMERORSUC or tList[i].mode==exgnss.TIMER or tList[i].para.delay) then return true end
    end
end

--GNSS定时器
local function timerFnc()
    for i=1,#tList do
        if tList[i].flag then
            log.info("exgnss.timerFnc@"..i,tList[i].mode,tList[i].para.tag,tList[i].para.val,tList[i].para.remain,tList[i].para.delay)
            local rmn,dly,md,cb = tList[i].para.remain,tList[i].para.delay,tList[i].mode,tList[i].para.cb

            if rmn and rmn>0 then
                tList[i].para.remain = rmn-1
            end
            if dly and dly>0 then
                tList[i].para.delay = dly-1
            end
            rmn = tList[i].para.remain

            if libgnss.isFix() and md==exgnss.TIMER and rmn==0 and not tList[i].para.delay then
                tList[i].para.delay = 1
            end
            dly = tList[i].para.delay
            if libgnss.isFix() then
                if dly and dly==0 then
                    if cb then cb(tList[i].para.tag) end
                    if md == exgnss.DEFAULT then
                        tList[i].para.delay = nil
                    else
                        exgnss.close(md,tList[i].para)
                    end
                end
            else
                if rmn and rmn == 0 then
                    if cb then cb(tList[i].para.tag) end
                    exgnss.close(md,tList[i].para)
                end
            end
        end
    end
    if existTimerItem() then sys.timerStart(timerFnc,1000) end
end

--[[
函数名：statInd
功能  ：处理gnss定位成功的消息
参数  ：
        evt：gnss消息类型
返回值：无
]]
local function statInd(evt)
    --定位成功的消息
    if evt == "FIXED" then
        fixFlag = true
        for i=1,#tList do
            log.info("exgnss.statInd@"..i,tList[i].flag,tList[i].mode,tList[i].para.tag,tList[i].para.val,tList[i].para.remain,tList[i].para.delay,tList[i].para.cb)
            if tList[i].flag then
                if tList[i].mode ~= exgnss.TIMER then
                    tList[i].para.delay = 1
                    if tList[i].mode == exgnss.DEFAULT then
                        if existTimerItem() then sys.timerStart(timerFnc,1000) end
                    end
                end
            end
        end
    end
end


--[[
设置gnss定位参数
@api exgnss.setup(opts)
@table opts gnss定位参数，可选值gnssmode:定位卫星模式，1为卫星全定位，2为单北斗，默认为卫星全定位
agps_enable:是否启用AGPS，true为启用，false为不启用，默认为false
debug:是否输出调试信息到luatools，true为输出，false为不输出，默认为false
uart:GNSS串口配置，780EGH和8000默认为uart2，可不填
uartbaud:GNSS串口波特率，780EGH和8000默认为115200，可不填
bind:绑定uart端口进行GNSS数据读取，是否设置串口转发，指定串口号，不需要转发可不填
rtc:定位成功后自动设置RTC true开启，flase关闭，默认为flase，不需要可不填
@return nil 无返回值
@usage
local gnssotps={
        gnssmode=1, --1为卫星全定位，2为单北斗
        agps_enable=true,    --是否使用AGPS，开启AGPS后定位速度更快，会访问服务器下载星历，星历时效性为北斗1小时，GPS4小时，默认下载星历的时间为1小时，即一小时内只会下载一次
        debug=true,    --是否输出调试信息
        -- uart=2,    --使用的串口,780EGH和8000默认串口2
        -- uartbaud=115200,    --串口波特率，780EGH和8000默认115200
        -- bind=1, --绑定uart端口进行GNSS数据读取，是否设置串口转发，指定串口号
        -- rtc=false    --定位成功后自动设置RTC true开启，flase关闭
         ----因为GNSS使用辅助定位的逻辑，是模块下载星历文件，然后把数据发送给GNSS芯片，
        ----芯片解析星历文件需要10-30s，默认GNSS会开启20s，该逻辑如果不执行，会导致下一次GNSS开启定位是冷启动，
        ----定位速度慢，大概35S左右，所以默认开启，如果可以接受下一次定位是冷启动，可以把auto_open设置成false
        ----需要注意的是热启动在定位成功之后，需要再开启3s左右才能保证本次的星历获取完成，如果对定位速度有要求，建议这么处理
        -- auto_open=false 
    }
    exgnss.setup(gnssotps)
]]
function exgnss.setup(opts)
    exgnss.opts=opts
    if hmeta.model():find("780EGH") or hmeta.model():find("8000") then
        uart_id=2
        uart_baudrate=115200
    else
        if exgnss.opts.uart_id then
            uart_id=exgnss.opts.uart_id
        else
            uart_id=2    
        end
        if exgnss.opts.uartbaud then
            uart_baudrate=exgnss.opts.uartbaud
        else
            uart_baudrate=115200
        end
    end   
end

--[[
打开一个“gnss应用”
@api exgnss.open(mode,para)
@number mode gnss应用模式，支持gnss.DEFAULT，gnss.TIMERORSUC，gnss.TIMER三种
@param para table类型，gnss应用参数,para.tag：string类型，gnss应用标记,para.val：number类型，gnss应用开启最大时长，单位：秒，mode参数为gnss.TIMERORSUC或者gnss.TIMER时，此值才有意义；使用close接口时，不需要传入此参数,para.cb：gnss应用结束时的回调函数，回调函数的调用形式为para.cb(para.tag)；使用close接口时，不需要传入此参数
@return nil 无返回值
@usage
-- “gnss应用”：指的是使用gnss功能的一个应用
-- 例如，假设有如下3种需求，要打开gnss，则一共有3个“gnss应用”：
-- “gnss应用1”：每隔1分钟打开一次gnss
-- “gnss应用2”：设备发生震动时打开gnss
-- “gnss应用3”：收到一条特殊短信时打开gnss
-- 只有所有“gnss应用”都关闭了，才会去真正关闭gnss
-- 每个“gnss应用”打开或者关闭gnss时，最多有4个参数，其中 gnss应用模式和gnss应用标记 共同决定了一个唯一的“gnss应用”：
-- 1、gnss应用模式(必选)
-- 2、gnss应用标记(必选)
-- 3、gnss开启最大时长[可选]
-- 4、回调函数[可选]
-- 例如gnss.open(exgnss.TIMER,{tag="MODE1",val=60,cb=mode1_cb})
-- exgnss.TIMER为gnss应用模式，"MODE1"为gnss应用标记，60秒为gnss开启最大时长，mode1_cb为回调函数
exgnss.open(exgnss.TIMER,{tag="MODE1",val=60,cb=mode1_cb})
exgnss.open(exgnss.DEFAULT,{tag="MODE2",cb=mode2_cb})
exgnss.open(exgnss.TIMERORSUC,{tag="MODE3",val=60,cb=mode3_cb})
]]
function exgnss.open(mode,para)
    assert((para and type(para) == "table" and para.tag and type(para.tag) == "string"),"exgnss.open para invalid")
    log.info("exgnss.open",mode,para.tag,para.val,para.cb)
    --如果gnss定位成功
    if libgnss.isFix() then
        if mode~=exgnss.TIMER then
            --执行回调函数
            if para.cb then para.cb(para.tag) end
            if mode==exgnss.TIMERORSUC then return end
        end
    end
    addItem(mode,para)
    --真正去打开gnss
    fnc_open()
    --启动1秒的定时器
    if existTimerItem() and not sys.timerIsActive(timerFnc) then
        sys.timerStart(timerFnc,1000)
    end
end


--[[
关闭一个“gnss应用”，只是从逻辑上关闭一个gnss应用，并不一定真正关闭gnss，是有所有的gnss应用都处于关闭状态，才会去真正关闭gnss
@api exgnss.close()
@number mode gnss应用模式，支持gnss.DEFAULT，gnss.TIMERORSUC，gnss.TIMER三种
@param para table类型，gnss应用参数,para.tag：string类型，gnss应用标记,para.val：number类型，gnss应用开启最大时长，单位：秒，mode参数为gnss.TIMERORSUC或者gnss.TIMER时，此值才有意义；使用close接口时，不需要传入此参数,para.cb：gnss应用结束时的回调函数，回调函数的调用形式为para.cb(para.tag)；使用close接口时，不需要传入此参数
@return nil 无返回值
@usage
exgnss.open(exgnss.TIMER,{tag="MODE1",val=60,cb=mode1_cb})
exgnss.close(exgnss.TIMER,{tag="MODE1"})
]]
function exgnss.close(mode,para)
    assert((para and type(para)=="table" and para.tag and type(para.tag)=="string"),"exgnss.close para invalid")
    log.info("exgnss.close",mode,para.tag,para.val,para.cb)
    --删除此“gnss应用”
    delItem(mode,para)
    local valid,i
    for i=1,#tList do
        if tList[i].flag then
            valid = true
        end
    end
    --如果没有一个“gnss应用”有效，则关闭gnss
    if not valid then fnc_close() end
end

--[[
关闭所有“gnss应用”
@api exgnss.close_all()
@return nil 无返回值
@usage
exgnss.open(exgnss.TIMER,{tag="MODE1",val=60,cb=mode1_cb})
exgnss.open(exgnss.DEFAULT,{tag="MODE2",cb=mode2_cb})
exgnss.open(exgnss.TIMERORSUC,{tag="MODE3",val=60,cb=mode3_cb})
exgnss.close_all()
]]
function exgnss.close_all()
    for i=1,#tList do
        if tList[i].flag and tList[i].para.cb then tList[i].para.cb(tList[i].para.tag) end
        exgnss.close(tList[i].mode,tList[i].para)
    end
end

--[[
判断一个“gnss应用”是否处于激活状态
@api exgnss.is_active(mode,para)
@number mode gnss应用模式，支持gnss.DEFAULT，gnss.TIMERORSUC，gnss.TIMER三种
@param para table类型，gnss应用参数,para.tag：string类型，gnss应用标记,para.val：number类型，gnss应用开启最大时长，单位：秒，mode参数为gnss.TIMERORSUC或者gnss.TIMER时，此值才有意义；使用close接口时，不需要传入此参数,para.cb：gnss应用结束时的回调函数，回调函数的调用形式为para.cb(para.tag)；使用close接口时，不需要传入此参数,gnss应用模式和gnss应用标记唯一确定一个“gnss应用”，调用本接口查询状态时，mode和para.tag要和gnss.open打开一个“gnss应用”时传入的mode和para.tag保持一致
@return bool result，处于激活状态返回true，否则返回nil
@usage
exgnss.open(exgnss.TIMER,{tag="MODE1",val=60,cb=mode1_cb})
exgnss.open(exgnss.DEFAULT,{tag="MODE2",cb=mode2_cb})
exgnss.open(exgnss.TIMERORSUC,{tag="MODE3",val=60,cb=mode3_cb})
log.info("gnss应用状态1",exgnss.is_active(exgnss.TIMER,{tag="MODE1"}))
log.info("gnss应用状态2",exgnss.is_active(exgnss.DEFAULT,{tag="MODE2"}))
log.info("gnss应用状态3",exgnss.is_active(exgnss.TIMERORSUC,{tag="MODE3"}))
]]
function exgnss.is_active(mode,para)
    assert((para and type(para)=="table" and para.tag and type(para.tag)=="string"),"exgnss.is_active para invalid")
    for i=1,#tList do
        if tList[i].flag and tList[i].mode==mode and tList[i].para.tag==para.tag then return true end
    end
end

sys.subscribe("GNSS_STATE",statInd)


--[[
当前是否已经定位成功
@api exgnss.is_fix()
@return boolean   true/false，定位成功返回true，否则返回false
@usage
log.info("nmea", "is_fix", exgnss.is_fix())
]]
function exgnss.is_fix()
   return libgnss.isFix()
end


--[[
获取number类型的位置和速度信息
@api exgnss.int_location(speed_type)
@number 速度单位,默认是m/h,
0 - m/h 米/小时, 默认值, 整型
1 - m/s 米/秒, 浮点数
2 - km/h 千米/小时, 浮点数
3 - kn/h 英里/小时, 浮点数
@return number lat数据, 格式为 DDDDDDDDD，示例：343482649，DDDDDDDDD格式是由DD.DDDDDDD*10000000转换而来，目的是作为整数，方便某些场景使用
@return number lng数据, 格式为 DDDDDDDDD，示例：1135039700，DDDDDDDDD格式是由DD.DDDDDDD*10000000转换而来，目的是作为整数，方便某些场景使用
@return number speed数据, 单位根据speed_type决定，m/h, m/s, km/h, kn/h
@usage
--DDDDDDDDD格式是由DD.DDDDDDD*10000000转换而来，目的是作为整数，方便某些场景使用，示例：343482649对应的原始值是34.3482649
-- 该数据是通过RMC转换的，如果想获取更详细的可以用exgnss.rmc(1)
-- speed数据默认 米/小时，返回值例如：343482649	1135039700	390m/h
log.info("nmea", "loc", exgnss.int_location())
-- speed数据米/秒，返回值例如：343482649	1135039700	0.1085478m/s
log.info("nmea", "loc", exgnss.int_location(1))
-- speed数据千米/小时，返回值例如：343482649	1135039700	0.3907720km/h
log.info("nmea", "loc", exgnss.int_location(2))
-- speed数据英里/小时，返回值例如：343482649	1135039700	0.2110000kn/h
log.info("nmea", "loc", exgnss.int_location(3))
]]
function exgnss.int_location(speed_type)
    return libgnss.int_location(speed_type)
end


--[[
获取RMC的信息，经纬度，时间，速度，航向，定位是否有效，磁偏角
@api exgnss.rmc(lnglat_mode)
@number 经纬度数据的格式, 0-ddmm.mmmmm格式, 1-DDDDDDDDD格式, 2-DD.DDDDDDD格式, 3-原始RMC字符串
@return table/string rmc数据
@usage
-- 解析nmea
log.info("nmea", "rmc", json.encode(exgnss.rmc(2)))
-- 实例输出,获取值的解释
-- {
--     "course":344.9920044,     // 地面航向，单位为度，从北向起顺时针计算
--     "valid":true,   // true定位成功,false定位丢失
--     "lat":34.5804405,  // 纬度, 正数为北纬, 负数为南纬
--     "lng":113.8399506,  // 经度, 正数为东经, 负数为西经
--     "variation":0,  // 磁偏角，固定为0
--     "speed":0.2110000       // 地面速度, 单位为"节"
--     "year":2023,    // 年份
--     "month":1,      // 月份, 1-12
--     "day":5,        // 月份天, 1-31
--     "hour":7,       // 小时,0-23
--     "min":23,       // 分钟,0-59
--     "sec":20,       // 秒,0-59
-- }
--模式0示例：
--json.encode默认输出"7f"格式保留7位小数，可以根据自己需要的格式调整小数位，本示例保留5位小数
log.info("nmea", "rmc0", json.encode(exgnss.rmc(0),"5f"))
{"variation":0,"lat":3434.82666,"min":54,"valid":true,"day":17,"lng":11350.39746,"speed":0.21100,"year":2025,"month":7,"sec":30,"hour":11,"course":344.99200}
--模式1示例：
--DDDDDDDDD格式是由DD.DDDDDDD*10000000转换而来，目的是作为整数，方便某些场景使用
log.info("nmea", "rmc1", json.encode(exgnss.rmc(1)))
{"variation":0,"lat":345804414,"min":54,"valid":true,"day":17,"lng":1138399500,"speed":0.2110000,"year":2025,"month":7,"sec":30,"hour":11,"course":344.9920044}
--模式2示例：
--json.encode默认输出"7f"格式保留7位小数，可以根据自己需要的格式调整小数位
log.info("nmea", "rmc2", json.encode(exgnss.rmc(2)))
{"variation":0,"lat":34.5804405,"min":54,"valid":true,"day":17,"lng":113.8399506,"speed":0.2110000,"year":2025,"month":7,"sec":30,"hour":11,"course":344.9920044}
--模式3示例：
log.info("nmea", "rmc3", exgnss.rmc(3))
$GNRMC,115430.000,A,3434.82649,N,11350.39700,E,0.211,344.992,170725,,,A,S*02\r
]]
function exgnss.rmc(lnglat_mode)
    return libgnss.getRmc(lnglat_mode)
end

--[[
获取原始GSV信息
@api exgnss.gsv()
@return table 原始GSV数据
@usage
-- 解析nmea
log.info("nmea", "gsv", json.encode(exgnss.gsv()))
-- 实例输出
-- {
--     "total_sats":24,      // 总可见卫星数量
--     "sats":[
--         {
--             "snr":27,     // 信噪比
--             "azimuth":278, // 方向角
--             "elevation":59, // 仰角
--             "tp":0,        // 0 - GPS, 1 - BD, 2 - GLONASS, 3 - Galileo, 4 - QZSS
--             "nr":4         // 卫星编号
--         },
--         // 这里忽略了22个卫星的信息
--         {
--             "snr":0,
--             "azimuth":107,
--             "elevation":19,
--             "tp":1,
--             "nr":31
--         }
--     ]
-- }
]]
function exgnss.gsv() 
    return libgnss.getGsv() 
end


--[[
获取原始GSA信息
@api exgnss.gsa(data_mode)
@number 模式，默认为0 -所有卫星系统全部输出在一起，1 - 每个卫星系统单独分开输出
@return table 原始GSA数据
@usage
-- 获取
log.info("nmea", "gsa", json.encode(exgnss.gsa()))
-- 示例数据(模式0, 也就是默认模式)
--sysid:1为GPS，4为北斗，2为GLONASS，3为Galileo
{"pdop":1.1770000,  位置精度因子，0.00 - 99.99，不定位时值为 99.99
"sats":[15,13,5,18,23,20,24,30,24,13,33,38,8,14,28,41,6,39,25,16,32,27],    // 正在使用的卫星编号
"vdop":1.0160000,   垂直精度因子，0.00 - 99.99，不定位时值为 99.99
"hdop":0.5940000,   // 水平精度因子，0.00 - 99.99，不定位时值为 99.99
"sysid":1,         // 卫星系统编号1为GPS，4为北斗，2为GLONASS，3为Galileo
"fix_type":3       // 定位模式, 1-未定位, 2-2D定位, 3-3D定位
}

--模式1
log.info("nmea", "gsa", json.encode(exgnss.gsa()))

[{"pdop":1.1770000,"sats":[15,13,5,18,23,20,24],"vdop":1.0160000,"hdop":0.5940000,"sysid":1,"fix_type":3},
{"pdop":1.1770000,"sats":[30,24,13,33,38,8,14,28,41,6,39,25],"vdop":1.0160000,"hdop":0.5940000,"sysid":4,"fix_type":3},
{"pdop":1.1770000,"sats":[16,32,27],"vdop":1.0160000,"hdop":0.5940000,"sysid":4,"fix_type":3},
{"pdop":1.1770000,"sats":{},"vdop":1.0160000,"hdop":0.5940000,"sysid":2,"fix_type":3},
{"pdop":1.1770000,"sats":{},"vdop":1.0160000,"hdop":0.5940000,"sysid":3,"fix_type":3}]

]]

function exgnss.gsa(data_mode)
    return libgnss.getGsa(data_mode)
end


--[[
获取VTG速度信息
@api exgnss.vtg(data_mode)
@number 可选, 3-原始字符串, 不传或者传其他值, 则返回浮点值
@return table/string 原始VTG数据
@usage
-- 解析nmea
log.info("nmea", "vtg", json.encode(exgnss.vtg()))
-- 示例
{
    "speed_knots":0,        // 速度, 英里/小时
    "true_track_degrees":0,  // 真北方向角
    "magnetic_track_degrees":0, // 磁北方向角
    "speed_kph":0           // 速度, 千米/小时
}

--模式3
log.info("nmea", "vtg", exgnss.vtg(3))
-- 返回值：$GNVTG,0.000,T,,M,0.000,N,0.000,K,A*13\r
-- 提醒: 在速度<5km/h时, 不会返回方向角
]]
function exgnss.vtg(data_mode)
    return  libgnss.getVtg(data_mode)
end

--获取原始ZDA时间和日期信息
--[[
获取原始ZDA时间和日期信息
@api exgnss.zda()
@return table 原始zda数据
@usage
log.info("nmea", "zda", json.encode(exgnss.zda()))
-- 实例输出
-- {
--     "minute_offset":0,   // 本地时区的分钟, 一般固定输出0
--     "hour_offset":0,     // 本地时区的小时, 一般固定输出0
--     "year":2023         // UTC 年，四位数字
--     "month":1,          // UTC 月，两位，01 ~ 12
--     "day":5,            // UTC 日，两位数字，01 ~ 31
--     "hour":7,           // 小时
--     "min":50,           // 分
--     "sec":14,           // 秒
-- }
]]
function exgnss.zda()
    return  libgnss.getZda()
end

--[[
获取GGA数据
@api exgnss.gga(lnglat_mode)
@number 经纬度数据的格式, 0-ddmm.mmmmm格式, 1-DDDDDDDDD格式, 2-DD.DDDDDDD格式, 3-原始GGA字符串
@return table GGA数据, 若如不存在会返回nil
@usage
local gga = exgnss.gga(2)
log.info("GGA", json.encode(gga, "11g"))
--实例输出,获取值的解释:
-- {
--     "dgps_age":0,             // 差分校正时延，单位为秒
--     "fix_quality":1,          // 定位状态标识 0 - 无效,1 - 单点定位,2 - 差分定位
--     "satellites_tracked":14,  // 参与定位的卫星数量
--     "altitude":0.255,         // 海平面分离度, 或者成为海拔, 单位是米,
--     "hdop":0.0335,            // 水平精度因子，0.00 - 99.99，不定位时值为 99.99
--     "longitude":113.231,      // 经度, 正数为东经, 负数为西经
--     "latitude":23.4067,       // 纬度, 正数为北纬, 负数为南纬
--     "height":0                // 椭球高，固定输出 1 位小数
-- }
模式0示例：
json.encode默认输出"7f"格式保留7位小数，可以根据自己需要的格式调整小数位，本示例保留5位小数
local gga = exgnss.gga(0)
if gga then
    log.info("GGA0", json.encode(gga, "5f"))
end
{"longitude":11419.19531,"dgps_age":0,"altitude":86.40000,"hdop":0.59400,"height":-13.70000,"fix_quality":1,"satellites_tracked":22,"latitude":3447.86914}
模式1示例：
DDDDDDDDD格式是由DD.DDDDDDD*10000000转换而来，目的是作为整数，方便某些场景使用
local gga1 = exgnss.gga(1)
if gga1 then
    log.info("GGA1", json.encode(gga1))
end
{"longitude":1143199103,"dgps_age":0,"altitude":86.4000015,"hdop":0.5940000,"height":-13.6999998,"fix_quality":1,"satellites_tracked":22,"latitude":347978178}
模式2示例：
json.encode默认输出"7f"格式保留7位小数，可以根据自己需要的格式调整小数位
local gga2 = exgnss.gga(2)
if gga2 then
    log.info("GGA2", json.encode(gga2))
end
{"longitude":114.3199081,"dgps_age":0,"altitude":86.4000015,"hdop":0.5940000,"height":-13.6999998,"fix_quality":1,"satellites_tracked":22,"latitude":34.7978172}
模式3示例：
local gga3 = exgnss.gga(3)
if gga3 then
    log.info("GGA3", gga3)
end
$GNGGA,131241.000,3434.81372,N,11350.39930,E,1,05,4.924,165.5,M,-15.2,M,,*6D\r
]]
function exgnss.gga(lnglat_mode)
    return  libgnss.getGga(lnglat_mode)
end

--[[
获取GLL数据
@api exgnss.gll(data_mode)
@number 经纬度数据的格式, 0-ddmm.mmmmm格式, 1-DDDDDDDDD格式, 2-DD.DDDDDDD格式
@return table GLL数据, 若如不存在会返回nil
@usage
local gll = exgnss.gll(2)
if gll then
    log.info("GLL", json.encode(gll, "11g"))
end
-- 实例数据,获取值的解释:
-- {
--     "status":"A",        // 定位状态, A有效, B无效
--     "mode":"A",          // 定位模式, V无效, A单点解, D差分解
--     "sec":20,            // 秒, UTC时间为准
--     "min":23,            // 分钟, UTC时间为准
--     "hour":7,            // 小时, UTC时间为准
--     "longitude":113.231, // 经度, 正数为东经, 负数为西经
--     "latitude":23.4067,  // 纬度, 正数为北纬, 负数为南纬
--     "us":0               // 微妙数, 通常为0
-- }
--模式0示例：
--json.encode默认输出"7f"格式保留7位小数，可以根据自己需要的格式调整小数位，本示例保留5位小数
local gll = exgnss.gll(0)
if gll then
    log.info("GLL0", json.encode(gll, "5f"))
end
{"longitude":11419.19531,"sec":14,"min":32,"mode":"A","hour":6,"us":0,"status":"A","latitude":3447.86914}
--模式1示例：
--DDDDDDDDD格式是由DD.DDDDDDD*10000000转换而来，目的是作为整数，方便某些场景使用
local gll1 = exgnss.gll(1)
if gll1 then
    log.info("GLL1", json.encode(gll1))
end
{"longitude":1143199103,"sec":14,"min":32,"mode":"A","hour":6,"us":0,"status":"A","latitude":347978178}
模式2示例：
--json.encode默认输出"7f"格式保留7位小数，可以根据自己需要的格式调整小数位
local gll2 = exgnss.gll(2)
if gll2 then
    log.info("GLL2", json.encode(gll2))
end
{"longitude":114.3199081,"sec":14,"min":32,"mode":"A","hour":6,"us":0,"status":"A","latitude":34.7978172}
]]
function exgnss.gll(data_mode)
    return  libgnss.getGll(data_mode)
end
--[[
获取最后的经纬度数据
@api exgnss.last_loc()
@return table 经纬度数据，表里面的内容：{lat=ddmm.mmmmm0000,lng=ddmm.mmmmm0000},返回nil表示没有数据，此数据在定位成功，关闭gps时，会自动保存到文件系统中，定位成功之后每10分钟如果还处于定位成功状态会更新
@usage
local loc= exgnss.last_loc()
if loc then
    log.info("lastloc", loc.lat,loc.lng)
end
日志输出内容示例：
3447.8679200000 11419.196290000
]]
function exgnss.last_loc()
    local locStr = io.readFile("/hxxtloc")
    if locStr then
        local jdata = json.decode(locStr)
        return jdata 
    end
end
return exgnss