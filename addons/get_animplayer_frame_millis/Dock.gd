tool

extends Control

signal button_pressed(anim_name)

var Anim : AnimationPlayer

var selected_anim : String

func _enter_tree() -> void:
	$VBoxContainer/HBoxContainer2/BtnCopyFramesData.disabled = true

func update_anim_list() -> void:
	
	if is_valid_animplayer() == false:
		return
	
	$VBoxContainer/LblAnimationName.text = "Current AnimPlayer: %s" %[Anim.name]
	
	var anim_list = Anim.get_animation_list()

	## limpiar lista de animaciones
	$VBoxContainer/OptionButtonAnimList.clear()
	## y la lista de tracks
	$VBoxContainer/OptionButtonTracksList.clear()
	## desactivar boton de copiar framedata
	$VBoxContainer/HBoxContainer2/BtnCopyFramesData.disabled = true
	## limpiar lista de botones de los frames
	for b in $VBoxContainer/ScrollContainer/HFlowContainerFrames.get_children():
		b.queue_free()
	
	## añadir item inicial y los de las animaciones exceptuando el reset
	$VBoxContainer/OptionButtonAnimList.add_item("- - -", 0)
	var i : int = 1
	for anim in anim_list:
		if anim != "RESET":
			$VBoxContainer/OptionButtonAnimList.add_item(anim, i)
		i += 1

func is_valid_animplayer() -> bool:
	var anim_valid : bool = is_instance_valid(Anim)
	if anim_valid == false:
		$VBoxContainer/LblAnimationName.text = "AnimPlayer Invalid!"
	return anim_valid

func _on_OptionButtonAnimList_item_selected(index: int) -> void:
	
	if is_valid_animplayer() == false:
		return
	
	$VBoxContainer/HBoxContainer2/LblAnimTotalTime.text = "Time: 00ms"
	
	## limpiar lista de tracks
	$VBoxContainer/OptionButtonTracksList.clear()
	## desactivar boton de copiar framedata
	$VBoxContainer/HBoxContainer2/BtnCopyFramesData.disabled = true

	if index < 1:
		## limpiar lista de botones de los frames
		for b in $VBoxContainer/ScrollContainer/HFlowContainerFrames.get_children():
			b.queue_free()
		return
	
	selected_anim = $VBoxContainer/OptionButtonAnimList.get_item_text(index)

	var AnimationObj : Animation = Anim.get_animation(
		selected_anim
	)
	
	## mostrar total de la linea de tiempo en milisegundos o segundos
	if AnimationObj.length >= 1.0:
		$VBoxContainer/HBoxContainer2/LblAnimTotalTime.text = "Time: %.2fs" % [AnimationObj.length]
	else:
		$VBoxContainer/HBoxContainer2/LblAnimTotalTime.text = "Time: %dms" % [int(AnimationObj.length*1000)]

	## recorrer tracks
	var i : int = 0
	for track_idx in range(AnimationObj.get_track_count()):
		## si el track es del tipo TrackType.TYPE_VALUE
		if AnimationObj.track_get_type(track_idx) == 0:
			## obtener path del track por ejemplo Sprite:frame
			var track_path : String = AnimationObj.track_get_path(track_idx)
			## obtener tracks que son de frames de animacions
			if track_path.ends_with(":frame") == true:
				$VBoxContainer/OptionButtonTracksList.add_item(
					track_path, track_idx
				)
				## emitir señal ya que no se hace automaticamente si es el primero de la lista
				if i == 0:
					_on_OptionButtonTracksList_item_selected(i)
				i += 1

