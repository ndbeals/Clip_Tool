
-- Libraries
local table = table;
local string = string;
local math = math;
local util = util;
local net = net;
local hook = hook;
local duplicator = duplicator;

-- Functions
local CLIENT = CLIENT;
local SERVER = SERVER;
local IsValid = IsValid;
local Vector = Vector;
local Angle = Angle;
local CurTime = CurTime;
local pairs = pairs;
local type = type;
local tobool = tobool;
local tostring = tostring;
local tonumber = tonumber;

-- Network Strings
if SERVER then

	util.AddNetworkString( "clip_add" );
	util.AddNetworkString( "clip_remove" );
	util.AddNetworkString( "clip_preview" );

	util.AddNetworkString( "clips_add" );
	util.AddNetworkString( "clips_remove" );
	util.AddNetworkString( "clips_get" );

end

-- Module
module( "clip" );

local Clips = {};
local Queue = {};

-- Server Methods and Hooks
if SERVER then

	function Send( ent, clip )

		if( !IsValid( ent ) or !IsValid( clip ) ) then return end

		net.Start( "clip_add" );
			net.WriteEntity( ent ); -- Entity Reference
			net.WriteFloat( clip.Angle.p ); -- Pitch
			net.WriteFloat( clip.Angle.y ); -- Yaw
			net.WriteFloat( clip.Angle.r ); -- Roll
			net.WriteDouble( clip.Mystery ); -- Mysterious Double?
			net.WriteBit( tobool( clip.Inside ) ); -- Render Inside switch, cheaper than a new net.*
		net.Broadcast();

	end
	
	function Register( ent, clip )

		if( !IsValid( ent ) or !IsValid( clip ) ) then return end
		
		if( !Clips[ ent ] ) then

			Clips[ ent ] = { clip };

		else

			table.insert( Clips[ ent ], clip );

		end

		ent:CallOnRemove( "RemoveFromClippedTable" , function( ent )

			Clips[ ent ] = nil;

		end );

		duplicator.StoreEntityModifier( ent, "clip", Clips[ ent ] );

		--@looter: todo: implement new queue system rather than sending after the register event
		--Send( ent, clip );

	end

end

-- Client Methods and Hooks
if CLIENT then


end

-- Shared Methods and Hooks
function Get( ent )

	if( IsValid( ent ) and Clips[ ent ] != nil ) then

		return Clips[ ent ];

	end

	return {};

end

function GetAll()

	return Clips;

end
