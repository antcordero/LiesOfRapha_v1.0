extends Node

signal shop_changed
signal shop_message(text: String)

var bag: Bag = null

func setup(_bag: Bag, _unused_coins: int = 0) -> void:
	# _unused_coins ya no se usa: las monedas son el item "coin" del Bag
	bag = _bag
	print("SHOPS> setup OK | bag:", bag)

func buy_item(item_id: String, amount: int, cost_coins: int) -> bool:
	if bag == null:
		shop_message.emit("❌ bag es null (falta Shops.setup)")
		print("SHOPS> ERROR: bag == null")
		return false

	# ✅ Monedas = item "coin" dentro del inventario
	var have := bag.contar_item("coin")
	print("SHOPS> coins in bag:", have, "cost:", cost_coins)

	if have < cost_coins:
		shop_message.emit("❌ No tienes suficientes monedas")
		print("SHOPS> ERROR: coins insuficientes")
		return false

	# ✅ pagar: quitar coins del inventario
	var paid_ok := bag.consumir_item("coin", cost_coins)
	if not paid_ok:
		shop_message.emit("❌ Error al pagar (consumir_item falló)")
		print("SHOPS> ERROR: consumir_item falló")
		return false

	# ✅ dar el item
	for i in range(amount):
		bag.agregar_item(item_id)

	# guardar y refrescar UI
	bag.save_to_disk()
	shop_changed.emit()
	shop_message.emit("✅ Compra OK: +" + str(amount) + " " + item_id)
	return true

func buy_potion() -> bool:
	# 1 poción cuesta 10 coins
	return buy_item("potion", 1, 10)
