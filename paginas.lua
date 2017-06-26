--PAGINAS DEL SERVIDOR

local moduleName = ...
local PAGINAS={}
_G[moduleName] = PAGINAS

--Definición de las páginas del servidor
--en request1 tenemos request1.query y request1.url por si necesitan aquí.
--es una variable global mientras esté activa una conexión

PAGINAS.GPIO_OUTPUT =function(pin,status)
    --local gpio_write = gpio.read
    local gpioActual
    if pin == 1 then
        gpioActual=3 -- data pin 3, GPIO1
    else
        gpioActual=4 -- data pin 4, GPIO2
    end
    gpio.mode(gpioActual, gpio.OUTPUT) 
    if status==1 then
        gpio.write(gpioActual, gpio.HIGH)
    else
        gpio.write(gpioActual, gpio.LOW)
    end
end

--Todas las páginas que puedo servir. Pueden ser reales, es decir un fichero o sólo una acción, o ambas si se quiere

--Pagina relacionada con la configuración del Esp8266, depende de los parámetros que se le pase hará una cosa u otra
PAGINAS["/config"]=function()
	local retorno
	if request1.query and request1.query["accion"] then
		if request1.query["accion"] =="manageFiles" then
			local accion=require("configHtmlfiles")
			retorno=accion.configAccion()
			
			--Descargamos, para liberar memoria
			accion=nil
			configHtmlfiles=nil
			package.loaded["configHtmlfiles"]=nil
		else
			local accion=require("configHtmlaccion")
			retorno=accion.configAccion()
			
			--Descargamos, para liberar memoria
			accion=nil
			configHtmlaccion=nil
			package.loaded["configHtmlaccion"]=nil
		end
	else
		local configHtmlModule=require("configHtml")
		retorno=configHtmlModule.config()
		--Descargamos, para liberar memoria
		configHtmlModule=nil
		configHtml=nil
		package.loaded["configHtml"]=nil
	end
	return retorno
end


PAGINAS["/ON1"]=function()
    PAGINAS.GPIO_OUTPUT(1,1)
    return "OK,ON1"
end 

PAGINAS["/OFF1"]=function()
    PAGINAS.GPIO_OUTPUT(1,0)
    return "OK,OFF1"
end 

       
PAGINAS["/ON2"]=function()
    PAGINAS.GPIO_OUTPUT(2,1)
    return "OK,ON2"
end

PAGINAS["/OFF2"]=function()
    PAGINAS.GPIO_OUTPUT(2,0)
    return "OK,OFF2"
end 

PAGINAS["/ALL_ON"]=function()
    PAGINAS.GPIO_OUTPUT(1,1)
    PAGINAS.GPIO_OUTPUT(2,1)
    return "OK,ALL_ON"
end 

PAGINAS["/ALL_OFF"]=function()
    PAGINAS.GPIO_OUTPUT(1,0)
    PAGINAS.GPIO_OUTPUT(2,0)
    return "OK,ALL_OFF"
end

PAGINAS["/foto.png"]=function()
    return {nombreFichero="foto.png",tipoFichero="image/png"}
end
        
PAGINAS["/"]=function()
    varsDinamicas={}
    varsDinamicas["LUA_STATUS_OUTPUT1"]=gpio.read(3)
    varsDinamicas["LUA_STATUS_OUTPUT2"]=gpio.read(4)
    return {nombreFichero="index.html",tipoFichero="text/html"}
end

PAGINAS["/config.js"]=function()
    return {nombreFichero="config.js",tipoFichero="text/javascript"}
end

PAGINAS["/config.css"]=function()
    return {nombreFichero="config.css",tipoFichero="text/css"}
end

return PAGINAS

--FIN PAGINAS DEL SERVIDOR
