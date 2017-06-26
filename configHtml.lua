--
local moduleName = ...
local CONFIG_HTML={}
_G[moduleName] = CONFIG_HTML

CONFIG_HTML.config=function()
    local respuestaRestart="OK,restart" -- 
    local respuestaSaveConfig="OK,saveConfig"
    local respuestaInmediato="OK,HECHO"
    
    
    --Peticiones simples sin parametros
    if request1.url=="/config" then
        --Si podemos escaneamos redes a ver que hay, para tenerlo listo, ya que la función es asíncrona
        scanAps()
        return {nombreFichero="config.html",tipoFichero="text/html"}
    elseif request1.url=="/config?scanAps" then
        --devolvemos las redes escaneadas, como la función de escanear tardaba un rato la hicimos asíncrona
        --es decir que ya tenemos escaneadas las redes y cuando terminamos esta función las volvemos a escanear para
        --tenerlas preparadas
        return CONFIG_HTML.scanApsTxt()
    elseif request1.url=="/config?getStatus" then
        --Obtenemos como está configurado actualmente el esp8266
        local status,k,v
        CONFIG_HTML.getStatus()
        status=""
        for k,v in pairs(varsDinamicas) do
            status=status .. string.sub(k,5,-1) .. "=" .. v .. ","
        end
		--Ya lo he procesado y no lo necesito
		varsDinamicas=nil 
        status=string.sub(status,1,-2)
        return status
    elseif request1.url=="/config?restart" then 
        --reseteamos el modulo, le damos un tiempo hasta que envie la respuesta a la petición
        tmr.alarm(0,1000,tmr.ALARM_SINGLE,function() node.restart() end)
        return respuestaRestart
    elseif request1.url=="/config?saveConfig" then
        --Grabamos en el fichero de configuración lo que tengamos en la variable global CONF_WIFI
        --Si resetearamos el modulo antes de grabar se perderían los cambios
        local fConfig=require("manageFConfig")
        fConfig.writeConfig()
        fConfig=nil
        manageFConfig=nil
        package.loaded["manageFConfig"]=nil
        return respuestaSaveConfig
    elseif request1.url=="/config?getApClients" then
        if CONF_WIFI["GENERAL"]["WIFI_MODE"]=="ap" or CONF_WIFI["GENERAL"]["WIFI_MODE"]=="staAp" then
            --Vamos a devolver los clientes que están conectados actualmente, más los que tenemos que no se pueden conectar
            --Además enviamos las macs, siempre en mayúsculas
            local table={}
            local aux="CONN="
            table=wifi.ap.getclient()
            for mac,ip in pairs(table) do
                mac=string.upper(mac)
                --Si ya le echado estará en esta variable, y hay un evento que se encarga de echarlo todo el rato.
                --Entonces le indico que ya no está conectado, porque se le va a echar inmediatamente.
                if string.find(CLIENTE_YA_ECHADO,mac)==nil then
                    aux=aux .. mac .. "," .. ip ..","
                end
            end
            --si no tenemos ningún cliente conectado, le ponemos la coma y quedará
            --AUTH=,DENY=. Es porque luego en el html busco ,DENY=
            if string.len(aux)==5 then
                aux=aux .. ","
            end
            aux=aux .. "ALLOW=" .. CONF_WIFI["AP"]["AP_ALLOW_MAC"]
            return aux
        else
            --devuelvo que no hay nadie conectado y la lista de permitidos, es por si me llaman para no resetear el modulo
            --por estar en el modo incorrecto
            return "CONN=,ALLOW=" .. CONF_WIFI["AP"]["AP_ALLOW_MAC"]
        end
    else
        return ERROR_404    
    end
end

CONFIG_HTML.getStatus=function()
   local status=require("configHtmlgetStatus")
   status.getStatus()
   status=nil
   configHtmlgetStatus=nil
   package.loaded["configHtmlgetStatus"]=nil
   
end

CONFIG_HTML.scanApsTxt=function()
    local txtAps=""
    --sólo se pueden escanear puntos de acceso, si tenemos activo sta o staAp
    --es decir, que el módulo pueda funcionar en modo estación
    --listAps es una variable global que se actualiza con la función scanAps
    --como la función de escanear redes es asincrona, pues nunca tenemos lo actual, sino lo escaneado en el anterior scanAps
    if listAps~=nil then
        local ssid,v
        for ssid,v  in pairs(listAps) do
            local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
            if authmode == "0" then authmode="Open"
            elseif authmode == "1" then authmode="WEP"
            elseif authmode == "2" then authmode="WPA"
            elseif authmode == "3" then authmode="WPA2"
            elseif authmode == "4" then authmode="WPA+WPA2"
            end
            txtAps=txtAps .. ssid .. "," .. bssid .. "," .. rssi .. "," .. authmode .. "," .. channel .. "\n\r"
        end
    else
        txtAps="Error Vuelve a Intentarlo"
    end
    --Escaneamos después otra vez para dejarlo preparado. Se hace así, porque la función es asíncrona, es decir va a su bola
     scanAps()
    return txtAps
end --del if

return CONFIG_HTML