func _on_OptionButtonTracksList_item_selected(index: int) -> void:
	
	## TODO Mejorar codigo... es un lío obtener la duracion del frame en diferentes situaciones
	## (que es el unico frame, que el frame no inicia en el 0 del timeline, que no haya frames por delante, por detras...) 
	## TODO tambien podria hacer la multiplicacion *1000 al final
	
	if is_valid_animplayer() == false:
		return
	
	var track_idx : int = $VBoxContainer/OptionButtonTracksList.get_item_id(index)

	var AnimationObj : Animation = Anim.get_animation(
		selected_anim
	)
	
	var track_keys_times : Array
	var track_keys_frame_numbers : Array

	## limpiar lista de botones de los frames
	for b in $VBoxContainer/ScrollContainer/HFlowContainerFrames.get_children():
		b.queue_free()
	## desactivar boton de copiar framedata
	$VBoxContainer/HBoxContainer2/BtnCopyFramesData.disabled = true
	
	## recorrer las keys del track segun su idx
	for track_key_idx in range(AnimationObj.track_get_key_count(track_idx)):
		## obtener el time del key frame
		track_keys_times.append(
			AnimationObj.track_get_key_time(track_idx, track_key_idx)
		)
		track_keys_frame_numbers.append(
			AnimationObj.track_get_key_value(track_idx, track_key_idx)
		)
		

	var i : int = 0
	for key_time in track_keys_times:
		var millis : int = 0
		
		## el primer frame
		if i == 0:
			## si el key inicia justo en el 0
			if key_time == 0:
				## si hay otro frame adelante, sumarlo
				if track_keys_times.size() > 1:
					millis = int(
						(key_time*1000) + (track_keys_times[i+1]*1000)
					)
				## si es el unico, entonces, su millis es la duracion del timeline
				else:
					millis = AnimationObj.length * 1000
			## frame 0 ademas de no inciar en el 0 del timeline
			else:
				## si hay otro frame adelante, restar ese frame con el frame 0
				if track_keys_times.size() > 1:
					millis = int(
						(track_keys_times[i+1]*1000) - (key_time*1000)
					)
				## frame 0 que no inicia en el 0 del timeline, no hay mas frames. usar animation.length
				else:
					millis = int(
						(AnimationObj.length*1000) - (key_time*1000)
					)
		
		## los demas frames
		else:
			## obtener el tiempo del anterior frame
			var prev_time : int = track_keys_times[i-1]*1000
			
			## si el anterior frame tenia 0 y hay un frame adelante, usar ese
			if prev_time == 0 and track_keys_times.size() > 2:
				millis = int(
					track_keys_times[i+1]*1000 - (key_time*1000)
				)
			## si el anterior frame tenia 0 y no hay mas frames, usar el animation.length
			elif prev_time == 0:
				millis = int(
					(AnimationObj.length*1000) - (key_time*1000)
				)
			## frames despues del primero que tengan frames por delante
			else:
				## si es el ultimo frame
				if i == track_keys_times.size()-1:
					millis = int(
						(AnimationObj.length*1000) - (key_time*1000)
					)
				else:
					millis = int(
						(track_keys_times[i+1]*1000) - (key_time*1000)
					)
		## sumar si numero termina en 99
		if str(millis).ends_with("9"):
			millis += 1

		## añadir boton de frame con el i como frame idx y el millis
		## (representa cuantos milisegundos debe durar)
		var Btn = Button.new()
		Btn.text = "Frame %d : %d ms" % [track_keys_frame_numbers[i], millis]
		Btn.size_flags_horizontal = 3
		## conectar señal
		Btn.connect("pressed", self, "_on_BtnFrame_pressed", [millis])
		$VBoxContainer/ScrollContainer/HFlowContainerFrames.add_child(Btn)
		
		i += 1

	## activar boton de copiar dataframe si es necesario
	if $VBoxContainer/ScrollContainer/HFlowContainerFrames.get_child_count() > 0:
		$VBoxContainer/HBoxContainer2/BtnCopyFramesData.disabled = false

func _on_BtnFrame_pressed(ms:int) -> void:
	OS.set_clipboard(str(ms))

func _on_BtnCopyFramesData_pressed() -> void:
	var txt : String
	## recorrer botones de frames
	for b in $VBoxContainer/ScrollContainer/HFlowContainerFrames.get_children():
		txt += "%s \n" % [b.text]
	OS.set_clipboard(txt)
