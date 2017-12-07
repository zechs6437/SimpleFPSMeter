-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter by Zechs6437
--
-- v1.2 - Added configuration window. I'm not much of a UI designer..
--		- More code cleanup (I could clean even more if I got rid of the slashcommand toggles..)
--
-- v1.1a - Moved latency meter to right of FPS readout
--		 - Changed round() to math.floor()
--
-- v1.1 - Added latency meter
--		- Code cleanup
--
-- v1.0 - Initial release
--
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "Apollo"
require "ChatSystemLib"

local SimpleFPSMeter = {} 
 
local bShowFPS = true
local bShowFPSFPS = true
local bShowLatency = true
local bShowLatencyMS = true

function SimpleFPSMeter:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function SimpleFPSMeter:Init()
    Apollo.RegisterAddon(self, true, "SimpleFPSMeter", nil)
end

-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter Save/Restore functions on UI load
-----------------------------------------------------------------------------------------------
function SimpleFPSMeter:OnSave(eLevel)
		if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account) then
		return
	end

	local tSave = {}
	tSave = {
				bShowFPS = bShowFPS,
				bShowFPSFPS = bShowFPSFPS,
				bShowLatency = bShowLatency,
				bShowLatencyMS = bShowLatencyMS
			}	
	return tSave
end

function SimpleFPSMeter:OnRestore(eLevel,tSavedData)
	if tSavedData.bShowFPS ~= nil then
		bShowFPS = tSavedData.bShowFPS
		bShowFPSFPS = tSavedData.bShowFPSFPS
		bShowLatency = tSavedData.bShowLatency
		bShowLatencyMS = tSavedData.bShowLatencyMS		
	end
end  

-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter OnLoad
-----------------------------------------------------------------------------------------------
function SimpleFPSMeter:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("SimpleFPSMeter.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter OnDocLoaded
-----------------------------------------------------------------------------------------------
function SimpleFPSMeter:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "SimpleFPSMeterForm", nil, self) -- window declarations
		self.wndConfig = Apollo.LoadForm(self.xmlDoc, "SimpleFPSMeterConfig", nil, self) --
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self) -- better than manually setting/saving anchors/offsets
		
		self.wndMain:Show(false, true)
		self.wndConfig:Show(false, false)

		self.xmlDoc = nil

		Apollo.RegisterSlashCommand("fps", "SimpleFPSMeterToggle", self)
		Apollo.RegisterSlashCommand("fpslatency", "fpsLatencyToggle", self)		
		Apollo.RegisterSlashCommand("fpsfps", "fpsTitleToggle", self)
		Apollo.RegisterSlashCommand("fpsms", "fpsLatencyMSToggle", self)	
		
		self.timer = ApolloTimer.Create(0.5, true, "OnTimer", self) -- changed from .1 to .5 
		self.supertimer = ApolloTimer.Create(2, true, "SuperTimer", self) -- Timer for delaying the initial display of the meter
																		  -- This prevents the meter "jumping" into it's saved position
																		  -- Purely aesthetic
		if type(bShowFPS) ~= "boolean" or bShowFPS == nil or type(bShowFPS) == "number" and bShowFPS >= 0 then -- load defaults if no settings or settings are mangled
			bShowFPS = true
			bShowFPSFPS = true
			bShowLatency = true
			bShowLatencyMS = true
			--The following line doesn't even print. Probably gets jammed up while the UI is starting. I'm keeping it in anyways.
			ChatSystemLib.PostOnChannel(2,"[SimpleFPSMeter] No saved settings found or existing settings mangled. Default settings loaded.")
		end
	end
end

function SimpleFPSMeter:OnWindowManagementReady() -- holler at me dem window positions, cuz.
    Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "SimpleFPSMeter"})
end

-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter Functions
-----------------------------------------------------------------------------------------------

function SimpleFPSMeter:SuperTimer() -- timer to prevent pop-in on initial load
	self.supertimer = nil
	self:ShowSimpleFPSMeter()
end

function SimpleFPSMeter:CheckLatency()
	if bShowLatency == false then
		self.wndMain:FindChild("Latency"):Show(false)
	else
		self.wndMain:FindChild("Latency"):Show(true)
	end
end

function SimpleFPSMeter:CheckDisplaySimpleFPSMeter()
	if bShowFPS == false then
		self.wndMain:Show(false, true)
		self:KillTimer()
	else
		self.wndMain:Show(true, true)
		self:RezTimer()
	end
end

function SimpleFPSMeter:ShowSimpleFPSMeter()
	self:CheckLatency()
	self:CheckDisplaySimpleFPSMeter()
end

