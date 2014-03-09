/*
Visual Clip Tool
	by TGiFallen
*/

TOOL.Category		= "Construction"
TOOL.Name			= "#Visual Clip"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["distance"] = "1"
TOOL.ClientConVar["p"] = "0"
TOOL.ClientConVar["y"] = "0"
TOOL.ClientConVar["inside"] = "0"


if CLIENT then
	language.Add( "Tool_visual_name", "Visual Clip Tool" )
	language.Add( "Tool_visual_desc", "Visually Clip Models" )
	language.Add( "Tool_visual_0", "Primary: Create a plane to clip on	Secondary: Clip Model (Do BEFORE you parent)	Reload: Remove Clips" )
end

duplicator.RegisterEntityModifier( "clips", function( p , Entity , data)
	if !Entity:IsValid() then return end
	Entity.ClipData = data
	timer.Simple(0.25, SendPropClip , Entity )
	duplicator.StoreEntityModifier( Entity, "clips", Entity.ClipData )
end)

function TOOL:LeftClick( trace )
	if CLIENT then return true end
	local ent = trace.Entity

	if !IsValid(ent) then return end
	if ent:IsPlayer() or ent:IsWorld() then return end
	
	Clipping.NewClip( ent , {Angle(self:GetClientNumber("p"),self:GetClientNumber("y"),0) , self:GetClientNumber("distance") })

	--duplicator.StoreEntityModifier( ent , "clips", ent.ClipData )
	return true
end

function TOOL:RightClick( trace )

	return true;
end

function TOOL:Reload( trace )
	if CLIENT then return true end
	Clipping.RemoveClips( trace.Entity )
	
	return true
end

if CLIENT then
	--[[
	function TOOL:Think()
		if !self.SetPreview then
			LocalPlayer().ClippingPreview = true

		end
	end

	function TOOL:Deploy()
		LocalPlayer().ClippingPreview = true
		self.SetPreview = false
	end
	--]]

	function TOOL.BuildCPanel( cp )
		cp:AddControl( "Header", { Text = "#Tool_visual_name", Description	= "#Tool_visual_desc" }  )

		cp:AddControl("Slider", { Label = "Distance", Type = "int", Min = "-100", Max = "100", Command = "visual_distance" } )
		cp:AddControl("Slider", { Label = "Pitch", Type = "int", Min = "-180", Max = "180", Command = "visual_p" } )
		cp:AddControl("Slider", { Label = "Yaw", Type = "int", Min = "-180", Max = "180", Command = "visual_y" } )
		cp:AddControl("Button", {Label = "Reset",Command = "visual_reset"})	
		cp:AddControl("Slider", { Label = "Max Clips Per Prop", Type = "int", Min = "0", Max = "25", Command = "max_clips_per_prop" } )

	end
end
