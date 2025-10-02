-- YED-M780-B V0.4 эхний програм
sys = require("sys")

-- GPIO тодорхойлолт
local LED_PIN = 27

-- GPIO эхлүүлэх
gpio.setup(LED_PIN, gpio.OUT)

-- Гэрэл анивчдаг функц
sys.timerLoopStart(function()
    gpio.set(LED_PIN, not gpio.get(LED_PIN))
    log.info("LED", gpio.get(LED_PIN) and "ON" or "OFF")
end, 1000)

-- Үндсэн давталт
sys.run()
