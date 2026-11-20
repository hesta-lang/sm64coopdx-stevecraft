import math, struct, subprocess, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
JAVA=ROOT/"tools"/"Minecraft263Reference.java"
OUT=ROOT/"build"/"java-reference.txt"
SCALE=10430.378350470453
def f32(x): return struct.unpack(">f",struct.pack(">f",float(x)))[0]
def expected_sin(angle,offset=0.0):
 index=int(angle*SCALE+offset)&65535
 return f32(math.sin(index/SCALE))
def expected_rot(alpha,from_angle,to_angle):
 diff=f32(f32(to_angle)-f32(from_angle)); npi=f32(-math.pi); pi=f32(math.pi); two=f32(math.pi*2)
 while diff<npi: diff=f32(diff+two)
 while diff>=pi: diff=f32(diff-two)
 return f32(f32(from_angle)+f32(f32(alpha)*diff))
class Minecraft263EquivalenceTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  with tempfile.TemporaryDirectory() as tmp:
   subprocess.run(["javac","-d",tmp,str(JAVA)],check=True,capture_output=True,text=True)
   run=subprocess.run(["java","-cp",tmp,"Minecraft263Reference"],check=True,capture_output=True,text=True)
  OUT.parent.mkdir(parents=True,exist_ok=True); OUT.write_text(run.stdout)
  cls.ref=dict(line.split("=",1) for line in run.stdout.splitlines())
 def close(self,key,value,eps=1e-6):
  actual=float(self.ref[key]); self.assertLessEqual(abs(actual-value),eps,f"{key}: Java={actual}, expected={value}")
 def test_sine_cosine_lookup_table(self):
  for i,a in enumerate([0.0,math.pi/2,-math.pi/2,1.23456789,123.456789]):
   self.close(f"sin.{i}",expected_sin(a)); self.close(f"cos.{i}",expected_sin(a,16384.0))
 def test_float_sqrt_and_rot_lerp(self):
  for i,x in enumerate([0.25,2.0,9.0]): self.close(f"sqrt.{i}",f32(math.sqrt(f32(x))))
  for i,args in enumerate([(0.5,3.0,-3.0),(1.0,0.0,7.0),(0.25,-2.9,2.9)]): self.close(f"rot.{i}",expected_rot(*args))
 def test_quadratic_helper_and_random_list_selection(self):
  for i,raw in enumerate([-2.0,0.0,0.3,1.0,5.0]):
   x=f32(raw); expected=f32(f32(f32(-65.0)*x)+f32(x*x)); self.close(f"quadratic.{i}",expected,1e-5)
  parts=["head","body","leftArm","rightArm","leftLeg","rightLeg"]
  for i,index in enumerate([0,3,5]): self.assertEqual(self.ref[f"random.{i}"],parts[index])
 def test_float_clamp_overload_inverted_bounds(self):
  for i,value in enumerate([6.0,3.0,4.0]): self.close(f"clamp.{i}",value)
if __name__=="__main__": unittest.main()
