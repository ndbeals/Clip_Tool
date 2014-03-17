
-- Render
local Clips = {}
local RenderOverride
local RenderInside

local cvar = CreateClientConVar("max_clips_per_prop" , 3 , true , false )

cvars.AddChangeCallback( "max_clips_per_prop" ,function(_,_,new)
	new = tonumber(new)
	for ent , _ in pairs( Clips ) do
		ent.MaxClips = math.min(new , #Clips[ent])
	end
end)

local function ReadAngleAsFloat()
	return Angle( net.ReadFloat() , net.ReadFloat() , net.ReadFloat() )
end

local function ReadClip( ent )
	return {ReadAngleAsFloat() , net.ReadDouble(), ent:OBBCenter()}
end

local function AddPropClip( ent , clip )
	Clips[ent] = Clips[ent] or {}
	Clips[ent][#Clips[ent]+1] = clip

	ent.MaxClips = math.min(cvar:GetInt() , #Clips[ent])

	ent:CallOnRemove("RemoveFromClippedTable" , function( ent ) Clips[ent] = nil end)
	
	ent.RenderOverride = RenderOverride
end


net.Receive("clipping_new_clip" , function()
	local ent = net.ReadEntity()

	if !IsValid(ent) then return end

	AddPropClip(ent , ReadClip( ent ))
end)

net.Receive("clipping_render_inside" , function()
	local ent = net.ReadEntity()
	local enabled = tobool( net.ReadBit() )

	if !IsValid(ent) then return end
	ent.RenderInside = enabled

	if !Clips[ent] and enabled then
		ent.RenderOverride = RenderInside
	elseif !Clips[ent] then
		ent.RenderOverride = nil 
	end
end)

net.Receive("clipping_all_prop_clips" , function()
	local ent = net.ReadEntity()
	local clips = net.ReadInt(16)

	if !IsValid(ent) then return end

	for i = 1 , clips do
		AddPropClip(ent , ReadClip(ent))
	end
end)

net.Receive("clipping_remove_all_clips" , function ()
	local ent = net.ReadEntity()

	if !IsValid(ent) then return end

	Clips[ent] = nil 
	ent.RenderOverride = nil 
end)

net.Receive("clipping_remove_clip" , function ()
	local ent = net.ReadEntity()
	local index = net.ReadInt(16)

	if !IsValid(ent) or !Clips[ent] then return end

	table.remove(Clips[ent] , index) 
	ent.MaxClips = math.min(cvar:GetInt() , #Clips[ent])

	if index == 1 then 
		ent.RenderOverride = nil
	end
end)

local render_EnableClipping = render.EnableClipping
local render_PushCustomClipPlane = render.PushCustomClipPlane
local render_PopCustomClipPlane = render.PopCustomClipPlane
local render_CullMode = render.CullMode

local entm = FindMetaTable("Entity")
local ent_LocalToWorldAngles = entm.LocalToWorldAngles
local ent_LocalToWorld = entm.LocalToWorld
local ent_SetupBones = entm.SetupBones
local ent_DrawModel = entm.DrawModel

local vecm = FindMetaTable("Vector")
local vec_Dot = vecm.Dot

local angm = FindMetaTable("Angle")
local ang_Forward = angm.Forward

local IsValid = IsValid

local n , enabled , curclips
function RenderOverride(self)
	if !IsValid(self) then return end
	enabled = render_EnableClipping( true )

	for i = 1 , self.MaxClips do
		curclips = Clips[self][i]
		n = ang_Forward( ent_LocalToWorldAngles(self , curclips[1] ) )
		
		render_PushCustomClipPlane(n, vec_Dot(ent_LocalToWorld( self , curclips[3] ) + n * curclips[2] , n ) )
	end

	ent_DrawModel( self )

	if self.RenderInside then
		render_CullMode(MATERIAL_CULLMODE_CW)
			ent_DrawModel( self )
		render_CullMode(MATERIAL_CULLMODE_CCW)
	end

	for i = 1 , self.MaxClips do
		render_PopCustomClipPlane()
	end

	render_EnableClipping( enabled )
end

function RenderInside(self)
	if !IsValid(self) then return end
	render_CullMode(MATERIAL_CULLMODE_CW)
		ent_DrawModel( self )
	render_CullMode(MATERIAL_CULLMODE_CCW)
	ent_DrawModel( self )
end

hook.Add("InitPostEntity" , "RequestClips" , function()
	timer.Simple( 5 , function() net.Start("clipping_request_all_clips") net.SendToServer() end)
end)

-- Preview
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


concommand.Add("visual_reset",function()
	RunConsoleCommand("visual_p",0)
	RunConsoleCommand("visual_y",0)
	RunConsoleCommand("visual_distance",0)

	d = 0 
	norm = Angle(0,0,0)
end)


net.Receive( "clipping_preview_clip" , function()
	RunConsoleCommand("visual_p",norm.p)
	RunConsoleCommand("visual_y",norm.y)
	RunConsoleCommand("visual_distance",d)

	norm = Angle( net.ReadFloat() , net.ReadFloat() , net.ReadFloat() )
	d = net.ReadDouble()
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
