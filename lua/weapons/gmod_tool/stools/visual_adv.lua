/*
Visual Clip Tool
	by TGiFallen
	Credits to Ralle105 of facepunch
*/

TOOL.Category		= "Construction"
TOOL.Name			= "#Visual Clip - Advanced"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["distance"] = "0"
TOOL.ClientConVar["inside"] = "0"

if CLIENT then
	language.Add( "Tool_visual_adv_name", "Visual Clip Tool - Advanced" )
	language.Add( "Tool_visual_adv_desc", "Visually Clip Models" )
	language.Add( "Tool_visual_adv_0", "Primary: Click two different ares to define a clipplane 	Primary + Shift: Clip by plane   Reload: Remove Clips" )
	language.Add( "Tool_visual_adv_1", "Primary: Click on a second spot" )
	language.Add( "Tool_visual_adv_2", "Primary: Select the side of the prop you want to keep	Seconday: Confirm clip" )
	language.Add( "Tool_visual_adv_3", "Shift + Primary: Define a new plane 	Secondary: Confirm clip")
end


duplicator.RegisterEntityModifier( "clips", function( p , Entity , data)
	if !IsValid( Entity ) then return end
	Entity.ClipData = data
	timer.Simple(0.25, SendPropClip , Entity )
	duplicator.StoreEntityModifier( Entity, "clips", Entity.ClipData )
end)

local spots = {ang = Angle(0,0,0)}
TOOL.toggle = 0
TOOL.mode = 0
TOOL.norm = Vector(0,0,1)
TOOL.dist = 0

function TOOL:Think()

	local trace = self:GetOwner():GetEyeTraceNoCursor( )
	local ent = trace.Entity
	if ent != self.lastent and !CLIENT and ent != NULL and IsValid(ent) and self.alt then
		self.lastent = ent

		local ang = self.norm:Angle()
		local pos = ent:LocalToWorld( ent:OBBCenter() )

		local LinePoint1 = self.pos
		local LinePoint2 = self.pos + ang:Forward()
		local dist = -(self.norm:Dot(pos-LinePoint1))/(self.norm:Dot(LinePoint2-LinePoint1))

		umsg.Start("visual_clip_data" , self:GetOwner())
			local ang = ent:WorldToLocalAngles(self.norm:Angle())
			spots.ang = ang
			umsg.Float(ang.p)
			umsg.Float(ang.y)
			umsg.Float(ang.r)
			umsg.Float(dist )
		umsg.End()

	end


	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return true end
	if self:GetStage() < 2 and self.mode == 2 then
		self:GetOwner():PrintMessage(HUD_PRINTCENTER , "Please complete all the steps before you clip")
		return
	end

	local ent = trace.Entity
	if !IsValid(ent) or ent:IsWorld() or ent:IsPlayer() or ent==NULL then return end

	ent.ClipData = ent.ClipData or {}

	local ind = table.insert(ent.ClipData , {
		n = spots.ang,
		d = self:GetClientInfo("distance"),
		inside = tobool( self:GetClientInfo("inside") or false ),
		new = true
	})
	SendPropClip( ent , nil , ind )
	duplicator.StoreEntityModifier( ent , "clips", ent.ClipData )
	if !table.HasValue( Clipped , ent ) then
		Clipped[ #Clipped + 1 ] =  ent
	end
	self.mode = 0
	self.alt = true
	self:SetStage(0)

	return true;
end

function TOOL:LeftClick( trace )
	if CLIENT then return true end
	local ent = trace.Entity
	if !ent:IsValid() or ent:IsWorld() or ent:IsPlayer() or ent==NULL then return end
	local pos = trace.HitPos
	local stage = self:GetStage()

	if self:GetOwner():KeyDown( IN_SPEED ) and self.mode != 2 and (stage == 0 or stage == 3) then
		self:SetStage( 3 )
		self.lastent = ent
		self.norm = -trace.HitNormal
		self.pos = trace.HitPos
		self.mode = 1
		self.alt = true

		local ang = self.norm:Angle()
		local pos = ent:LocalToWorld( ent:OBBCenter() )

		local LinePoint1 = self.pos
		local LinePoint2 = self.pos + ang:Forward()
		local dist = -(self.norm:Dot(pos-LinePoint1))/(self.norm:Dot(LinePoint2-LinePoint1))

		umsg.Start("visual_clip_data" , self:GetOwner() )
			local ang = ent:WorldToLocalAngles(self.norm:Angle())
			spots.ang = ang
			umsg.Float(ang.p)
			umsg.Float(ang.y)
			umsg.Float(ang.r)
			umsg.Float(dist)
			
		umsg.End()
		return true
	end

	if self.mode != 1 and stage != 3 then
		self.mode = 2
		
		spots[ stage + 1 ] = pos

		if stage == 2 or stage == 1 then
			self:SetStage( 2 )
			self.toggle = self.toggle + 1

			local norm = (spots[1] - spots[2]):GetNormalized()
			local ang = norm:Angle()
			local pos = ent:LocalToWorld( ent:OBBCenter() )

			if self.toggle == 1 then
				ang:RotateAroundAxis(ang:Right() , -90 )
			elseif self.toggle == 2 then
				ang:RotateAroundAxis(ang:Right() , 90 )
			elseif self.toggle == 3 then
				ang:RotateAroundAxis(ang:Up() , 90 )
			elseif self.toggle == 4 then
				ang:RotateAroundAxis(ang:Up() , -90 )
				self.toggle = 0
			end

			local Normal = ang:Forward()
			local LinePoint1 = spots[1]
			local LinePoint2 = spots[1] + ang:Forward()
			local dist = -(Normal:Dot(pos-LinePoint1))/(Normal:Dot(LinePoint2-LinePoint1))
			
			umsg.Start("visual_clip_data" , self:GetOwner() )
				local ang = ent:WorldToLocalAngles(Normal:Angle())
				spots.ang = ang
				umsg.Float(ang.p)
				umsg.Float(ang.y)
				umsg.Float(ang.r)
				umsg.Float(dist)
			umsg.End()
			return true
		end
		self:SetStage( stage + 1 )
	end
	return true
end

function TOOL:Reload( trace )
	if CLIENT then return true end
	local ent = trace.Entity
	if !IsValid(ent) then return end
	ent.ClipData = ent.ClipData or {}
	local count = #ent.ClipData
	ent.ClipData[ count ] = nil
	if count == 1 then
		ent.ClipData = {}
		for k , v in pairs(Clipped) do
			if v == ent then
				Clipped[ k ] = nil
			end
		end
	end
	umsg.Start("visual_clip_reset")
		umsg.Entity(ent)
	umsg.End()
	return true
end

function TOOL:Holster()
	self:SetStage(0)
	self.mode = 0
	self.alt = false
end

if CLIENT then
	function TOOL.BuildCPanel( cp )
		cp:AddControl( "Header", { Text = "#Tool_visual_adv_name", Description	= "#Tool_visual_adv_desc" }  )

		cp:AddControl("Slider", { Label = "Distance", Type = "float", Min = "-100", Max = "100", Command = "visual_adv_distance" } )
		cp:AddControl("Button", {Label = "Reset",Command = "visual_adv_reset"})	
		cp:AddControl("CheckBox" , {Label = "Render inside of prop", Description = "Clicking this will render the inside of the prop", Command = "visual_adv_inside" } )
		cp:AddControl("Slider", { Label = "Max Clips Per Prop", Type = "int", Min = "0", Max = "25", Command = "max_clips_per_prop" } )
	end
end
