local norm , d = Angle(0,0,0) , 0 

cvars.AddChangeCallback("visual_p",function(_,_,new)
	norm.p = tonumber(new) or 0	
end)
cvars.AddChangeCallback("visual_y",function(_,_,new)
	norm.y = tonumber(new) or 0
end)
cvars.AddChangeCallback("visual_distance",function(_,_,new)
	d = tonumber(new) or 0	
end)
cvars.AddChangeCallback("visual_adv_distance",function(_,_,new)
	d = tonumber(new) or 0		
end)

concommand.Add("visual_adv_reset",function()
	norm = Angle(0,0,0)
	RunConsoleCommand("visual_adv_distance" , 0)
end)
concommand.Add("visual_reset",function()
	RunConsoleCommand("visual_p",0)
	RunConsoleCommand("visual_y",0)
	RunConsoleCommand("visual_distance",0)
end)

--local function ClipData( um )
--	norm = Angle(um:ReadFloat() , um:ReadFloat() , um:ReadFloat())
--	d = um:ReadFloat()
--	RunConsoleCommand("visual_adv_distance",d)
--end
--usermessage.Hook("visual_clip_data" , ClipData)


net.Receive( "clipping_preview_clip" , function()
	norm = Angle( net.ReadFloat() , net.ReadFloat() , net.ReadFloat() )
	d = net.ReadDouble()
end)


local halfmodel1 = ClientsideModel("error.mdl")
halfmodel1:SetNoDraw(true)
local halfmodel2 = ClientsideModel("error.mdl")
halfmodel2:SetNoDraw(true)

local ply 
local aiment

local last = NULL
local function drawpreview()
	aiment = ply:GetEyeTraceNoCursor().Entity

	if last == aiment and IsValid(aiment) then 
		aiment:SetNoDraw(true)
	else
		if IsValid(last) then
			last:SetNoDraw(false)
		end
		last = NULL
	end

	if !IsValid( ply ) or !IsValid(aiment) then return end
	if GetConVarString("gmod_toolmode") != "visual" or ply:GetActiveWeapon():GetClass() != "gmod_tool" then return end 

	last = aiment
	if halfmodel1:GetModel() != aiment:GetModel() then
		halfmodel1:SetModel(aiment:GetModel() )
		halfmodel2:SetModel(aiment:GetModel() )
	end
	local e_pos = aiment:LocalToWorld( aiment:OBBCenter() )

	halfmodel1:SetPos(aiment:GetPos())
	halfmodel1:SetAngles(aiment:GetAngles())
	halfmodel2:SetPos(aiment:GetPos())
	halfmodel2:SetAngles(aiment:GetAngles())

	local n = -aiment:LocalToWorldAngles(norm):Forward()


	render.EnableClipping(true)
	render.SetColorModulation(0,2,0)			
	render.PushCustomClipPlane(-n, -n:Dot(e_pos-n*d) ) -- n , 
		halfmodel2:DrawModel()
	render.PopCustomClipPlane()	

	render.SetColorModulation(2,0,0)			
	render.PushCustomClipPlane(n, n:Dot(e_pos-n*d) ) -- n , 
		halfmodel1:DrawModel()
	render.PopCustomClipPlane()
	render.SetColorModulation(1,1,1)		
	render.EnableClipping(false)
	
end
timer.Simple(0.1,function() 
	ply = LocalPlayer() 
	hook.Add("PostDrawOpaqueRenderables" , "VisualClip.Preview" , drawpreview )
end)