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

local n , enabled
function RenderOverride(self)
	if !IsValid(self) then return end
	enabled = render_EnableClipping( true )

	for i = 1 , self.MaxClips do
		n = ang_Forward( ent_LocalToWorldAngles(self , Clips[self][i][1] ) )
		
		render_PushCustomClipPlane(n, vec_Dot(ent_LocalToWorld(self , Clips[self][i][3])+n* Clips[self][i][2] , n ) )
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
	if IsValid(self) then
		render_CullMode(MATERIAL_CULLMODE_CW)
			ent_DrawModel( self )
		render_CullMode(MATERIAL_CULLMODE_CCW)
		ent_DrawModel( self )
	end
end

hook.Add("InitPostEntity" , "RequestClips" , function()
	timer.Simple( 5 , function() net.Start("clipping_request_all_clips") net.SendToServer() end)
end)