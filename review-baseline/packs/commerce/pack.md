---
pack: commerce
agent: commerce-reviewer
escalate_in_qa_pass: false
---
Enable for: e-commerce, marketplaces, booking/ticketing, food delivery, anything with catalogue, cart, pricing, inventory and orders. Usually paired with the payments pack.

Route commerce-reviewer when the diff touches:
- paths/names containing: product, catalog, sku, variant, price, discount, coupon, promo, voucher, cart, checkout, order, inventory, stock, reservation, booking, shipping, fulfilment, return, tax
- pricing or promotion rules, inventory reservation, order state
