local moduleName = ...
local M={}
_G[moduleName] = M
local ficheroConfiguracion="config.ini" --nombre del fichero de configuracion
local ficheroConfiguracionAux=ficheroConfiguracion .. ".aux"
local ficheroConfiguracionBack=ficheroConfiguracion .. ".back"

--Patrones de busqueda en el fichero. Son las secciones que tiene el fichero de configuracion
--Ej:[GENERAL]
--Son las que van entre corchetes
local seccion={"^%[GENERAL%]","^%[STATION%]","^%[ACCESS_POINT%]"}
--Total de secciones
local totalSecciones=#seccion
--Nombre de las secciones en la variable CONFIGURACION_WIFI
local seccionActualTxt={"GENERAL","STA","AP"} 

--setenvf(1,M) 

--Definición de las variables globales de configuración
--Opciones generales
--Opciones modo estación
--Opciones modo punto acceso
M.inicializa=function()
    CONF_WIFI={
    ["GENERAL"]={
    ["WIFI_MODE"]="",
    ["WIFI_STANDARD"]="",
    ["WIFI_SLEEP"]="",
    ["UART_BAUD"]="",
    ["DEBUG"]=""
    },
    ["STA"]={
    ["STA_HOSTNAME"]="",
    ["STA_IP"]="",
    ["STA_NETMASK"]="",
    ["STA_MAC"]="",
    ["STA_GATEWAY"]="",
    ["STA_SSID"]="",
    ["STA_PASSWORD"]=""
    },
    ["AP"]={
    ["AP_SSID"]="",
    ["AP_PASSWORD"]="",
    ["AP_SECURITY"]="",
    ["AP_HIDDEN"]="",
    ["AP_CHANNEL"]="",
    ["AP_MAX_CONNECTIONS"]="",
    ["AP_IP"]="",
    ["AP_NETMASK"]="",
    ["AP_MAC"]="",
    ["AP_GATEWAY"]="",
    ["AP_DHCP_START"]="",
    ["AP_ALLOW_MAC"]=""
    }}
end

--Separa una linea en parametro y valor y nos devuelve el valor
M.extraeValor=function (linea)
    local valor
    valor=string.match(linea,"=.*;")
    valor=string.sub(valor,2,string.len(valor)-1)
    return valor
end 

M.buscaSeccion=function(linea)
    local numSeccion=nil
    local i=1
    --Miramos a ver a que seccion pertenece
    while i<=totalSecciones do
        if string.match(linea,seccion[i]) ~= nil then
            numSeccion=i
            i=totalSecciones --me salgo, ya he encontrado la seccion
        end
        i=i+1
    end
    return numSeccion
end

--Vamos a leer el fichero de configuración y conseguir la configuración
--del esp8266 que tenemos grabada en el fichero de configuración

M.readConfig=function()
    local lineaFichConf=""
    --local seccion={"^%[GENERAL%]","^%[STATION%]","^%[ACCESS_POINT%]"} --Patrones de busqueda en el fichero
    --local totalSecciones=#seccion
    local seccionActual
    --local seccionActualTxt={"GENERAL","STA","AP"} --Nombre de las secciones en la variable CONFIGURACION_WIFI 
    --local i,valor
    local valor
    --Creamos las variables que vamos a buscar en el fichero
    M.inicializa()
    --Abrimos el fichero de configuración y lo leeremos de linea en linea
    if (file.open(ficheroConfiguracion,"r")) then
        lineaFichConf=file.readline()
        while lineaFichConf~=nil do
           -- print(lineaFichConf)
            --Si la linea no es un comentario la vamos a tratar
            if string.match(lineaFichConf,"^%s*#") == nil then
                --print(lineaFichConf)
                --Si la linea es una sección, miramos a ver cual es y lo ponemos en seccionActual
                --Si no es ninguna de las que tenemos se queda a nil y esa seccion no se procesa
                --Una seccion es una línea que comience y temine en corchetes por ejemplo [GENERAL]
                if string.match(lineaFichConf,"^%[.*%]") ~= nil then
                    seccionActual=M.buscaSeccion(lineaFichConf)
                else
                    if seccionActual~=nil then
                        --es una seccion y vamos a mirar si es una de las que tenemos controladas
                        --La seccion en número se corresponde con un texto, que es parte del array del CONF_WIFI
                        --Si estamos en la seccion GENERAL en la variable CONF_WIFI
                        --será CONF_WIFI[seccionActualTxt[1]]
                        --los arrays empiezan con uno
                        if seccionActualTxt[seccionActual]~= nil then
                            for key,v in pairs(CONF_WIFI[seccionActualTxt[seccionActual]]) do
                                if string.match(lineaFichConf,"^" .. key )~= nil then
                                    valor=M.extraeValor(lineaFichConf)
                                    CONF_WIFI[seccionActualTxt[seccionActual]][key]=valor;
                                    --print(seccionActualTxt[seccionActual] .. " " .. key .."=" .. valor)
                                end 
                            end
                        end
                     end-- de seccion no es igual a nil
                end -- soy una linea de parametro y no una cabecera de configuracion
            end --no soy comentario
            
            lineaFichConf=file.readline()
        end --del bucle de lectura
        file.close() --Cerramos el fichero
    else
        debug("Fichero de configuracion no encontrado")
    end
