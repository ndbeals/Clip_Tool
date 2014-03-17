
-- Entity Modifiers
duplicator.RegisterEntityModifier( "clip", function( p, ent, data )
	
	if( !IsValid( ent ) or !IsValid( data ) ) then return end

	for _, clip in pairs( data ) do

		if( IsValid( ent ) ) then

			clip.Register( ent, clip );

		end

	end

end );

-- Old versions
duplicator.RegisterEntityModifier( "clipping_all_prop_clips", function( p, ent, data )
	
	if( !IsValid( ent ) or !IsValid( data ) ) then return end

	for _, clip in pairs( data ) do

		if( IsValid( ent ) ) then

			local newclip = {
				Angle: clip[1],
				Mystery: clip[2],
				Inside: clip[3] -- probably wont work..
			};

			clip.Register( ent, newclip );

		end

	end

end );

duplicator.RegisterEntityModifier( "clips", function( p, ent, data )

	if( !IsValid( ent ) or !IsValid( data ) ) then return end
	
	for _, clip in pairs( data ) do

		if( IsValid( ent ) ) then

			local newclip = {
				Angle: clip.n,
				Mystery: clip.d,
				Inside: clip.inside
			};

			clip.Register( ent, newclip );

		end

	end
		
end );
