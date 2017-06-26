--Fichero que contiene la lógica y manejo del servidor
local moduleName = ...
local SERVIDOR={}
_G[moduleName] = SERVIDOR

--Creación del servidor
local srv=net.createServer(net.TCP)
local activo

SERVIDOR.detieneServidor=function()
    srv:close()
end

--iniciarServidor = function (puerto)
SERVIDOR.iniciarServidor=function(puerto)

	--esta variable me va a indicar si ya he llamado a la función socket1:send y si ha terminado
    local estoyEnviandoAlgo=false

    --Será un array donde tenemos lo que queremos enviar de respuesta. 
    local respuesta={}
	
	--Variable que nos tendrá desglosada una petición recibida, en forma de parametros en unas tablas, en vez del string inicial que se recibe
	local peticionDesglosada
	
	--Ini Variables necesarias para realizar el envio de un fichero.
    
	local envioFichero=nil	--Será una tabla con el nombre del fichero, el tipo y los bytes a enviar
    varsDinamicas=nil     --Contendrá las sustituciones que hay que realizar en el envío del fichero
    
    --Si al sustituir variables en el fichero el paquete se hace más grande, lo partimos para ajustarlo al tamaño del buffer
    --y nunca enviar un paquete más grande, nos indicará si tenemos algo pendiente de enviar
    local bufferPending=false
	
	local tamBuffer=768    --tamaño de los paquetes para enviar
	local maxTamVar=30     --tamaño maximo del nombre de una variable. Para garantizar su sustitución
						   --Ej. LUA_TEMP, esto son ocho, si fuera LUA_PATATINPATANTATNTNNT
						   --si es más grande que esta variable puede que no sea sustituida
    
	--Fin Variables para envio de fichero
	
	--Variables donde se guardarán las peticiones y las conexiones (sockets) que nos piden algo
	--Se van añadiendo en el evento on:receive
	--y la función de atenderPetición será la encargada de resolverlas
	local peticiones={}
	local sockets={}
	local ocupadoAtendiendoPeticion=false --nos indicará si estamos atendiendo una petición, y hasta que no terminemos con esta no empezaremos otra
	
    --Esta función nos analiza la petición que nos ha hecho el navegador, o quien sea
    --nos devuelve el metodo y la dirección
    --Se almacenará en peticionDesglosada en vez de retornarlo
    local parseRequest = function(request)
        -- the first line of the request is in the form METHOD URL PROTOCOL
        local _, _, method, url = string.find(request, "(%a+)%s([^%s]+)")
        local _, _, path, queryString = string.find(url, "([^%s]+)%?([^%s]+)")
        local query={}
        if queryString then
            local parametroAux
            local key,valor,termino,i
            for parametroAux in string.gmatch(queryString, "[^%&]+") do
                i=0
                --El primero antes del igual será el key y el de después del igual el valor
                key=""
                valor=""
                for termino in string.gmatch(parametroAux,"[^%=]+") do
                    if i==0 then
                        key=termino
                    else
                        valor=termino
                    end
                    i=i+1 
                end
                query[key]=valor
            end
            --Para enviar ficheros al final de la petición adjuntamos el fichero o parte de él
            --si cualquier petición tiene un buffer, lo almacenaremos en data recortando desde el final de la petición
            if query["buffer"] then
                query["data"]=string.sub(request,-query["buffer"])
            end
        else
            path = url
            query = nil
        end
        peticionDesglosada={ method = method, url = url, path = path, query = query}
      end

    --Nos devuelve el tamaño de un fichero en el sistema del nodemcu
    local getBytes = function(fichero)
        local totalBytes = 0
        for nombreFichero,bytes in pairs(file.list()) do
            if nombreFichero == fichero then
                totalBytes=bytes
                break
            end
        end
        return totalBytes
    end
    
    
	--enviará un texto de respuesta. Lo añade a un array y la función sendTextAux, será la encargada de gestionar que se envía
    --y que termina el envío, para cerrar la conexión.
	--En cuanto quede vacío el array respuesta, se cerrará la conexión
	local sendText=function(text)
		--añadimos al array lo que queremos enviar
		respuesta[#respuesta+1]=text
		--Si es la primera vez que empiezo a enviar algo, llamamos a la función que controlará el envio
		--Si ya estaba enviando no es necesario decirle que empiece, sólo añado al array y salgo
		if estoyEnviandoAlgo==false then
			estoyEnviandoAlgo=true
			socket1:send(table.remove(respuesta,1))
		end
	end
	

	--Función encargada de enviar un fichero y trocearlo y enviarlo en partes si es demasiado grande.
	--Se llamará tantas veces a esta función como sea necesaria para completar el envio
	--Se llamará cuando del anterior paquete se haya confirmado el envío
	local sendFileAux=function()
		local linea
		--Si es la primera vez que me llaman en el envio del fichero
		if envioFichero["bytesLeidos"] == 0 then
		
			debug("Enviando Fichero " .. envioFichero["nombreFichero"] .. " " .. envioFichero["totalBytes"] .. "(bytes)")
			if varsDinamicas then
				debug("   El fichero tiene variables Dinamicas, que son sustituidas en tiempo de ejecucion.")
				debug("   El tamano del fichero no sera exactamente el indicado")
			end
		end
		
		--He enviado un paquete del tamaño de tamBuffer, pero no cabía todo después de las sustituciones de las variables
		--Aqui lo termino de enviar
		if bufferPending then
			--Si lo que tenemos pendiente de enviar es más grande que un paquete, pues lo volvemos a partir
			--para hacerlo en más envios
			if string.len(bufferPending)>tamBuffer then
				linea=string.sub(bufferPending,1,tamBuffer)
				bufferPending=string.sub(bufferPending,tamBuffer+1,-1)
			else
				
				linea=bufferPending
				bufferPending=nil
			  --  bufferPending=false
			end
			--Enviamos el paquete que tenemos preparado
			socket1:send(linea)
			linea=nil
		else
			--todo va bien y voy leyendo paquete a paquete
			if (file.open(envioFichero["nombreFichero"],"r")) then
					local tamBufferAux=tamBuffer
					local ultimosBytes
					local tamRecorte=maxTamVar*2 --El doble de lo que pueda ocupar la variable
					file.seek("set",envioFichero["bytesLeidos"])
					--Si tenemos variables dinamicas que explandir
					if varsDinamicas then
						--Vamos a leer el tamaño del buffer más lo máximo que pueda ocupar una variable
						--para ser expandida, ej. 512+30   512 de buffer y 30 caracteres como máximo puede ocupar una
						--variable
						linea=file.read(tamBuffer+maxTamVar)
						if string.len(linea)> tamRecorte then
							--voy a analizar los ultimos caracteres que sean dos veces el tamaño máximo de las variables
							--Ej 512 del buffer +30 caracteres que he leido de más
							--El tamaño de una variable puede ser 30, por lo tanto me quedaré con
							--los caracteres desde las posiciones 482 a 542, total 60 caracteres
							ultimosBytes=string.sub(linea,-tamRecorte)
							local k,v,j
							local ultimaVariable=-1 --inicializamos por si no encontramos ninguna variable

							--Buscamos las variables y nos quedamos con la posición de la última más su tamaño
							for k,v in pairs(varsDinamicas) do
								j=string.find(ultimosBytes,k)
								if j then
									if (ultimaVariable<j) then
										ultimaVariable=j+string.len(k)
									end
								end
							end

							--Si hay alguna variable pues vamos a recortar, para dejar que lo último
							--sea la variable y asi no partamos ninguna por la mitad
							if ultimaVariable > -1 then
								tamBufferAux=tamBuffer-maxTamVar+ultimaVariable-1
							end
							--Si hemos encontrado variable recortamos hasta ella (con ella incluida)
							--Si no encontramos variable en los últimos carácteres pues nos quedamos con nuestro tamaño de buffer
							--Ej. nos quedamos con 512
							linea=string.sub(linea,1,tamBufferAux)
						end
					else
						linea=file.read(tamBuffer)
					end
					
					file.close()
					--Actualizo lo que leido.
					--Puede ser hasta tamBuffer + maxTamVar, es decir 542
					--Puede que envie 512 o cualquier valor hasta 542, dependiendo de
					--si hay una variable a expandir en los últimos bytes.
					envioFichero["bytesLeidos"]=envioFichero["bytesLeidos"]+tamBufferAux
			end
			if linea ~= nil then
				--Si tengo que sustituir alguna variable en el fichero, la busco y lo hago
				if varsDinamicas then
					local nombreVariable,valor
					for nombreVariable,valor in pairs(varsDinamicas) do
						--if string.find(linea,nombreVariable) ~= nil  then
						--    debug ("Sutituyendo variable " .. nombreVariable)
						--end
						linea=string.gsub(linea, nombreVariable, valor)
					end
					--ya no lo necesito hasta la proxima línea
					variablesEnEstaLinea=nil
	
					--Al realizar sustituciones puede que el paquete sea más grande del tamanoBuffer
					--Ejemplo he sustituido LUA_HTML, por "EN EL PUEBLO DE MI TIA HAY NO SE QUE"
					--la linea leida es más grande y la recorto a tamanoBuffer, me guardo el resto en bufferPending
					--para ser enviado en otro paquete
					if string.len(linea)>tamBuffer then
						bufferPending=string.sub(linea,tamBuffer+1,-1)
						linea=string.sub(linea,1,tamBuffer)
					end
				end
				--Enviamos el paquete que tenemos preparado
				socket1:send(linea)
				linea=nil
			end
		end --else de bufferPending
	end
	
	--Esta función envía un fichero, configura los parametros del fichero que se quiere enviar y envia la cabecera de la respuesta
	local sendFile=function(nombreFichero,tipoFichero)

		local totalBytes=getBytes(nombreFichero)
		
		envioFichero={} 
		envioFichero["nombreFichero"]=nombreFichero
		envioFichero["bytesLeidos"]=0
		envioFichero["totalBytes"]=totalBytes
       --No hace falta enviar el content-length, nos viene bien que no sea así al enviar text/html sustituidos dinámicamente
		--socket1:send("HTTP/1.1 200 OK\r\nContent-Type: " .. tipoFichero .. "\r\n" .. "Content-Length: " .. totalBytes .. "\r\nConnection: Closed\r\n\r\n")
        socket1:send("HTTP/1.1 200 OK\r\nContent-Type: " .. tipoFichero .. "\r\nConnection: Closed\r\n\r\n")
		--Transfer-Encoding: gzip
	end

	--Funcion para atender las peticiones
	--Puede ser, que el navegador o quien sea me haya hecho varias peticiones, nosotros las resolveremos una a una en orden de llegada
	local atenderPeticion=function()
		local k,v,retorno
		--para que se libere memoria si ya no tengo peticiones que atender
		socket1=nil
		request1=nil
		--Si tenemos alguna petición que atender
		if #peticiones>0 then
			--indicamos que estamos trabajando con una petición
			ocupadoAtendiendoPeticion=true
			--request1 será global para poder pasarsela a los módulos directamente
			--se hace así, porque la petición a veces es muy grande y si se lo paso por valor a las
			--funciones se queda sin memoria, ejemplo al subir ficheros, la petición es de más de 512bytes
			--socket1 será la conexión asociada a la petición request1 que estamos tratando
			request1=table.remove(peticiones,1)
			socket1=table.remove(sockets,1)
		
			debug("Peticion Recibida:")
			debug(request1.method .. " " .. request1.url .. " " .. request1.path)
			
			--Imprimimos la petición con sus variables desglosadas
			--si viene el campo data, lo recorto. Si no estoy en debug no hago nada
			if CONF_WIFI["GENERAL"]["DEBUG"]~="nd" then
				if request1.query then 
					for k,v in pairs(request1.query) do
						if k=="data" then
							debug(k .. "   " .. string.sub(v,1,20) .. " L= " .. string.len(v) .. " bytes")
						else
							debug (k .. "   " .. v)
						end
					end
				end
			end
				
			--Cargamos las páginas que tiene nuestro Servidor
			--PAGINAS=require("paginas")
			--local PAGINAS={}
			local paginasModule=require("paginas")
			 
			--Tenemos un array con funciones y como indice las rutas de las páginas
			--Ej PAGINAS["/"](), ejecutará esa función 
			--Las paginas se cargan con paginas.lua
			 
			local paginaDefinida=false
			
			for k,v in pairs(paginasModule) do 
				if k == request1.path then
					paginaDefinida=true
				end
			end
			--He encontrado la página pues ejecuto lo que tenga en ella
			if paginaDefinida then
				retorno=paginasModule[request1.path]()
				if retorno~=ERROR_404 then
					debug("Pagina encontrada")
				end 
			else
				debug("pagina no encontrada")
				retorno=ERROR_404
			end
			
			--Descargamos páginas para liberar memoria
			paginasModule=nil
			paginas=nil
			package.loaded["paginas"]=nil

			
			--Si he entrado en alguno de los sitios anteriores y tengo algo que enviar
			if retorno then
				--si retorno tiene un nombre de fichero, la página es un fichero
				--si no tiene esa key pues es un texto html y lo enviamos tal cual
				if retorno.nombreFichero then
					sendFile(retorno.nombreFichero,retorno.tipoFichero)
				else
					--Ponemos la cabecera http y devolvemos el texto que nos ha devuelto la función que se haya ejecutado
					retorno="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: Closed\r\n\r\n" .. retorno
					debug(retorno)
					sendText(retorno)
				end
			end
			--Ya no lo necesito lo pongo a nil para que despeje memoria
			request1=nil
		end --de si hay peticiones
	end -- de la funcion atenderPeticion

	--Cierra la conexion e intenta liberar memoria
	local function sendClose()
		ocupadoAtendiendoPeticion=false
		estoyEnviandoAlgo=false
		--cerramos la conexión de la petición actual
		socket1:close()
		--ya no lo necesito
		request1=nil
		
		--En principio deberían estar a nil, pero por si se me ha pasado las vuelvo a poner
		varsDinamicas=nil
		envioFichero=nil
		liberaMemoria()
		debug("Peticion Atendida. Desconectado.")
		--Miramos a ver si hay más peticiones pendientes de lanzar
		atenderPeticion()
	end
    
    srv:listen(puerto,function(conn) 

        --Evento que se lanza cuando se desconecta un cliente, no que nosotros hemos hecho el close
        conn:on("disconnection",function(sck) 
            --sendClose(sck)
        end)
        
        --Cada vez que se envía algo, cuando el TCP/IP ha terminado de enviarlo, se llama a esta función
        --En el caso del envio de un fichero, lo hacemos paquetitos de por ejemplo 1024bytes
        --enviamos un paquete de lo que indique la variable tamBuffer y no enviamos otro paquete hasta que confirmemos aquí, que se ha enviado
        conn:on("sent",function(sck)
            if envioFichero then
                if envioFichero["bytesLeidos"] < envioFichero["totalBytes"] or bufferPending then
                    sendFileAux()
                else
                    --He terminado de enviar el fichero, reinicializo las variables, para que no contengan nada
                    debug("Envio completado")
					--ya no las necesito
                    envioFichero=nil
                    varsDinamicas=nil
					--cerramos la conexión
                    sendClose()
                end
            else
                --Es un envio de un texto plano, he enviado ya algo y he terminado, miro si tengo algo en respuesta para 
                --enviar algo más. Vamos sacando del array y enviandolo hasta que el array esté vacio.
                --cuando se quede vacío cerramos la conexión y hemos terminado
                if #respuesta>0 then
                    socket1:send(table.remove(respuesta,1))
                else
                    sendClose()
                    estoyEnviandoAlgo=false
                end
            end
        end)
         
        --Evento donde se maneja la petición que nos hace el navegador
        conn:on("receive",function(sck,request)
            --Me voy a guardar la conexion y la petición que me hacen y las iré atendiendo en orden de llegada
            --y cuando pueda y haya terminado la anterior
            parseRequest(request)
            table.insert(peticiones, peticionDesglosada)
            table.insert(sockets,sck)
            request=nil
            peticionDesglosada=nil
            liberaMemoria()
            if ocupadoAtendiendoPeticion==false then
               atenderPeticion()
            end
        end)
        
    end) --de listen
end --de servidor

return SERVIDOR
