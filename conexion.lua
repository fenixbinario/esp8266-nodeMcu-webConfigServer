local moduleName = ...
local M={}
_G[moduleName] = M

local default={}
default.apIp="192.168.1.1"
default.apNetmask="255.255.255.0"
default.apGateway="192.168.1.1"
default.apPassword="esp82266admin"
default.apSsid="ESP8266-LINK"
default.apSecurity="OPEN"
default.apMaxConnections=4
default.apDhcpStart="192.168.1.100"

--Configuramos los demás parámetros en modo station con esta función
M.configuraStation=function()
    --Si tenemos hostname lo establecemos
    if CONF_WIFI["STA"]["STA_HOSTNAME"]~="" then
        wifi.sta.sethostname(CONF_WIFI["STA"]["STA_HOSTNAME"])
    end
    
    --Para configurar una ip estática necesito por lo menos la ip y el netmask
    local cfg={}
    if CONF_WIFI["STA"]["STA_IP"]~="" and CONF_WIFI["STA"]["STA_NETMASK"]~="" then
        cfg.ip = CONF_WIFI["STA"]["STA_IP"]
        cfg.netmask = CONF_WIFI["STA"]["STA_NETMASK"]
        cfg.gateway = CONF_WIFI["STA"]["STA_GATEWAY"]
        wifi.sta.setip(cfg)
    end
    
    --Si tenemos una nueva mac la cambiamos
    if CONF_WIFI["STA"]["STA_MAC"] ~= "" then
        wifi.sta.setmac(CONF_WIFI["STA"]["STA_MAC"])
    end
    
    --Nos conectamos al punto de acceso, o lo intentamos
    if CONF_WIFI["STA"]["STA_SSID"]~="" then
        wifi.sta.config(CONF_WIFI["STA"]["STA_SSID"],CONF_WIFI["STA"]["STA_PASSWORD"])
        wifi.sta.connect()
    end 
end

