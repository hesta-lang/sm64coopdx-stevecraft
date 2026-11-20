local MC = { Mth = {}, Util = {} }
local function float32(value) return (string.unpack("f", string.pack("f", value))) end
MC.Mth.PI=float32(math.pi); MC.Mth.HALF_PI=float32(math.pi/2); MC.Mth.TWO_PI=float32(math.pi*2)
MC.Mth.DEG_TO_RAD=float32(math.pi/180); MC.Mth.RAD_TO_DEG=float32(180/math.pi)
-- 26.3 float/double overload; int/long overloads require Java overload resolution.
function MC.Mth.clamp(value, low, high) if value < low then return low end return math.min(value, high) end
function MC.Mth.lerp(delta, start_value, end_value) return start_value + delta * (end_value - start_value) end
function MC.Mth.sign(value) if value == 0 then return 0 end if value > 0 then return 1 end return -1 end
function MC.Mth.wrapDegrees(value)
 value=value%360; if value>=180 then value=value-360 end; if value < -180 then value=value+360 end; return value
end
function MC.Mth.absMax(x,y) return math.max(math.abs(x),math.abs(y)) end
function MC.Mth.degreesDifference(a,b) return MC.Mth.wrapDegrees(b-a) end
function MC.Mth.degreesDifferenceAbs(a,b) return math.abs(MC.Mth.degreesDifference(a,b)) end
function MC.Mth.rotateIfNecessary(base,target,maxdiff)
 local delta=MC.Mth.degreesDifference(base,target); return target-MC.Mth.clamp(delta,-maxdiff,maxdiff)
end
function MC.Mth.approach(current,target,increment)
 increment=math.abs(increment)
 if current<target then return MC.Mth.clamp(current+increment,current,target) end
 return MC.Mth.clamp(current-increment,target,current)
end
function MC.Mth.approachDegrees(current,target,increment)
 local difference=MC.Mth.degreesDifference(current,target)
 return MC.Mth.approach(current,current+difference,increment)
end
function MC.Mth.positiveModulo(input,mod) return (input%mod+mod)%mod end
function MC.Mth.frac(value) return value-math.floor(value) end
function MC.Mth.square(value) return value*value end
function MC.Mth.cube(value) return value*value*value end
function MC.Mth.equal(a,b) return math.abs(b-a)<1.0E-5 end
function MC.Mth.clampedLerp(factor,minimum,maximum)
 if factor<0 then return minimum end; if factor>1 then return maximum end
 return MC.Mth.lerp(factor,minimum,maximum)
end
-- 26.3 uses a 65,536-entry float sine lookup table.
local SIN_SCALE=10430.378350470453
local SIN_MASK=65535
local SIN_CACHE={}
local function sin_index(angle,offset)
 local scaled=angle*SIN_SCALE+offset
 if scaled~=scaled then return 0 end
 if scaled==math.huge then return SIN_MASK end
 if scaled==-math.huge then return 0 end
 local truncated=scaled<0 and math.ceil(scaled) or math.floor(scaled)
 return truncated%(SIN_MASK+1)
end
local function sin_table_value(index)
 local value=SIN_CACHE[index]
 if value==nil then value=float32(math.sin(index/SIN_SCALE)); SIN_CACHE[index]=value end
 return value
end
function MC.Mth.sin(angle) return sin_table_value(sin_index(angle,0)) end
function MC.Mth.cos(angle) return sin_table_value(sin_index(angle,16384.0)) end
function MC.Mth.sqrt(value) return float32(math.sqrt(value)) end
function MC.Mth.rotLerpRad(alpha,from_angle,to_angle)
 local diff=float32(float32(to_angle)-float32(from_angle))
 local negative_pi=float32(-math.pi); local pi=float32(math.pi); local two_pi=float32(math.pi*2)
 while diff<negative_pi do diff=float32(diff+two_pi) end
 while diff>=pi do diff=float32(diff-two_pi) end
 return float32(float32(from_angle)+float32(float32(alpha)*diff))
end
-- Exact Util.getRandom(List<T>, RandomSource) adapter used by PlayerModel.
function MC.Util.getRandom(list,random)
 assert(type(list)=="table","Util.getRandom expects a list table")
 assert(type(random)=="table" and type(random.nextInt)=="function",
  "Util.getRandom expects a RandomSource adapter with nextInt(bound)")
 local size
 if type(list.size)=="function" then size=list:size() else size=#list end
 if size<=0 then error("bound must be positive",2) end
 local index=random:nextInt(size)
 assert(type(index)=="number" and index%1==0 and index>=0 and index<size,
  "RandomSource.nextInt returned an out-of-range index")
 if type(list.get)=="function" then return list:get(index) end
 return list[index+1]
end
return MC
