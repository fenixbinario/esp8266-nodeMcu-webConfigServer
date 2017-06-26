local moduleName = ...
local M={}
_G[moduleName] = M

M.configAccion=function()
    --jacin.ini
    --local detenerServicio=false
    --jacin.fin
    local retorno
    local respuestaEstandard
	--pregunto por el parámetro orden, para saber que tengo que hacer
    if request1.query["orden"] then
        --respuesta estandard devulve OK,y la acción que se ha echo
        respuestaEstandard="OK"..",".. request1.query["accion"] .. "," .. request1.query["orden"]
				
        if request1.query["orden"]=="appendFile" then
            --Si estoy en la primera ejecución del proceso de envio y existe
            --el fichero lo borro directamente
            --la aplicación web es la encargada de preguntar si existe primero el fichero
            if request1.query["progreso"]=="0" then
                if file.exists(request1.query["filename"]) then
                    file.remove(request1.query["filename"])
                end
            end
            --para grabar un fichero
            local totalBytesRecibidos=string.len(request1.query["data"])
            --vemos los bytes recibidos
            debug("Bytes para escribir: " .. totalBytesRecibidos)
            debug("Escribiendo Fichero: " .. request1.query["filename"])
            --abrimos el fichero en modo añadir y escribimos del tirón todos
            if file.open(request1.query["filename"], "a+") then
                file.write(request1.query["data"])
                file.close()
                retorno=respuestaEstandard
            else
                retorno="Error Grabando Fichero"
            end
        elseif request1.query["orden"]=="existe" then
            --para saber si existe un fichero
            if file.exists(request1.query["filename"]) then
                retorno=respuestaEstandard..",SI"
            else
                retorno=respuestaEstandard..",NO"
            end
        elseif request1.query["orden"]=="deleteFile" then
            --para eliminar un fichero
            if file.exists(request1.query["filename"]) then
                debug("Borrando fichero: " .. request1.query["filename"])
                file.remove(request1.query["filename"])
                retorno=respuestaEstandard
            else
                debug("No puedo borrar el fichero " .. request1.query["filename"] .. ", este no existe.")
                retorno="Error " .. request1.query["filename"] .. " no existe"
            end
        elseif request1.query["orden"]=="renameFile" then
            --para renombrar un fichero
            if file.exists(request1.query["filenameOld"]) then
                file.rename(request1.query["filenameOld"],request1.query["filenameNew"])
                retorno=respuestaEstandard
            else
                retorno="Error " .. request1.query["filenameOld"] .. " no existe"
            end
        elseif request1.query["orden"]=="listFiles" then
            local fichero,size
            retorno=""
            --lFiles debe conterner la lista de ficheros en la última vez que se llamó a listFiles
            --Se llama una vez al iniciar el esp8266 en el init
            --y luego aquí cada vez que se hace algo cuya accion sea igual manageFiles
            for fichero,size in pairs(lFiles) do
                retorno=retorno .. fichero .. "," .. size .. ";"
            end
            if retorno~="" then
                --quitamos el último ;
               retorno=string.sub(retorno,1,-2) 
            else
                retorno="NO_FILES"
            end
		elseif request1.query["orden"]=="compile" then
			if file.exists(request1.query["filename"]) then
				--Para compilar, lo que hago es meter los nombres en un fichero
				--reinicio el esp8266
				--Al iniciarse de nuevo y ya con toda la memoria disponible el esp8266 busca este fichero y compila todos los nombres de ficheros que contiene
				file.open(FICHERO_COMPILACIONES,"w")
				file.writeline(request1.query["filename"])
				file.close()
				--le damos un poco de tiempo a que cierre la conexión y lo reinicio
				tmr.alarm(0,500,tmr.ALARM_SINGLE,node.restart)
				retorno=respuestaEstandard
			else
				debug("El fichero para compila no existe")
				retorno="Error " .. request1.query["filename"] .. " no existe"
			end
		elseif request1.query["orden"]=="compileAll" then
			local extension
			local fichero
			local size
			--abrimos el fichero donde vamos a meter los nombres de los ficheros a compilar
			file.open(FICHERO_COMPILACIONES,"w")
			--nos recorremos todos los ficheros y si son .lua y existen los apunto para compilar
			for fichero,size in pairs(lFiles) do
				extension=string.sub(fichero,-4,-1)
				if extension==".lua" then
					if file.exists(fichero) then
						file.writeline(fichero)
					end
				end
            end
			file.close()
			--le damos un poco de tiempo a que cierre la conexión y lo reinicio
			tmr.alarm(0,500,tmr.ALARM_SINGLE,node.restart)
			retorno=respuestaEstandard
        else
            retorno=ERROR_404
        end
    else
        retorno=ERROR_404
    end

    --leemos los fichero para tenerlos actualizados en lFiles. Se hace así, porque es asíncrona la función
    --y si la llamamos directamente nos devuelve un nil
    listFiles()

    --jacin.ini
    --vamos a detener el servidor web y reinicialo, le damos un segundo a que envie la respuesta
    --if detenerServicio then
    --    tmr.alarm(0,1000,tmr.ALARM_SINGLE,function()
    --            servidor.detieneServidor()
    --            wifi.sta.disconnect()
    --            liberaMemoria()
    --            --damos otro segundo a que haga sus cosas, para desconectarse
    --            tmr.alarm(0,1000,tmr.ALARM_SINGLE,function() configuraGeneral() end)
    --            end)
    --end
    --jacin.fin
    
    --Devolvemos un mensaje según lo que hayamos hecho
    return retorno
end
return M
