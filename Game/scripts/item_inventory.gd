extends RefCounted

static func take(state:Dictionary,id:int,item:ItemData)->bool:
	if state.taken.has(str(id)) or int(state.cargo.get(item.id,0))>=item.stack_size:return false
	state.taken[str(id)]=true
	state.seen[item.id]=true
	state.cargo[item.id]=int(state.cargo.get(item.id,0))+1
	return true

static func sale_value(cargo:Dictionary,items:Array[Resource])->int:
	var total:=0
	for item:ItemData in items:total+=int(cargo.get(item.id,0))*item.value
	return total
