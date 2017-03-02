
--[[
 * @brief: sgoly_tool.lua

 * @author:	  kun si
 * @date:	2017-01-12
--]]


require "sgoly_query"
local sgoly_tool = {}
local sgoly_dat_ser = require "sgoly_dat_ser"
local skynet = require "skynet"
local queue = require "skynet.queue"
local lock = queue()
local sgoly_rank = require "sgoly_rank"

--!
--! @brief      网络数据包取长度
--!
--! @param      str   网络网络数据包
--!
--! @return     网络数据包长度
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-16
--!
function sgoly_tool.wordToInt(str)
	return str:byte(1) * 256 + str:byte(2)
end

--!
--! @brief      数值用两个字节存储
--!
--! @param      num   数值
--!
--! @return     两个字节的数值
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-16
--!
function sgoly_tool.intToWord(num)
	local wordH = string.char(math.floor(num / 256))
	local wordL = string.char(num % 256)
	return wordH .. wordL	
end

--!
--! @brief      保存用户一键注册id
--!
--! @param      uuid  用户一键注册id
--!
--! @return     nil
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-16
--!
local function saveUuid(uuid)
	redis_query({"set","uuid", uuid})
end

--!
--! @brief      查询用户一键注册id
--!
--! @return     用户一键注册id
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-16
--!
local function getUuid()

	local uuid = redis_query({"get", "uuid"})
	return tonumber(uuid)
end

--!
--! @brief      Redis数字索引table转字符串索引
--!
--! @param      redisResult  Redis查询结果
--!
--! @return     bool, table		执行是否成功、转换结果
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-16
--!
function sgoly_tool.multipleToTable(redisResult)

	if #redisResult <= 0 then
		printI("redisResult type[%s]", type(redisResult))
		return false, redisResult
	end
	local rt = {}
	local index = 1
	while index <= #redisResult-1 do
		rt[redisResult[index]] = redisResult[index+1]
		index = index + 2
	end 
	
	return true, rt 
end

--!
--! @brief      查询用户一键注册id
--!
--! @return     用户一键注册id
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-16
--!
function sgoly_tool.getUuid()
	return getUuid()
end

--!
--! @brief      保存用户一键注册id
--!
--! @param      uuid  用户一键注册id
--!
--! @return     nil
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-16
--!
function sgoly_tool.saveUuid(uuid)
	saveUuid(uuid)
end

--!
--! @brief      获得用户金钱
--!
--! @param      nickname  用户名
--!
--! @return     bool, money		执行是否成功、查询结果
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-16
--!
function sgoly_tool.getMoney(nickname)
	nickname = tostring(nickname)
	local db = "user:" ..  nickname
	local money = redis_query({"hget", db, "money"})
	if money then
		return true, tonumber(money)
	else
		local judge
		judge, money = sgoly_dat_ser.get_money(tonumber(nickname))
		if judge then
			redis_query({"hset", db, "money", money})
			return true, money
		else
			return false, money
		end
	end
end

--!
--! @brief      Gets the user fd.
--!
--! @param      nickname  The nickname
--!
--! @return     The user fd.
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-16
--!
function sgoly_tool.getUserFdFromRedis(nickname)
	nickname = tostring(nickname)
	local key = "user:" ..  nickname
	local fd = redis_query({"hget", key, "fd"})
	if fd then
		return true, tonumber(fd)
	end
	return false, nil
end

--!
--! @brief      Sets the user fd.
--!
--! @param      nickname  The nickname
--! @param      fd        { parameter_description }
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-16
--!
function sgoly_tool.setUserFdToRedis(nickname, fd)
	nickname = tostring(nickname)
	fd = tostring(fd)
	local key = "user:" ..  nickname
	redis_query({"hset", key, "fd", fd})
	return true, nil
end

--!
--! @brief      Saves address to redis.
--!
--! @param      uid   The uid
--! @param      addr  The address
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-16
--!
function sgoly_tool.saveAddrToRedis(uid, addr)
	uid = tostring(uid)
	local key = "user:" ..  uid
	redis_query({"hset", key, "addr", addr})
	return true, nil
end

--!
--! @brief      保存用户总金币到Redis
--!
--! @param      nickname  用户名
--! @param      money     用户总金币
--!
--! @return     bool, errorMsg 执行成功与否、错误消息
--!
--! @author     kun si
--! @date       2017-01-16
--!
function sgoly_tool.saveMoneyToRedis(nickname, money)
	if nickname == nil or money == nil then
		return false, "nickname or money is nil"
	end
	
	local key = "user:" .. nickname
	redis_query({"hset", key, "money", money})
	return true, nil
end

--!
--! @brief      从Redis中获取结算信息
--!
--! @param      nickname  用户名
--!	@param		dt		  日期		 		
--!
--! @return     bool,table 执行成功与否、｛结算信息｝
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-19
--!
function sgoly_tool.getStatementsFromRedis(nickname, dt)
	if nickname == nil then
		return false, "There are nil in args."
	end
	local res = {}
	local key = "statements:" ..  tostring(nickname) .. "_" ..dt
	local res = redis_query({"hgetall", key})
	if #res > 0 then
		return sgoly_tool.multipleToTable(res)
	end

	local ok, result = sgoly_dat_ser.get_statments_from_MySQL(nickname, dt)
	if ok then
		result.eighthNoWin = eighthNoWin
		result.recoveryRate = recoveryRate
		if dt ~= os.date("%Y-%m-%d") then
			result.saveStatementsToMySQL = 1
		else
			result.saveStatementsToMySQL = 0
		end
		redis_query({"hmset", key, result})
		return ok, result
	end
	return ok, result

end
--!
--! @brief      保存游戏结算结果到Redis
--!
--! @param      nickname      	用户名
--! @param      winMoney      	本轮游戏赢的金钱
--! @param      costMoney	  	本轮游戏消耗的金钱
--! @param		playNum			本轮游戏抽奖次数
--! @param      winNum        	本轮游戏中奖次数
--! @param      serialWinNum  	本轮游戏连续中奖次数
--! @param      maxWinMoney  	本轮游戏最大中奖金额	
--!	@param		eighthNoWin 	8次连续不中奖计数值
--!	@param		recoveryRate 	回收率
--!	
--! @return     bool, errorMsg 	执行成功与否、错误消息
--!
--! @author     kun si
--! @date       2017-01-16
--!
function sgoly_tool.saveStatementsToRedis(nickname, winMoney, costMoney, playNum, winNum, serialWinNum, maxWinMoney, eighthNoWin, recoveryRate, dt)
	nickname = tostring(nickname)
	if nickname == nil or winMoney == nil or 
		costMoney == nil or playNum == nil 
		or winNum == nil or serialWinNum == nil 
		or eighthNoWin == nil or recoveryRate == nil then

		return false, "There are nil in args."
	end
	printI("Save statements nickname[%s]  winMoney[%d] costMoney[%d] playNum[%d] winNum[%d] serialWinNum[%d] maxWinMoney[%d] eighthNoWin[%d] recoveryRate[%d] dt[%s]",
		nickname, winMoney, costMoney, playNum, winNum, serialWinNum, maxWinMoney, eighthNoWin, recoveryRate, dt)
	local key = "statements:" .. nickname .. "_" ..dt
	local ok, result = sgoly_tool.getStatementsFromRedis(tonumber(nickname), dt)
	if ok then

		result.winMoney = result.winMoney + winMoney
		result.costMoney = result.costMoney + costMoney
		result.playNum = result.playNum + playNum
		result.winNum = result.winNum + winNum
		
		if tonumber(serialWinNum) > tonumber(result.serialWinNum) then
			result.serialWinNum = serialWinNum
		end

		if tonumber(maxWinMoney) > tonumber(result.maxWinMoney) then

			result.maxWinMoney = maxWinMoney
		end

		result.eighthNoWin = eighthNoWin
		result.recoveryRate = recoveryRate
		result.saveStatementsToMySQL = 0
		redis_query({"hmset", key, result})
		--local ok , result = sgoly_dat_ser.update_statments_to_MySQL(tonumber(nickname), result.winMoney, result.costMoney, result.playNum, result.winNum, result.maxWinMoney, result.serialWinNum, dt)
		return true, nil
	end

	return ok, result
end

--!
--! @brief      获取玩法改变模式的必要参数
--!
--! @param      nickname  用户名
--!
--! @return     bool,table 执行成功与否、｛8次连续不中奖计数值, 回收率｝
--!
--! @author     kun si
--! @date       2017-01-18
--!
function sgoly_tool.getPlayModelFromRedis(nickname)
	nickname = tostring(nickname)
	local res = {}
	local key = "statements:" ..  nickname .. "_" ..os.date("%Y-%m-%d")
	res = redis_query({"hmget", key, "eighthNoWin", "recoveryRate"})
	if #res == 0 then
		res[1]=0
		res[2]=1
	end
	res[1]=tonumber(res[1])
	res[2]=tonumber(res[2])

	return true, res
end

--!
--! @brief      获得结算统计
--!
--! @param      nickname	用户名
--! @param 		dt			日期 
--!
--! @return     bool,table 执行成功与否、｛结算统计信息｝
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-20
--!
function sgoly_tool.getCountStatementsFromRedis(nickname, dt)
	nickname = tostring(nickname)
	local res = {}
	
	local key = "count:" .. nickname
	local res = redis_query({"hgetall", key})
	if #res > 0 then

		local ok1, result1 = sgoly_tool.multipleToTable(res)
		local ok2, result2 = sgoly_tool.getStatementsFromRedis(nickname, os.date("%Y-%m-%d"))
		local result3 = {
							winMoney = result1.winMoney+result2.winMoney, 
							costMoney = result1.costMoney+result2.costMoney, 
							playNum = result1.playNum+result2.playNum, 
							winNum = result1.winNum+result2.winNum,
							serialWinNum = result1.serialWinNum, 
							maxWinMoney = result1.maxWinMoney
						}

		if tonumber(result2.serialWinNum) > tonumber(result1.serialWinNum) then
			printD(result2.serialWinNum, result1.serialWinNum)
			result3.serialWinNum = result2.serialWinNum
		end
		if tonumber(result2.maxWinMoney) > tonumber(result1.maxWinMoney) then
			result3.maxWinMoney = result2.maxWinMoney
		end
		return ok2, result3	
	end
	local ok2, result2 = sgoly_tool.getStatementsFromRedis(nickname, os.date("%Y-%m-%d"))
	local ok, result = sgoly_dat_ser.get_count_statements_from_MySQL(tonumber(nickname), dt)
	if ok then
		redis_query({"hmset", key, result})
		local result3 = {
							winMoney = result.winMoney+result2.winMoney, 
							costMoney = result.costMoney+result2.costMoney, 
							playNum = result.playNum+result2.playNum, 
							winNum = result.winNum+result2.winNum, 
							serialWinNum = result.serialWinNum, 
							maxWinMoney = result.maxWinMoney
						}


		if tonumber(result2.serialWinNum) > tonumber(result.serialWinNum) then
			result3.serialWinNum = result2.serialWinNum
		end

		if tonumber(result2.maxWinMoney) > tonumber(result.maxWinMoney) then
			result3.maxWinMoney = result2.maxWinMoney
		end

		return ok, result3
	end
	redis_query({"hmset", key, result2})
	return ok2, result2
	
end

--!
--! @brief      保存钱到MySQL
--! 
--! @param      nickname	用户名
--! @return     bool, string  执行成功与否、错误信息
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-21
--!
function sgoly_tool.saveMoneyFromRdisToMySQL(nickname)
	nickname = tostring(nickname)
	local key = "user:" .. nickname
	local result = tonumber(redis_query({"hget", key , "money"}))
	if result == nil then
		return false, "No money"
	end 
	local ok , result = sgoly_dat_ser.upadate_money_to_MySQL(tonumber(nickname), result)
	if ok then
		redis_query({"del", key})
	end
	return ok, result
end

--!
--! @brief      保存结算到MySQL
--!
--! @param      nickname	用户名
--! @param      dt			日期
--!
--! @return    bool, string  执行成功与否、错误信息
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-21
--!
function sgoly_tool.saveStatmentsFromRdisToMySQL(nickname, dt)
	nickname = tostring(nickname)
	local key1 = "count:" .. nickname
	local key2 = "statements:" .. nickname .. "_" ..dt 
	local key3 = "user:" .. nickname
	local ok, result = sgoly_tool.getStatementsFromRedis(nickname, dt)
	if ok then
		printD("%s have statements " .. dt, nickname)
		if tonumber(result.saveStatementsToMySQL) == 0 then 
			ok , result = sgoly_dat_ser.update_statments_to_MySQL(tonumber(nickname), result.winMoney, result.costMoney, result.playNum, result.winNum, result.maxWinMoney, result.serialWinNum, dt)
	
			--skynet.error(ok, result)	
		end

		redis_query({"del", key1})
		redis_query({"del", key2})
		redis_query({"del", key3})

		return ok, result
		
	end
	printD("%s no have statements " .. dt, nickname)
	return ok ,result
	
end

--!
--! @brief      { function_description }
--!
--! @param      names  The names
--! @param      args   The arguments
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-22
--!
function sortRank(names, args)
	table.sort(names, function (n1, n2)
		local t1 = args[n1][1]
		local t2 = args[n2][1]
		local d1 = args[n1][2]
		local d2 = args[n2][2]
		if t1 > t2 then
			return true
		elseif t1 == t2 then
			if d1 < d2 then
				return true
			elseif d1 == d2 then
				return false
			else
				return false
			end
		else
			return false
		end
	end)
end

--!
--! @brief      { function_description }
--!
--! @param      result  The result
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-22
--!
function rankArgsToTable(result, fori)
	local rank = {}
	local args = {}
	--skynet.error("fori", fori)
	for i=1, fori do
		--skynet.error(result[i])
		local nickname, value, date, award = string.match(result[i],"(.+):(.+):(.+):(.+)")
		rank[i] = nickname
		args[nickname]={tonumber(value), tonumber(date), tonumber(award)}
	end	
	return rank, args
end

--!
--! @brief      Gets the rank from rdis.
--!
--! @param      dt    { parameter_description }
--!
--! @return     The rank from rdis.
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-22
--!
function sgoly_tool.getRankFromRedis(nickname, value, rank_type, date)
	nickname = tostring(nickname)
	local ok, my_name = sgoly_dat_ser.get_nickname(nickname)
	local rank = {} 
	local args = {}
	local name_rank = {}
	if date == nil then
		return false, "There are nil in args."
	end
	local res = {}
	local key = "rank:".. rank_type .. date
	local res = redis_query({"hmget", key, "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"})
	if #res > 0 then
		rank, args = rankArgsToTable(res, #res)

		for k,v in pairs(rank) do
			name_rank[v] = k
		end
	end

	if date ~= os.date("%Y-%m-%d") then
		local ok, result
		if #res == 0 then
			ok, result = sgoly_tool.getRankFromMySQL(rank_type, date)
			if ok then
				for k, v in pairs(result) do
					--skynet.error(v.rank, v.nickname, v.value, v.award)
					rank[k] = v.nickname
					args[v.nickname] = {v.value, k, v.award}
				end	
				sgoly_tool.updateRankToRedis(rank, args, rank_type, date)
			end
			--skynet.error(ok, #result)
		end
	else

		if rank_type == "serialWinNum" then
			if value >= 4 then	
				if name_rank[my_name] then
					if value > args[my_name][1] then
						args[my_name][1] = value
						args[my_name][2] = os.time()
						lock(sortRank,rank, args)
						for k,v in pairs(rank) do
							name_rank[v] = k
						end
						sgoly_tool.updateRankToRedis(rank, args, rank_type, date)
					end

				else
					if #rank == 10 and value <= args[rank[10]][1] then

					else
						args[my_name] = {value, os.time()}
						table.insert(rank,my_name)
						lock(sortRank,rank, args)

						local len = #rank
						if len  > 10 then
							local name = rank[11]
							rank[11] = nil
							args[name] = nil
						end
						for k,v in pairs(rank) do
							name_rank[v] = k
						end
						sgoly_tool.updateRankToRedis(rank, args, rank_type, date)
					end
				end

			end
		else
			if value >= 400000 then
				if name_rank[my_name] then
					if value > args[my_name][1] then
						args[my_name][1] = value
						args[my_name][2] = os.time()
						lock(sortRank,rank, args)
						for k,v in pairs(rank) do
							name_rank[v] = k
						end
						sgoly_tool.updateRankToRedis(rank, args, rank_type, date)
					end

				else
					local len = #rank 
					if #rank == 10 and value <= args[rank[10]][1]then

					else
						args[my_name] = {value, os.time()}
						table.insert(rank,my_name)
						lock(sortRank,rank, args)
						if len  > 10 then
							local name = rank[11]
							rank[11] = nil
							args[name] = nil
						end
						
						for k,v in pairs(rank) do
							name_rank[v] = k
						end
						sgoly_tool.updateRankToRedis(rank, args, rank_type, date)
					end
				end

			end
		end
	end
		
	return true, {rank, name_rank, args, value}
end

--!
--! @brief      { function_description }
--!
--! @param      rank       The rank
--! @param      args       The arguments
--! @param      rank_type  The rank type
--! @param      date       The date
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-23
--!
function sgoly_tool.updateRankToRedis(rank, args, rank_type, date)
	if date ~= nil then
		local key = "rank:" .. rank_type .. date
		local result = {}
		for i = 1, #rank do
			local nickname = rank[i]
			local value = nickname .. ":" .. args[nickname][1] .. ":" .. args[nickname][2] .. ":0"
			--skynet.error(i, "value" ,value)
			result[tostring(i)] = value
		end

		if #rank > 0 then
			redis_query({"hmset", key, result})
			local year, month, day = string.match(date, "(.+)-(.+)-(.+)")
			year = tonumber(year)
			month = tonumber(month)
			day = tonumber(day)
			local time = os.time({day=day+3, month=month, year=year,hour = 0, min=0, sec=0})
			redis_query({"expireat", key, time})
			return true
		end
	end

	local key = "rank:" .. rank_type
	local result = {}
	for i = 1, #rank do
		local nickname = rank[i]
		local value = nickname .. ":" .. args[nickname][1] .. ":" .. args[nickname][2]
		--skynet.error(i, "value" ,value)
		result[tostring(i)] = value
	end

	if #rank > 0 then
			redis_query({"hmset", key, result})
			return true
	end
end

--!
--! @brief      保存排行榜到MySQL
--!
--! @param      rank_type  排行绑类型 "serialWinNum"或"winMoney"
--! @param      date       日期
--! 
--! @return     bool, string		执行是否成功、查询结果
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-24
--!
function sgoly_tool.saveRankToMySQL(rank_type, date)
	local rank = {} 
	local args = {}
	local key = "rank:".. rank_type .. date
	local res = redis_query({"hmget", key, "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"})
	if #res > 0 then
		rank, args = rankArgsToTable(res, #res)
		local ok, result = sgoly_dat_ser.save_rank_to_MySQL(rank_type, rank, args, date)
		--skynet.error(res, ok, result)
	end
end

--!
--! @brief      从MySQL中查询排行榜
--!
--! @param      rank_type  排行绑类型 "serialWinNum"或"winMoney"
--! @param      date       The date
--!
--! @return     bool, table		执行是否成功、查询结果
--! 
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-24
--!
function sgoly_tool.getRankFromMySQL(rank_type, date)
	return sgoly_dat_ser.get_rank_from_MySQL(rank_type, date)
end

--!
--! @brief      领奖励
--!
--! @param      rank1  日连续中奖名次
--! @param      rank1  日累计中奖金额名次
--! @param      date   日期
--!
--! @return     bool, money 执行是否成功、奖励金额
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-01-24
--!
function sgoly_tool.getAwardFromRedis(rank1, rank2, date)
	local money1 = 0
	local money2 = 0
	local ok = nil
	local key1 = "rank:" .. "serialWinNum" .. date
	local key2 = "rank:" .. "winMoney" .. date
	local year, month, day = string.match(date, "(.+)-(.+)-(.+)")
	year = tonumber(year)
	month = tonumber(month)
	day = tonumber(day)

	local time = os.time({day=day+3, month=month, year=year,hour = 0, min=0, sec=0})
	if rank1 ~= 0 then
		
		local value = redis_query({"hget", key1 , rank1})
		if value then
			value  = string.sub(value, 1, #value - 1)
			value = value .. 1
			redis_query({"hset", key1, rank1, value})
			redis_query({"expireat", key1, time})
			ok, money1 = sgoly_dat_ser.get_award("dayMaxContinuous", rank1)
		end
	end

	if rank2 ~= 0 then
		local value = redis_query({"hget", key2 , rank2})
		if value then
			value  = string.sub(value, 1, #value - 1)
			value = value .. 1
			redis_query({"hset", key2, rank2, value})
			redis_query({"expireat", key2, time})
			ok, money2 = sgoly_dat_ser.get_award("dayMaxWin", rank2)
		end
	end

	return true, money1 + money2
	
end

--!
--! @brief      从Redis中得到领取救济金的次数
--!
--! @param      nickname  用户名
--!
--! @return     bool, times 执行是否成功、已领救济金次数
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-10
--!
function sgoly_tool.getCharityTimesFromRedis(nickname)
	nickname = tostring(nickname)
	local date = os.date("%Y-%m-%d")
	local key = "dayRecords:" .. nickname .. "_" .. date
	local value = redis_query({"hget", key , "charityTimes"})
	if value ~= nil then
		return true, tonumber(value)
	end

	local year, month, day = string.match(date, "(.+)-(.+)-(.+)")
	year = tonumber(year)
	month = tonumber(month)
	day = tonumber(day)
	local time = os.time({day=day+1, month=month, year=year,hour = 0, min=0, sec=0})
	redis_query({"hset", key, "charityTimes", 0})
	redis_query({"expireat", key, time})
	return true, 0
end

--!
--! @brief      设置领救济金次数到Redis
--!
--! @param      nickname  用户名
--! @param      times     次数
--!
--! @return     bool, times 执行是否成功、nil
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-10
--!
function sgoly_tool.setCharityTimesToRedis(nickname, times)
	nickname = tostring(nickname)
	local date = os.date("%Y-%m-%d")
	local key = "dayRecords:" .. nickname .. "_" .. date
	local year, month, day = string.match(date, "(.+)-(.+)-(.+)")
	year = tonumber(year)
	month = tonumber(month)
	day = tonumber(day)
	local time = os.time({day=day+1, month=month, year=year,hour = 0, min=0, sec=0})
	redis_query({"hset", key, "charityTimes", times})
	redis_query({"expireat", key, time})
	return true, nil
end

--!
--! @brief      从Redis获取财富绑
--!
--! @param      nickname  用户名
--! @param      value     用户当前的金额
--!
--! @return     bool, table		执行是否成功、查询结果
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-10
--!
function sgoly_tool.getMoneyRankFromRedis(nickname, value)
	nickname = tostring(nickname)
	local ok, my_name = sgoly_dat_ser.get_nickname(nickname)
	local rank = {} 
	local args = {}
	local name_rank = {}

	local function redisArgsToTable(result, fori)
		local rank_i = {}
		local args_i = {}
		--skynet.error("fori", fori)
		for i=1, fori do
			--skynet.error(result[i])
			local nickname_i, value_i, time_i = string.match(result[i],"(.+):(.+):(.+)")
			rank_i[i] = nickname_i
			args_i[nickname_i]={tonumber(value_i), tonumber(time_i)}
		end	
		return rank_i, args_i
	end


	local key = "rank:money"
	local res = redis_query({"hmget", key, "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"})
	if #res > 0 then
		rank, args = redisArgsToTable(res, #res)

		for k,v in pairs(rank) do
			name_rank[v] = k
		end
		if name_rank[my_name] then
			if value ~= args[my_name][1] then
				args[my_name][1] = value
				args[my_name][2] = os.time()
				lock(sortRank,rank, args)
				for k,v in pairs(rank) do
					name_rank[v] = k
				end
				sgoly_tool.updateRankToRedis(rank, args, "money")
			end

		else
			if #rank == 10 and value <= args[rank[10]][1] then

			else
				args[my_name] = {value, os.time()}
				table.insert(rank,my_name)
				lock(sortRank,rank, args)

				local len = #rank
				if len  > 10 then
					local name = rank[11]
					rank[11] = nil
					args[name] = nil
				end
				for k,v in pairs(rank) do
					name_rank[v] = k
				end
				sgoly_tool.updateRankToRedis(rank, args, "money")
			end
		end

	else 
		local ok, result = sgoly_rank.get_money_rank_from_MySQL()
		if #result > 0 then
			for k, v in ipairs(result) do
				local ok, my_name_1 = sgoly_dat_ser.get_nickname(v.id)
				rank[k] = my_name_1

				name_rank[my_name_1] = k
				local year, month, day, hour, minute, second = string.match(v.update_time,"(.+)-(.+)-(.+) (.+):(.+):(.+)")
				local time = os.time({day=day, month=month, year=year, hour=hour, min=minute, sec=second})
				args[my_name_1] = {v.money, time}
			end
		end

		if name_rank[my_name] then
			if value ~= args[my_name][1] then
				if #rank == 10 and value <= args[rank[10]][1] then
				else
					args[my_name][1] = value
					args[my_name][2] = os.time()
					lock(sortRank,rank, args)
					for k,v in pairs(rank) do
						name_rank[v] = k
					end
					sgoly_tool.updateRankToRedis(rank, args, "money")
				end
			end

		else
			if #rank == 10 and value <= args[rank[10]][1] then

			else
				args[my_name] = {value, os.time()}
				table.insert(rank, my_name)
				lock(sortRank,rank, args)

				local len = #rank
				if len  > 10 then
					local name = rank[11]
					rank[11] = nil
					args[name] = nil
				end
				for k,v in pairs(rank) do
					name_rank[v] = k
				end
				sgoly_tool.updateRankToRedis(rank, args, "money")
			end
		end
	end
	return true, {rank, name_rank, args, value}
end

--!
--! @brief      Gets the package from redis.
--!
--! @param      nickname  The nickname
--!
--! @return     The package from redis.
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-21
--!
function sgoly_tool.getPackageFromRedis(nickname)
	nickname = tostring(nickname)
	local key = nickname .. ":package"
	result = redis_query({"hgetall", key})
	if #result > 0 then
		ok, result = sgoly_tool.multipleToTable(result)
		return ok, result
	end
	local ok, result = sgoly_dat_ser.get_all_prop(nickname)
	if #result > 0 then
		redis_query({"hmset", key, result})
	end
	return ok, result
end

--!
--! @brief      Sets the property to redis.
--!
--! @param      nickname  The nickname
--! @param      propId    The property identifier
--! @param      propNum   The property number
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-21
--!
function sgoly_tool.setPropToRedis(nickname, propId, propNum)
	nickname = tostring(nickname)
	local key = nickname .. ":package"
	redis_query({"hset", key, tostring(propId), tostring(propNum)})
	return true, nil
end

--!
--! @brief      Saves a property to my sql.
--!
--! @param      nickname  The nickname
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-21
--!
function sgoly_tool.savePropToMySQL(nickname)
	nickname = tostring(nickname)
	local key = nickname .. ":package"
	result = redis_query({"hgetall", key})
	if #result > 0 then
		ok, result = sgoly_tool.multipleToTable(result)
		for k, v in pairs(result) do
			k = tonumber(k)
			v = tonumber(v)
			sgoly_dat_ser.set_prop(tonumber(nickname), tonumber(k), tonumber(v))
		end
	end
	redis_query({"del", key})
	return true, nil
end

--!
--! @brief      Gets the property from redis.
--!
--! @param      nickname  The nickname
--! @param      propId    The property identifier
--!
--! @return     The property from redis.
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-21
--!
function sgoly_tool.getPropFromRedis(nickname, propId)
	nickname = tostring(nickname)
	local key = nickname .. ":package"
	local number = redis_query({"hget", key, tostring(propId)})

	if number ~= nil then
		return true, tonumber(number)
	end

	return true, 0
end

--!
--! @brief      Gets the probability from redis.
--!
--! @param      modle  The modle
--!
--! @return     The probability from redis.
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-24
--!
function sgoly_tool.getProbabilityFromRedis(modle)
	local key = "probability:" .. modle
	local result = redis_query({"hgetall", key})
	if #result > 0 then
		local ok, result = sgoly_tool.multipleNumToTable(result)
		return ok, result
	end
	local ok, result = sgoly_dat_ser.getProbabilityFromMySQL(modle)
	redis_query({"hmset", key, result})
	return ok, result 
end

--!
--! @brief      { function_description }
--!
--! @param      redisResult  The redis result
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-24
--!
function sgoly_tool.multipleNumToTable(redisResult)

	if #redisResult <= 0 then
		printI("redisResult type[%s]", type(redisResult))
		return false, redisResult
	end
	local rt = {}
	local index = 1
	while index <= #redisResult-1 do
		rt[tonumber(redisResult[index])] = redisResult[index+1]
		index = index + 2
	end 
	
	return true, rt 
end

--!
--! @brief      { function_description }
--!
--! @param      type  The type
--! @param      rate  The rate
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-24
--!
function sgoly_tool.awardTypeAndRate()
	local ok, awardType = sgoly_tool.getProbabilityFromRedis("type")
	local ok, awardRate = sgoly_tool.getProbabilityFromRedis("rate")
	local award = {}
	for k, v in ipairs(awardType) do
		-- print(k, v, awardRate[k])
		award[k] = {v, awardRate[k]}
	end
	return true, award
end

--!
--! @brief      { function_description }
--!
--! @param      probability  The probability
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-24
--!
function sgoly_tool.probaToSpace(probability)
	local temp = 0
	for k, v in ipairs(probability) do
		local tp  = probability[k] * 10000
		probability[k] = tp + temp
		temp = probability[k]
		-- print(probability[k], k)
	end
	return true, probability
end

--!
--! @brief      { function_description }
--!
--! @param      left         The left
--! @param      right        The right
--! @param      number       The number
--! @param      probability  The probability
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-24
--!
function sgoly_tool.hitAward(left, right, number, probability)
	if number > probability[#probability] + 1 then
		return true, 18
	end

	local mid = math.floor((left + right)/2)
	if  left == right or left > right then
		if number > probability[left] then
			return true, mid + 1
		end

		return true, mid
	end
	if number == probability[mid]  then
		return true, mid
	elseif number < probability[mid] then

		right = mid - 1
		return sgoly_tool.hitAward(left, right, number, probability)
	else
		left = mid + 1 
		return sgoly_tool.hitAward(left, right, number, probability)

	end
end

--!
--! @brief      Gets the space from redis.
--!
--! @return     The space from redis.
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-24
--!
function sgoly_tool.getSpaceFromRedis()
	local ok, difficulty = sgoly_tool.getProbabilityFromRedis("difficulty")
	local ok, simple = sgoly_tool.getProbabilityFromRedis("simple")
	local ok, normal = sgoly_tool.getProbabilityFromRedis("normal")
	local ok, lucky = sgoly_tool.getProbabilityFromRedis("lucky")
	local ok, difficultyS = sgoly_tool.probaToSpace(difficulty)
	local ok, simpleS = sgoly_tool.probaToSpace(simple)
	local ok, normalS = sgoly_tool.probaToSpace(normal)
	local ok, luckyS = sgoly_tool.probaToSpace(lucky)
	return ok, normalS, simpleS, difficultyS, luckyS 
end

--!
--! @brief      Saves a probability to my sql.
--!
--! @return     { description_of_the_return_value }
--!
--! @author     kun si, 627795061@qq.com
--! @date       2017-02-24
--!
function sgoly_tool.saveProbabilityToMySQL()
	local ok, difficulty = sgoly_tool.getProbabilityFromRedis("difficulty")
	sgoly_dat_ser.saveProbabilityToMySQL("difficulty", difficulty)
	local ok, simple = sgoly_tool.getProbabilityFromRedis("simple")
	sgoly_dat_ser.saveProbabilityToMySQL("simple", simple)
	local ok, normal = sgoly_tool.getProbabilityFromRedis("normal")
	sgoly_dat_ser.saveProbabilityToMySQL("normal", normal)
	local ok, rate = sgoly_tool.getProbabilityFromRedis("rate")
	sgoly_dat_ser.saveProbabilityToMySQL("rate", rate)
	local ok, atype = sgoly_tool.getProbabilityFromRedis("type")
	sgoly_dat_ser.saveProbabilityToMySQL("type", atype)
	local ok, lucky = sgoly_tool.getProbabilityFromRedis("lucky")
	sgoly_dat_ser.saveProbabilityToMySQL("lucky", lucky)
end

function sgoly_tool.getProbabilityFromMySQL(type)
	local ok, result = sgoly_dat_ser.getProbabilityFromMySQL(type)
	local key = "probability:" .. type
	redis_query({"hmset", key, result})
end

return sgoly_tool