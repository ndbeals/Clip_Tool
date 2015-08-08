--compatitbility for old tool style dupes 

duplicator.RegisterEntityModifier( "clips", function( p , ent , data)
	if !IsValid(ent)  or !data then return end
	if ent:GetTable().EntityMods and ent:GetTable().EntityMods.clipping_all_prop_clips then return end -- Got newer clipping table, screw old one.

	timer.Simple(0.25 , function()
		for _, clip in pairs(data) do
			if IsValid(ent) then
				Clipping.NewClip( ent , {clip.n,clip.d})

				Clipping.RenderInside( ent , clip.inside )
			end
		end
	end)
end)
