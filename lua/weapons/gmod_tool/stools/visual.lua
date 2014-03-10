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
TOOL.ClientConVar["r"] = "0"
TOOL.ClientConVar["inside"] = "0"
TOOL.ClientConVar["mode"] = ""


if CLIENT then
	language.Add( "Tool.visual.name", "Visual Clip Tool" )
	language.Add( "Tool.visual.desc", "Visually Clip Models" )
	language.Add( "Tool.visual.0", "Primary: Define a clip plane	Secondary: Clip Model 	Reload: Remove Clips" )
	language.Add( "Tool.visual.1", "Primary: Click on a second spot		Secondary: Restart" )
	language.Add( "Tool.visual.2", "Primary: Select the side of the prop you want to keep	Seconday: Clip Model" )
	language.Add( "Tool.visual.3", "Primary: Define a new plane based off of another prop 	Secondary: Restart")
	language.Add( "Tool.visual.4", "Aim at other props: 	Secondary: Clip Model")
end

if SERVER then
	function TOOL:Think()
		local ent = self:GetOwner():GetEyeTraceNoCursor( ).Entity

		if ent != self.lastent and IsValid(ent) and self:GetStage() == 4 then
			self.lastent = ent

			local ang = self.norm:Angle()
			local pos = ent:LocalToWorld( ent:OBBCenter() )

			local linepoint1 = self.pos
			local linepoint2 = self.pos + ang:Forward()
			local dist = -(self.norm:Dot(pos-linepoint1))/(self.norm:Dot(linepoint2-linepoint1))
			ang = ent:WorldToLocalAngles(self.norm:Angle())

			net.Start("clipping_preview_clip")
				net.WriteFloat( ang.p )
				net.WriteFloat( ang.y )
				net.WriteFloat( ang.r )
				net.WriteDouble( dist )
			net.Send( self:GetOwner() )
		end

		if self:GetClientNumber("mode") == 2 and self:GetStage() != 4 then
			self:SetStage(3)
		end

	end

end
	

function TOOL:LeftClick( trace )
	if CLIENT then return true end
	local ent = trace.Entity
	local mode = self:GetClientNumber("mode")

	self.Points = self.Points or {}
	self.Step = self.Step or 0

	if !IsValid(ent) then return end
	if ent:IsPlayer() or ent:IsWorld() then return end
	
	if mode == 1 then
		self.Points[ self:GetStage() ] = trace.HitPos

		if self:GetStage() == 1 then
			self:SetStage(2)
			self.Step = self.Step + 1

			local normal = (self.Points[0] - self.Points[1]):GetNormalized()
			local ang = normal:Angle()
			local pos = ent:LocalToWorld( ent:OBBCenter() )

			if self.Step == 1 then
				ang:RotateAroundAxis(ang:Right() , -90 )
			elseif self.Step == 2 then
				ang:RotateAroundAxis(ang:Right() , 90 )
			elseif self.Step == 3 then
				ang:RotateAroundAxis(ang:Up() , 90 )
			elseif self.Step == 4 then
				ang:RotateAroundAxis(ang:Up() , -90 )
				self.Step = 0
			end

			normal=ang:Forward()
			local linepoint1 = self.Points[0]
			local linepoint2 = self.Points[0] + ang:Forward()
			local dist = -(normal:Dot(pos-linepoint1))/(normal:Dot(linepoint2-linepoint1))
			ang = ent:WorldToLocalAngles(normal:Angle())

			net.Start("clipping_preview_clip")
				net.WriteFloat( ang.p )
				net.WriteFloat( ang.y )
				net.WriteFloat( ang.r )
				net.WriteDouble( dist )
			net.Send( self:GetOwner() )
		else
			self:SetStage( self:GetStage() + 1 )
		end

	elseif mode == 2 then
		self:SetStage(4)

		self.norm = -trace.HitNormal
		self.pos = trace.HitPos

		local ang = self.norm:Angle()
		local pos = ent:LocalToWorld( ent:OBBCenter() )

		local linepoint1 = self.pos
		local linepoint2 = self.pos + ang:Forward()
		local dist = -(self.norm:Dot(pos-linepoint1))/(self.norm:Dot(linepoint2-linepoint1))

		ang = ent:WorldToLocalAngles(self.norm:Angle())

		net.Start("clipping_preview_clip")
			net.WriteFloat( ang.p )
			net.WriteFloat( ang.y )
			net.WriteFloat( ang.r )
			net.WriteDouble( dist )
		net.Send( self:GetOwner() )
	end

	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return true end
	local ent = trace.Entity

	self:SetStage(0)

	if !IsValid(ent) then return end
	if ent:IsPlayer() or ent:IsWorld() then return end
	
	if self:GetStage() == 0 or self:GetStage() == 2 or self:GetStage(4) then
		Clipping.NewClip( ent , {Angle(self:GetClientNumber("p"),self:GetClientNumber("y"),0) , self:GetClientNumber("distance") })
	end

	return true;
end

function TOOL:Reload( trace )
	if CLIENT then return true end
	Clipping.RemoveClips( trace.Entity )

	return true
end

if CLIENT then
	function TOOL.BuildCPanel( pnl )
		pnl:Help("#Tool.visual.desc")

		local clipfunctions = vgui.Create("DListView",pnl)
		local tmp = clipfunctions:AddColumn("Plane functions")
		tmp.Header.DoClick=function()end
		clipfunctions:AddLine("Point to Point")
		clipfunctions:AddLine("Plane of another prop")
		clipfunctions:SetTall( 50 )


		clipfunctions.OnClickLine = function( self , line , selected )
			clipfunctions:SelectItem(line)
			RunConsoleCommand("visual_mode",line:GetID())
		end

		pnl:AddPanel(clipfunctions)



		--cp:AddControl( "Header", { Text = "#Tool_visual_name", Description	= "#Tool_visual_desc" }  )

		pnl:AddControl("Slider", { Label = "Distance", Type = "float", Min = "-100", Max = "100", Command = "visual_distance" } )
		pnl:AddControl("Slider", { Label = "Pitch", Type = "float", Min = "-180", Max = "180", Command = "visual_p" } )
		pnl:AddControl("Slider", { Label = "Yaw", Type = "float", Min = "-180", Max = "180", Command = "visual_y" } )
		pnl:AddControl("Button", {Label = "Reset",Command = "visual_reset"})	
		pnl:AddControl("Slider", { Label = "Max Clips Per Prop", Type = "int", Min = "0", Max = "25", Command = "max_clips_per_prop" } )

	end
end
