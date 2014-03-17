
if SERVER then

	AddCSLuaFile( "clip/modules/clip.lua" );
	AddCSLuaFile( "clip/sh_clip.lua" );
	AddCSLuaFile( "clip/cl_clip.lua" );

	include( "clip/sh_clip.lua" );
	include( "clip/sv_clip.lua" );

else

	include( "clip/sh_clip.lua" );
	include( "clip/cl_clip.lua" );

end
