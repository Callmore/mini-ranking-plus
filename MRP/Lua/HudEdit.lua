--MRP
--MiniRank Plus
--by Callmore

local FACE_X = 9
local FACE_Y = 92

local hudeditenable = true

local facegfx = {}
local ranknumsgfx = nil
local hilightgfx = nil
local nobumpersgfx = nil
local bumpergfx = nil
local miniitemgfx = nil
local miniiteminvulgfx = nil
local sadgfx = nil
local hornmodgfx = nil
local frboardergfx = nil

local loadedconfig = false

--CONSTANTS
local DT_NORMAL = 0
local DT_COMBI = 1

local FACEWIDTH = 16

local ITEMMINI = {
	"K_ISSHOE",
	"K_ISRSHE",
	"K_ISINV1",
	"K_ISBANA",
	"K_ISEGGM",
	"K_ISORBN",
	"K_ISJAWZ",
	"K_ISMINE",
	"K_ISBHOG",
	"K_ISSPB",
	"K_ISGROW",
	"K_ISSHRK",
	"K_ISTHNS",
	"K_ISHYUD",
	"K_ISPOGO",
	"K_ISSINK"
}

local spinoutstart = {}
local hornmodIsHorn = {}

local cv_showitems = CV_RegisterVar{
	name = "mrp_showitems",
	defaultvalue = "Yes",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
local cv_showitemslocal = CV_RegisterVar{
	name = "mrp_showitemslocal",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_showitemswhenspectating = CV_RegisterVar{
	name = "mrp_showitemswhenspectating",
	defaultvalue = "No",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_hpmodshowhp = CV_RegisterVar{
	name = "mrp_hpmodshowhp",
	defaultvalue = "Yes",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
local cv_hpmodshowhplocal = CV_RegisterVar{
	name = "mrp_hpmodshowhplocal",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_showhorns = CV_RegisterVar{
	name = "mrp_showhorns",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_shrinkgrow = CV_RegisterVar{
	name = "mrp_shrinkgrow",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_spinoutshake = CV_RegisterVar{
	name = "mrp_spinoutshake",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_showflashtics = CV_RegisterVar{
	name = "mrp_showflashtics",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_showinvis = CV_RegisterVar{
	name = "mrp_showinvis",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_showcombi = CV_RegisterVar{
	name = "mrp_showcombi",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_showfriendmodteams = CV_RegisterVar{
	name = "mrp_friendmodshowteams",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_showdnf = CV_RegisterVar{
	name = "mrp_showdnf",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_forceoffminirank = CV_RegisterVar{
	name = "mrp_forceoffvanillaminirank",
	defaultvalue = "Yes",
	flags = 0,
	PossibleValue = CV_YesNo
}
local cv_forcedisplay = CV_RegisterVar{
	name = "mrp_forcedisplay",
	defaultvalue = "None",
	flags = CV_CALL,
	PossibleValue = {On = 1, None = 0, Off = -1},
	func = function (self)
		if self.value == -1 then
			hud.enable("minirankings")
		elseif self.value == 1 then
			hud.disable("minirankings")
		end
	end
}

--ffs why doesent lua have a random function
--i have to create a random function just for hornmod to not look suck

--yes this was also copied from source
local rseed = 0xBADE4404
local function hudRandom()
	rseed = $ ^^ ($ >> 13)
	rseed = $ ^^ ($ >> 13)
	rseed = $ ^^ ($ << 21)
	return ( (rseed*36548569) >> 4) & (FRACUNIT-1)
end

local function hudRandomRange(a, b)
	return ((hudRandom() * (b-a+1)) >> FRACBITS) + a
end

--latius wanted this so ayyy
rawset(_G, "minrankplus", {
    enabled = true
})

local function sortfunc(a, b)
	return a[1].kartstuff[k_position] < b[1].kartstuff[k_position]
end

local function calcXOffsetSpinout(p, dt)

	--return 0 if shake off
	if not cv_spinoutshake.value then return 0 end
	
	if not (p and p.valid) then return 0 end -- this is stupid i hate this pls
	if dt == DT_COMBI and not (p.combi and p.combi.valid) then return 0 end -- this is stupid i hate this pls
	
	--dont do any shake
	if not (spinoutstart[#p] or (dt == DT_COMBI and spinoutstart[#p.combi])) then return 0 end

	local spint = p.kartstuff[k_spinouttimer]
	if p.pflags&PF_TIMEOVER then
		spint = 0
	end
	local spintc = 0
	if dt == DT_COMBI then
		if p.combi.pflags&PF_TIMEOVER then
			spintc = 0
		else
			spintc = p.combi.kartstuff[k_spinouttimer]
		end
	end

	--figgure out some player specific vars for combi
	local t = leveltime-(spinoutstart[#p] or leveltime)
	local spinoutt = spint
	if dt == DT_COMBI then
		t = leveltime - max(spinoutstart[#p] or spinoutstart[#p.combi], spinoutstart[#p.combi] or spinoutstart[#p])
		spinoutt = max(spint or spintc, spintc or spint)
	end
	local spinoutang = FixedAngle(FixedDiv((t%(TICRATE/2)), TICRATE)*720)
	--print(spinoutang/ANG1)
	local spinoutshake = (sin(spinoutang)*spinoutt)/5
	--print(spinoutshake)
	return spinoutshake
end

local playersingame = {}
local alreadycombi = {}
local onsameteam = {}
local displaypos = 0
local rankcenter = 3
local xanioff = FACE_X
local cv_teamcolour = nil

local function hudThink()
	playersingame = {}
	alreadycombi = {}
	onsameteam = {}

	if not loadedconfig then
		COM_BufInsertText(consoleplayer, "exec mrp.cfg -silent")
		loadedconfig = true
	end

	local dp = displayplayers[0]

	for p in players.iterate do
		if not spinoutstart[#p] and p.kartstuff[k_spinouttimer] then
			spinoutstart[#p] = leveltime
		elseif spinoutstart[#p] and not p.kartstuff[k_spinouttimer] then
			spinoutstart[#p] = nil
		end

		if HORNMOD_AddHorns
		and p.noisemaker
		and p.noisemaker.valid
		and not (p.noisemaker.flags2 & MF2_DONTDRAW) then
			hornmodIsHorn[#p] = true
			--print(#p .. " is playing a horn.")
		else
			hornmodIsHorn[#p] = nil
			--print(#p .. " is not playing a horn.")
		end
		
		if not (p.valid and not p.spectator) then continue end

		-- Combi support
		if not alreadycombi[p] then --skip someone if their parner was already read
			local dt = DT_NORMAL
			if cv_showcombi.value
			and p.combi
			and p.combi.valid
			and p.combi.valid ~= "uwu"
			and p.combi.valid ~= "maybe"
			and not p.combi.spectator then
				--HA
				--YOU WONT TROLL ME WITH ADDING AN MO INSTEAD OF A PLAYER
				dt = DT_COMBI
				alreadycombi[p.combi] = true
			end
			playersingame[#playersingame+1] = {p, dt}
			--so... all player names have to be unike...
		end

		-- FRIENDMOD support
		if p.FRoverhead and dp ~= p and dp.FRteam == p.FRteam then
			onsameteam[p] = true
			if not cv_teamcolour then
				--they are needed now, go fetch them
				cv_teamcolour = {CV_FindVar("fr_bluecolor"), CV_FindVar("fr_orangecolor")}
			end
		end
	end
	
	if (#playersingame <= 1) and (cv_forcedisplay.value ~= 1) then return end
	
	if server.vir_enabled then return end -- WORLDS EASIEST MOD INTERGRAION
	
	table.sort(playersingame, sortfunc)
	
	displaypos = 0
	for i, k in ipairs(playersingame) do
		if k[1] == dp then
			displaypos = i
			break
		end
	end
	
	rankcenter = 3
	if #playersingame > 5 and G_RaceGametype() then
		rankcenter = min(max(3, displaypos), #playersingame-2)
	end
	
	if leveltime < TICRATE*20 then
		xanioff = min(leveltime*5-(TICRATE*45), FACE_X)
	end
end

addHook("ThinkFrame", hudThink)


local function drawMinirank(v, p)
	
	if p ~= displayplayers[0] then return end

	--####################
	--###CACHE GRAPHICS###
	--####################
	
	do
		for s in skins.iterate do
			if facegfx[s.name] then continue end
			--print("Caching " .. s.facerank .. " into " .. #s)
			facegfx[s.name] = v.cachePatch(s.facerank)
		end
		
		if not ranknumsgfx then
			ranknumsgfx = {}
			for i = 0, 16 do
				--print("Caching " .. string.format("OPPRNK%02d", i) .. " into " .. i)
				ranknumsgfx[i] = v.cachePatch(string.format("OPPRNK%02d", i))
			end
		end
		
		if not hilightgfx then
			hilightgfx = {}
			for i = 1, 8 do
				--print("Caching K_CHILI" .. i .. " into " .. i)
				hilightgfx[i-1] = v.cachePatch("K_CHILI" .. i)
			end
		end
		
		if not nobumpersgfx then
			nobumpersgfx = v.cachePatch("K_NOBLNS")
		end
		
		if not bumpergfx then
			bumpergfx = {}
			bumpergfx[1] = v.cachePatch("K_BLNA")
			bumpergfx[2] = v.cachePatch("K_BLNB")
		end
		
		if not miniitemgfx then
			miniitemgfx = {}
			for i, k in ipairs(ITEMMINI) do
				--print("Caching " .. k .. " into " .. i)
				miniitemgfx[i] = v.cachePatch(k)
			end
		end
		
		if not miniiteminvulgfx then
			miniiteminvulgfx = {}
			for i = 1, 6 do
				--print("Caching K_ISINV" .. i .. " into " .. i)
				miniiteminvulgfx[i] = v.cachePatch("K_ISINV" .. i)
			end
		end
		
		if not sadgfx then
			sadgfx = v.cachePatch("K_ITSAD")
		end

		if HORNMOD_AddHorns and not hornmodgfx then
			hornmodgfx = v.cachePatch("HORNA0")
		end

		if not frboardergfx then
			frboardergfx = {}
			for i = 1, 8 do
				--print("Caching K_ISINV" .. i .. " into " .. i)
				frboardergfx[i-1] = v.cachePatch("FRBOARD" .. i)
			end
		end
	end

	
	if not (minrankplus and minrankplus.enabled) then return end
	
	if (cv_forceoffminirank.value and not (cv_forcedisplay.value == -1)) and hud.enabled("minirankings") then
		hud.disable("minirankings")
	end

	if outrun and outrun.running then return end

	--#########################
	--###GENERATE PLACEMENTS###
	--#########################
	
	--if leveltime < TICRATE*10 then return end
	if (splitscreen) and (cv_forcedisplay.value ~= 1) then return end
	
	--stupid mod compat stuff

	if (#playersingame <= 1) and (cv_forcedisplay.value ~= 1) then return end

	if cv_forcedisplay.value == -1 then return end
	
	if server.vir_enabled then return end -- WORLDS EASIEST MOD INTERGRAION
	
	--####################
	--###DRAW MINI RANK###
	--####################

	
	for i = -2, 2 do
		if playersingame[rankcenter+i] then

			--draw the players icon, and other extra stuff because AYYYY
			local rankplayer = playersingame[rankcenter+i][1]
			
			if not (rankplayer and rankplayer.valid and rankplayer.mo and rankplayer.mo.valid) then continue end
			
			local drawtype = playersingame[rankcenter+i][2]
			local colorized = {rankplayer.mo.skin}
			local skincolor = {rankplayer.mo.color}
			local vflags = V_HUDTRANS|V_SNAPTOLEFT
			local xpos = xanioff+FixedInt(calcXOffsetSpinout(rankplayer, drawtype))
			local ypos = (FACE_Y+(i*18)+(max(0, 5-#playersingame)*9))

			if rankplayer.mo.colorized then
				colorized[1] = TC_RAINBOW
			end

			--calulate combi
			local colormap = {v.getColormap(colorized[1], skincolor[1])}
			local plrs = {rankplayer}
			if drawtype == DT_COMBI
			and rankplayer and rankplayer.valid
			and rankplayer.combi and rankplayer.combi.valid
			and rankplayer.combi.mo and rankplayer.combi.mo.valid then
				plrs[2] = rankplayer.combi
				skincolor[2] = plrs[2].mo.color
				colorized[2] = plrs[2].mo.skin
				if plrs[2].mo.colorized then
					colorized[2] = TC_RAINBOW
				end
				
				colormap[2] = v.getColormap(colorized[2], skincolor[2])
			else
				drawtype = DT_NORMAL
			end

			--draw items OR rocket sneakers OR eggbox timer
			
			--ITEM DRAW MATHS!!!
			if (cv_showitems.value and cv_showitemslocal.value)
			or (cv_showitemswhenspectating.value and consoleplayer.spectator) then -- should show if the player who
				for i, k in ipairs(plrs) do
					if not (k and k.valid and not k.spectator) then continue end
					if k.pflags&PF_TIMEOVER then continue end
					
					local itemxoff = (i-1)*(20*FRACUNIT)
					if drawtype == DT_COMBI then
						itemxoff = $+15*FRACUNIT
					end
					local itemyoff = 0
					local itemscale = FRACUNIT/2+FRACUNIT/4
					do
						local faceheight = 16*FRACUNIT
						local mitemheight = -(47*FRACUNIT)/2
						itemyoff = FixedMul(mitemheight, itemscale)+(faceheight/2)
					end
					
					local drawstr = false
					if not k.kartstuff then continue end
					local itemcount = k.kartstuff[k_itemamount]
					
					--alright so im gonna move this into a function since it getting beeg
					--nevermind time for it to be the beegest if statement
					--hmm maybe i can make this a masive for loop LOL
					if k.kartstuff[k_rocketsneakertimer] then
						if not (leveltime&1) then
							v.drawScaled((xpos*FRACUNIT)+(8*FRACUNIT)+itemxoff, ypos*FRACUNIT+itemyoff, itemscale, miniitemgfx[2], vflags)				
						end
					elseif k.kartstuff[k_eggmanexplode] then
						local cmap = nil
						if (leveltime/4)&1 then
							cmap = v.getColormap(TC_BLINK, SKINCOLOR_RED)
						end				
						v.drawScaled((xpos*FRACUNIT)+(8*FRACUNIT)+itemxoff, ypos*FRACUNIT+itemyoff, itemscale, miniitemgfx[5], vflags, cmap)				
					elseif k.kartstuff[k_itemtype] and (not k.kartstuff[k_hyudorotimer] or consoleplayer.spectator) then
						local itemp = miniitemgfx[k.kartstuff[k_itemtype]] or sadgfx
						drawstr = true
						--inv is shiny
						if k.kartstuff[k_itemtype] == KITEM_INVINCIBILITY then
							itemp = miniiteminvulgfx[((leveltime%(6*3))/3)+1]
						end
						--draw item stack (or amount as a number if more than 5)
						if not (k.kartstuff[k_itemheld] and not (leveltime&1)) then
							if itemcount > (drawtype == DT_COMBI and 1 or 5) then
								v.drawScaled((xpos*FRACUNIT)+(8*FRACUNIT)+itemxoff, ypos*FRACUNIT+itemyoff, itemscale, itemp, vflags)
							else
								for i = itemcount-1, 0, -1 do
									v.drawScaled((xpos*FRACUNIT)+((8+(i*2))*FRACUNIT)+itemxoff, ypos*FRACUNIT+itemyoff, itemscale, itemp, vflags)
								end
							end
						end
					end
					
					--draw item count
					if drawstr and itemcount>(drawtype == DT_COMBI and 1 or 5) then
						v.drawString(xpos+26+FixedInt(itemxoff), ypos+6, itemcount, vflags)
					end
				end -- END FOR
			end
			
			--drawScaled
			
			--face
			--also some code to make it fade if hyudo or flashtics
			for i, k in ipairs(plrs) do
				local facexoff = (i-1)*(15*FRACUNIT)
				local facevflags = vflags
				if (k.kartstuff[k_hyudorotimer] and cv_showinvis.value)
				or ((k.powers[pw_flashing] and not (leveltime&1)
				and not k.kartstuff[k_wipeoutslow]
				and not k.kartstuff[k_spinouttimer]
				and not k.kartstuff[k_respawn]) and cv_showflashtics.value) then
					facevflags = $&(~V_HUDTRANS)
					facevflags = $|V_HUDTRANSHALF
				end
				--grow scaling
				local faceoffs = 0
				local facescale = 0
				if not (k.pflags&PF_TIMEOVER) and cv_shrinkgrow.value then --yeah not if you timeover lol
					if k.kartstuff[k_growshrinktimer]>0 then
						faceoffs = -(FACEWIDTH*FRACUNIT/8)
						facescale = FRACUNIT/4
					elseif k.kartstuff[k_growshrinktimer]<0 then
						faceoffs = (FACEWIDTH*FRACUNIT/8)
						facescale = -FRACUNIT/4
					end
				end
				v.drawScaled((xpos*FRACUNIT)+faceoffs+facexoff, ypos*FRACUNIT+faceoffs, FRACUNIT+facescale, facegfx[k.mo.skin], facevflags, colormap[i])

				if k == p then
					v.drawScaled((xpos*FRACUNIT)+faceoffs+facexoff, ypos*FRACUNIT+faceoffs, FRACUNIT+facescale, hilightgfx[(leveltime / 4) % 8], vflags)
				end
				
				if onsameteam[k] and cv_showfriendmodteams.value then
					v.drawScaled((xpos*FRACUNIT)+faceoffs+facexoff, ypos*FRACUNIT+faceoffs, FRACUNIT+facescale, frboardergfx[(leveltime / 4) % 8], vflags, v.getColormap(0, cv_teamcolour[k.FRteam].value))
				end
			end

			--draw bumpers
			if hud.enabled("battlerankingsbumpers") then
				for i, k in ipairs(plrs) do
					local itemxoff = (i-1)*(20*FRACUNIT)
					if drawtype == DT_COMBI then
						itemxoff = $+15*FRACUNIT
					end
					
					if G_BattleGametype() and k.kartstuff[k_bumper] > 0 then
						v.draw(xpos+17+itemxoff, ypos, bumpergfx[1], vflags, colormap[i])
						for b = 1, k.kartstuff[k_bumper]-1 do
							v.draw(xpos+(19+(b*5))+itemxoff, ypos, bumpergfx[2], vflags, colormap[i])
						end
					end
				end
			end
			
			--hpmod compat (ez, also my mod lol)
			if hpmod and hpmod.running
			and (cv_hpmodshowhp.value and cv_hpmodshowhplocal.value) then
				for i, k in ipairs(plrs) do
					local facexoff = (i-1)*(15)
					
					if k.hpmod then
						v.drawString(xpos+facexoff+15, ypos+11, k.hpmod.hp, vflags, "small-right")
					end
				end
			end

			--no bumper indicator
			for i, k in ipairs(plrs) do
				local facexoff = (i-1)*15
				if ((G_BattleGametype() and k.kartstuff[k_bumper] <= 0) and not (hpmod and hpmod.running))
				or (k.pflags&PF_TIMEOVER and cv_showdnf.value) then
					v.draw(xpos-4+facexoff, ypos-3, nobumpersgfx, vflags)
				end
			end

			--placement (eh whatever show both anyway!)
			v.draw(xpos-5, ypos+10, ranknumsgfx[min(max(0, rankplayer.kartstuff[k_position]), 16)], vflags)

			--hornmod is funni
			if HORNMOD_AddHorns and cv_showhorns.value then
				for i, k in ipairs(plrs) do
					if hornmodIsHorn[#k] then
						--print(k.shakefactor)
						local facexoff = (i-1)*15
						
						local colour = v.getColormap(TC_RAINBOW, k.mo.color)
						if k.sincelasthorn < 2 then --wait hornmod has this just INSIDE of it ezzzzzzz
							colour = v.getColormap(TC_RAINBOW, SKINCOLOR_YELLOW)
						end --thx tyron

						--yes i took this from hornmod because ezzzzzzzzzz
						--thx for cool mod
						--although also thx for multiple headaches and hornsoff
						local shake = min((max(k.shakefactor, 10) - 10) / 3, 15)
						
						local destx = hudRandomRange(-1 * shake, shake)
						local desty = hudRandomRange(-1 * shake, shake)
						--tyron pls
						
						local scale = FRACUNIT
						if k.noisemaker and k.noisemaker.valid then
							scale = FixedDiv(k.noisemaker.scale, k.noisemaker.destscale)
						end
						scale = $/4
						v.drawScaled((xpos+facexoff+10 + destx)*FRACUNIT, (ypos+6 + desty)*FRACUNIT, scale, hornmodgfx, vflags, colour)
					end
				end
			end
		end
	end
end
hud.disable("minirankings")
hud.add(drawMinirank, game)