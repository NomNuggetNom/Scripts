--local modem = peripheral.wrap("right")	modem.open(1)
local terminalBridge = peripheral.wrap("back") terminalBridge.clear()
local sysBridge = peripheral.wrap("right")
local controller = peripheral.wrap("bottom")
local modem = peripheral.wrap("top") for i=1, 50 do modem.open(i) end

-- AE Storage
calcUsage = (controller.getUsedBytes()) / (controller.getTotalBytes())
calcDisplay = math.floor(calcUsage * 75)
calcPercent = math.floor(calcUsage * 100)

-- addBox(x,y,width,height,hexcolor,opacity)
-- addText(x,y,text,color)
function displayAE()
	terminalBridge.clear()
	local meter = terminalBridge.addBox(calcDisplay, 244, 1, 7, 0x000000, 1.0)
	local box = terminalBridge.addBox(5, 245, 75, 5, 0xB3150C, 0.5)
	box.setGradient(2)
	box.setColor2(0x1A991C)
	local meter = terminalBridge.addBox(calcDisplay, 244, 1, 7, 0x000000, 1.0)
	local percentDisplay = terminalBridge.addText(83, 244, "" ..tostring(calcPercent).. "%", 0xFFFFFF)
end

---------------------------------------------------
----------------[[ Item System ]]------------------
---------------------------------------------------
itemIndex = {}
-- itemIndex[name] = id
idIndex = {}
-- idIndex[id] = name
itemStock = {}
-- itemStock[id] = number

function retrieveCrafts()
	canCraft = sysBridge.listCraft()
end

function retrieveStorage()
	itemStock = sysBridge.listItems()
end

function retrieveIDs()
        fileRead = fs.open("itemIndex", "r")
	lineText = fileRead.readLine()
        while lineText ~= nil do
		_, _, key, value = string.find(lineText, "(%a+)%s*=%s*(%d+)")
		itemIndex[key]= tonumber(value)
		_, _, key, value = string.find(lineText, "(%a+)%s*=%s*(%d+)")
		idIndex[tonumber(value)]=key
		lineText = fileRead.readLine()
        end
        fileRead.close()
end

retrieveIDs()

function isIndexed(itemID)
	if itemIndex[itemID] == nil then return false
	else return true end
end

function craftItem(reqID, reqQty, transfer)
		sysBridge.craft(reqID,reqQty)
		if idIndex[reqID] ~= nil then
			sysSatus = "Crafting.."
			displayText("Crafting " ..tostring(reqQty).. " " ..tostring(idIndex[reqID]).. "...")
		else
			sysSatus = "Crafting.."
			displayText("Crafting " ..tostring(reqQty).. " " ..tostring(reqID).. "...")
		end
		if transfer ~= "n" then
			transferItem(reqID,reqQty)
		end
end

function indexID(itemName, itemID)
	if itemIndex[itemName] == nil then
		fileWrite = fs.open("itemIndex", "a")
		fileWrite.writeLine(tostring(itemName).. "=" ..tonumber(itemID))
		displayText("Item '" ..tostring(itemName).. "' indexed (" ..tostring(itemID) .. ").")
		fileWrite.close()
		retrieveIDs()
	else
		displayText("Item already exists.")
	end
end

function displayText(textInput)
	terminalBridge.clear()	displayAE()
	-- addText(x,y,text,color)
	-- x,y,width,height,color,opacity,color2,opacity2,gradientDirection
	stringL = math.floor(terminalBridge.getStringWidth(tostring(textInput)))
	centerT = math.floor(500/2) - (stringL/2)
 	centerB = centerT - 10
	boxW = stringL + 20
	boxDisplay = terminalBridge.addBox(centerB, 0, boxW, 15, 0x000000,0.0) boxDisplay.setZIndex(1)
	textDisplay = terminalBridge.addText(centerT, 3, "", 0xFFFFFF) textDisplay.setZIndex(2)
	for i = 0, 0.5, 0.025 do
		boxDisplay.setOpacity(i)
		sleep(0.05)
	end
	textDisplay.setText(tostring(textInput))
	sleep(2)
	textDisplay.setText("")
	for i = 0.5, 0, -0.025 do
		boxDisplay.setOpacity(i)
		sleep(0.05)
	end
end

