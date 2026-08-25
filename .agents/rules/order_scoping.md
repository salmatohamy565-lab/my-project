# Order Isolation and Scoping Rule (عزل وتخصيص طلبات العملاء)

## Strict Rules for Customer Orders vs. Admin Orders

1. **Customer Order Scoping (تخصيص الطلبات لليوزر):**
   - Every customer user MUST see ONLY their own requested orders (`_isOrderBelongingToUser` / `isBelongingToCurrentUser`).
   - Customer orders must NEVER be mixed with other users' orders under any circumstance.
   - Match criteria for customer orders:
     - `user_id` matching `currentUser.id`
     - OR `customer_phone` / `sender_info` matching `currentUser.phone`
     - OR `customer_name` matching `currentUser.displayName` / `username`.

2. **Admin Order Scoping (عرض جميع الطلبات للأدمن والموظفين):**
   - When the logged-in user is an Admin or Employee (`isAdmin == true || isEmployee == true`), ALL orders across all users MUST be displayed in full detail.
   - Admin views (`AdminOrdersScreen`, `EmployeeDashboard`, `ProfileScreen` for staff) must show:
     - Customer name (`customer_name`)
     - Customer phone (`customer_phone`)
     - Delivery address / notes (`customer_address` / `sender_info`)
     - Complete item list & images (`items_summary` / `items_details`)
     - Total price (`total_price`)
     - Payment method (`payment_method`)
     - Uploaded payment receipt proof image (`payment_proof_url`)
     - Action buttons (Approve, Reject, Change Status).

3. **Database Schema Enforcement (Supabase `public.orders`):**
   - Always write `user_id`, `customer_name`, `customer_phone`, `product_ids`, `items_summary`, `total_price`, `payment_method`, `payment_proof_url`, `customer_address`, `sender_info`, and `status` to `public.orders`.
