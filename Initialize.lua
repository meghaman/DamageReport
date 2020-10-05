function Initialize()
	UpdateDamageReport(SKIN:GetVariable('inputFile', 'DamageReport.txt'), '', false)
end

function Cleaned(taskName)
	print("Mark Task Cleaned: "..taskName)
	UpdateDamageReport(SKIN:GetVariable('inputFile', 'DamageReport.txt'), taskName, true)
end

-- If specified, will remove a given element from the priorities list
function UpdateDamageReport(filePath, taskName, addressed)
	file = io.open(SKIN:MakePathAbsolute(filePath), "r")
	io.input(file)

	local daysPast = GetDaysSinceLastUpdate(file:read("*l"))

	local orderedTaskList = GetUpdatedOrderedTaskList(file, daysPast)

	local taskAddressed = {}
	if taskName ~= nil and taskName ~= '' then
		taskAddressed = GetAddressedOrMarkCompleteTask(orderedTaskList, taskName, addressed)
	end

	-- Was a task addressed? It needs to be added back to the table
	if table.getn(taskAddressed) > 0 then
		table.insert(orderedTaskList, taskAddressed)
	end

	UpdateSkin(orderedTaskList)

	io.close(file)

	file = io.open(SKIN:MakePathAbsolute(filePath), "w")
	io.input(file)

	WriteDamageReportToFile(file, orderedTaskList)

	io.close(file);
end

-- Addressed tasks have their timer reset 1
function GetAddressedOrMarkCompleteTask(orderedTaskList, taskName, addressed)
	local taskAddressed = {}
	for k, v in pairs(orderedTaskList) do
		if orderedTaskList[k][1] == taskName then
			taskClicked = table.remove(orderedTaskList, k)
		end
	end
	if addressed == true then
		updatedPriorityLevel = 1
		taskAddressed = { taskClicked[1], updatedPriorityLevel , taskClicked[3] }
	end
	return taskAddressed
end

function UpdateSkin(orderedTaskList)
	for i=1,table.getn(orderedTaskList) do
		taskName = orderedTaskList[i][1]
		maxValue = orderedTaskList[i][3]
		currentValue = orderedTaskList[i][2]
		percentage = (currentValue / maxValue) * 100

		if (currentValue == 1) then
			red = 0
			green = 255
		elseif (percentage > 100) then
			red = 255
			green = 0
		elseif (percentage < 50) then
			green = 255
			red = 255 * ((percentage * 2) / 100)
		else
			red = 255
			green = 255 * (((100 - percentage) * 2) / 100)
		end

		SKIN:Bang('!SetOption Meter'..taskName..' ImageTint '..red..','..green..',0,255')
	end
	SKIN:Bang('!Update')
end

function GetDaysSinceLastUpdate(strLastUpdated)
	print("Date read from input: "..strLastUpdated)

	local tblLastUpdated = { month = os.date("%m"), day = os.date("%d"), year = os.date("%Y") , hour = 0, sec = 0, min = 0 }
	local dateOrder = { "month", "day", "year" }

	-- Gets the each numeric value in the date string
	local dateIterator = string.gmatch(strLastUpdated,"[0-9]+")

	-- Assumes date format of "MM/DD/YY"
	for k, v in ipairs(dateOrder) do
		tblLastUpdated[v] = dateIterator()
	end
	local lastUpdated = os.time(tblLastUpdated)

	print("Last Updated On: "..os.date("%c", lastUpdated))
	print("Current Date: "..os.date("%c"))

	local secondsPast = os.difftime(os.time(), lastUpdated)
	print("Seconds Past: "..secondsPast)

	local daysPast = math.floor(secondsPast / 60 / 60 / 24)
	print("Days Past Since Last Update: "..daysPast)

	return daysPast
end

-- Splits a string with a given pattern. Returns a new table or adds to an existing one
function string:Split( inSplitPattern, outResults )
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end


function GetUpdatedOrderedTaskList(file, daysPast)
	local lineItem = {}
	local orderedTaskList = {}

	for l in file:lines() do
		lineItem = l:Split("*")

		local taskName = lineItem[1]
		local taskValue = lineItem[2]
		local taskIncrement = 1
		local taskMaxValue = lineItem[3]

		table.insert(orderedTaskList, { taskName, taskValue + taskIncrement * daysPast, taskMaxValue})
	end

	table.sort(orderedTaskList, function(a, b) return a[2] > b[2] end)

	return orderedTaskList
end

function WriteDamageReportToFile(file, orderedTaskList)
	file:write(os.date("%m").."/"..os.date("%d").."/"..os.date("%Y").."\n")
	for i in pairs(orderedTaskList) do
		file:write(orderedTaskList[i][1].."*"..orderedTaskList[i][2].."*"..orderedTaskList[i][3].."\n")
	end
end
