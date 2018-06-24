'Plugin Name	: 	REST
'Plugin Version	:	0.3
'Date Modified	:	21/06/2018
'Created By	:	SW

Function REST_Initialize(msgPort As Object, userVariables As Object, bsp as Object)

    REST = newREST(msgPort, userVariables, bsp)
    return REST

End Function

Function newREST(msgPort As Object, userVariables As Object, bsp as Object)

	' Create the object to return and set it up
	s 			= 	{}
	s.version 		= 	0.3
	s.msgPort 		= 	msgPort
	s.userVariables 	= 	userVariables
	s.bsp 			= 	bsp
	s.ProcessEvent 		= 	REST_ProcessEvent
	
	'Zone Msg
	s.zoneMsgSend 		= 	zoneMsgSend
	
	'HTTP Server
	s.newREST		=	createobject("roHttpServer", {port : 9000})
	s.newRest.SetPort(msgPort)
	s.newREST.AddGetFromEvent({	
		url_path 	: 	"/rest/control"
		user_data	:	"restControl"	
	})
		
	'Object Name
	s.objectName 		= 	"REST_object"
	
	return s

End Function

REM Event Process Region

Function REST_ProcessEvent(event As Object) as boolean

	retval = false
	
	? "Incoming event type is: " type(event)

	if type(event) = "roAssociativeArray" then
		? event
		if type(event["EventType"]) = "roString"
			? "RSCook: " event["EventType"]
			 if (event["EventType"] = "SEND_PLUGIN_MESSAGE") then
				if event["PluginName"] = "REST" then
					pluginMessage$ = event["PluginMessage"]
					? "SEND_PLUGIN/EVENT_MESSAGE:";pluginMessage$
					retval = ParsenetCommPluginMsg(pluginMessage$, m)
				endif
			endif
		endif			
	elseif type(event) = "roHttpEvent" then	
		'Protect against LFN type settings		
		if type(event.GetUserData()) = "roString" then			
			if event.GetUserData() = "restControl" then
				if event.GetRequestParam("cmd") <> "" then
					m.zoneMsgSend(event.GetRequestParam("cmd"))
					event.SetResponseBodyString("CMD_Received: "+event.GetRequestParam("cmd"))
					event.SendResponse(200)
					retval = true
				else
					? "There is no parameter"
					event.SetResponseBodyString("Invalid pararmeter. Try cmd=command")
					event.SendResponse(200)
					? "Don't pass this to another plugin"
					retval = true
				endif
			endif		
		endif			
	endif
	return retval	
	
End Function

REM Plugin Msg Parser - Not currently used but added here if needed at a later date
Function ParseRESTPluginMsg(origMsg as string, s as object) as boolean
	
	retval = false			
	return retval
	
End Function

REM Send a zone message to Presentation.
Function zoneMsgSend(cmd$ As String)
	
	zoneMessageCmd 	= CreateObject("roAssociativeArray")
	zoneMessageCmd["EventType"] = "SEND_ZONE_MESSAGE"
	zoneMessageCmd["EventParameter"] = cmd$
	m.bsp.msgPort.PostMessage(zoneMessageCmd)	
	zoneMessageCmd	=	invalid

End Function
