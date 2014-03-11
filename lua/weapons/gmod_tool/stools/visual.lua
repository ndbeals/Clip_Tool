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


if CLIENT then
	language.Add( "Tool.visual.name", "Visual Clip Tool" )
	language.Add( "Tool.visual.desc", "Visually Clip Models" )
	language.Add( "Tool.visual.0", "Primary: Define a clip plane      Secondary: Clip Model      Reload: Remove Clips" )
	language.Add( "Tool.visual.1", "Primary: Click on a second spot      Secondary: Clip Model      Reload: Restart" )
	language.Add( "Tool.visual.2", "Primary: Select the side of the prop you want to keep      Secondary: Clip Model      Reload: Restart" )
	language.Add( "Tool.visual.3", "Primary: Define a new plane based off of another prop      Secondary: Clip Model      Reload: Restart")
	language.Add( "Tool.visual.4", "Aim at other props:      Secondary: Clip Model      Reload: Restart")

	language.Add( "undone_clip", "Undone Clip" )
else
	util.AddNetworkString("clipping_cliptool_mode")
end

if SERVER then
	TOOL.Function = 1
	function TOOL:Think()
		local ent = self:GetOwner():GetEyeTraceNoCursor( ).Entity

		if ent != self.LastEnt and IsValid(ent) and (self:GetStage() == 4 or self:GetStage() == 2) then
			self.LastEnt = ent

			local ang = self.Normal:Angle()
			local pos = ent:LocalToWorld( ent:OBBCenter() )

			local linepoint1 = self.Position
			local linepoint2 = self.Position + ang:Forward()
			local dist = -(self.Normal:Dot(pos-linepoint1))/(self.Normal:Dot(linepoint2-linepoint1))
			ang = ent:WorldToLocalAngles(self.Normal:Angle())

			net.Start("clipping_preview_clip")
				net.WriteFloat( ang.p )
				net.WriteFloat( ang.y )
				net.WriteFloat( ang.r )
				net.WriteDouble( dist )
			net.Send( self:GetOwner() )
		end
	end

	net.Receive("clipping_cliptool_mode" , function(_,ply)
		local mode = net.ReadInt(8)
		local tool = ply:GetTool("visual")
		tool.Function = mode

		if mode == 2 then 
			tool.Points = {}
			tool.Step = 0
			tool:SetStage(0)
		elseif mode == 1 then
			tool:SetStage(3)
		end
	end)
end
	

