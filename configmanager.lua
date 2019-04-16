local cfgm_version = 20190416

if CFGM then
	if CFGM.Version <= cfgm_version then
		return
	else
		CFGM = {}
	end
end

CFGM = {}
CFGM.Registry = {}
CFGM.Version = cfgm_version

local SupportedTypes = {
	"boolean",
	"string",
	"number"
}

function CFGM:Msg( str )
	MsgC( Color( 0, 255, 0 ), "[Config Manager] ", Color( 255, 255, 255 ), str .. "\n" )
end

function CFGM:HasAccess( ply )
	if CLIENT then
		if !ply then ply = LocalPlayer() end
	end
	return ply:IsSuperAdmin()
end


function CFGM:SaveCFG()
	local filename
	if SERVER then
		filename = "cfgm_svconfiguration.txt"
	elseif CLIENT then
		filename = "cfgm_clconfiguration.txt"
	end

	local str = ""
	for k, v in pairs( CFGM.Registry ) do
		str = str .. k
		for _, arg in pairs( v ) do
			str = str .. ";" .. tostring(arg)
		end
		str = str .. "\n"
	end
	file.Write( filename, str )
end

function CFGM:LoadCFG()
	local filename
	if SERVER then
		filename = "cfgm_svconfiguration.txt"
	elseif CLIENT then
		filename = "cfgm_clconfiguration.txt"
	end

	local data = file.Read( filename, "DATA" )
	if not data then return end
	data = string.Split( data, "\n" )
	for _, line in ipairs( data ) do
		local args = string.Split( line, ";" )
		local name = args[1]
		if !name then return end
		local value = args[3]
		if !value then return end
		if value == "true" or value == "false" then
			value = tobool(value)
		else
			if tonumber(value) != nil then
				value = tonumber(value)
			end
		end
		if self.Registry[name] then
			self:Set( name, value )
		else
			self:Register( name, args[4], value, args[2] )
		end
	end
end

function CFGM:Get( name )
	return self.Registry[name].value
end

function CFGM:Set( name, value )
	if type( value ) == self.Registry[name].datatype then
		CFGM.Registry[name].value = value
		hook.Call( "CFGM_ConfigUpdated", {}, name, value )
		self:Msg( "Set " .. name .. " to " .. tostring(value) .. "." )
	else
		self:Msg( "Bad value type." )
	end
end

function CFGM:Register( name, datatype, fallback, description )
	if self.Registry[name] then return end

	if table.HasValue( SupportedTypes, datatype ) then
		if type( fallback ) == datatype then
			self.Registry[name] = {
				value = fallback,
				datatype = datatype,
				description = description or "No description given."
			}
		else
			self:Msg( "Fallback datatype mismatch." )
		end
	else
		self:Msg( "Datatype unsupported." )
	end
end

if SERVER then
	util.AddNetworkString( "CFGM_RequestAdminConfig" )
	util.AddNetworkString( "CFGM_SendAdminConfig" )
	util.AddNetworkString( "CFGM_SendConfigChange" )

	net.Receive( "CFGM_RequestAdminConfig", function( len, ply )
		if CFGM:HasAccess(ply) then
			net.Start( "CFGM_SendAdminConfig" )
			net.WriteTable( CFGM.Registry )
			net.Send(ply)
		else
			CFGM:Msg( ply:Nick() .. " Admin config request denied." )
		end
	end )

	local ReadNetVars = {
	    ["boolean"] = net.ReadBool,
	    ["string"] = net.ReadString,
	    ["number"] = net.ReadFloat
	}

	net.Receive( "CFGM_SendConfigChange", function( len, ply )
		if CFGM:HasAccess(ply) then
			cfg_name = net.ReadString()
			cfg_type = CFGM.Registry[cfg_name].datatype
			cfg_value = ReadNetVars[cfg_type]()

			if type(cfg_value) == cfg_type then
				CFGM:Set( cfg_name, cfg_value )
				CFGM:SaveCFG()
			end
		else
			CFGM:Msg( ply:Nick() .. " Admin config request denied." )
		end
	end )