function transferItem(itemID, itemQty, doCraft)
	retrieveStorage()	 -- print(itemStock[itemID])
	if doCraft then
		totalStock = sysBridge.retrieve(tonumber(itemID), itemQty, 4)
		itemsNeeded = math.abs(totalStock - itemQty)
		print("doCraft")
		if itemsNeeded ~= 0 then
			craftItem(itemID, itemsNeeded, n)
			sleep(.5)
			sysBridge.retrieve(tonumber(itemID), itemsNeeded, 4)
		else
			displayText("Transferred " ..tostring(itemQty).. " '" ..tostring(idIndex[itemID]) .. "'.")
		end
	elseif not doCraft then
		numberofItems = sysBridge.retrieve(tonumber(itemID), 1728, 4)
		displayText("Transferred " ..tostring(numberofItems).. " '" ..tostring(idIndex[itemID]) .. "'.")
	end
end

retrieveIDs()
retrieveCrafts()
retrieveStorage()
-------------
while true do
-------------
	displayAE()

	--[[ Input Handling ]]--
	local event, input = os.pullEvent("chat_command")
	local userInput = {}
	for i in string.gmatch(input, "%S+") do
		table.insert(userInput, i)
	end
	
	--[[ Crafting Handling ]]--
	if userInput[1] == "craft" or userInput[1] == "make" then
		-- userInput[2] is quantity
		-- userInput[3] is item
		-- userInput[4] is optional, for transferring items
		if not tonumber(userInput[3]) then	-- Received text input
			if itemIndex[userInput[3]] ~= nil then
				craftItem(tonumber(itemIndex[userInput[3]]), tonumber(userInput[2]), userInput[4])
			else
				displayText("Item '" ..tostring(userInput[3]).. "' not recognized.")
			end
		else
			craftItem(tonumber(userInput[3]), tonumber(userInput[2]), userInput[4])
		end

	--[[ Transfer Handling ]]--
	elseif userInput[1] ==  "transfer" or userInput[1] == "move" then
		-- userInput[2] is quantity, or all
		-- userInput[3] is item name
		if not tonumber(userInput[3]) then 	-- Received text input
			if itemIndex[userInput[3]] ~= nil then
				if userInput[2] == "all" then
					transferItem(tonumber(itemIndex[userInput[3]]), tonumber(userInput[2]), false)
				else
					transferItem(tonumber(itemIndex[userInput[3]]), tonumber(userInput[2]), true)
				end
			else
				displayText("Item '" ..tostring(userInput[3]).. "' not recognized.")
			end
		else
			transferItem(tonumber(userInput[3]), tonumber(userInput[2]), true)
		end

	--[[ Manual Item Indexing ]]--
	elseif userInput[1] == "index" then
		-- userInput[2] is name
		-- userInput[3] is ID
		-- userInput[4] is metadata
		if userInput[4] ~= nil then
			indexID(userInput[2], (tonumber(userInput[4]) * 32768)+userInput[3])
			retrieveIDs()
		else
			indexID(userInput[2],tonumber(userInput[3]))
			retrieveIDs()
		end

	elseif userInput[1] == "check" or userInput[1] == "num" or userInput[1] == "stock" then
		-- userInput[2] is name or ID
		if not tonumber(userInput[2]) then -- Received text
			if isIndexed(userInput[2]) then
				displayText("Currently " ..tostring(itemStock[itemIndex[userInput[2]]]).. " '" ..tostring(userInput[2]).. "' stored.")
			else 
				displayText("Item '" ..tostring(userInput[2]).. "' not recognized.")
			end	
		end
		
	elseif userInput[1] == "tool" then
		-- 1:$$tool <2:name> <3:id> <4:durability>
		if tonumber(userInput[2]) then displayText("Name expected, got '"..tostring(userInput[2]).."'." else
		if not tonumber(userInput[3]) then displayText("ID expected, got '"..tostring(userInput[3].."'." else
		if not tonumber(userInput[4]) then displayText("Durability number expected, got '"..tostring(userInput[4].."'." else
			for i = 1, tonumber(userInput[4]) do 
				indexID(userInput[2], tonumber(i*32768)+userInput[3])
			end
			retrieveIDs()
		end
		end
		end
	--[[ Multiplacation ]]--
	elseif userInput[1] == "math" then
		local eval, error = loadstring("return " ..userInput[2])
		if error then
			displayText("Error processing '" ..tostring(userInput[2]).. "'.")
		else
			displayText(eval())
		end

	--[[ Display Request ]]--
	elseif userInput[1] == "display" then
		for i in string.gmatch(input, "display(.+)") do
		displayText(i)
		end

	--[[ Modem Handling ]]--
	elseif userInput[1] == "toggle" or userInput[1] == "t" then
		modem.transmit(50, 50, tostring(userInput[2]))
		local modemMessage, p1, p2, p3, p4 = os.pullEvent("modem_message")
		if p4 then spawnerStatus = "off" else spawnerStatus = "on" end
		displayText("Toggled '"..tostring(userInput[2]).."' to "..tostring(spawnerStatus)..".")
			
	end
---
end
---