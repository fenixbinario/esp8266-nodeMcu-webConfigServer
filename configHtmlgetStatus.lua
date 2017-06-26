local moduleName = ...
local M={}
_G[moduleName] = M

--Vemos la configuración general y la cargamos en varsDinamicas
 M.getStatus=function()
    varsDinamicas={}
    local mem=collectgarbage("count")*1024
    varsDinamicas["LUA_MEMUSED"]=mem .. " bytes"
    varsDinamicas["LUA_MEMFREE"]=MEMORIA_LIBRE .. " bytes"
    varsDinamicas["LUA_WIFIMODE"]=CONF_WIFI["GENERAL"]["WIFI_MODE"]
    varsDinamicas["LUA_WIFIPHY"]=CONF_WIFI["GENERAL"]["WIFI_STANDARD"]
    varsDinamicas["LUA_SLEEPMODE"]=CONF_WIFI["GENERAL"]["WIFI_SLEEP"]
    varsDinamicas["LUA_UART_SETUP"]=CONF_WIFI["GENERAL"]["UART_BAUD"]
    varsDinamicas["LUA_DEBUG"]=CONF_WIFI["GENERAL"]["DEBUG"]
    
    
    --Conseguimos la configuración del modo estación si es que está activo
    if CONF_WIFI["GENERAL"]["WIFI_MODE"] == "sta" or CONF_WIFI["GENERAL"]["WIFI_MODE"] == "staAp" then
        local ip,netmask,gateway=wifi.sta.getip()
        if ip == nil then
            ip="No asignada"
        end
        --Sacamos la mac
        local mac=wifi.sta.getmac()
        local ssid, password, bssid_set, bssid=wifi.sta.getconfig()
        if ssid==nil then
            ssid=""
        end
        --Lo podiamos mirar en el config pero
        local mode=wifi.getmode()
        
        if mode==wifi.STATION then mode="sta"
            elseif mode==wifi.SOFTAP then mode="ap"
            elseif mode==wifi.STATIONAP then mode="staAp"
            elseif mode==wifi.NULLMODE then mode="nullmode"
        end
    
        --Vemos el estado que tenemos
        local status=wifi.sta.status()
        if status==0 then status="Sin Conexi&oacute;n"
            elseif status==1 then status="Conectando"
            elseif status==2 then status="WRONG PASSWORD"
            elseif status==3 then status="AP. No Encontrado"
            elseif status==4 then status="Fallo"
            elseif status==5 then status="Conexi&oacute;n Establecida"
        end
        
        local rssi=wifi.sta.getrssi()
        if rssi==nil then 
            rssi=""
        end
    
        
        local hostname=wifi.sta.gethostname()
    
          
        --varsDinamicas={LUA_WIFIADDRESS=ip,LUA_WIFIMAC=mac,LUA_WIFISTATUS=status,LUA_WIFIRSSI=rssi,LUA_WIFIMODE=mode,
        --LUA_WIFICONFNETWORK=ssid,LUA_WIFIPHY=phy,LUA_HOSTNAME=hostname}
        --LUA_WIFICONFNETWORK=ssid,LUA_WIFIPHY=phy,LUA_LISTAP=htmlAps}
        --Si tengo una ip en el fichero de configuración, es que es una ip fija, sino se ha obtenido por dhcp
        if CONF_WIFI["STA"]["STA_IP"]=="" then
            varsDinamicas["LUA_STA_DHCP"]="SI"
        else
            varsDinamicas["LUA_STA_DHCP"]="NO"
        end
        varsDinamicas["LUA_STA_ADDRESS"]=ip
        varsDinamicas["LUA_STA_NETMASK"]=netmask
        varsDinamicas["LUA_STA_GATEWAY"]=gateway
        varsDinamicas["LUA_STA_MAC"]=mac
        varsDinamicas["LUA_STA_STATUS"]=status
        varsDinamicas["LUA_STA_RSSI"]=rssi
        varsDinamicas["LUA_STA_CONFNETWORK"]=ssid
        varsDinamicas["LUA_STA_HOSTNAME"]=hostname
    end
    --Conseguimos la configuración del modo punto de acceso si está activo
    if CONF_WIFI["GENERAL"]["WIFI_MODE"] == "ap" or CONF_WIFI["GENERAL"]["WIFI_MODE"] == "staAp" then
        
        varsDinamicas["LUA_AP_SSID"]=CONF_WIFI["AP"]["AP_SSID"]
        varsDinamicas["LUA_AP_PASSWORD"]=CONF_WIFI["AP"]["AP_PASSWORD"]
        varsDinamicas["LUA_AP_SECURITY"]=CONF_WIFI["AP"]["AP_SECURITY"]
        if CONF_WIFI["AP"]["AP_HIDDEN"] == "0" or CONF_WIFI["AP"]["AP_HIDDEN"]=="" then
            varsDinamicas["LUA_AP_VISIBLE"]="Si"
        else
            varsDinamicas["LUA_AP_VISIBLE"]="No"
        end
        varsDinamicas["LUA_AP_CANAL"]=wifi.getchannel()
        varsDinamicas["LUA_AP_MAX_CONNECTIONS"]=CONF_WIFI["AP"]["AP_MAX_CONNECTIONS"]
        varsDinamicas["LUA_AP_DHCP_START"]=CONF_WIFI["AP"]["AP_DHCP_START"]
            
        local ip,netmask,gateway=wifi.ap.getip()
        varsDinamicas["LUA_AP_IP"]=ip
        varsDinamicas["LUA_AP_NETMASK"]=netmask
        varsDinamicas["LUA_AP_GATEWAY"]=gateway
    
        varsDinamicas["LUA_AP_MAC"]=wifi.ap.getmac()
        
    end
end
return M
