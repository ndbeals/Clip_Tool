--compatitbility for old tool style dupes 

duplicator.RegisterEntityModifier( "clips", function( p , ent , data)
	if !IsValid(ent)  or !data then return end
	

	timer.Simple(0.25 , function()
		for _, clip in pairs(data) do
			Clipping.NewClip( ent , {clip.n,clip.d})
		end
	end)
end)