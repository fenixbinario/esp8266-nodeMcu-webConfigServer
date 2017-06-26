	var T_ACT_COMMANDO=8000;
	
	//para ahorrarme letras
	function $(name){
		return document.getElementById(name);
	}
	
	//muestra un aviso de que estamos esperando para que se refresquen los cambios
	function fVentEsperaRespuesta(show){
		if (show){
			$("izq").style.opacity=0.5;
			$("drch").style.opacity=0.5;
			$("divEperaRespuesta").style.display="flex";
			$("divBloqueaAplicacion").style.display="block";
			window.location.hash="#divBloqueaAplicacion";
		}else{
			$("izq").style.opacity=1;
			$("drch").style.opacity=1;
			$("divEperaRespuesta").style.display="none";
			$("divBloqueaAplicacion").style.display="none";
		}
	}
	
	//para volver a escanear los puntos de acceso disponibles
	function fActualizaListaAps(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				//borramos todas las filas de la tabla. Nota tRedesDisponibles es el tbody de la tabla
				eliminaFilasTabla("tRedesDisponibles");
				var lineas=xhttp.responseText.split("\n\r");
				var i,columnas;
				for (i=0;i<lineas.length;i++){
					if (lineas[0].length>0){
						columnas=lineas[i].split(",");
						if (columnas.length==5){
							anadeFilaTabla("tRedesDisponibles",columnas);	//añadimos la fila a la tabla, con sus correspondientes columnas
						}
					}
				}
				//añadimos la funcionalidad a cada fila de ser seleccionada y deseleccionada
				anadeFuncUnSoloSelFila("tRedesDisponibles");

			}
		};
		xhttp.open("GET", "/config?scanAps", true);
		xhttp.send();
	}
	
	
	function fIsNumberKey(evt) {
        var charCode = (evt.which) ? evt.which : event.keyCode;
        if (charCode > 31 && (charCode < 48 || charCode > 57)) {
            return false;
        }
        return true;
    }
    
    
	function fGeneralEstacion(confNetwork,status,dhcp,address,netmask,gateway,rssi,mac,hostName){
		//Si hay alguna variable que no ha sido sustituida la ponemos a blanco
		var i;
		for (i=0;i<arguments.length;i++){
			if (typeof arguments[i] == 'undefined'){
				arguments[i]="";
			}
		}
		
		//sustituimos las variables.
		$("staConfNetwork").innerHTML=confNetwork;
		$("staStatus").innerHTML=status;
		$("staDHCP").innerHTML=dhcp;
		$("staAddress").innerHTML=address;
		$("staNetmask").innerHTML=netmask;
		$("staGateway").innerHTML=gateway;
		$("staRssi").innerHTML=rssi;
		$("staMac").innerHTML=mac;
		$("staHostName").innerHTML=hostName;
		//Si no estoy en modo estación pues pongo que está desactivado y deshabilito el acceso a su configuración
		span=$("generalStaStatus");
		if ($("modoEsp8266").value=="ap"){
			span.innerHTML="(Desactivado)";
			$("menuSta").onclick=function(){alert("Activa primero el modo Estación para configuralo")};
		}
		else{
			span.innerHTML="(Activado)";
			$("menuSta").onclick=function() {fAccionMenu(3)};
			//si obtenemos la ip automaticamente los textbox de la pantalla de configuración de estación ip,netmask y gateway aparecerá deshabilitado y check activado
			if (dhcp == "SI")
				$("checkStaConfIpAuto").checked=true;
			else
				$("checkStaConfIpAuto").checked=false;
		
			//actualizamos los textbox habilitados o no según esté el checkbox de ip automatica
			fConfStaCheckIpAuto();
			fEstacionCargaDatos();		//traspasamos los datos de la pantalla general de estación, a la pantalla de configuración de estación
		}
	}
	
	function fGeneralPuntoAcceso(ssid,password,security,ip,netmask,gateway,mac,visible,canal,maxConn,dhcpStart){
		//Si hay alguna variable que no ha sido sustituida la ponemos a blanco
		var i;
		var span;
		for (i=0;i<arguments.length;i++){
			if (typeof arguments[i] == 'undefined'){
				arguments[i]="";
			}
		}
		//sustituimos las variables.
		$("apSsid").innerHTML=ssid;
		$("apPassword").innerHTML=password;
		$("apSecurity").innerHTML=security;
		$("apIp").innerHTML=ip;
		$("apNetmask").innerHTML=netmask;
		$("apGateway").innerHTML=gateway;
		$("apMac").innerHTML=mac;
		$("apVisible").innerHTML=visible;
		$("apCanal").innerHTML=canal;
		$("apMaxConn").innerHTML=maxConn;
		$("apDhcpStart").innerHTML=dhcpStart;
		
		//Si no estoy en modo ap pues pongo que está desactivado y deshabilito el acceso a su configuración
		span=$("generalApStatus");
		if ($("modoEsp8266").value=="sta"){
			span.innerHTML="(Desactivado)";
			$("menuAp").onclick=function(){alert("Activa primero el modo Punto de Acceso para configuralo")};
		}else{
			span.innerHTML="(Activado)";
			$("menuAp").onclick=function() {fAccionMenu(4)};
			fApCargaDatos();			//traspasamos los datos de la pantalla general de punto de acceso, a la pantalla de configuración de punto de acceso
		}
		
	}
	
	//vemos que ventanas mostramos o ocultamos
	function fVentanas(general,generalEstacion,generalPuntoAcceso,confEstacion,confPuntoAcceso,confFiles){
		var div;
		div=$("general");
		if (general)
			div.style="display:block";
		else
			div.style="display:none";
		
		div=$("generalEstacion");
		if (generalEstacion)
			div.style="display:block";
		else
			div.style="display:none";
		
		div=$("generalPuntoAcceso");
		if (generalPuntoAcceso)
			div.style="display:block";
		else
			div.style="display:none";
		
		div=$("confEstacion");
		if (confEstacion)
			div.style="display:block";
		else
			div.style="display:none";
		
		div=$("confPuntoAcceso");
		if (confPuntoAcceso)
			div.style="display:block";
		else
			div.style="display:none";
			
		div=$("confFiles");
		if (confFiles)
			div.style="display:block";
		else
			div.style="display:none";
	}
	
	function fEstacionCargaDatos(){
		$("txtStaHostname").value=$("staHostName").innerHTML;
		$("txtStaIp").value=$("staAddress").innerHTML;
		$("txtStaNetmask").value=$("staNetmask").innerHTML;
		$("txtStaGateway").value=$("staGateway").innerHTML;
		$("txtStaMac").value=$("staMac").innerHTML;
	}
	
	function fApCargaDatos(){
		$("selApSecurity").value=$("apSecurity").innerHTML;
		$("txtApSsid").value=$("apSsid").innerHTML;
		$("txtApPassword").value=$("apPassword").innerHTML;
		$("selApVisible").value=$("apVisible").innerHTML;
		$("selApCanal").value=$("apCanal").innerHTML;
		$("txtApMac").value=$("apMac").innerHTML;
		$("txtApIp").value=$("apIp").innerHTML;
		$("selApMaxCon").value=$("apMaxConn").innerHTML;
		$("txtApNetmask").value=$("apNetmask").innerHTML;
		$("txtApGateway").value=$("apGateway").innerHTML;
		$("txtApDhcpIni").value=$("apDhcpStart").innerHTML;
	}
	
	function fAccionMenu(menu){
		switch (menu){
			//menu inicio
			case 1: 
				window.location.href = "/";
				break;
			//mostramos el estatus general y ocultamos el resto
			case 2:
				//general,estacion y punto de acceso se ven, configuración de wifi y configuración del punto de acceso no se ven
				fVentanas(true,true,true,false,false,false);
				window.location.hash="#general";
				break;
			case 3:
				//mostramos la configuración del modo estación
				fVentanas(false,false,false,true,false,false);
				fActualizaListaAps();
				window.location.hash="#confEstacion";
				//fEstacionCargaDatos();
				break;
			case 4:
				//mostramos la configuración del modo punto de acceso
				fVentanas(false,false,false,false,true,false);
				window.location.hash="#confPuntoAcceso";
				fConfApActualizaDhcpClients(); //cargamos la lista de clientes conectados y los autorizados
				break;
			case 5:
				if(confirm("¿Quieres grabar la configuración actual?")){
					var xhttp = new XMLHttpRequest();
					xhttp.onreadystatechange = function() {
						if (xhttp.readyState == 4 && xhttp.status == 200) {
							if(xhttp.responseText!="OK,saveConfig")
								alert(xhttp.responseText);
							//le damos 1 segundo, ya que no tarda nada en grabar y es casi inmediato
							setTimeout(fActualizaStatus, 1000);
					}
					};
					//ponemos la ventana en espera
					fVentEsperaRespuesta(true);
					xhttp.open("GET", "/config?saveConfig", true);
					xhttp.send();
				}
				break;
			case 6:
				//Gestión de ficheros
				//Mostramos la ventana de gestión de ficheros y ocultamos las demás
				fVentanas(false,false,false,false,false,true);
				//actualizamos la lista de ficheros
				fListFiles(false);
				break;
			case 7:
				//restart esp8266
				if(confirm("Cualquier cambio no grabado se perderá. ¿Quieres resetear?")){
					var xhttp = new XMLHttpRequest();
					xhttp.onreadystatechange = function() {
						if (xhttp.readyState == 4 && xhttp.status == 200) {
							if(xhttp.responseText!="OK,restart")
								alert(xhttp.responseText);
							//le damos unos segundos e intentamos actualizar
							setTimeout(fActualizaStatus, T_ACT_COMMANDO);
					}
					};
					fVentEsperaRespuesta(true);
					xhttp.open("GET", "/config?restart", true);
					xhttp.send();
				}
				break;
		}	
	}
	
	function fCargaGeneral(memUsed,memFree,estandardRed,modoEsp8266,sleepEsp8266,debugEsp8266,uartSetupEsp8266){
		$("memUsed").innerHTML=memUsed;
		$("memFree").innerHTML=memFree;
		$("estandardRed").value=estandardRed;
		$("modoEsp8266").value=modoEsp8266;
		$("sleepEsp8266").value=sleepEsp8266;
		$("debugEsp8266").value=debugEsp8266;
		$("uartSetupEsp8266").value=uartSetupEsp8266;
	}
	
	//vamos a cargar las variables que nos devuelve el esp8266 sobre su configuración
    function fCargaConfIni(){
		//cargamos la configuración general
		
		//mostramos la pantalla con los estatus solamente, pestaña general
		fAccionMenu(2);
		
		fActualizaStatus();
		
		//quitamos la ventana de espera
		fVentEsperaRespuesta(false);
		
		$("fileSobreescribe").checked = false;
		
		//la primera vez que cargamos nos ponemos arriba del todo
		window.location.hash="#izq";
		
		
		
	}
	
	//vamos a enviar un comando indicando que queremos cambiar algo de la configuración general
	function fCambiarGeneral(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				if (xhttp.responseText=="OK,changeGeneral")
					fVentEsperaRespuesta(true);
				else
					alert(xhttp.responseText);
				//le damos unos segundos e intentamos actualizar
				setTimeout(fActualizaStatus, T_ACT_COMMANDO);
			}
		};
		var estandardRed,modoEsp8266,sleepEsp8266,debugEsp8266,uartSetupEsp8266;
		estandardRed=$("estandardRed").value;
		modoEsp8266=$("modoEsp8266").value;
		sleepEsp8266=$("sleepEsp8266").value;
		debugEsp8266=$("debugEsp8266").value;
		//como tiene u115200 por ejemplo, pues le quito la u
		uartSetupEsp8266=$("uartSetupEsp8266").value.substring(1);
		
		xhttp.open("GET", "/config?accion=changeGeneral&estandardRed="+estandardRed+"&modoEsp8266="+modoEsp8266+"&sleepEsp8266="
		+ sleepEsp8266+"&debugEsp8266="+debugEsp8266+"&uartSetupEsp8266="+uartSetupEsp8266, true);
		xhttp.send();
	}
	
	//vamos a enviar un comando para indicarle al esp8266 que queremos cambiar, el hostname,la mac, la ip,el netmask o el gateway del modo estación
	function fCambiarEstacionParam(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				if (xhttp.responseText=="OK,changeEstacionParam")
					fVentEsperaRespuesta(true);
				else
					alert(xhttp.responseText);
				//le damos unos segundos para actualizar
				setTimeout(fActualizaStatus, T_ACT_COMMANDO);
			}
		};
		var hostname,mac,dhcpAuto,ip,netmask,gateway;
		hostname=$("txtStaHostname").value;
		mac=$("txtStaMac").value;
		ip=$("txtStaIp").value;
		netmask=$("txtStaNetmask").value;
		gateway=$("txtStaGateway").value;
		
		//Si la ip es autómatica, aunque aquí tengamos otra puesta la vamos a ignorar en el esp8266
		if ($("checkStaConfIpAuto").checked)
			dhcpAuto='s';
		else
			dhcpAuto='n';
		
		xhttp.open("GET", "/config?accion=changeEstacionParam&staHostname="+hostname+"&staMac="+mac+"&staDhcpAuto="+dhcpAuto+"&staIp="
		+ ip+"&staNetmask="+netmask+"&staGateway="+gateway, true);
		xhttp.send();
	}
	
	//vamos a enviar un comando para indicarle al esp8266 que queremos cambiar opciones del punto de acceso
	function fCambiarApParam(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				if (xhttp.responseText=="OK,changeApParam")
					fVentEsperaRespuesta(true);
				else
					alert(xhttp.responseText);
				//le damos unos segundos para actualizar
				setTimeout(fActualizaStatus, T_ACT_COMMANDO);
			}
		};
		var security,ssid,password,visible,canal,maxCon,mac,ip,netmask,gateway,dhcpStart;
		security=$("selApSecurity").value
		ssid=$("txtApSsid").value
		password=$("txtApPassword").value
		if ($("selApVisible").value=="Si")
			visible=0;
		else
			visible=1;
		canal=$("selApCanal").value
		mac=$("txtApMac").value
		ip=$("txtApIp").value
		maxCon=$("selApMaxCon").value
		netmask=$("txtApNetmask").value
		gateway=$("txtApGateway").value
		dhcpStart=$("txtApDhcpIni").value
		
		xhttp.open("GET", "/config?accion=changeApParam&apSecurity="+security+"&apSsid="+ssid+"&apPassword="+password+"&apVisible="
		+ visible+"&apCanal="+canal+"&apMac="+mac+"&apIp="+ip+"&apMaxCon="+maxCon+"&apNetmask="+netmask+"&apGateway="+gateway+"&apDhcp="+dhcpStart, true);
		xhttp.send();
	}
	
	//en una tabla buscamos que fila esta seleccionada, lo sabemos por la clase que tenga asignada
	//devolvemos false, si no hay ninguna seleccionada
	function fBuscaSelTabla(tbody){
		//me voy a recorrer todas las filas de la tabla y voy a ver cual está seleccionada para sacar su ssid y utilizarlo para conectarme
		var tr = document.querySelectorAll("#"+tbody+">tr");
		var fila;
		var encontrado=false;
		fila=0;
		while (!encontrado && fila<tr.length){
			if (tr[fila].classList.contains("trSelected")) 
				encontrado=true;
			else
				fila++;
		}
		if (encontrado)
			return tr[fila];
		else	
			return false;
	}
	
		
	//nos conectamos a un ap de la lista en modo estacion
	function fConfStaConnect(){
		//me voy a recorrer todas las filas de la tabla y voy a ver cual está seleccionada para sacar su ssid y utilizarlo para conectarme
		var tr = fBuscaSelTabla("tRedesDisponibles");
		
		//He encontrado una fila seleccionada
		if (tr!=false){
			//obtengo el valor de la primera columna
			var ssid=tr.childNodes[0].innerHTML;
			var password=$("cTxtConfPassword").value;
			var xhttp = new XMLHttpRequest();
				xhttp.onreadystatechange = function() {
				if (xhttp.readyState == 4 && xhttp.status == 200) {
					if (xhttp.responseText!="OK,changeEstacionConnect")
						alert(xhttp.responseText);
					//le damos unos segundos para actualizar
					setTimeout(fActualizaStatus, T_ACT_COMMANDO);
				}
			};
			fVentEsperaRespuesta(true);
			xhttp.open("GET", "/config?accion=changeEstacionConnect&ssid="+ssid+"&password="+password, true);
			xhttp.send();
		}else
			alert("Selecciona una red para conectarte.");
	}
	
	//Esta función será la encargada de actualizar los datos de la pantalla general
	//la llamaremos, después de una actualización del modo por ejemplo o cualquier otro cambio, para confirmar que realmente se ha cambiado
	function fActualizaStatus(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				var resultado=xhttp.responseText;
				//vamos a extraer los parametros, que vienen asi: MEMUSED=123 bytes,MEMFREE=1234 bytes,...
				var parametrosAux=resultado.split(",");
				var nombreParametro,valorParametro;
				var parametros=new Array();
				var i;
				var aux;
				for (i=0;i<parametrosAux.length;i++){
					aux=parametrosAux[i].split("=");
					parametros[aux[0]]=aux[1];
				}
				//cargamos los parametros generales
				fCargaGeneral(parametros["MEMUSED"],parametros["MEMFREE"],
					parametros["WIFIPHY"],parametros["WIFIMODE"],parametros["SLEEPMODE"],parametros["DEBUG"],"u"+parametros["UART_SETUP"]);
					
				//si no me ha venido algún parámetro porque por ejemplo no está activo como punto de acceso, se pondrá a blanco en la función ya que pregunta por undefined
				//actualizamos los parámetros de modo estación si es que está activo
				fGeneralEstacion(parametros["STA_CONFNETWORK"],parametros["STA_STATUS"],parametros["STA_DHCP"],
					parametros["STA_ADDRESS"],parametros["STA_NETMASK"],parametros["STA_GATEWAY"],parametros["STA_RSSI"],parametros["STA_MAC"],parametros["STA_HOSTNAME"]);
					
				//lo mismo que la anterior
				//actualizamos los parámetros de modo ap si es que está activo
				fGeneralPuntoAcceso(parametros["AP_SSID"],parametros["AP_PASSWORD"],parametros["AP_SECURITY"],
					parametros["AP_IP"],parametros["AP_NETMASK"],parametros["AP_GATEWAY"],parametros["AP_MAC"],parametros["AP_VISIBLE"],
					parametros["AP_CANAL"],parametros["AP_MAX_CONNECTIONS"],parametros["AP_DHCP_START"]);
				fVentEsperaRespuesta(false);
			}
		}
		//le pedimos al esp8266 el estatus general
		xhttp.open("GET", "/config?getStatus", true);
		xhttp.send();
	}
	
	//Si en la ventana de configuración de estación está activado el check de ip automatico, se deshabilitan el resto de cajas
	function fConfStaCheckIpAuto(){
		if ($("checkStaConfIpAuto").checked ){
			$("txtStaIp").disabled=true;
			$("txtStaNetmask").disabled=true;
			$("txtStaGateway").disabled=true;
		}else{
			$("txtStaIp").disabled=false;
			$("txtStaNetmask").disabled=false;
			$("txtStaGateway").disabled=false;
		
		}
	}
	
	//sirve para añadir filas a una tabla. Se le pasará el nombre del tbody de la tabla y un array con las columnas.
	function anadeFilaTabla(tBody,columnas){
		var trNode,tdNode,txtNode,i;
		trNode = document.createElement("tr"); //creamos la fila
		for (i=0;i<columnas.length;i++){
			tdNode = document.createElement("td");				//Creamos una columna
			txtNode = document.createTextNode(columnas[i]);       // Ponemos el texto
			tdNode.appendChild(txtNode);						//añadimos el texto a la columna
			trNode.appendChild(tdNode);							//añadimos la columna a la fila
		}
		$(tBody).appendChild(trNode);
	}
	
	//eliminamos todas las filas de la tabla, ojo que nos pasan el tbody
	function eliminaFilasTabla(tBody){
		var t=$(tBody);
		while (t.childNodes.length>0){
			t.removeChild(t.childNodes[0]);
		}
	}
	
	//añadimos una función en cada fila de la tabla, para que sólo se pueda seleccionar una fila a la vez
	function anadeFuncUnSoloSelFila(tBody){
		var trs=document.querySelectorAll("#"+tBody+">tr");
		for (i=0;i<trs.length;i++){
			trs[i].onclick=function(){
				if (this.classList.contains("trSelected")){
					this.classList.remove("trSelected");
					this.classList.add("trUnSelected");
				}else{ 
					//para poder sólo seleccionar una a la vez, nos recorremos todas y las deseleccionamos
					var tr = document.querySelectorAll("#"+tBody+">tr");
					var filas;
					for (fila=0;fila<tr.length;fila++){
						tr[fila].classList.remove("trSelected");
						tr[fila].classList.remove("trUnSelected");
					}
					this.classList.add("trSelected");
				}
			};
		}
	}
	
	//nos devolvera la lista de los clientes conectados en modo ap, además de las mac que están en la lista de autorizados
	function fConfApActualizaDhcpClients(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				//recibiremos algo así "CONN=00:a1:b0:80:11:b9,192.168.1.100,ALLOW=00:a1:b0:80:11:b9,00:a1:b0:80:11:b6"
				var aux=xhttp.responseText.split(",ALLOW=");
				var conn;
				//cortamos el CONN=
				conn=aux[0].substr(5,aux[0].length-5);
				
				//en conn tendremos que cada 2 son mac,ip. Así que siempre tendremos un número par
				if (conn.length>0)
					conn=conn.split(",");
					
				//aquí solo viene macs
				var allow="";
				if ( aux[1].length != 0  )
					allow=aux[1].split(",");
								
				//eliminamos todas las filas de la tabla
				eliminaFilasTabla("tDhcpClientList");
				
				//añadimos las filas de los que están conectados y autorizados
				var i;
				var cols=[];
				for(i=0;i<conn.length;i=i+2){
					cols[0]="Conectado";
					cols[1]=conn[i];	//columna 1
					cols[2]=conn[i+1];  //columna 2
					anadeFilaTabla("tDhcpClientList",cols)
				}
				
				//añadimos las filas de los que están bloqueados
				i=0;
				while (i<allow.length){
					cols[0]="Acceso Permitido";
					cols[1]=allow[i];	//columna1
					cols[2]=""; //columna2
					anadeFilaTabla("tDhcpClientList",cols);
					i++;
				}
				
				//le vamos a añadir a cada fila una función para que puedan ser seleccionadas, y sólamente una a la vez
				anadeFuncUnSoloSelFila("tDhcpClientList");
			}
		}
		//le pedimos al esp8266 la lista de clientes
		xhttp.open("GET", "/config?getApClients", true);
		xhttp.send();
	}
	
	//se añade una mac manual a la lista y se establecera como bloqueada
	function fConfApAnadeMac(){
		var mac = prompt("Añadir nueva MAC");
		//si no han cancelado
		if (mac){
			//si es una mac correcta pues la añadimos
			if (validateMac(mac)) {
				var xhttp = new XMLHttpRequest();
						xhttp.onreadystatechange = function() {
						if (xhttp.readyState == 4 && xhttp.status == 200) {
							if (xhttp.responseText=="OK,addApAllowMac"){
								fConfApActualizaDhcpClients();
								fVentEsperaRespuesta(false);
								window.location.hash="#tDhcpClientList";
								//setTimeout(fConfApActualizaDhcpClients, 500);	//actualizamos la lista y confirmamos que está
							}
						}
					};
				fVentEsperaRespuesta(true);
				//la enviamos en mayúscula
				xhttp.open("GET", "/config?accion=addApAllowMac&mac="+mac.toUpperCase(), true);
				xhttp.send();
			}else	
				alert("Formato de Mac incorrecta");
		}
	}
	
	//quita una mac de la lista de autorizados
	function fConfApRemoveMac(){
		var mac;
		var tr=fBuscaSelTabla("tDhcpClientList");
		if (tr!=false){
			if (tr.childNodes[0].innerHTML=="Conectado"){
				alert("Sólo puedes quitar una MAC cuyo estatus sea Acceso Permitido");
			}else{
				mac=tr.childNodes[1].innerHTML;
				var xhttp = new XMLHttpRequest();
					xhttp.onreadystatechange = function() {
					if (xhttp.readyState == 4 && xhttp.status == 200) {
						if (xhttp.responseText=="OK,removeApAllowMac"){
							fConfApActualizaDhcpClients();
							fVentEsperaRespuesta(false);
							window.location.hash="#tDhcpClientList";
							//setTimeout(fConfApActualizaDhcpClients, 500);	//actualizamos la lista y confirmamos que está
						}
					}
				};
				fVentEsperaRespuesta(true);
				//la enviamos en mayúscula
				xhttp.open("GET", "/config?accion=removeApAllowMac&mac="+mac.toUpperCase(), true);
				xhttp.send();
			}
		}else	
			alert("Seleccione una Mac de la lista");
	}
	
	//devuelve los ficheros que actualmente hay en el esp8266
	function fListFiles(ventanaEspera){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				//borramos todas las filas de la tabla. Nota tExploradorFich es el tbody de la tabla
				eliminaFilasTabla("tExploradorFich");
				if (xhttp.responseText!="NO_FILES"){
					var i;
					var cols;
					var filas=xhttp.responseText.split(";");
					filas.sort();
					for(i=0;i<filas.length;i++){
						cols=filas[i].split(",");
						anadeFilaTabla("tExploradorFich",cols)
					}
					//añadimos la funcionalidad a cada fila de ser seleccionada y deseleccionada
					anadeFuncUnSoloSelFila("tExploradorFich");
				}
				fVentEsperaRespuesta(false); //quitamos la ventana de espera, si estaba puesta y sino pues nada
			}
		};
		xhttp.ontimeout = function () { alert("Timed out!!!"); }
		fVentEsperaRespuesta(ventanaEspera);
		xhttp.open("GET", "/config?accion=manageFiles&orden=listFiles", true);
		xhttp.send();
	}
	
	const SF_BUFFER=512;
	var SF_BYTES_LEIDOS_FICHERO=0;
	var SF_PROGRESO_ACTUAL;
	var SF_PROGRESO_ACTUAL_TOTAL;
	var SF_PROGRESO_SUMA;
	var SF_PROGRESO_SUMA_TOTAL;
	var SF_OBJFILE;
	var SF_FILENAME;
	var SF_CANCEL=false;
	var SF_NUM_FICH_ACT;
	
	function fsendFile(){
		var i;
		var totalBytes,partes;
		if ($("sendFileButton").innerHTML=="Cancelar"){
			SF_CANCEL=true;
		}else{
			//si tenemos un fichero para subir
			if ($('upLoadfiles').files.length>0){
				SF_NUM_FICH_ACT=0;
				//En la barra de total tendendremos el progreso total, para ello vamos a ver cada archivo y cuanto ocupa como primer paso
				totalBytes=0;
				for(i=0;i<$('upLoadfiles').files.length;i++)
					totalBytes+=$('upLoadfiles').files[i].size;
				//esto es, cuantas veces vamos a llamar a la función para terminar de enviar todos los ficheros
				partes=totalBytes/SF_BUFFER;
				
				//cáculamos que porcentaje del total que pertenece a cada parte enviada
				SF_PROGRESO_SUMA_TOTAL=100/partes;
				SF_PROGRESO_SUMA_TOTAL= parseFloat(SF_PROGRESO_SUMA_TOTAL.toFixed(2)); //limitamos a dos decimales y como el fixed me lo convierte a string, lo vuelvo a poner a float
				
				//pongo la barra de progreso del total a cero
				SF_PROGRESO_ACTUAL_TOTAL=0;
				$("fileProgressTot").value=0;
				$("porcentajeFichTotal").value="0.00%";
				
				//pongo la barra de progreso del fichero actual a 0
				$("fileProgressAct").value=0;
				$("porcentajeFichAct").value="0.00%";
				
				//empezamos a enviar ficheros
				fsendNextFile();
			}else
				alert("Introduce uno o varios ficheros para subir");
		}	//de cancelar
	}
	
	//coge un fichero de la lista de ficheros y llama a la función engargada de trocearlos y enviarlos
	function fsendNextFile(){
		//si quedan ficheros sin procesar
		if ($('upLoadfiles').files.length>SF_NUM_FICH_ACT){
			SF_OBJFILE=$('upLoadfiles').files[SF_NUM_FICH_ACT];
			//al nombre del fichero que vamos a enviar, le sustituimos los espacios por un guión bajo
			SF_FILENAME=$('upLoadfiles').files[SF_NUM_FICH_ACT].name;
			SF_FILENAME=SF_FILENAME.replace(/ /g, "_");
			console.log("Tamaño del fichero a enviar: "+SF_OBJFILE.size);
			$("nameUploadFile").innerHTML="Subiendo " + SF_FILENAME;
			
			//si tengo el check de sobreescribir no miro si existe el fichero o no en el esp8266 y empezamos a enviar automáticamente
			//en caso contrario por cada comienzo de envío si existe el fichero preguntaré si se quiere sobreescribir
			if (!$("fileSobreescribe").checked){
				var xhttp = new XMLHttpRequest();
				xhttp.onreadystatechange = function() {
					if (xhttp.readyState == 4 && xhttp.status == 200) {
						//contestación del esp8266 si existe el fichero. Si no existe lo subimos directamente. Si existe preguntamos si quiere machacarlo.
						if (xhttp.responseText=="OK,manageFiles,existe,NO")
							fEmpiezaSubidaFichero();
						else{
							if(confirm("El fichero "+SF_FILENAME+ " existe. ¿Quieres sobreescribirlo?")){
								//me han dicho que lo sobreescriba
								fEmpiezaSubidaFichero();
							}else{
								//me han preguntado si quería sobreescribirlo, y he dicho que no, pasamos al siguiente fichero si lo hay
								fsendNextFile();
							}
							
						}
					}
				};
				//le vamos a preguntar al esp8266 si existe el fichero
				xhttp.open("GET", "/config?accion=manageFiles&orden=existe&filename="+$('upLoadfiles').files[SF_NUM_FICH_ACT].name, true);
				xhttp.send();
			}else
				fEmpiezaSubidaFichero();
			SF_NUM_FICH_ACT++;
		}else{
			//he acabado de subir ficheros en un principio, restauro los mensajes
			$("nameUploadFile").innerHTML="Progeso de subida:";
			//la barra de progeso total la pongo al 100 y el porcentaje también
			$("fileProgressTot").value=100;
			$("porcentajeFichTotal").innerHTML="100%";
			//restauramos el nombre del botón y en vez de poner cancelar lo dejamos nuevamente en upload
			$("sendFileButton").innerHTML="Upload";
		}
	}
	
	//Configuramos los datos necesarios para la subida
	//Calculamos las llamadas que vamos a hacer al esp8266, para calcular lo que va avanzando la barra de progreso
	function fEmpiezaSubidaFichero(){
		SF_BYTES_LEIDOS_FICHERO=0;
		SF_CANCEL=false;
		$("sendFileButton").innerHTML="Cancelar";	//ponemos el boton en modo cancelar
		//imprimimos el tamaño total del fichero
		console.log("Tamaño del fichero a enviar: "+SF_OBJFILE.size);
		
		//Ponemos la barra de progreso a cero
		$("fileProgressAct").value=0;
		//calculamos cuantas veces vamos a tener que llamar a la función que realiza el envío por partes
		var partes=SF_OBJFILE.size/SF_BUFFER;
		
		SF_PROGRESO_SUMA=100/partes;
		
		SF_PROGRESO_SUMA= parseFloat(SF_PROGRESO_SUMA.toFixed(2)); //limitamos a dos decimales y como el fixed me lo convierte a string, lo vuelvo a poner a float
		
		//El progreso de la barra lo pongo a cero
		SF_PROGRESO_ACTUAL=0;
		
		//empezamos a realizar el envío
		freadAndSendPartOfFile();
	}
	
	//la lectura del fichero empieza con cero y termina con file.size -1;
	function freadAndSendPartOfFile(){
		var stop=SF_BYTES_LEIDOS_FICHERO+SF_BUFFER;
		var blob;
		var bufferRealEnviado=SF_BUFFER;
		if (SF_OBJFILE){
			//si el stop es mayor que el fichero lo ajustamos, y además en la petición le ajusto la cantidad de bytes que vamos a enviar
			if (stop>SF_OBJFILE.size){
				bufferRealEnviado=SF_OBJFILE.size-SF_BYTES_LEIDOS_FICHERO
				stop=SF_OBJFILE.size;
			}
			//aquí recortamos el fichero, la parte que queremos
			blob=SF_OBJFILE.slice(SF_BYTES_LEIDOS_FICHERO, stop);
		
			//Creamos el objeto que será el encargado de leer el fichero
			var reader = new FileReader();
			//El evento que lanzará cuando termine de leer la parte del fichero que le hemos indicado
			reader.onloadend = function(evt) {
				var lectura;
				if (evt.target.readyState == FileReader.DONE) { // DONE == 2
					lectura=evt.target.result;
					var xhttp = new XMLHttpRequest();
					xhttp.onreadystatechange = function() {
						if (xhttp.readyState == 4 && xhttp.status == 200) {
							if (xhttp.responseText=="OK,manageFiles,appendFile"){
								
								//le sumamos la cantidad calculada al principio del envío del fichero
								SF_PROGRESO_ACTUAL+=SF_PROGRESO_SUMA;
								SF_PROGRESO_ACTUAL=parseFloat(SF_PROGRESO_ACTUAL.toFixed(2)); //lo dejo en dos decimales
								console.log("PActu: "+SF_PROGRESO_ACTUAL);
								$("fileProgressAct").value=SF_PROGRESO_ACTUAL.toFixed(2); //Me que sólo con dos decimales
								$("porcentajeFichAct").innerHTML=formatPorcentaje($("fileProgressAct").value)+"%";	//actualizamos el elemento html para que se vea por el usuario
								
								//parecido a lo anterior pero con barra de progreso total
								SF_PROGRESO_ACTUAL_TOTAL+=SF_PROGRESO_SUMA_TOTAL;
								SF_PROGRESO_ACTUAL_TOTAL=parseFloat(SF_PROGRESO_ACTUAL_TOTAL.toFixed(2)); //lo dejo en dos decimales
								$("fileProgressTot").value=SF_PROGRESO_ACTUAL_TOTAL.toFixed(2);
								$("porcentajeFichTotal").innerHTML=formatPorcentaje($("fileProgressTot").value)+"%";	//actualizamos el elemento html para que se vea por el usuario
								console.log("PActuTotal: "+SF_PROGRESO_ACTUAL_TOTAL);
								
								//Si nos queda fichero por enviar o por el contrario hemos terminado
								console.log(SF_BYTES_LEIDOS_FICHERO+" "+SF_OBJFILE.size);
								if (SF_BYTES_LEIDOS_FICHERO<SF_OBJFILE.size){
									//si nos mandan cancelar o seguimos
									if (!SF_CANCEL){
										//recursividad. Como no hemos terminado de enviar el fichero. Volvemos a enviar la siguiente parte y así hasta el final
										setTimeout(freadAndSendPartOfFile,50);
									}else{
										//nos han cancelado
										$("sendFileButton").innerHTML="Upload";
										//actualizamos la lista de ficheros
										fListFiles(false);
									}
								}else{
									
									//hemos terminado un fichero ponemos el progreso al 100% del fichero actual
									$("fileProgressAct").value=100;
									$("porcentajeFichAct").innerHTML="100%";
									
									//actualizamos la lista de ficheros
									fListFiles(false);
									
									//vamos a por el siguiente fichero si lo hay
									fsendNextFile();
									
								}
							}else{
								alert("Error al enviar el fichero");
								$("porcentajeFichAct").innerHTML="Fallido";
								$("porcentajeFichTotal").innerHTML="Fallido";
								$("sendFileButton").innerHTML="Upload";
							}
						}
					};
					
					//Enviamos al esp8266 la petición, y le indicamos además cuantos bytes van del fichero.
					xhttp.open("POST", "/config?accion=manageFiles&orden=appendFile&buffer="+bufferRealEnviado+"&filename="+SF_FILENAME+"&progreso="+SF_PROGRESO_ACTUAL, true);
					//No se muy bien para que el header éste. En vez de enviar el tamaño de lo que envío, podía buscar esto y luego recortar, pero me parecía más fácil lo hecho.
					xhttp.setRequestHeader("X_FILENAME", SF_FILENAME);
					xhttp.send(lectura);
				}
			};
			//le mandamos leer la parte del fichero que queremos. Al final usamos readAsArrayBuffer, para poder leer y enviar correctamente los ficheros binarios
			//reader.readAsBinaryString(blob);
			reader.readAsArrayBuffer(blob);
			//reader.readAsText(blob);
			//actualizamos los bytes que hemos leido
			SF_BYTES_LEIDOS_FICHERO=stop;
		}
		
	}
	
	function fcompileFileAll(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				//Si se compila correctamente actualizamos la lista de ficheros, sino pues mostramos error
				if (xhttp.responseText=="OK,manageFiles,compileAll"){
					//espero un momento antes de pedir actualizar ficheros, para dar tiempo al esp8266 a que se reinicie
					setTimeout(function(){fListFiles(true);},1000);
				}else
					alert("Error al compilar");
			}
		};
		if(confirm("Vas a compilar todos los ficheros .lua. Para compilar tengo que reiniciar ¿estas seguro?")){
			xhttp.open("GET", "/config?accion=manageFiles&orden=compileAll", true);
			xhttp.send();
			//pongo la ventana de espera
			fVentEsperaRespuesta(true);
		}
	}
	
	function fcompileFile(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				//Si se compila correctamente actualizamos la lista de ficheros, sino pues mostramos error
				if (xhttp.responseText=="OK,manageFiles,compile"){
					//espero un momento antes de pedir actualizar ficheros, para dar tiempo al esp8266 a que se reinicie
					setTimeout(function(){fListFiles(true);},1000);
				}else
					alert("Error al compilar");
			}
		};
		//voy a buscar la fila que tengo seleccionada
		var tr = fBuscaSelTabla("tExploradorFich");
		
		//He encontrado una fila seleccionada
		if (tr!=false){
			//obtengo el valor de la primera columna
			var filename=tr.childNodes[0].innerHTML;
			//voy a mirar si es un fichero .lua
			if (filename.substr(filename.length-4, 4)==".lua"){
				if(confirm("Para compilar tengo que reiniciar ¿estas seguro?")){
					xhttp.open("GET", "/config?accion=manageFiles&orden=compile&filename="+filename, true);
					xhttp.send();
					//pongo la ventana de espera
					fVentEsperaRespuesta(true);
				}
			}else
				alert("La extensión del fichero debe ser .lua");
		}else
			alert("Elige un fichero primero.");
	}	
	
	function frenameFile(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				//Si se compila correctamente actualizamos la lista de ficheros, sino pues mostramos error
				if (xhttp.responseText=="OK,manageFiles,renameFile")
					fListFiles(false);
				else
					alert("Error al renombrar");
			}
		};
		//voy a buscar la fila que tengo seleccionada
		var tr = fBuscaSelTabla("tExploradorFich");
		
		//He encontrado una fila seleccionada
		if (tr!=false){
			//obtengo el valor de la primera columna
			var filenameOld=tr.childNodes[0].innerHTML;
			var filenameNew=prompt("Introduce el nuevo nombre",filenameOld);
			//si el nombre es distinto
			if (filenameOld!=filenameNew){
				xhttp.open("GET", "/config?accion=manageFiles&orden=renameFile&filenameOld="+filenameOld+"&filenameNew="+filenameNew, true);
				xhttp.send();
			}
		}else
			alert("Elige un fichero primero.");
		
	}
	
	function fdeleteFile(){
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (xhttp.readyState == 4 && xhttp.status == 200) {
				//Si se compila correctamente actualizamos la lista de ficheros, sino pues mostramos error
				if (xhttp.responseText=="OK,manageFiles,deleteFile")
					fListFiles(false);
				else
					alert("Error al borrar el fichero.");
			}
		};
		//voy a buscar la fila que tengo seleccionada
		var tr = fBuscaSelTabla("tExploradorFich");
		
		//He encontrado una fila seleccionada
		if (tr!=false){
			//obtengo el valor de la primera columna
			var filename=tr.childNodes[0].innerHTML;
			//si el nombre es distinto
			if(confirm("¿Quieres eliminar el fichero "+filename+" ?")){
				xhttp.open("GET", "/config?accion=manageFiles&orden=deleteFile&filename="+filename, true);
				xhttp.send();
			}
		}else
			alert("Elige un fichero primero.");
		
	}
	
	
	//formateamos un número.Ej 1.4, devolvemos 01.40
	function formatPorcentaje(num){
		var aux;
		aux=num.toString().split('.');
		if (aux.length==2){
			if (aux[0].length!=2)
				aux[0]='0'+aux[0];
			if (aux[1].length!=2)
				aux[1]=aux[1]+'0';
			aux=aux[0]+'.'+aux[1];
		}else
			aux=num+".00";
		
		return aux;
	}
	
	//valida una mac, mayúsculas o minúsculas, guiones o dos puntos
	function validateMac(mac){
		var regex = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/;
		return regex.test(mac);
	}
		
	//valida un ip, hay que probarla
	function validateIp(ip){
		//var regex= /^([0-9]{1-3}.){3}([0-9]{1-3})$/;
		var regex=/^(?!0)^([0-9]{1-3}.){3}([0-9]{1-3})$/;
		return regex.test(ip)
	}
