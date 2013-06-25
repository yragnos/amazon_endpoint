class AmazonClient

  def initialize(config, message_id)
    @client = MWS.new(aws_access_key_id: config['aws_access_key'], 
                      secret_access_key: config['secret_key'],
                      seller_id:         config['seller_id'], 
                      marketplace_id:    config['marketplace_id'])
    @base_response = { message_id: message_id }
    @config = config
  end

  def get_orders
    response = @base_response
    order_list = @client.orders.list_orders(created_after: @config['last_created_after'])

    if order_list.orders.nil?
      response
    elsif order_list.orders.first.is_a? Array
      response.merge(assemble_single_order(order_list))
    else
      response.merge(assemble_multiple_orders(order_list))
    end
  end

  def assemble_single_order(order)
    messages_hash = { messages: [] }
    messages_hash[:messages] << build_order_hash(order.orders)

    item_response = @client.orders.list_order_items(amazon_order_id: order.orders.amazon_order_id)

    item_response.order_items.each do |item|
        messages_hash[:messages][0][:payload][:order][:line_items] << build_item_hash(item)   
      end

    messages_hash[:parameters] = [{ name: 'last_created_after', value: order.orders.last_update_date }]
    messages_hash
  end

  def assemble_multiple_orders(order_list)
    messages_hash = { messages: [] }
    last_updated_at = order_list.orders.last.last_update_date

    order_list.orders.each_with_index do |order, index|
      messages_hash[:messages] << build_order_hash(order)

      item_response = @client.orders.list_order_items(amazon_order_id: order.amazon_order_id)
        
      item_response.order_items.each do |item|
        messages_hash[:messages][index][:payload][:order][:line_items] << build_item_hash(item)   
      end
    end

    messages_hash[:parameters] = [{ name: 'last_created_after', value: last_updated_at }]
    messages_hash
  end

  def build_order_hash(order)
    order.shipping_address
    { message: 'spree:import:order', 
      payload: 
        { order: 
          { amazon_order_id: order.amazon_order_id, 
            email: order.buyer_email, 
            line_items: [], 
            shipping_address: {
              firstname: order.shipping_address.name.split(' ').first,
              lastname: order.shipping_address.name.split(' ').last,
              address1: order.shipping_address.address_line1,
              city: order.shipping_address.city,
              zipcode: order.shipping_address.postal_code,
              phone: order.shipping_address.phone,
              country: { iso: order.shipping_address.country_code },
              state: { name: order.shipping_address.state_or_region }},
            shipping_method: { name: order.shipment_service_level_category }}}}
  end

  def build_item_hash(item)
    { name: item.title, 
      price: item.item_price.amount, 
      sku: item.seller_sku, 
      quantity: item.quantity_shipped }
  end
end