end

if CLIENT then
	CFGM.AdminRegistry = {}

	function CFGM:AdminFetch()
		net.Start( "CFGM_RequestAdminConfig" )
		net.SendToServer()
	end

	local WriteNetVars = {
	    ["boolean"] = net.WriteBool,
	    ["string"] = net.WriteString,
	    ["number"] = net.WriteFloat
	}

	function CFGM:AdminSet( name, value )
		net.Start( "CFGM_SendConfigChange" )
		net.WriteString( name )
		WriteNetVars[type(value)]( value )
		net.SendToServer()
	end

	net.Receive( "CFGM_SendAdminConfig", function( len )
		CFGM.AdminRegistry = net.ReadTable()
	end )

	local gradientMatD = Material( "vgui/gradient_down" )
	local gradientMatL = Material( "vgui/gradient-l" )
	local gradientMatR = Material( "vgui/gradient-r" )
	local selectedCfg = "User"

	local function SelectIndicator( x, y, w, h, clr )
		surface.SetDrawColor( clr )
		surface.SetMaterial( gradientMatR )
		surface.DrawTexturedRect( x, y, w/2, h )
		surface.SetMaterial( gradientMatL )
		surface.DrawTexturedRect( w/2, y, w/2, h )	
	end

	local frmW = (ScrW()/2)
	local frmH = (ScrH()/1.5)
	function CFGM:OpenMenu()
		if self:HasAccess() then
			self:AdminFetch()
		end
		
		local frm = vgui.Create( "DFrame" )
			frm:SetSize( frmW, frmH )
			frm:Center()
			frm:SetTitle( "" )
			frm:ShowCloseButton( false )
			frm:MakePopup()

		function frm:Paint( w, h )
			surface.SetDrawColor( 35, 35, 35 )
			surface.DrawRect( 0, 0, w, h )
		end

		local vrs = vgui.Create( "DLabel", frm )
			vrs:SetPos( 5, 5 )
			vrs:SetSize( 100, 25 )
			vrs:SetText( "configmanager\n" .. CFGM.Version )
			vrs:SetTextColor( Color( 125, 125, 125 ) )
			vrs:SetMouseInputEnabled( true )

		function vrs:DoClick()
			gui.OpenURL( "https://github.com/Vintage-Warhawk/Config-Manager" ) 
		end

		local cls = vgui.Create( "DButton", frm )
			cls:SetSize( 60, 40 )
			cls:SetPos( frmW - 65, 5 )
			cls:SetText( "" )
			cls.tempalpha = 0

		function cls:Paint( w, h )
			if self:IsHovered() then
				surface.SetDrawColor( 255, 25, 25, 25 )
				self.tempalpha = 25
			else
				surface.SetDrawColor( 255, 25, 25, self.tempalpha )
				if self.tempalpha != 0 then
					self.tempalpha = self.tempalpha - 1
				end
			end
			surface.SetMaterial( gradientMatD )
			surface.DrawTexturedRect( 0, 0, w, h )
			draw.SimpleText( "Close", "Trebuchet18", w/2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		function cls:DoClick()
			frm:Close()
		end

		local cfgbtn = vgui.Create( "DButton", frm )
			cfgbtn:SetSize( frmW/4, 40 )
			cfgbtn:SetPos( (frmW/2) - ((frmW/4) + 2), 5 )
			cfgbtn:SetText( "" )
			cfgbtn.tempalpha = 0

		function cfgbtn:Paint( w, h )
			SelectIndicator( 0, h - 10, w, 10, Color( 0, 0, 0 ) )

			if self:IsHovered() then
				surface.SetDrawColor( 25, 25, 255, 25 )
				self.tempalpha = 25
			else
				surface.SetDrawColor( 25, 25, 255, self.tempalpha )
				if self.tempalpha != 0 then
					self.tempalpha = self.tempalpha - 1
				end
			end
			surface.SetMaterial( gradientMatD )
			surface.DrawTexturedRect( 0, 0, w, h )

			if selectedCfg == "User" then
				SelectIndicator( 0, h - 6, w, 4, Color( 0, 0, 255, 125 ) )
			end

			draw.SimpleText( "User", "Trebuchet24", w/2, h/2.5, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		local svcfgbtn = vgui.Create( "DButton", frm )
			svcfgbtn:SetSize( frmW/4, 40 )
			svcfgbtn:SetPos( (frmW/2) + 2, 5 )
			svcfgbtn:SetText( "" )
			svcfgbtn.tempalpha = 0

		function svcfgbtn:Paint( w, h )
			SelectIndicator( 0, h - 10, w, 10, Color( 0, 0, 0 ) )

			if self:IsHovered() then
				if CFGM:HasAccess() then
					surface.SetDrawColor( 25, 25, 255, 25 )
					self.tempalpha = 25
				else
					surface.SetDrawColor( 255, 25, 25, 25 )
					self.tempalpha = 25
				end
			else
				if CFGM:HasAccess() then
					surface.SetDrawColor( 25, 25, 255, self.tempalpha )
				else
					surface.SetDrawColor( 255, 25, 25, self.tempalpha )
				end
				if self.tempalpha != 0 then
					self.tempalpha = self.tempalpha - 1
				end
			end
			surface.SetMaterial( gradientMatD )
			surface.DrawTexturedRect( 0, 0, w, h )

			if selectedCfg == "Admin" then
				SelectIndicator( 0, h - 6, w, 4, Color( 0, 0, 255, 125 ) )
			end

			draw.SimpleText( "Admin", "Trebuchet24", w/2, h/2.5, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		local body = vgui.Create( "DPanel", frm )
			body:SetSize( frmW, frmH - 50 )
			body:SetPos( 0, 50 )

		function body:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
		end

		local scrl = vgui.Create( "DScrollPanel", body )
			scrl:Dock( FILL )

		local function UpdateRegistry()
			scrl:Clear()

			local registry = {}
			if selectedCfg == "Admin" then
				CFGM.AdminFetch()
				registry = CFGM.AdminRegistry
			elseif selectedCfg == "User" then
				registry = CFGM.Registry
			end

			local tblnum = 0
			for k, v in pairs( registry ) do
				local num = tblnum
				tblnum = tblnum + 1

				local cfg = scrl:Add( "DPanel" )
					cfg:SetSize( 50, 50 )
					cfg:Dock( TOP )
					cfg:DockMargin( 5, 5, 5, 0 )

				function cfg:Paint( w, h )
					draw.RoundedBox( 0, 0, 0, w, h, (num % 2) == 0 and Color( 15, 15, 15 ) or Color( 20, 20, 20 ) )
				end

				local cfglbl = vgui.Create( "DLabel", cfg )
					cfglbl:SetSize( 200, 25 )
					cfglbl:SetPos( 5, 0 )
					cfglbl:SetFont( "Trebuchet18" )
					cfglbl:SetText( k )
					cfglbl:SetTextColor( Color( 175, 175, 175 ) )

				if v.datatype == "string" then
					local cfgtxt = vgui.Create( "DTextEntry", cfg )
						cfgtxt:SetSize( 200, 20 )
						cfgtxt:SetPos( 5, 25 )
						cfgtxt:SetValue( v.value )

					function cfgtxt:Paint( w, h )
						draw.RoundedBox( 0, 0, 0, w, h, Color( 175, 175, 175 ) )
						draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 30, 30, 30 ) )
						self:DrawTextEntryText( Color( 175, 175, 175 ), Color( 30, 130, 255 ), Color( 175, 175, 175 ) )
					end

					local cfgset = vgui.Create( "DButton", cfg )
						cfgset:SetSize( 40, 20 )
						cfgset:SetPos( 210, 25 )
						cfgset:SetText( "" )

					function cfgset:Paint( w, h )
						draw.RoundedBox( 0, 0, 0, w, h, self:IsHovered() and Color( 45, 45, 45 ) or Color( 35, 35, 35 ) )
						draw.SimpleText( "Set", "Trebuchet18", w/2, h/2, self:IsHovered() and Color( 185, 185, 185 ) or Color( 175, 175, 175 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					function cfgset:DoClick()
						if selectedCfg == "Admin" then
							CFGM:AdminSet( k, cfgtxt:GetValue() )
						elseif selectedCfg == "User" then
							CFGM:Set( k, cfgtxt:GetValue() )
							CFGM:SaveCFG()
						end
					end

				elseif v.datatype == "number" then

					local cfgnum = vgui.Create( "DNumSlider", cfg )
						cfgnum:SetSize( 200, 20 )
						cfgnum:SetPos( 5, 25 )
						cfgnum:SetText( "Number Value" )
						cfgnum:SetMin( 0 )			
						cfgnum:SetMax( 256 )
						cfgnum:SetDecimals( 0 )
						cfgnum:SetValue( v.value )
						cfgnum:SetDark( false )

					function cfgnum.TextArea:Paint( w, h )
						draw.RoundedBox( 0, 0, 0, w, h, Color( 175, 175, 175 ) )
						draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 30, 30, 30 ) )
						self:DrawTextEntryText( Color( 175, 175, 175 ), Color( 30, 130, 255 ), Color( 175, 175, 175 ) )
					end

					local cfgset = vgui.Create( "DButton", cfg )
						cfgset:SetSize( 40, 20 )
						cfgset:SetPos( 210, 25 )
						cfgset:SetText( "" )

					function cfgset:Paint( w, h )
						draw.RoundedBox( 0, 0, 0, w, h, self:IsHovered() and Color( 45, 45, 45 ) or Color( 35, 35, 35 ) )
						draw.SimpleText( "Set", "Trebuchet18", w/2, h/2, self:IsHovered() and Color( 185, 185, 185 ) or Color( 175, 175, 175 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					function cfgset:DoClick()
						if selectedCfg == "Admin" then
							CFGM:AdminSet( k, cfgnum:GetValue() )
						elseif selectedCfg == "User" then
							CFGM:Set( k, cfgnum:GetValue() )
							CFGM:SaveCFG()
						end
					end

				elseif v.datatype == "boolean" then

					local cfgbool = vgui.Create( "DCheckBox", cfg )
						cfgbool:SetPos( 5, 25 )
						cfgbool:SetChecked( v.value )

					local cfgset = vgui.Create( "DButton", cfg )
						cfgset:SetSize( 40, 20 )
						cfgset:SetPos( 210, 25 )
						cfgset:SetText( "" )

					function cfgset:Paint( w, h )
						draw.RoundedBox( 0, 0, 0, w, h, self:IsHovered() and Color( 45, 45, 45 ) or Color( 35, 35, 35 ) )
						draw.SimpleText( "Set", "Trebuchet18", w/2, h/2, self:IsHovered() and Color( 185, 185, 185 ) or Color( 175, 175, 175 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end

					function cfgset:DoClick()
						if selectedCfg == "Admin" then
							CFGM:AdminSet( k, cfgbool:GetChecked() )
						elseif selectedCfg == "User" then
							CFGM:Set( k, cfgbool:GetChecked() )
							CFGM:SaveCFG()
						end
					end
				end

				local cfgdesc = vgui.Create( "DLabel", cfg )
					cfgdesc:SetSize( (frmW - 10)/2, 50 )
					cfgdesc:Dock( RIGHT )
					cfgdesc:SetText( v.description )
			end
		end

		function cfgbtn:DoClick()
			selectedCfg = "User"
			UpdateRegistry()
		end

		function svcfgbtn:DoClick()
			if CFGM:HasAccess() then
				selectedCfg = "Admin"
				UpdateRegistry()
			end
		end

		UpdateRegistry()
	end
	concommand.Add( "ConfigManager", function()
		CFGM:OpenMenu()
	end )
end

CFGM:LoadCFG()
MsgC( Color( 0, 255, 0 ), "Config Manager (" .. CFGM.Version .. ") loaded.\n" )