--Configuración del esp8266 para convertirlo en punto de acceso
M.configuraAp=function()
    if CONF_WIFI["AP"]["AP_MAC"] ~= "" then
        wifi.ap.setmac(CONF_WIFI["AP"]["AP_MAC"])
    end
    
    local cfg={}
    if CONF_WIFI["AP"]["AP_SSID"] == "" then
        CONF_WIFI["AP"]["AP_SSID"]=default.apSsid
    end
    cfg.ssid=CONF_WIFI["AP"]["AP_SSID"]
   
    --necesito siempre un password aunque sea en modo ap y la red open. Sino, no funciona 
    if CONF_WIFI["AP"]["AP_PASSWORD"] == "" then
        CONF_WIFI["AP"]["AP_PASSWORD"]=default.apPassword
    end
    cfg.pwd=CONF_WIFI["AP"]["AP_PASSWORD"]

    if CONF_WIFI["AP"]["AP_SECURITY"] ~= "" then
        if CONF_WIFI["AP"]["AP_SECURITY"]=="WPA_PSK" then
            cfg.auth=wifi.WPA_PSK
        elseif CONF_WIFI["AP"]["AP_SECURITY"]=="WPA2_PSK" then
            cfg.auth=wifi.WPA2_PSK
        elseif CONF_WIFI["AP"]["AP_SECURITY"]=="WPA_WPA2_PSK" then
            cfg.auth=wifi.WPA_WPA2_PSK
        elseif CONF_WIFI["AP"]["AP_SECURITY"]=="OPEN" then
            cfg.auth=wifi.OPEN
        end
    else
        cfg.auth=wifi.OPEN
        CONF_WIFI["AP"]["AP_SECURITY"]=default.apSecurity
    end

    if CONF_WIFI["AP"]["AP_CHANNEL"] ~= "" then
        cfg.channel=CONF_WIFI["AP"]["AP_CHANNEL"]
    end

    if CONF_WIFI["AP"]["AP_HIDDEN"] == 1 then
        --0 visible 1 hidden
        --en pruebas cualquier valor que le ponga, oculta el ssid. Asi que si tiene 0 en la configuración
        --lo que hago es no declararle y estará a nil
        cfg.hidden=CONF_WIFI["AP"]["AP_HIDDEN"]
    else
        cfg.hidden=nil
    end
    
    if CONF_WIFI["AP"]["AP_MAX_CONNECTIONS"] == "" then
        CONF_WIFI["AP"]["AP_MAX_CONNECTIONS"]=default.apMaxConnections
    end
    cfg.max=CONF_WIFI["AP"]["AP_MAX_CONNECTIONS"]
    
    wifi.ap.config(cfg)
    
    local cfgIp ={}

    if CONF_WIFI["AP"]["AP_IP"] == "" then
        CONF_WIFI["AP"]["AP_IP"]=default.apIp
    end
    cfgIp.ip=CONF_WIFI["AP"]["AP_IP"]
    
    if CONF_WIFI["AP"]["AP_NETMASK"] == "" then
        CONF_WIFI["AP"]["AP_NETMASK"]=default.apNetmask
    end
    cfgIp.netmask=CONF_WIFI["AP"]["AP_NETMASK"]
    
    if CONF_WIFI["AP"]["AP_GATEWAY"] == "" then
        CONF_WIFI["AP"]["AP_GATEWAY"]=default.apGateway
    end
    cfgIp.gateway=CONF_WIFI["AP"]["AP_GATEWAY"]
    
    wifi.ap.setip(cfgIp)
    
    local dhcp_config ={}
    
    if CONF_WIFI["AP"]["AP_DHCP_START"] == "" then
        CONF_WIFI["AP"]["AP_DHCP_START"]=default.apDhcpStart
    end
    dhcp_config.start=CONF_WIFI["AP"]["AP_DHCP_START"]

    wifi.ap.dhcp.config(dhcp_config)
    wifi.ap.dhcp.start()

    --Si tenemos una lista de macs permitidas. Crearemos un evento, que mirará que cada estación que se conecta a nosotros está 
    --en la lista. Si no está en la lista se le echa.
    --Esta función se repite muchas veces
    if CONF_WIFI["AP"]["AP_ALLOW_MAC"]~="" then
        wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T) 
            local autorizada=false
            local mensaje=true
            local mac=string.upper(T.MAC)
            if string.find(CLIENTE_YA_ECHADO,mac)~=nil then
                mensaje=false
            end
            if mensaje then
                debug("\n\tAP - Conectado".."\n\tMAC: ".. mac)
            end
            if CONF_WIFI["AP"]["AP_ALLOW_MAC"]~="" then
                if string.find(CONF_WIFI["AP"]["AP_ALLOW_MAC"],mac)~=nil then
                    autorizada=true
                end
            else
                --la lista de autorizados está vacía por lo tanto todos están autorizados por defecto.
                autorizada=true
            end
            if autorizada==false then
                wifi.ap.deauth(T.MAC)
                if mensaje then
                    debug("\tEstacion desautorizada.")
                    CLIENTE_YA_ECHADO=CLIENTE_YA_ECHADO .. "," .. mac
                end
            end
            
        end)
    end

    --imprimimos como lo hemos configurado
    debug("Caracteristicas modo punto de acceso:")
    debug("\tSSID: " .. cfg.ssid)
    debug("\tPassword: " .. cfg.pwd)
    debug("\tIp: " .. cfgIp.ip)
    debug("\tNetmask: " .. cfgIp.netmask)
    debug("\tGateway: " .. cfgIp.gateway)
    debug("\tDhcp start: " .. dhcp_config.start)
    debug("\tLista MAC autorizados: " .. CONF_WIFI["AP"]["AP_ALLOW_MAC"])
end

