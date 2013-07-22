#ATTRIBUTES FOR MWS ITEM

# "order_item_id": "",
# "gift_wrap_price": {
#   "amount": "0.00",
#   "currency_code": "USD"
# },
# "quantity_ordered": "1",
# "gift_wrap_tax": {
#   "amount": "0.00",
#   "currency_code": "USD"
# },
# "seller_sku": "",
# "title": "",
# "shipping_tax": {
#   "amount": "0.00",
#   "currency_code": "USD"
# },
# "shipping_price": {
#   "amount": "0.00",
#   "currency_code": "USD"
# },
# "item_tax": {
#   "amount": "0.00",
#   "currency_code": "USD"
# },
# "item_price": {
#   "amount": "40.00",
#   "currency_code": "USD"
# },
# "promotion_discount": {
#   "amount": "0.00",
#   "currency_code": "USD"
# },
# "asin": "",
# "condition_id": "New",
# "quantity_shipped": "1",
# "condition_subtype_id": "New",
# "shipping_discount": {
#   "amount": "0.00",
#   "currency_code": "USD"
# }

class Item

  def initialize(item_hash)
    @name = item_hash.title
    @price = item_hash.item_price.amount
    @sku = item_hash.seller_sku
    @quantity = item_hash.quantity_ordered
  end
end