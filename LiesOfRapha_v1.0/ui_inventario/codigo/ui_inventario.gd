extends Control

@onready var grid_container: GridContainer = $PanelContainer/GridContainer

var mochila:Mochila 

# Función para agregar un ítem a la interfaz del inventario.
# Esta lógica primero intenta apilar el ítem en un slot existente. Si no es posible, lo coloca en un slot vacío.
func agregar_item_a_mochila(item_a_agregar:Item) -> void:
	# Bandera para saber si el ítem se apiló con éxito.
	var se_apilo = false
	# Si el ítem es apilable, recorre los slots del inventario para ver si puede apilarse.
	if item_a_agregar.apilable:
		# Recorre cada slot hijo del 'GridContainer'.
		for i in range(grid_container.get_child_count()):
			var slot = grid_container.get_child(i)
			var item_en_slot = slot.item_data
# Comprueba si el slot tiene un ítem, si es el mismo tipo y si no ha alcanzado la cantidad máxima.
			if item_a_agregar is Item:
				if item_en_slot and item_en_slot.nombre == item_a_agregar.nombre  and item_en_slot.cantidad < item_en_slot.max_cantidad:
			# Incrementa la cantidad del ítem en el slot.
					item_en_slot.cantidad += 1
			# Llama a la función de la mochila para que la lógica de datos también lo registre.		
					mochila.agregar_item(item_a_agregar)
			# Actualiza la UI del slot para reflejar el cambio.
					slot.llenar_espacio(item_en_slot)
			# Marca la bandera como 'true' y sale del bucle.
					se_apilo = true
					break
# Si el ítem no se apiló (es un ítem no apilable o no encontró un slot compatible).	
	if not se_apilo:
# Busca un slot vacío para colocar el nuevo ítem.
		var slot_vacio = buscar_slot_vacio()
		# Si se encuentra un slot vacío.
		if slot_vacio:
			# Primero, agrega el ítem al recurso de la mochila para que se registre en los datos.
			mochila.agregar_item(item_a_agregar)
			# Opcional: una forma alternativa de encontrar slots vacíos.
			var nuevos_slots = grid_container.get_children().filter(func(child): return child.item_data == null)
		# Si la lista de slots vacíos no está vacía, llena el primer slot disponible.
			if nuevos_slots:
				nuevos_slots[0].llenar_espacio(item_a_agregar)

# Función que busca el primer slot vacío en el inventario.
# Retorna la referencia al nodo del slot si lo encuentra, o 'null' si todos están ocupados.
func buscar_slot_vacio() -> Control:
	# Recorre cada slot en el 'GridContainer'.
	for slot in grid_container.get_children():
		# Si el slot no tiene datos de ítem (es decir, 'item_data' es 'null'), lo retorna.
		if not slot.item_data:
			return slot
	# Si el bucle termina y no se encontró un slot vacío, retorna 'null'.
	return null