function SimpleFPSMeter:SimpleFPSMeterToggle(cmd, args)
	if args == "config" then
		self:OnConfigure()
	elseif args == "latency" then
		self:fpsLatencyToggle()
	elseif args == "fps" then
		self:fpsTitleToggle()
	elseif args == "ms" then
		self:fpsLatencyMSToggle()
	else
		self:CheckLatency()
		if bShowFPS == false then
			self:RezTimer()
			bShowFPS = true
			self.wndMain:Show(true, true)
		elseif bShowFPS == true then
			self:KillTimer()
			bShowFPS = false
			self.wndMain:Show(false, true)
		end
	end
end

function SimpleFPSMeter:fpsTitleToggle()
	if bShowFPSFPS == false then
		bShowFPSFPS = true
	else
		bShowFPSFPS = false
	end
end

function SimpleFPSMeter:fpsLatencyToggle()
	if bShowLatency == false then
		bShowLatency = true
		self.wndMain:FindChild("Latency"):Show(true)
	else
		bShowLatency = false
		self.wndMain:FindChild("Latency"):Show(false)
	end
end

function SimpleFPSMeter:fpsLatencyMSToggle()
	if bShowLatencyMS == false then
		bShowLatencyMS = true
	else
		bShowLatencyMS = false
	end
end

function SimpleFPSMeter:KillTimer()
	self.timer = nil
end

function SimpleFPSMeter:RezTimer()
	self.timer = ApolloTimer.Create(0.5, true, "OnTimer", self)
end

function SimpleFPSMeter:OnTimer()
	local fpsMeter = math.floor(GameLib.GetFrameRate() + 0.5)
	local pingMeter = GameLib.GetPingTime()
	if bShowFPSFPS == false then
		self.wndMain:FindChild("FPS"):SetText(fpsMeter)
	elseif bShowFPSFPS == true then
		self.wndMain:FindChild("FPS"):SetText(fpsMeter .. " FPS")
	end
	if bShowLatency == false then
		self.wndMain:FindChild("Latency"):Show(false)
	elseif bShowLatency == true then
		if bShowLatencyMS == false then
			self.wndMain:FindChild("Latency"):SetText(pingMeter)
		elseif bShowLatencyMS == true then
			self.wndMain:FindChild("Latency"):SetText(pingMeter .. "ms")
		end
		self.wndMain:FindChild("Latency"):Show(true)
	end
end

-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter Config Window Functions
-----------------------------------------------------------------------------------------------

function SimpleFPSMeter:OnConfigure()
	bConfigArray = {bShowFPS, bShowFPSFPS, bShowLatency, bShowLatencyMS}
	self.wndConfig:Show(true)
	self.wndConfig:FindChild("ShowSimpleFPSMeterButton"):SetCheck(bShowFPS)
	self.wndConfig:FindChild("ShowFPSFPSButton"):SetCheck(bShowFPSFPS)
	self.wndConfig:FindChild("ShowLatencyButton"):SetCheck(bShowLatency)
	self.wndConfig:FindChild("ShowLatencyMSButton"):SetCheck(bShowLatencyMS)
end

function SimpleFPSMeter:OnOk( wndHandler, wndControl, eMouseButton )
	bConfigArray = nil
	self.wndConfig:Close()
end

function SimpleFPSMeter:OnCancel( wndHandler, wndControl, eMouseButton )  -- this is so incredibly ghetto due to WindowClosed in SimpleFPSMeterConfig
	if bConfigArray ~= nil then
		bShowFPS = bConfigArray[1]
		bShowFPSFPS = bConfigArray[2]
		bShowLatency = bConfigArray[3]
		bShowLatencyMS = bConfigArray[4]
		bConfigArray = nil
	end
	self.wndConfig:Close()
	self:CheckDisplaySimpleFPSMeter()
end

function SimpleFPSMeter:OnShowSimpleFPSMeterButton( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		bShowFPS = true
		self:CheckDisplaySimpleFPSMeter()
	else
		bShowFPS = false
		self:CheckDisplaySimpleFPSMeter()
	end
end

function SimpleFPSMeter:OnShowFPSFPSButton( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		bShowFPSFPS = true
	else
		bShowFPSFPS = false
	end
end

function SimpleFPSMeter:OnShowLatencyButton( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		bShowLatency = true
	else
		bShowLatency = false
	end	
end

function SimpleFPSMeter:OnShowLatencyMSButton( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		bShowLatencyMS = true
	else
		bShowLatencyMS = false
	end	
end

local SimpleFPSMeterInst = SimpleFPSMeter:new()
SimpleFPSMeterInst:Init()
