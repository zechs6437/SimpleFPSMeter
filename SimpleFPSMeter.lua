-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter by Maarek
--
-- v1.3 - Fixed window position saving
--		- Removed Slashcommand toggles, use config window instead
--		- Redone Config window
--		- Added some code comments
--		- Updated toc.xml to APIVersion 16
--		- Still simple 3 years later
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
require "ApolloTimer"

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
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter OnDocumentReady
-----------------------------------------------------------------------------------------------
function SimpleFPSMeter:OnDocumentReady()
	
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "SimpleFPSMeterForm", nil, self)		-- window declarations
		self.wndConfig = Apollo.LoadForm(self.xmlDoc, "SimpleFPSMeterConfig", nil, self) 	--
	
		Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self) -- better than manually setting/saving anchors/offsets
		
		self.wndMain:Show(false, true)
		self.wndConfig:Show(false, false)

		self.xmlDoc = nil

		Apollo.RegisterSlashCommand("fps", "SimpleFPSMeterToggle", self)
		
		self.timer = ApolloTimer.Create(0.5, true, "OnTimer", self) -- changed from .1 to .5, 1.3: possibly add option to change polling rate???
		self.supertimer = ApolloTimer.Create(1, true, "SuperTimer", self) -- Timer for delaying the initial display of the meter
																		  -- This prevents the meter "jumping" into it's saved position
																		  -- Purely aesthetic
																		  -- 1.3: lowered timer to 1 second
		if type(bShowFPS) ~= "boolean" or bShowFPS == nil or type(bShowFPS) == "number" and bShowFPS >= 0 then -- load defaults if no settings or settings are mangled
			bShowFPS = true
			bShowFPSFPS = true
			bShowLatency = true
			bShowLatencyMS = true
			--The following line doesn't even print. Probably gets jammed up while the UI is starting. I'm keeping it in anyways. -- 1.3 no i'm not
			--ChatSystemLib.PostOnChannel(2,"[SimpleFPSMeter] No saved settings found or existing settings mangled. Default settings loaded.")
		end
		
		self:OnWindowManagementReady()	-- 1.3 fix for window position saving pt1
	end
end

function SimpleFPSMeter:OnWindowManagementReady() -- holler at me dem window positions, cuz.
	Event_FireGenericEvent("WindowManagementRegister", {wnd = self.wndMain, strName = "SimpleFPSMeter"})
    Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "SimpleFPSMeter"}) -- 1.3 fix for window position saving pt2
end

-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter Functions
-- 1.3 notes: may cleanup logic. might take another 3 years.. 		:3
-----------------------------------------------------------------------------------------------

function SimpleFPSMeter:SuperTimer() -- timer to prevent pop-in on initial load, kills self after triggering
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

function SimpleFPSMeter:SimpleFPSMeterToggle()
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

function SimpleFPSMeter:KillTimer()
	self.timer = nil
end

function SimpleFPSMeter:RezTimer()
	self.timer = ApolloTimer.Create(0.5, true, "OnTimer", self)
end

function SimpleFPSMeter:OnTimer()
	--local fpsMeter = math.floor(GameLib.GetFrameRate() + 0.5)				-- old
	local fpsMeter = math.floor(GameLib.GetFrameRate())						-- 1.3 new, why add 0.5?  -- pulls current framerate
	local pingMeter = GameLib.GetPingTime()									-- pulls ping
	if bShowFPSFPS == false then											-- logic for showing FPS suffix
		self.wndMain:FindChild("FPS"):SetText(fpsMeter)						-- 	false
	elseif bShowFPSFPS == true then
		self.wndMain:FindChild("FPS"):SetText(fpsMeter .. " FPS") 			-- true
	end
	if bShowLatency == false then											-- logic for ping
		self.wndMain:FindChild("Latency"):Show(false)						--  no ping display
	elseif bShowLatency == true then										--  yes ping display
		if bShowLatencyMS == false then										-- logic for ms suffix
			self.wndMain:FindChild("Latency"):SetText(pingMeter)			--  no suffix
		elseif bShowLatencyMS == true then
			self.wndMain:FindChild("Latency"):SetText(pingMeter .. "ms")	--  yes suffix
		end
		self.wndMain:FindChild("Latency"):Show(true)						-- show latency. this entire OnTimer() function looks disgusting..
	end
end

-----------------------------------------------------------------------------------------------
-- SimpleFPSMeter Config Window Functions
-- 1.3 notes
-- 	no changes req'd, still works. might break if I mess with this..
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
