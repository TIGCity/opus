local BulkGet  = require('bulkget')
local Git      = require('git')
local Packages = require('packages')
local Util     = require('util')

local fs       = _G.fs
local term     = _G.term

local args     = { ... }
local action   = table.remove(args, 1)

local function Syntax(msg)
	_G.printError(msg)
	print('\nSyntax: Package list | install [name] ... |  update [name] | uninstall [name]')
	error(0)
end

local function progress(max)
	-- modified from: https://pastebin.com/W5ZkVYSi (apemanzilla)
	local _, y = term.getCursorPos()
	local wide, _ = term.getSize()
	term.setCursorPos(1, y)
	term.write("[")
	term.setCursorPos(wide - 6, y)
	term.write("]")
	local done = 0
	return function()
		done = done + 1
		local value = done / max
		term.setCursorPos(2,y)
		term.write(("="):rep(math.floor(value * (wide - 8))))
		local percent = math.floor(value * 100) .. "%"
		term.setCursorPos(wide - percent:len(),y)
		term.write(percent)
	end
end

local function install(name, isUpdate)
	local manifest = Packages:getManifest(name) or error('Invalid package')

	if manifest.required then
		for _, v in pairs(manifest.required) do
			if isUpdate or not Packages:isInstalled(v) then
				install(v, isUpdate)
			end
		end
	end

	print(string.format('%s: %s',
		isUpdate and 'Updating' or 'Installing',
		name))

	local packageDir = fs.combine('packages', name)

	local list = Git.list(manifest.repository)
	local showProgress = progress(Util.size(list))

	local getList = { }
	for path, entry in pairs(list) do
		table.insert(getList, {
			path = fs.combine(packageDir, path),
			url = entry.url
		})
	end

	BulkGet.download(getList, function(_, s, m)
		if not s then
			error(m)
		end
		showProgress()
	end)
end

if action == 'list' then
	for k in pairs(Packages:list()) do
		Util.print('[%s] %s', Packages:isInstalled(k) and 'x' or ' ', k)
	end
	return
end

if action == 'install' then
	local name = args[1] or Syntax('Invalid package')
	if Packages:isInstalled(name) then
		error('Package is already installed')
	end
	install(name)
	print('installation complete\n')
	_G.printError('Reboot is required')
	return
end

if action == 'update' then
	local name = args[1] or Syntax('Invalid package')
	if not Packages:isInstalled(name) then
		error('Package is not installed')
	end
	install(name, true)
	print('update complete')
	return
end

if action == 'uninstall' then
	local name = args[1] or Syntax('Invalid package')
	if not Packages:isInstalled(name) then
		error('Package is not installed')
	end
	local packageDir = fs.combine('packages', name)
	fs.delete(packageDir)
	print('removed: ' .. packageDir)
	return
end

Syntax('Invalid command')
