from pathlib import Path
import os, json, shutil, importlib.util
root=Path("E:/VNB/game")
project=root/".godot/verification/20261023T122205Z-e74c5c74/project"
out=Path("E:/VNB/temp/finale-handbook-20261023/ending-gpu-final")
out.mkdir(parents=True,exist_ok=False)
custom="FinaleCinematicGpuChecks/ending-gpu-final"
profile=out/"runtime"/custom
profile.mkdir(parents=True)
(profile/"presentation.cfg").write_text('[audio]\nenabled=false\nvolume=0.0\n[ambience]\nenabled=false\nvolume=0.0\n[window]\nfullscreen=false\n',encoding="utf-8")
for name in ["ending_probe.gd","ending_probe.tscn"]:
 shutil.copy2(root/"docs/verification/20261023-finale-handbook/gpu-probe"/name,project/name)
original=(project/"project.godot").read_bytes()
settings=(root/"project.godot").read_text(encoding="utf-8").replace('[application]\n','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='+json.dumps(custom)+'\n',1)
spec=importlib.util.spec_from_file_location("verify",root/"scripts/verify-project.py"); mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
env=dict(os.environ,APPDATA=str(out/"runtime"),LOCALAPPDATA=str(out/"runtime"),TEMP="E:/VNB/temp",TMP="E:/VNB/temp")
try:
 (project/"project.godot").write_text(settings,encoding="utf-8")
 code=mod.run_logged_process(["E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe","--path",str(project),"--rendering-method","gl_compatibility","--windowed","--resolution","1280x720","res://ending_probe.tscn"],env,out/"probe.txt",50)
 print((out/"probe.txt").read_text(encoding="utf-8",errors="replace"))
 print("EXIT",code)
finally: (project/"project.godot").write_bytes(original)
raise SystemExit(code)
