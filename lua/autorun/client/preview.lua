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


concommand.Add("visual_reset",function()
	RunConsoleCommand("visual_p",0)
	RunConsoleCommand("visual_y",0)
	RunConsoleCommand("visual_distance",0)

	d = 0 
	norm = Angle(0,0,0)
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

	RunConsoleCommand("visual_p",norm.p)
	RunConsoleCommand("visual_y",norm.y)
	RunConsoleCommand("visual_distance",d)
end)


local halfmodel1 = ClientsideModel("error.mdl")
halfmodel1:SetNoDraw(true)
local halfmodel2 = ClientsideModel("error.mdl")
halfmodel2:SetNoDraw(true)

local aiment
local last

local render_EnableClipping = render.EnableClipping
local render_PushCustomClipPlane = render.PushCustomClipPlane
local render_PopCustomClipPlane = render.PopCustomClipPlane
local render_SetColorModulation = render.SetColorModulation

local entm = FindMetaTable("Entity")
local ent_SetNoDraw = entm.SetNoDraw 
local ent_SetModel = entm.SetModel 
local ent_GetModel = entm.GetModel 
local ent_OBBCenter = entm.OBBCenter 
local ent_SetPos = entm.SetPos 
local ent_GetPos = entm.GetPos 
local ent_SetAngles = entm.SetAngles 
local ent_GetAngles = entm.GetAngles 
local ent_LocalToWorldAngles = entm.LocalToWorldAngles 
local ent_LocalToWorld = entm.LocalToWorld 
local ent_DrawModel = entm.DrawModel 

local function drawpreview()
	aiment = LocalPlayer():GetEyeTraceNoCursor().Entity

	if IsValid(last) then
		last:SetNoDraw(false)
		last = nil
	end

	if !IsValid(LocalPlayer()) or !IsValid(aiment) then return end
	if GetConVarString("gmod_toolmode") != "visual" or LocalPlayer():GetActiveWeapon():GetClass() != "gmod_tool" then return end		

	ent_SetNoDraw(aiment,true)

	last = aiment
	if ent_GetModel(halfmodel1) != ent_GetModel(aiment) then
		ent_SetModel(halfmodel1 , ent_GetModel(aiment))
		ent_SetModel(halfmodel2 , ent_GetModel(aiment))
	end
	local e_pos = ent_LocalToWorld( aiment , ent_OBBCenter(aiment) )

	ent_SetPos(halfmodel1 , ent_GetPos(aiment))
	ent_SetAngles(halfmodel1 , ent_GetAngles(aiment))
	ent_SetPos(halfmodel2 , ent_GetPos(aiment))
	ent_SetAngles(halfmodel2 , ent_GetAngles(aiment))

	local n = -ent_LocalToWorldAngles(aiment , norm):Forward()


	render_EnableClipping(true)
	render_SetColorModulation(0,2,0)			
	render_PushCustomClipPlane(-n, -n:Dot(e_pos-n*d) ) -- n , 
		ent_DrawModel(halfmodel2)
	render_PopCustomClipPlane()	

	render_SetColorModulation(2,0,0)			
	render_PushCustomClipPlane(n, n:Dot(e_pos-n*d) ) -- n , 
		ent_DrawModel(halfmodel1)
	render_PopCustomClipPlane()
	render_SetColorModulation(1,1,1)		
	render_EnableClipping(false)
	
end

hook.Add("PostDrawOpaqueRenderables" , "VisualClip.Preview" , drawpreview )
