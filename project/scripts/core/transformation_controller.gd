extends RefCounted
static func due(build,time:float) -> String:
 if time>=150 and build.form_branch=="":return "choice"
 if time>=330 and build.form_stage==1:return "second"
 return ""
static func choose(build,branch:String) -> bool:
 if build.form_branch!="" or branch not in ["kyubi","sage"]:return false
 build.form_branch=branch;return true
