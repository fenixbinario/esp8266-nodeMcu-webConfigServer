local moduleName = ...
local M={}
_G[moduleName] = M
M.configAccion=function()
    local detenerServicio=true
    local retorno
    local respuestaEstandard
    --respuesta estandard devulve OK,y la acción que se ha echo
    respuestaEstandard="OK"..","..request1.query["accion"]
    
    --Son cambios que no son inmediatos y requieren normalmente para el servidor
    --tienen el parametro accion= a algo ej /config?accion=changeGeneral
    if request1.query["accion"]=="changeGeneral" then
        --Cambiamos el modo general de funcionamiento del esp8266
         --si no he cambiado nada de los tres primeros, no hace falta hacerlo todo desde el principio
        if CONF_WIFI["GENERAL"]["WIFI_MODE"] == request1.query["modoEsp8266"] and 
            CONF_WIFI["GENERAL"]["WIFI_SLEEP"]==request1.query["sleepEsp8266"] and 
            CONF_WIFI["GENERAL"]["WIFI_STANDARD"]==request1.query["estandardRed"] then
            detenerServicio=false
        else
            CONF_WIFI["GENERAL"]["WIFI_MODE"]=request1.query["modoEsp8266"]
            CONF_WIFI["GENERAL"]["WIFI_SLEEP"]=request1.query["sleepEsp8266"]
            CONF_WIFI["GENERAL"]["WIFI_STANDARD"]=request1.query["estandardRed"]
        end
        --Estas dos las establecemos siempre
        CONF_WIFI["GENERAL"]["UART_BAUD"]=request1.query["uartSetupEsp8266"]
        CONF_WIFI["GENERAL"]["DEBUG"]=request1.query["debugEsp8266"]

        if detenerServicio then
            retorno=respuestaEstandard
        else
            --ha podido cambiar el uartSetup o el debug
            --El debug con cambiar la variable ya se actualiza, porque pregunta por ella
            --El uartSetup con modificarlo aquí vale
            debug("Modificando Velocidad Uart a " .. CONF_WIFI["GENERAL"]["UART_BAUD"])
            
            --le damos un segundo a que imprima el debug con la velocidad anterior
            tmr.alarm(0,1000,tmr.ALARM_SINGLE,function()
                uart.setup(0,CONF_WIFI["GENERAL"]["UART_BAUD"], 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
            end)
            retorno=respuestaInmediato
        end 
    elseif request1.query["accion"]=="changeEstacionParam" then
        --Cambismo los parámetros generales del modo estación
        CONF_WIFI["STA"]["STA_HOSTNAME"]=request1.query["staHostname"]
        --Si la actual mac no está establecida y es la de por defecto
        --Si la mac es la misma que la por defecto no la establezco en el fichero de conf
        --Dejo que el esp8266 elija la suya por defecto
        if CONF_WIFI["STA"]["STA_MAC"]=="" then
            local mac=wifi.sta.getmac()
            if mac~=request1.query["staMac"] then
                CONF_WIFI["STA"]["STA_MAC"]=request1.query["staMac"]
            end
        end
        if request1.query["staDhcpAuto"]=="n" then
            CONF_WIFI["STA"]["STA_IP"]=request1.query["staIp"]
            CONF_WIFI["STA"]["STA_NETMASK"]=request1.query["staNetmask"]
            CONF_WIFI["STA"]["STA_GATEWAY"]=request1.query["staGateway"]
        else
            --las ponemos como automaticas.
            CONF_WIFI["STA"]["STA_IP"]=""
            CONF_WIFI["STA"]["STA_NETMASK"]=""
            CONF_WIFI["STA"]["STA_GATEWAY"]=""
        end
        retorno=respuestaEstandard
    elseif request1.query["accion"]=="changeEstacionConnect" then
        --Nos conectamos a un ap, en modo estación
        CONF_WIFI["STA"]["STA_SSID"]=request1.query["ssid"]
        CONF_WIFI["STA"]["STA_PASSWORD"]=request1.query["password"]
        retorno=respuestaEstandard
    elseif request1.query["accion"]=="changeApParam" then
        --Cambiamos los parámetros del modo ap
        CONF_WIFI["AP"]["AP_SSID"]=request1.query["apSsid"]
        CONF_WIFI["AP"]["AP_PASSWORD"]=request1.query["apPassword"]
        CONF_WIFI["AP"]["AP_SECURITY"]=request1.query["apSecurity"]
        CONF_WIFI["AP"]["AP_HIDDEN"]=request1.query["apVisible"]
        CONF_WIFI["AP"]["AP_CHANNEL"]=request1.query["apCanal"]
        CONF_WIFI["AP"]["AP_MAX_CONNECTIONS"]=request1.query["apMaxCon"]
        CONF_WIFI["AP"]["AP_IP"]=request1.query["apIp"]
        CONF_WIFI["AP"]["AP_NETMASK"]=request1.query["apNetmask"]
        CONF_WIFI["AP"]["AP_MAC"]=request1.query["apMac"]
        CONF_WIFI["AP"]["AP_GATEWAY"]=request1.query["apGateway"]
        CONF_WIFI["AP"]["AP_DHCP_START"]=request1.query["apDhcp"]
        retorno=respuestaEstandard
    elseif request1.query["accion"]=="addApAllowMac" then
        --Añadimos una mac a la lista de clientes no permitidos en modo ap

        --Si es la primera mac que añado quiero que cuando termine, se ejecute el fichero de conexión desde 0.
        --para que se registre el evento que vigila quien se conecta y quien no
        --Si ya está arrancado el proceso no hace falte que detenga el servicio y ejecute el fichero de conexión.
        if CONF_WIFI["AP"]["AP_ALLOW_MAC"]=="" then
            detenerServicio=true
        else
            detenerServicio=false
        end
        
        --lo pasamos a mayúsculas
        request1.query["mac"]=string.upper(request1.query["mac"])
        
        local find=string.find(CONF_WIFI["AP"]["AP_ALLOW_MAC"],request1.query["mac"])
        --si no está añadida la mac en la lista la añadimos, sino pues paso de ella y ya esta
        if find == nil then
            if CONF_WIFI["AP"]["AP_ALLOW_MAC"]=="" then
                --es la primera que tenemos
                CONF_WIFI["AP"]["AP_ALLOW_MAC"]=request1.query["mac"]
            else
                --hay una o varias, por lo tanto le añadimos la ","
                CONF_WIFI["AP"]["AP_ALLOW_MAC"]=CONF_WIFI["AP"]["AP_ALLOW_MAC"] .. "," .. request1.query["mac"]
            end
            debug("AÑADO MAC Y QUEDA" .. CONF_WIFI["AP"]["AP_ALLOW_MAC"])
        end
        --detenerServicio=false
        retorno=respuestaEstandard
    elseif request1.query["accion"]=="removeApAllowMac" then
        --quitamos una mac de la lista de clientes no permitidos en modo ap

        --lo pasamos a mayúsculas
        request1.query["mac"]=string.upper(request1.query["mac"])
       
        --si la mac está la segunda, u otra a partir de la segunda
        CONF_WIFI["AP"]["AP_ALLOW_MAC"]=string.gsub(CONF_WIFI["AP"]["AP_ALLOW_MAC"],","..request1.query["mac"],"")
        --la primera mac, con más detrás
        CONF_WIFI["AP"]["AP_ALLOW_MAC"]=string.gsub(CONF_WIFI["AP"]["AP_ALLOW_MAC"],request1.query["mac"]..",","")
        --solo había una mac
        CONF_WIFI["AP"]["AP_ALLOW_MAC"]=string.gsub(CONF_WIFI["AP"]["AP_ALLOW_MAC"],request1.query["mac"],"")
        debug("Lista de Autorizados: ".. CONF_WIFI["AP"]["AP_ALLOW_MAC"])

        --limpiamos la lista de los clientes ya echados en esta sesión. Es para que no se impriman tantos mensajes de desautorizado al mismo.
        --Como hemos cambiado la lista quiero que por lo menos la primera vez se imprima si se ha echado a un cliente.
        CLIENTE_YA_ECHADO=""
        
        --Si se queda la lista vacía quitamos el proceso que vigila quien se conecta. Está en el fichero conexión.
        if CONF_WIFI["AP"]["AP_ALLOW_MAC"]=="" then
            wifi.eventmon.unregister(wifi.eventmon.AP_STACONNECTED)
        end
        detenerServicio=false
        retorno=respuestaEstandard
    else
        detenerServicio=false
        retorno=ERROR_404
    end
    --vamos a detener el servidor web y reinicialo, le damos un segundo a que envie la respuesta
    if detenerServicio then
        tmr.alarm(0,1000,tmr.ALARM_SINGLE,function()
                servidor.detieneServidor()
                wifi.sta.disconnect()
                liberaMemoria()
                --damos otro segundo a que haga sus cosas, para desconectarse
                tmr.alarm(0,1000,tmr.ALARM_SINGLE,function() configuraGeneral() end)
                end)
    end
    --Devolvemos un mensaje según lo que hayamos hecho
    return retorno
end
return M
