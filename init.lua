

--Variables globales

--El tiempo que esperará el esp8266 antes de arrancar, por si queremos detener la ejecución
local TIEMPO_ESPERA_PARA_ARRANCAR=5000

--ERROR_404 pude ser un literal o un fichero. Será lo que se envíe cuando no se encuentre una página
--ERROR_404={nombreFichero="error404.html",tipoFichero="text/html"}
ERROR_404="Error 404. Pagina no encontrada"

--Esta variable la voy a usar para cuando un cliente, que no está en la lista de autorizados, en modo ap y se le eche, no se
--repitan los mensajes constantemente de desautorizando.
--También la usaré para mirar que se le está echando todo el rato y no indicar que está conectado
CLIENTE_YA_ECHADO=""

FICHERO_COMPILACIONES="internalCompile.comp"

--Sólo la ejecutaré una vez
local configuraPines=function()
    --Configuración inicial de los pines
    gpio.mode(3, gpio.OUTPUT)
    gpio.mode(4, gpio.OUTPUT)
    gpio.write(3, gpio.LOW)
    gpio.write(4, gpio.LOW)
end

--**********Definimos las funciones globales****************
--Esta función sirve para hacer debug por pantalla o fichero o ambos
function debug(mensaje)
    if CONF_WIFI["GENERAL"]["DEBUG"] == "uart" or CONF_WIFI["GENERAL"]["DEBUG"] == "uartFile" then
        print(mensaje)
    elseif CONF_WIFI["GENERAL"]["DEBUG"] == "file" or CONF_WIFI["GENERAL"]["DEBUG"] == "uartFile" then
        --escribimos el mensaje en un fichero log
    end
end

--funcion global para escanear puntos de acceso cercanos.
--Es asíncrona asi que siempre tenemos algo guardado que será la anterior lectura
listAps={}
scanAps=function()
    if CONF_WIFI["GENERAL"]["WIFI_MODE"] == "sta" or CONF_WIFI["GENERAL"]["WIFI_MODE"] == "staAp" then
        wifi.sta.getap(function(aps) listAps=aps end)
    end
end

lFiles={}
listFiles=function()
    lFiles=file.list()
end

--Libera memoria y nos quedamos con su valor, una vez liberada la memoria
MEMORIA_LIBRE=0
liberaMemoria=function()
    --debug("Memoria antes: " .. node.heap())
    --configHtml=nil
    --paginas=nil
    --varsDinamicas=nil
    collectgarbage()
	MEMORIA_LIBRE=node.heap()
end

--Carga el modulo conexion y ejecuta la misma función dentro del modulo
configuraGeneral=function()
    local fConexion=require("conexion")
    fConexion.configuraGeneral()
    fConexion=nil
    conexion=nil
    package.loaded["conexion"]=nil
    liberaMemoria()
end
--******Fin funciones globales****************************

--Funcion para arrancar el esp8266 y toda su configuracion
local init=function()
    --dehabilitamos la espera de enter por uart
    uart.on("data")
  
    --cargamos el servidor, lo dejamos en memoria y no hacemos nada más
    --se crea global, porque tendrá que estar pendiente de realizar peticiones
    servidor=require("servidor")

    --Cargamos el fichero de configuración, se creará una variable global con la configuración del esp8266
    local fConfig=require("manageFConfig")
    fConfig.readConfig()
    fConfig=nil
    manageFConfig=nil
    package.loaded["manageFConfig"]=nil
    
    --liberamos memoria despues de descargar el fichero
    liberaMemoria()
    
    --leemos los ficheros que tenemos actualmente en el esp8266 y los dejamos almacenados en la lista
    listFiles()
    
    --Configuramos el esp8266 y nos conectamos o montamos el ap, si está definido
    configuraGeneral()
end

--Lo primero que vamos a hacer siempre, si o si, es configurar los pines del esp8266
configuraPines()

--En un reinicio voy a tardar mínimo 7 segundos, más lo que tarde el resto de configuración 
--Damos 2 segundos a que imprima las cosas de su firmware y demás y el explorer le pregunte
tmr.alarm(0,2000,tmr.ALARM_SINGLE,function()
	local fich
	--me han pedido compilar ficheros, como necesito que sea rápido me salto el inicio donde se puede cancelar.
	--lo hago al principio del reinicio que es cuando más memoria tengo
	if file.exists(FICHERO_COMPILACIONES) then
		print('Iniciando compilacion ficheros')
		--abro el fichero me lo recorro línea a línea y si existe el fichero de la línea lo compilo
		if file.open(FICHERO_COMPILACIONES, "r") then
			fich=file.readline()
			while fich do
				--quitamos el retorno y el salto de carro
				fich=string.gsub(fich, "\n", "")
				fich=string.gsub(fich, "\r", "")
				if file.exists(fich) then
					node.compile(fich)
					print('compilando ' .. fich)
				end
				fich=file.readline()
			end
			file.close()
			file.remove(FICHERO_COMPILACIONES)
			print('Fin compilacion de ficheros')
		end
		init()
	else
		--Damos 5 segundos para inicializar
		tmr.alarm(0,TIEMPO_ESPERA_PARA_ARRANCAR,tmr.ALARM_SINGLE,init)
		print('La Ejecucion empezara en 5 segundos. Pulsa q + Enter para parar la ejecucion')
		--Si q + enter es pulsado cancelamos el timer que iba a llamar a la función init
		uart.on("data", "\r",function(data)
			--dehabilitamos la espera de enter por uart
			if data=="q\r" then
				uart.on("data")
				tmr.stop(0)
				tmr.unregister(0)
				print("Ejecucion cancelada por el usuario")
			end
		end,0)
	end
end)


    
   

--jacin
--local valor1,valor2=node.bootreason()
--si ha habido un reset debido a que hemos pulsado el botón de reset, cargamos una configuración
--en modo access point segura, que sabemos que funciona y lo devolvemos a su estado de origen
--if valor1==2 and valor2==6 then
--
--end






