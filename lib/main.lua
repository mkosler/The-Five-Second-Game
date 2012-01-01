--======================================================================
-- Title: 		The Five Second Game
-- Author: 		Michael Kosler
-- License:		implied, except for tween.lua, which has its own
--				copyright located at:
--				https://github.com/kikito/tween.lua/blob/master/LICENSE.txt
-- Description:	Collect as many green pieces of food before time runs
--				out.
--======================================================================

tween = require "./tween.lua"

--- The colors used for identifying the food
COLORS = {
	red = {r=255,g=0,b=0,a=255},
	green = {r=0,g=255,b=0,a=255}
}

--======================================================================
-- PLAYER

--- The player:
--- Since this is single player, there is no constructor function,
--- just a table representing the player.
-- @var x: x-coordinate
-- @var y: y-coordinate
-- @var r: radius
player = {
	x = 0,
	y = 0,
	r = 7,
}

--- Attaches the player's position to the mouse position:
function player:position()
	local x, y = love.mouse.getPosition()
	self.x = x
	self.y = y
end

--- Governs logic for the consumption of food:
-- @param c: string of food color
function player:consume(c)
	assert(type(c) == "string", "color not string")
	-- If the food was green, increase the timer and radius by 1 and the
	-- score by 10.
	if c == "green" then
		timer = timer + 1
		self.r = self.r + 1
		score = score + 10
	-- If the food was red, decrease the timer by 0.2 seconds, and
	-- decrease the score by 5.
	elseif c == "red" then
		timer = timer - 0.2
		score = score - 5
	end
end

--- Draws the player:
function player:draw()
	love.graphics.setColor(255,255,255,255) -- White
	love.graphics.circle("fill", self.x, self.y, self.r)
end

--- The player's metatable:
--- Prevent accidental additions to the player's variable table
pMeta = {
	__newindex = function() error("Can't add newindex to player") end,
	__metatable = true
}
setmetatable(player, pMeta)

--======================================================================
-- FOOD

--- The food's metatable:
--- Prevents accidental additions to the food's variable table.
food = {
	__newindex  = function() error("Can't add newindex to food") end,
}
food.__index = food

--- Updates the food's position (CURRENTLY BUGGED)
-- @param dt: delta time
function food:update(dt)
	if not self.isMoving then return end
	tween(0.5, self, self.destp) -- BUGGED
end

--- Draws the food
function food:draw()
	-- Sets the color based on internal color RGB values.
	love.graphics.setColor(self.cval.r, self.cval.g, self.cval.b, self.cval.a)
	love.graphics.circle("fill", self.x, self.y, self.r)
end

--- Finds a pseudorandom position:
--- It is pseudorandom because it won't allow the position to instantly
--- collide with the player.
function getRandPos()
	local x = math.random(20, 380)
	local y = math.random(20, 380)
	if collision(player, {x = x, y = y, r = 5}) then
		return getRandPos()
	end
	return x, y
end

--- Food constructor
--- Since the food is randomly placed on the board, none are the
--- variables are controlled via parameters.
function newFood()
	local x, y = getRandPos()
	--~ local wx = math.random(20, 380)	-- DEBUG
	--~ print("===")					-- DEBUG
	--~ print(wx)						-- DEBUG
	local dx = math.random(20, 380)	-- DEBUG
	--~ print(dx)						-- DEBUG
	local f = {
		x = x,
		y = y,
		r = 5
	}
	-- 75% of the time, the food will be bad (red) food.
	if math.random() < 0.75 then
		f.cname = "red"
	-- 25% of the time, the food will be good (green) food.
	else
		f.cname = "green"
	end
	f.cval = COLORS[f.cname]
	-- 15% of the time, the food will move
	if math.random() < 0.15 then
		--print("mover")				-- DEBUG
		f.isMoving = true
		f.destp = {x = dx, y = math.random(20, 380)}	-- DEBUG
	-- 85% of the time, the food will be static
	else
		f.isMoving = false
	end
	return setmetatable(f, food)
end

--======================================================================
-- GAME

function love.load()
	math.randomseed(os.time())
	timer = 5	-- The countdown timer
	tSpawn = 0
	score = 0	-- The score of the game
	love.mouse.setVisible(false)	-- The mouse will not show inside the game.
	gFood = {}	-- The collection of food
end

function love.update(dt)
	timer = timer - dt	-- Decrement the timer
	tSpawn = tSpawn + dt
	if timer < 0 then timer = 0 return end	-- When it hits 0, freeze the game.
	player:position()
	-- Every 0.2 seconds, a new food item spawns.
	if tSpawn > 0.2 then
		tSpawn = 0
		table.insert(gFood, newFood())
	end
	-- If the player collides with a food item, then consume that item.
	-- The player's response to consuming that item is governed by
	-- player:consume(c), where c is the food color.
	for k,v in pairs(gFood) do
		v:update(dt)
		if collision(player, v) then
			player:consume(v.cname)
			table.remove(gFood, k)
		end
	end
end

--- Circle-to-circle collision check:
-- @param a: circle a
-- @param b: circle b
function collision(a, b)
	local dist = math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
	if dist < (a.r + b.r) then return true end
	return false
end

function love.draw()
	for k,v in pairs(gFood) do v:draw() end
	player:draw()
	love.graphics.setColor(255,255,255,255)
	love.graphics.print(string.format("%.2f", timer), 10, 22, 0, 1.5, 1)
	love.graphics.print("SCORE: " .. score, 10, 10, 0, 1.5, 1)
end

--- A few debug keyboard controls:
-- @param key: pressed key (rising-edge)
function love.keypressed(key)
	if key == "escape" then
		love.event.push("q")
	elseif key == "f2" then
		love.load()
	end
end
