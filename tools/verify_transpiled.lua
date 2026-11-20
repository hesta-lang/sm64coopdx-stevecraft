package.path="build/transpiled/?.lua;build/transpiled-real/?.lua;"..package.path
local PlayerMath=require("net/minecraft/demo/PlayerMath")
local PlayerEntry=require("net/minecraft/demo/PlayerEntry")
local HumanoidModel=require("net/minecraft/client/model/HumanoidModel")
local PlayerModel=require("net/minecraft/client/model/player/PlayerModel")
local RealMth=require("net/minecraft/util/Mth")
local MC=require("mc_compat");local Mth=MC.Mth
assert(PlayerMath.LIMIT==8.0);assert(math.abs(PlayerMath.step(4.0)-6.5)<0.000001)
assert(PlayerMath.squareRoot(9.0)==3.0);assert(PlayerMath.isNotZero(1)==true and PlayerMath.isNotZero(0)==false)
assert(PlayerEntry.calculate(4.0)==8.0)
local expected={}
for line in io.lines("build/java-reference.txt") do local key,value=line:match("^([^=]+)=(.+)$");if key then expected[key]=value end end
local realExpected={}
for line in io.lines("build/java-real-source-reference.txt") do local key,value=line:match("^([^=]+)=(.+)$");if key then realExpected[key]=value end end
local modelExpected={}
for line in io.lines("build/java-model-reference.txt") do local key,value=line:match("^([^=]+)=(.+)$");if key then modelExpected[key]=value end end
local function close(actual,reference,epsilon) assert(math.abs(actual-reference)<=epsilon,("numeric mismatch: actual=%s reference=%s"):format(actual,reference)) end
local angles={0.0,math.pi/2,-math.pi/2,1.23456789,123.456789}
for i=1,#angles do close(Mth.sin(angles[i]),tonumber(expected["sin."..(i-1)]),1e-6);close(Mth.cos(angles[i]),tonumber(expected["cos."..(i-1)]),1e-6) end
local roots={0.25,2.0,9.0};for i=1,#roots do close(Mth.sqrt(roots[i]),tonumber(expected["sqrt."..(i-1)]),1e-6) end
local rotations={{0.5,3.0,-3.0},{1.0,0.0,7.0},{0.25,-2.9,2.9}};for i,args in ipairs(rotations) do close(Mth.rotLerpRad(args[1],args[2],args[3]),tonumber(expected["rot."..(i-1)]),1e-6) end
local xs={-2.0,0.0,0.3,1.0,5.0};for i,x in ipairs(xs) do close(HumanoidModel.quadraticArmUpdate({},MC.java_float(x)),tonumber(modelExpected["model.quadratic."..(i-1)]),1e-5) end
local head={id="head"};assert(HumanoidModel.getHead({head=head}).id==modelExpected["model.head"])
local leftArm={id="leftArm"};local rightArm={id="rightArm"};local humanoid={head=head,leftArm=leftArm,rightArm=rightArm}
assert(HumanoidModel.getArm(humanoid,MC.HumanoidArm.LEFT).id==modelExpected["model.arm.left"]);assert(HumanoidModel.getArm(humanoid,MC.HumanoidArm.RIGHT).id==modelExpected["model.arm.right"])
local parts={{id="head"},{id="body"},{id="leftArm"},{id="rightArm"},{id="leftLeg"},{id="rightLeg"}};local indexes={0,3,5};local random={calls=0}
function random:nextInt(bound) assert(bound==#parts);self.calls=self.calls+1;return indexes[self.calls] end
local player={bodyParts=parts};for i=1,#indexes do assert(PlayerModel.getRandomBodyPart(player,random).id==modelExpected["model.random."..(i-1)]) end
local javaList={items={"alpha","beta"}};function javaList:size() return #self.items end;function javaList:get(index) return self.items[index+1] end
local fixed={};function fixed:nextInt(bound) assert(bound==2);return 1 end
assert(MC.Util.getRandom(javaList,fixed)=="beta");assert(not pcall(MC.Util.getRandom,{},fixed))
assert(Mth.clamp(5,0,4)==4 and Mth.clamp(5,6,3)==6 and Mth.clamp(7,6,3)==3);assert(Mth.lerp(0.5,2,6)==4)
assert(Mth.sign(-4)==-1 and Mth.sign(0)==0 and Mth.sign(4)==1 and Mth.sign(0/0)==-1)
assert(Mth.wrapDegrees(190)==-170 and Mth.wrapDegrees(-190)==170);assert(Mth.degreesDifference(350,10)==20 and Mth.degreesDifferenceAbs(350,10)==20)
assert(Mth.rotateIfNecessary(0,90,30)==60);assert(Mth.approach(2,10,3)==5 and Mth.approach(10,2,3)==7)
assert(Mth.approachDegrees(350,10,5)==355);assert(Mth.positiveModulo(-3,2)==1 and Mth.frac(-1.25)==0.75)
assert(Mth.square(3)==9 and Mth.cube(3)==27 and Mth.equal(1.0,1.000001))
assert(Mth.clampedLerp(-1,3,7)==3 and Mth.clampedLerp(2,3,7)==7 and Mth.clampedLerp(0.5,3,7)==5)
local function real_close(key,value,epsilon) close(value,tonumber(realExpected[key]),epsilon or 1e-12) end
real_close("clamp.normal",RealMth.clamp(2.0,0.0,4.0));real_close("clamp.inverted",RealMth.clamp(5.0,6.0,3.0));real_close("clamp.inverted.high",RealMth.clamp(7.0,6.0,3.0));real_close("lerp",RealMth.lerp(0.25,2.0,6.0))
real_close("clampedLerp.low",RealMth.clampedLerp(-1.0,3.0,7.0));real_close("clampedLerp.middle",RealMth.clampedLerp(0.5,3.0,7.0));real_close("clampedLerp.high",RealMth.clampedLerp(2.0,3.0,7.0))
real_close("absMax",RealMth.absMax(-7.0,3.0));real_close("square",RealMth.square(-3.0));real_close("inverseLerp",RealMth.inverseLerp(5.0,0.0,10.0))
real_close("clampedMap",RealMth.clampedMap(15.0,0.0,10.0,20.0,40.0));real_close("map",RealMth.map(15.0,0.0,10.0,20.0,40.0))
real_close("lengthSquared3",RealMth.lengthSquared(2.0,3.0,6.0));real_close("length3",RealMth.length(2.0,3.0,6.0))
real_close("cube.negative",RealMth.cube(-2.0));real_close("cube.positive",RealMth.cube(3.0));real_close("frac.negative",RealMth.frac(-1.25));real_close("frac.positive",RealMth.frac(2.25))
real_close("approach.up",RealMth.approach(2.0,10.0,3.0));real_close("approach.down",RealMth.approach(10.0,2.0,3.0));real_close("approach.reach",RealMth.approach(2.0,4.0,10.0))
assert(RealMth.sign(-4.0)==tonumber(realExpected["sign.negative"]));assert(RealMth.sign(-0.0)==tonumber(realExpected["sign.zero"]));assert(RealMth.sign(0/0)==tonumber(realExpected["sign.nan"]))
assert(RealMth.equal(1.0,1.000001)==(realExpected["equal.near"]=="true"));assert(RealMth.equal(1.0,1.00002)==(realExpected["equal.far"]=="true"))
print("Minecraft 26.3 selected Java excerpts and Mth/Util equivalence checks passed")
