class Order
  attr_accessor :line_items, :last_update_date

  def initialize(attr_hash)
    @line_items = []
    @attr_hash = attr_hash
    @order_total = attr_hash['order_total']['amount']
    @shipping_method = attr_hash['shipment_service_level_category']
    @last_update_date = attr_hash['last_update_date']
    @status = attr_hash['order_status']
    @shipping_total = 0.00
    @shipping_discount = 0.00
    @promotion_discount = 0.00
    @amazon_tax = 0.00
    @gift_wrap = 0.00
    @gift_wrap_tax = 0.00
    @items_total = 0.00
  end

  def to_message
    roll_up_item_values
    items_hash = assemble_line_items
    address_hash = assemble_address
    totals_hash = assemble_totals_hash
    adjustments_hash = assemble_adjustments_hash
    shipment_hash = assemble_shipment_hash(items_hash)

    { message: 'order:new',
      payload:
      { order:
        { amazon_order_id: @attr_hash['amazon_order_id'],
          channel: @attr_hash['sales_channel'],
          currency: @attr_hash['order_total']['currency_code'],
          status: @attr_hash['order_status'],
          placed_on: @attr_hash['purchase_date'],
          updated_at: @attr_hash['last_update_date'],
          email: @attr_hash['buyer_email'],
          totals: totals_hash,
          adjustments: adjustments_hash,
          line_items: items_hash,
          payments: [{
            amount: @order_total,
            payment_method: 'Amazon',
            status: 'complete'
          }],
          shipments: shipment_hash,
          shipments: shipment_hash,
          shipping_address: address_hash,
          billing_address: address_hash }}}
  end

  def assemble_line_items
    @line_items.collect { |item| item.to_h }
  end

  def assemble_address
    { firstname: @attr_hash['buyer_name'].split(' ').first,
      lastname: @attr_hash['buyer_name'].split(' ').last,
      address1: @attr_hash['shipping_address']['address_line1'],
      city: @attr_hash['shipping_address']['city'],
      zipcode: @attr_hash['shipping_address']['postal_code'],
      phone: @attr_hash['shipping_address']['phone'],
      country: @attr_hash['shipping_address']['country_code'],
      state: @attr_hash['shipping_address']['state_or_region'] }
  end

  def roll_up_item_values
    @line_items.each do |item|
      @shipping_total += item.shipping_price
      @shipping_discount += item.shipping_discount
      @promotion_discount += item.promotion_discount
      @amazon_tax += item.item_tax
      @gift_wrap += item.gift_wrap
      @gift_wrap_tax += item.gift_wrap_tax
      @items_total += item.price
    end
  end

  def assemble_totals_hash
    { item: @items_total,
      adjustment: @promotion_discount + @shipping_discount + @gift_wrap + @amazon_tax + @gift_wrap_tax,
      tax: @amazon_tax + @gift_wrap_tax,
      shipping: @shipping_total,
      order:  @order_total }
  end

  def assemble_adjustments_hash
    [{ name: 'Shipping Discount', value: @shipping_discount },
     { name: 'Promotion Discount', value: @promotion_discount },
     { name: 'Amazon Tax', value: @amazon_tax },
     { name: 'Gift Wrap Price', value: @gift_wrap },
     { name: 'Gift Wrap Tax', value: @gift_wrap_tax }]
  end

  def assemble_shipment_hash(line_items)
    [{ cost: @shipping_total,
       status: @status,
       shipping_method: @shipping_method,
       line_items: line_items }]
  end
end