end

M.writeConfig=function()
    local lineaFichConf=""
--    local seccion={"^%[GENERAL%]","^%[STATION%]","^%[ACCESS_POINT%]"} --Patrones de busqueda en el fichero
 --   local totalSecciones=#seccion
    local seccionActual=nil
 --   local seccionActualTxt={"GENERAL","STA","AP"} --Nombre de las secciones en la variable CONFIGURACION_WIFI 
 --   local i,valor
    local lineaAux
    local bytesLeidos=0
    --borramos el fichero auxiliar si existe
    file.remove(ficheroConfiguracionAux)
    if (file.open(ficheroConfiguracion,"r")) then
        lineaFichConf=file.readline()
        file.close()
        while lineaFichConf~=nil do
            bytesLeidos=bytesLeidos+string.len(lineaFichConf) --Calculamos lo que hemos leido del fichero de configuración
            file.open(ficheroConfiguracionAux,"a")    --abrimos el fichero de configuración auxiliar
            --si la linea es un comentario la escribimos tal cual
            if string.match(lineaFichConf,"^%s*#") == nil then
                --si la linea es una seccion miramos cual es
                if string.match(lineaFichConf,"^%[.*%]") ~= nil then
                    seccionActual=M.buscaSeccion(lineaFichConf)
                else
                    --Estoy dentro de una seccion
                    if seccionActual~=nil then
                        --es una seccion y vamos a mirar si es una de las que tenemos controladas
                        --La seccion en número se corresponde con un texto, que es parte del array del CONF_WIFI
                        --Si estamos en la seccion GENERAL en la variable CONF_WIFI
                        --será CONF_WIFI[seccionActualTxt[1]]
                        --los arrays empiezan con uno
                        if seccionActualTxt[seccionActual]~= nil then
                            for key,v in pairs(CONF_WIFI[seccionActualTxt[seccionActual]]) do
                                if string.match(lineaFichConf,"^" .. key )~= nil then
                                    --busco el igual, recorto hasta él, y pego el nuevo valor con su ";" correspondiente
                                    lineaAux=string.sub(lineaFichConf,1,string.find(lineaFichConf,"=")) .. CONF_WIFI[seccionActualTxt[seccionActual]][key]
                                    --busco si la linea tiene comentarios para pegarselos después del ;
                                    lineaAux=lineaAux .. string.sub(lineaFichConf,string.find(lineaFichConf,";"),-1)
                                    lineaFichConf=lineaAux
                                    break --me salgo del bucle for, ya he hecho lo que queria
                                end 
                            end
                        end
                     end-- de seccion
                end
            end
            file.write(lineaFichConf) --Escribimos la linea en el fichero auxiliar
            file.close()                -- cerramos fichero auxiliar
            file.open(ficheroConfiguracion,"r")  --volmemos a abrir fichero de configuración 
            file.seek("set",bytesLeidos)         --Vamos a donde nos habiamos quedado leyendo
            lineaFichConf=file.readline()        --leemos la nueva linea
            file.close()                         --Cerramos el fichero de configuración
        end
        --si llegamos aquí todo ha ido bien
        --Eliminamos el fichero .back si lo hay
        file.remove(ficheroConfiguracionBack)

        --renombramos el config.ini a config.ini.back
        file.rename(ficheroConfiguracion,ficheroConfiguracionBack)

        --renombramos el config.ini.aux a config.ini
        file.rename(ficheroConfiguracionAux,ficheroConfiguracion)

        --M.viewFile(ficheroConfiguracion)
    else
        debug("Fichero de configuracion no encontrado")
    end
end

--Por si necesita ver un fichero
M.viewFile=function(fichero)
    local linea
    file.open(fichero,"r")
    linea=file.readline()
    while linea~=nil do
        linea=string.gsub(linea,"\n","")    --le quitamos el salto de linea, que ya lo hará el debug
        debug(linea)
        linea=file.readline()
    end 
    file.close()
end
return M
