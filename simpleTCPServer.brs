'Plugin Name	: 	tcpServer
'Plugin Version	:	0.16
'Date Modified	:	08/07/2018
'Created By	:	SW

Function tcpServer_Initialize(msgPort As Object, userVariables As Object, bsp as Object)

    tcpServer = newtcpServer(msgPort, userVariables, bsp)
    return tcpServer

End Function

Function newtcpServer(msgPort As Object, userVariables As Object, bsp as Object)

	' Create the object to return and set it up
	s 			= 	{}
	s.version 		= 	0.16
	s.msgPort 		= 	msgPort
	s.userVariables 	= 	userVariables
	s.bsp 			= 	bsp
	s.ProcessEvent 		= 	tcpServer_ProcessEvent
	
	'Zone Msg
	s.zoneMsgSend 		= 	zoneMsgSend
	
	s.acceptTCPConnection 	= 	acceptTCPConnection
	s.closeTCP		=	closeTCP
	
	'TCP Section
	s.tcpServ = CreateObject("roTCPServer")
	s.tcpServ.SetPort(msgPort)
	s.tcpServ.BindToPort(9005)
	s.tcpServ.SetUserData({
		name : "tcpPort01"
	})
	
	'This is where the TCP connections are stored.
	s.tcpConnections = CreateObject("roArray",1,true)
		
	'Object Name
	s.objectName 		= 	"tcpServer_object"
	
	return s

End Function

REM Event Process Region

Function tcpServer_ProcessEvent(event As Object) as boolean

	retval = false
	
	? "Incoming event type is: " type(event)

	if type(event) = "roAssociativeArray" then
		? event
		if type(event["EventType"]) = "roString"
			? "RSCook: " event["EventType"]
			 if (event["EventType"] = "SEND_PLUGIN_MESSAGE") then
				if event["PluginName"] = "tcpServer" then
					pluginMessage$ = event["PluginMessage"]
					? "SEND_PLUGIN/EVENT_MESSAGE:";pluginMessage$
					retval = ParsetcpServerPluginMsg(pluginMessage$, m)
				endif
			endif
		endif			
	elseif type(event) = "roTCPConnectEvent" then	
		if type(event.GetUserData().name) = "roString" then
			if event.GetUserData().name = "tcpPort01" then
				retval = m.acceptTCPConnection(event,m)
			endif
		endif
		
	elseif type(event) = "roStreamLineEvent" then

		if type(event.GetUserData()) = "roInt" then				
			m.zoneMsgSend(event.GetString())
			m.tcpConnections[event.GetUserData()].SendLine("Msg_Received: From Connection Number:"+event.GetUserData().ToStr())
			retval = true
		endif
		
	elseif type(event) = "roStreamEndEvent" then			

		if type(event.GetUserData()) = "roInt" then	
			retval = m.closeTCP(event.GetUserData(),m)
		endif
		
	endif
	return retval
	
End Function

REM Plugin Msg Parser - Not currently used but added here if needed at a later date
Function ParsetcpServerPluginMsg(origMsg as string, s as object) as boolean
	
	retval = false			
	return retval
	
End Function

REM Create and accept the incoming TCP connection
Function acceptTCPConnection(connection as object, s as object) as boolean
	
	'No conditions are tested for safety as this is for testing and will always return as handled.
	
	retval = false
	
	index% = s.tcpConnections.count()
	conn = CreateObject("roTCPStream")
	conn.SetLineEventPort(s.msgPort)
	conn.SetSendEOL(chr(13))
	conn.SetReceiveEOL(chr(13))
	conn.Accept(connection)
	conn.SetUserData(index%)
	
	'Add the connection to the array. This will keep growing until you restart the player.
	'I would normally cap this at 20 and reshuffle the index% when full
	'0=tcp0,1=invalid(closed),2=tcp2 would become 0=tcp,1=tcp2 just to manage the active connections when you have 100's
	
	s.tcpConnections.push(conn)

	return retval

End Function

REM Close a disconnected connection and makes it's instance invalid
Function closeTCP(index% as integer, s as object) as boolean

	'No conditions are tested for safety as this is for testing and will always return as handled.
	
	retval = false
	s.tcpConnections[index%] = invalid	
	retval = true	
	return retval
	
End Function

REM Send a zone message to Presentation.
Function zoneMsgSend(cmd$ As String)
	
	zoneMessageCmd = CreateObject("roAssociativeArray")
	zoneMessageCmd["EventType"] = "SEND_ZONE_MESSAGE"
	zoneMessageCmd["EventParameter"] = cmd$
	m.bsp.msgPort.PostMessage(zoneMessageCmd)	
	zoneMessageCmd	=	invalid

End Function