--Esta función es sólo necesaria si el modo estación esta activo. Es porque la función de conseguir una ip tarda un poco y no puedo
--montar el servidor sin tener una ip válida. Se hace con un timer para no bloquear la ejecución del esp8266
M.montaServidor = function()
 
    scanAps()
    debug("Caracteristicas Modo Estacion")
    debug("\tHostname: " .. CONF_WIFI["STA"]["STA_HOSTNAME"])
    debug("\tLa direccion MAC es: " .. wifi.sta.getmac())
    debug("\tConectando a punto de acceso: " .. CONF_WIFI["STA"]["STA_SSID"])
    debug("\tEsperando a obtener una ip.")
    --dofile("servidor.lua")

    tmr.alarm(0,1000,tmr.ALARM_AUTO,function()
        if wifi.sta.getip() == nil then
            uart.write(0,".")
            --error, wrong password o punto de acceso no encontrado
            if wifi.sta.status()==2 or wifi.sta.status()==3 or wifi.sta.status() == 4 then
                tmr.stop(0)
                tmr.unregister(0)
                debug("\t\tError, password incorrecto o ap no encontrado");
            end
            --print(configuracionTerminada)
        else
            debug("")
            debug("Configuracion Completada, la IP del modo estacion es ".. wifi.sta.getip())
            tmr.stop(0)
            tmr.unregister(0)
            --inicia el servidor en el puerto 80
            servidor.iniciarServidor(80)
            wifi.sta.getip()
            liberaMemoria()
            --iniciarServidor(80) 
        end 
    end)
end

M.configuraGeneral=function()

    --Configuramos el estandard de red
    if CONF_WIFI["GENERAL"]["WIFI_STANDARD"]=="b" then
        wifi.setphymode(wifi.PHYMODE_B)
    elseif CONF_WIFI["GENERAL"]["WIFI_STANDARD"]=="g" then
        wifi.setphymode(wifi.PHYMODE_G)
    elseif CONF_WIFI["GENERAL"]["WIFI_STANDARD"]=="n" then
        wifi.setphymode(wifi.PHYMODE_N)
    end

    if CONF_WIFI["GENERAL"]["WIFI_SLEEP"]=="ns" then
        wifi.sleeptype(wifi.NONE_SLEEP)
    elseif CONF_WIFI["GENERAL"]["WIFI_SLEEP"]=="ls" then
        wifi.sleeptype(wifi.LIGHT_SLEEP)
    elseif CONF_WIFI["GENERAL"]["WIFI_SLEEP"]=="ms" then
        wifi.sleeptype(wifi.MODEM_SLEEP)
    end

    --Configuramos el modo elegido en el fichero de configuración
    if CONF_WIFI["GENERAL"]["WIFI_MODE"]=="sta" then
        wifi.setmode(wifi.STATION)
        M.configuraStation()
        M.montaServidor()
    elseif CONF_WIFI["GENERAL"]["WIFI_MODE"]=="ap" then
        wifi.setmode(wifi.SOFTAP)
        M.configuraAp()
        servidor.iniciarServidor(80)
    elseif CONF_WIFI["GENERAL"]["WIFI_MODE"]=="staAp" then
        wifi.setmode(wifi.STATIONAP)
        M.configuraStation()
        M.configuraAp()
        --Me han cambiado a modo Estación y Punto de Acceso. Si no tengo todavía un SSID
        --no intento conectarme en modo estación. Sigo dejando del modo AP
        if CONF_WIFI["STA"]["STA_SSID"]~="" then
            M.montaServidor()
        else
            servidor.iniciarServidor(80)
        end
        --NULLMODE no puedo ser, es tontería
    --elseif CONF_WIFI["GENERAL"]["WIFI_MODE"]=="null" then
    --    wifi.setmode(wifi.NULLMODE)
    end

    local uartBaud=CONF_WIFI["GENERAL"]["UART_BAUD"]
    if uartBaud~="" then
        uart.setup(0,uartBaud , 8, 0, 1, 1 )
    else
        uart.setup(0,115200 , 8, 0, 1, 1 )
    end 

    local mode=wifi.getmode()
    debug("Configuracion General ESP8266")
    debug("\tEl modo de Ejecucion es: ")
    if mode==1 then
        debug("\t\tEstacion")
    elseif mode==2 then
        debug("\t\tPunto de acceso")
    elseif mode==3 then
        debug("\t\tEstacion y Punto de acceso")
    end

    debug("\tConfigurando Wifi Standard:" ..CONF_WIFI["GENERAL"]["WIFI_STANDARD"])
    debug("\tConfigurando Sleep:" ..CONF_WIFI["GENERAL"]["WIFI_SLEEP"])
    debug("\tConfigurando Modo Wifi:" .. CONF_WIFI["GENERAL"]["WIFI_MODE"]) 
end

return M





