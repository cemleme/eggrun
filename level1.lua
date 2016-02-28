-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------
local inspect = require( "inspect" )
local composer = require( "composer" )
local scene = composer.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()
physics.setDrawMode( "hybrid" )

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5


local CLOUD_ASSESTS = { { name = "./img/cloud1.png", height = 100, width = 229}, 
						{ name = "./img/cloud2.png", height = 80, width = 148}, 
						{ name = "./img/cloud3.png", height = 120, width = 226}, 
						{ name = "./img/cloud4.png", height = 64, width = 100}}

local FORWARD_ACTIVE_BACKGROUND_WINDOW_SIZE = 1
local BACKWARD_ACTIVE_BACKGROUND_WINDOW_SIZE = 1

function scene:touch( event )
	 if ( event.phase == "moved" ) then
        local dX = event.x - event.xStart
        self.parachute:applyForce(dX/2,0,self.parachute.x,self.parachute.y)
    end
    if ( event.phase == "began" ) then
        self.parachute.linearDamping = 1
    elseif ( event.phase == "ended" ) then
        self.parachute.linearDamping = 100
    end
    return true
end

function scene:create( event )

	-- Called when the scene's view does not exist.
	-- 
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	local sceneGroup = self.view

	-- create a grey rectangle as the backdrop
	--[[
	local background = display.newImageRect( "./img/bg.png", 320, 568 )
	background.x, background.y = 0, 0
	background.anchorX = 0
	background.anchorY = 0
	sceneGroup:insert( background )
	--]]
	display.setDefault("background", 88/255, 110/255, 254/255)

	self.ledderGroup = display.newGroup()
	sceneGroup:insert(self.ledderGroup)

	self.clouds = {}
	self.lastActiveWindowIndex = 0
	self.firstActiveWindowIndex = 0

	-- make a crate (off-screen), position it, and rotate slightly
	local parachute = display.newImageRect(self.ledderGroup, "./img/parachute.png", 80, 110 )
	parachute.x, parachute.y = 160, 55
	parachute.rotation = 0
	self.parachute = parachute
	physics.addBody( parachute, { density=0.1, friction=0.3, bounce=0.3, box = { halfWidth=100, halfHeight=10, x=0, y=-30, angle=0 } } )
	parachute.linearDamping = 100

	-- make a crate (off-screen), position it, and rotate slightly
	local egg = display.newImageRect(self.ledderGroup, "./img/egg2.png", 50, 66 )
	egg.x, egg.y = 160, 120
	egg.rotation = 0
	self.egg = egg
	physics.addBody( egg, { density=1.0, friction=0.3, bounce=0.3, radius = 25 } )
	--crate.isFixedRotation = true

	physics.newJoint( "distance", parachute, egg, 125, 30, 160, 120 )
	physics.newJoint( "distance", parachute, egg, 195, 30, 160, 120 )

	--rope ile
	--local rope1 = physics.newJoint( "rope", parachute, crate, -30, -15, -10, 0 )
	--rope1.maxLength = 105
	--local rope2 = physics.newJoint( "rope", parachute, crate, 30, -15, 10, 0 )
	--rope2.maxLength = 105

	--distance joint ile

	
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- 
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		physics.start()
		Runtime:addEventListener( "touch", self )
		Runtime:addEventListener("enterFrame", self)
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		physics.stop()
		Runtime:removeEventListener( "touch", self )
		Runtime:removeEventListener("enterFrame", self)
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
	
end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view
	
	package.loaded[physics] = nil
	physics = nil
end

function scene:getCloud(cloudAsset)
	local cloud =  display.newImageRect(cloudAsset.name, cloudAsset.width, cloudAsset.height)
	if cloud == nil then
		print("cloud" .. cloudAsset.name .. " is nil")
	end
	return cloud
end


function scene:createScreenBackground(screenId)
	print("createScreenBackground:" .. screenId)
	local screenStartY = (screenId - 1) * screenH
	local screenStartX = -100
	local screenEndX = screenW + 100
	local cloudAsset = CLOUD_ASSESTS[math.random(1, #CLOUD_ASSESTS)]
	local cloud = self:getCloud(cloudAsset)
	cloud.screenId = screenId
	cloud.y = screenStartY + math.random(0,screenH)
    cloud.x = screenStartX + math.random(0,screenEndX)
	self.ledderGroup:insert(cloud)
	cloud:toBack()
	table.insert(self.clouds, cloud)
end

function scene:cleanScreenBackground(screenId)
	print("cleanScreenBackground:" .. screenId)
	for cloudIndex, cloud in ipairs(self.clouds) do
	    if cloud.screenId == screenId then
	    	cloud:removeSelf()
	    	table.remove(self.clouds, cloudIndex)
	    end
	end
end

function scene:getCurrentScreenId()
	--screenId starts with 1
	return math.floor(-self.ledderGroup.y / screenH) + 1
end

function scene:createScreenBackgroundIfNecessary()
	local currentScreenId = self:getCurrentScreenId()
	if self.lastActiveWindowIndex > currentScreenId + FORWARD_ACTIVE_BACKGROUND_WINDOW_SIZE then
		return
	else
		for i=self.lastActiveWindowIndex, currentScreenId + FORWARD_ACTIVE_BACKGROUND_WINDOW_SIZE - 1 do
			self.lastActiveWindowIndex = i + 1
			self:createScreenBackground(self.lastActiveWindowIndex)
		end
	end
end

function scene:cleanScreenBackgroundIfNecessary()
	local currentScreenId = self:getCurrentScreenId()
	if self.firstActiveWindowIndex > currentScreenId - BACKWARD_ACTIVE_BACKGROUND_WINDOW_SIZE then
		return
	else
		for i=self.firstActiveWindowIndex, currentScreenId - BACKWARD_ACTIVE_BACKGROUND_WINDOW_SIZE do
			self:cleanScreenBackground(i)
			self.firstActiveWindowIndex = i + 1
		end
	end
end

function scene:scrollScene() 
	if self.egg.y > self.ledderGroup.y + display.contentHeight/2 then 
		self.ledderGroup.y = -1 * (self.egg.y - display.contentHeight/2)
	end
end


function scene:enterFrame(e)
	self:scrollScene()
	self:createScreenBackgroundIfNecessary()
	self:cleanScreenBackgroundIfNecessary()
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene