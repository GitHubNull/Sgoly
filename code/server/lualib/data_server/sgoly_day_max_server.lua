--[[
 * @Version:     1.0
 * @Author:      GitHubNull
 * @Email:       641570479@qq.com
 * @github:      GitHubNull
 * @Description: 这是1个检查 sgoly_day_max_dao 模块的执行前逻辑的模块
 * @DateTime:    2017-01-17 15:14:36
 --]]

 require "sgoly_printf"
 local day_max_dao = require "sgoly_day_max_dao"
 local users_server = require "sgoly_users_server"

 local day_max_server = {}

 --[[
 函数说明：
 		函数作用：检查函数 day_max_dao.insert 是否符合执行逻辑,若符合调用执行
 		传入参数：nickname(昵称), single_max(单次最大), conti_max(最大连续值), 
 				 dt(日期)
 		返回参数：执行结果的正确与否的布尔值和相关消息
 --]]
 function day_max_server.insert(nickname, single_max, conti_max, dt)
	printD("day_max_server.insert(%s, %d, %d, %s)", nickname, single_max, conti_max, dt)
 	printI("day_max_server.insert(%s, %d, %d, %s)", nickname, single_max, conti_max, dt)
 	local tag, uid = users_server.select_uid(nickname)
 	if(false == tag ) then
 		return false, nickname.." 不存在"
 	else
 		return day_max_dao.insert(uid, single_max, conti_max, dt)
 	end
 end

 --[[
 函数说明：
 		函数作用：检查函数 day_max_dao.update_single_max 是否符合						 执行逻辑,若符合调用执行
 		传入参数：nickname(昵称), single_max(单次最大), 
 				 dt(日期)
 		返回参数：执行结果的正确与否的布尔值和相关消息
 --]]
 function day_max_server.update_single_max(nickname, single_max, dt)
 	printD("day_max_server.update_single_max(%s, %d, %s)", nickname, single_max, dt)
 	printI("day_max_server.update_single_max(%s, %d, %s)", nickname, single_max, dt)
 	local tag, uid = users_server.select_uid(nickname)
 	if(false == tag ) then
 		return false, nickname.." 不存在"
 	else
 		return day_max_dao.update_single_max(uid, single_max, dt)
 	end
 end

--[[
函数说明：
		函数作用：检查函数 day_max_dao.update_conti_max 								 是否符合执行逻辑,若符合调用执行
 		传入参数：nickname(昵称), conti_max(最大连续值), 
 				 dt(日期)
 		返回参数：执行结果的正确与否的布尔值和相关消息
--]]
function day_max_server.update_conti_max(nickname, conti_max, dt)
 	printD("day_max_server.update_conti_max(%s, %d, %s)", nickname, conti_max, dt)
 	printI("day_max_server.update_conti_max(%s, %d, %s)", nickname, conti_max, dt)
 	local tag, uid = users_server.select_uid(nickname)
 	if(false == tag ) then
 		return false, nickname.." 不存在"
 	else
 		return day_max_dao.update_conti_max(uid, conti_max, dt)
 	end
end

--[[
函数说明：
		函数作用：检查函数 day_max_dao.select 是否符合执行逻辑,若符合调用执行
 		传入参数：nickname(昵称), 
 				 dt(日期)
 		返回参数：执行结果的正确与否的布尔值和相关消息
--]]
function day_max_server.select(nickname, dt)
 	printD("day_max_server.select(%s, %s)", nickname, dt)
 	printI("day_max_server.select(%s, %s)", nickname, dt)
 	local tag, uid = users_server.select_uid(nickname)
 	if(false == tag ) then
 		return false, nickname.." 不存在"
 	else
 		return day_max_dao.select(uid, dt)
 	end
end

--[[
函数说明：
		函数作用：检查函数 day_max_dao.select_single_max 								 是否符合执行逻辑,若符合调用执行
 		传入参数：nickname(昵称), 
 				 dt(日期)
 		返回参数：执行结果的正确与否的布尔值和相关消息
--]]
function day_max_server.select_single_max(nickname, dt)
 	printD("day_max_server.select_single_max(%s, %s)", nickname, dt)
 	printI("day_max_server.select_single_max(%s, %s)", nickname, dt)
 	local tag, uid = users_server.select_uid(nickname)
 	if(false == tag ) then
 		return false, nickname.." 不存在"
 	else
 		return day_max_dao.select_single_max(uid, dt)
 	end
end

--[[
函数说明：
		函数作用：检查函数 day_max_dao.select_conti_max 								 是否符合执行逻辑,若符合调用执行
 		传入参数：nickname(昵称), 
 				 dt(日期)
 		返回参数：执行结果的正确与否的布尔值和相关消息
--]]
function day_max_server.select_conti_max(nickname, dt)
 	printD("day_max_server.select_conti_max(%s, %s)", nickname, dt)
 	printI("day_max_server.select_conti_max(%s, %s)", nickname, dt)
	local tag, uid = users_server.select_uid(nickname)
 	if(false == tag ) then
 		return false, nickname.." 不存在"
 	else
 		return day_max_dao.select_conti_max(uid, dt)
 	end
end

return day_max_server