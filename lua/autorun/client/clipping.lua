local Clips = {}
local RenderOverride


local cvar = CreateClientConVar("max_clips_per_prop" , 3 , true , false )

cvars.AddChangeCallback( "max_clips_per_prop" ,function(_,_,new)
	new = tonumber(new)
	for ent , _ in pairs( Clips ) do
		if new >= #ent.ClipData then
			ent.MaxClips = #ent.ClipData
		else
			ent.MaxClips = new
		end
	end
end)

local function ReadAngleAsFloat()
	return Angle( net.ReadFloat() , net.ReadFloat() , net.ReadFloat() )
end

local function ReadClip( ent )
	return {ReadAngleAsFloat() , net.ReadDouble(), ent:OBBCenter()}
end

local function AddPropClip( ent , clip )
	Clips[ ent ] = Clips[ ent ] or {}
	Clips[ ent ][ #Clips[ ent ] + 1 ] = clip

	ent.MaxClips = math.min( cvar:GetInt() , #Clips[ent] )

	ent:CallOnRemove( "RemoveFromClippedTable" , function( ent ) Clips[ent] = nil end)
	
	ent.RenderOverride = RenderOverride
end

net.Receive( "clipping_new_clip" , function()
	local ent = net.ReadEntity()
	AddPropClip( ent , ReadClip( ent ) )
end)

net.Receive( "clipping_all_prop_clips" , function()
	local ent = net.ReadEntity()
	local clips = net.ReadInt( 16 )

	for i = 1 , clips do
		AddPropClip( ent , ReadClip(ent) )
	end
end)

net.Receive( "clipping_remove_clips" , function ()
	local ent = net.ReadEntity()

	Clips[ent] = nil 
	ent.RenderOverride = nil 
end)



local render_EnableClipping = render.EnableClipping
local render_PushCCP = render.PushCustomClipPlane
local render_PopCCP = render.PopCustomClipPlane

local entm = FindMetaTable("Entity")
local ent_LocalTWA = entm.LocalToWorldAngles
local ent_LocalTW = entm.LocalToWorld
local ent_SetupBones = entm.SetupBones
local ent_DrawModel = entm.DrawModel

local vecm = FindMetaTable("Vector")
local vec_Dot = vecm.Dot

local angm = FindMetaTable("Angle")
local ang_Forward = angm.Forward

local IsValid = IsValid

local n , enabled
function RenderOverride(self)
	enabled = render_EnableClipping( true )

	for i = 1 , self.MaxClips do
		n = ang_Forward( ent_LocalTWA(self , Clips[self][i][1] ) )
		
		render_PushCCP(n, vec_Dot(ent_LocalTW(self , Clips[self][i][3])+n* Clips[self][i][2] , n ) )
	end

	ent_SetupBones( self )
	ent_DrawModel( self )

	for i = 1 , self.MaxClips do
		render_PopCCP()
	end

	render_EnableClipping( enabled )
end

hook.Add("InitPostEntity" , "RequestClips" , function()
	timer.Simple( 5 , function() net.Start("clipping_request_all_clips") net.SendToServer() end)
end)