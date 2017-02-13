local skynet = require "skynet"
local sgoly_tool=require"sgoly_tool"
local dat_ser=require "sgoly_dat_ser"
require "sgoly_printf"
require "skynet.manager"
local md5 = require "md5"
local sgoly_pack=require "sgoly_pack"
local CMD={}
function CMD.sign_in(fd,mes,name)
	if mes.TYPE=="query" then
	    	local bool1,req1 = dat_ser.query_sign(name)
		    printI("this is sign1,%s",mes.NAME)
		if bool1  then 
			local rqs={SESSION=mes.SESSION,ID="10",STATE=true,TYPE="query",LIST=req1}
			local req2_1=sgoly_pack.encode(rqs)
		    return req2_1
		else 
	        return returnfalse(mes,req1)
		end
	elseif mes.TYPE=="signin" then
	    	local bool1,req1 = dat_ser.sign(name,os.date("%Y-%m-%d"))
	    	local bool2,req2 = dat_ser.get_award("signIn","1")
	    	local bool3,req3=sgoly_tool.getMoney(name)
	    	local bool4,req4=sgoly_tool.saveMoneyToRedis(name,req3+req2)
		    printI("this is sign2,%s",mes.NAME)
		if bool1 and bool2 and bool3 and bool4 then 
			local rqs={SESSION=mes.SESSION,ID="10",STATE=true,TYPE="signin",MONEY=req3+req2}
			local req2_1=sgoly_pack.encode(rqs)
		    return req2_1
		else 
	        return returnfalse(mes,req1)
		end
	elseif mes.TYPE=="award" then
	    	local bool1,req1 = dat_ser.get_award("signIn",mes.DAY)
	    	local bool,req=sgoly_tool.getMoney(name)
	    	local bool2,req2=sgoly_tool.saveMoneyToRedis(name,req+req1)
		    printI("this is sign3,%s",mes.NAME)
			if bool1 and bool and bool2 then 
				local rqs={SESSION=mes.SESSION,ID="10",STATE=true,TYPE="award",MONEY=req+req1}
				local req2_1=sgoly_pack.encode(rqs)
			    return req2_1
			else 
		        return returnfalse(mes,req1..req..req2)
			end
	else 
		returnfalse(mes,"参数错误")
	end           
end

function returnfalse(mes,msg)
	        local req1={SESSION=mes.SESSION,ID="10",STATE=false,TYPE=mes.TYPE,MESSAGE=msg}
			local req1_1=sgoly_pack.encode(req1)
			return req1_1
end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)
    -- 要注册个服务的名字，以.开头
    skynet.register(".sign")
end)