function TOOL:LeftClick( trace )
	if CLIENT then return true end
	local ent = trace.Entity

	self.Points = self.Points or {}
	self.Step = self.Step or 0

	if !IsValid(ent) then return end
	if ent:IsPlayer() or ent:IsWorld() then return end
	
	if self.Function == 1 then
		self:SetStage(4)

		self.Normal = -trace.HitNormal
		self.Position = trace.HitPos

		local ang = self.Normal:Angle()
		local pos = ent:LocalToWorld( ent:OBBCenter() )

		local linepoint1 = self.Position
		local linepoint2 = self.Position + ang:Forward()
		local dist = -(self.Normal:Dot(pos-linepoint1))/(self.Normal:Dot(linepoint2-linepoint1))

		ang = ent:WorldToLocalAngles(self.Normal:Angle())

		net.Start("clipping_preview_clip")
			net.WriteFloat( ang.p )
			net.WriteFloat( ang.y )
			net.WriteFloat( ang.r )
			net.WriteDouble( dist )
		net.Send( self:GetOwner() )
	elseif self.Function == 2 then
		self.Points[#self.Points+1] = trace.HitPos
		self:SetStage(#self.Points)

		if #self.Points > 1 then
			self:SetStage(2)
			self.Step = self.Step + 1

			local normal = (self.Points[1] - self.Points[2]):GetNormalized()
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
			local linepoint1 = self.Points[1]
			local linepoint2 = self.Points[1] + ang:Forward()
			local dist = -(normal:Dot(pos-linepoint1))/(normal:Dot(linepoint2-linepoint1))
			ang = ent:WorldToLocalAngles(normal:Angle())
			
			self.Position = linepoint1
			self.Normal= -normal

			net.Start("clipping_preview_clip")
				net.WriteFloat( ang.p )
				net.WriteFloat( ang.y )
				net.WriteFloat( ang.r )
				net.WriteDouble( dist )
			net.Send( self:GetOwner() )
		end
	end
	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return true end
	local ent = trace.Entity

	self:SetStage(0)

	if !IsValid(ent) then return end
	if ent:IsPlayer() or ent:IsWorld() then return end
	
	Clipping.NewClip( ent , {Angle(self:GetClientNumber("p"),self:GetClientNumber("y"),0) , self:GetClientNumber("distance") })

	undo.Create("clip")
		undo.AddFunction(function( data , ent , numclips )
			Clipping.RemoveClip( ent , numclips )
		end, ent , #Clipping.GetClips(ent))

		undo.SetPlayer(self:GetOwner()) 
	undo.Finish()

	return true;
end

function TOOL:Reload( trace )
	if CLIENT then return true end

	if self:GetStage() == 2 or self:GetStage()==4 then
		if self.Function == 2 then 
			self:SetStage(0)
		elseif self.Function == 1 then
			self:SetStage(3)
		end

		self.Points = {}
		self.Step = 0

		return false
	end

	Clipping.RemoveClips( trace.Entity )

	return true
end

if CLIENT then
	function TOOL.BuildCPanel( pnl )
		pnl:Help("#Tool.visual.desc")

		local clipfunctions = vgui.Create("DListView",pnl)
		local tmp = clipfunctions:AddColumn("Plane functions")
		tmp.Header.DoClick=function()end
		clipfunctions:AddLine("Plane from Prop")
		clipfunctions:AddLine("Point to Point")
		clipfunctions:SetTall( 50 )


		clipfunctions.OnClickLine = function( self , line , selected )
			clipfunctions:ClearSelection()
			clipfunctions:SelectItem(line)

			net.Start("clipping_cliptool_mode")
				net.WriteInt(line:GetID() , 8)
			net.SendToServer()
		end
		pnl:AddPanel(clipfunctions)

		local temp = pnl:AddControl("Slider", { Label = "Distance", Type = "float", Min = "-100", Max = "100", Command = "visual_distance" } )
		local temp2 = vgui.Create("DNumberScratch")
		temp2:SetParent(temp)
		temp2:SetMax(100)
		temp2:SetMin(-100)
		temp2:SetPos( 120 , 10)
		temp2.OnValueChanged = function(self)
			RunConsoleCommand("visual_distance",self:GetFloatValue())
		end
		temp2:SetShouldDrawScreen(true)


		temp = pnl:AddControl("Slider", { Label = "Pitch", Type = "float", Min = "-180", Max = "180", Command = "visual_p" } )
		temp2 = vgui.Create("DNumberScratch")
		temp2:SetParent(temp)
		temp2:SetMax(180)
		temp2:SetMin(-180)
		temp2:SetPos( 120 , 10)
		temp2.OnValueChanged = function(self)
			RunConsoleCommand("visual_p",self:GetFloatValue())
		end
		temp2:SetShouldDrawScreen(true)


		temp = pnl:AddControl("Slider", { Label = "Yaw", Type = "float", Min = "-180", Max = "180", Command = "visual_y" } )
		temp2 = vgui.Create("DNumberScratch")
		temp2:SetParent(temp)
		temp2:SetMax(180)
		temp2:SetMin(-180)
		temp2:SetPos( 120 , 10)
		temp2.OnValueChanged = function(self)
			RunConsoleCommand("visual_y",self:GetFloatValue())
		end
		temp2:SetShouldDrawScreen(true)


		pnl:AddControl("Button", {Label = "Reset",Command = "visual_reset"})	
		pnl:AddControl("Slider", { Label = "Max Clips Per Prop", Type = "int", Min = "0", Max = "25", Command = "max_clips_per_prop" } )

	end
end
