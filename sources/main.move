module cafeteria::cafeteria {

    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{TxContext};

    // Error section
    const ERR_INSUFFICIENT_BALANCE: u64 = 1;
    const ERR_ORDER_ALREADY_PAID: u64 = 2;
    const ERR_INVALID_INPUT: u64 = 3;
    const ERR_UNAUTHORIZED: u64 = 4;

    // Roles
    const ROLE_USER: u8 = 1;
    const ROLE_ADMIN: u8 = 2;

    // Event struct for logging
    struct Event has key, store {
        id: UID,
        event_type: vector<u8>,
        details: vector<u8>,
        timestamp: u64,
    }

    // User struct to hold user details
    struct User has key, store {
        id: UID,
        name: vector<u8>,
        balance: Balance<SUI>,
        loyalty_points: u64,
        role: u8,
    }

    // Menu item struct
    struct MenuItem has key, store {
        id: UID,
        name: vector<u8>,
        price: u64,
    }

    // Order struct
    struct Order has key, store {
        id: UID,
        user: ID,
        items: vector<MenuItem>,
        total_price: u64,
        paid_amount: u64,
        is_paid: bool,
        discount: u64,
    }

    // Function to register a new user
    public fun register_user(
        name: vector<u8>,
        role: u8,
        ctx: &mut TxContext,
    ): User {
        validate_user_input(name, role);

        let user_id = object::new(ctx);
        let user = User {
            id: user_id,
            name,
            balance: balance::zero(),
            loyalty_points: 0,
            role,
        };

        log_event(b"User Registration", b"New user registered", ctx);
        user
    }

    // Function to get user details
    public fun get_user_details(user: &User): (vector<u8>, &Balance<SUI>, u64, u8) {
        (user.name, &user.balance, user.loyalty_points, user.role)
    }

    // Function to add balance to the user's account
    public fun add_balance(user: &mut User, amount: Coin<SUI>, ctx: &mut TxContext) {
        let balance_to_add = coin::into_balance(amount);
        balance::join(&mut user.balance, balance_to_add);

        log_event(b"Add Balance", b"Balance added to user account", ctx);
    }

    // Function to add loyalty points to the user's account
    public fun add_loyalty_points(user: &mut User, points: u64, ctx: &mut TxContext) {
        user.loyalty_points = user.loyalty_points + points;

        log_event(b"Add Loyalty Points", b"Loyalty points added to user account", ctx);
    }

    // Function to create a menu item
    public fun create_menu_item(
        name: vector<u8>,
        price: u64,
        ctx: &mut TxContext,
    ): MenuItem {
        assert!(name.size() > 0, ERR_INVALID_INPUT);
        assert!(price > 0, ERR_INVALID_INPUT);

        let menu_item_id = object::new(ctx);
        let item = MenuItem {
            id: menu_item_id,
            name,
            price,
        };

        log_event(b"Create Menu Item", b"New menu item created", ctx);
        item
    }

    // Function to place an order
    public fun place_order(
        user: &User,
        items: vector<MenuItem>,
        discount: u64,
        total_price: u64,
        ctx: &mut TxContext,
    ): Order {
        assert!(total_price > 0, ERR_INVALID_INPUT);

        let order_id = object::new(ctx);
        let order = Order {
            id: order_id,
            user: object::uid_to_inner(&user.id),
            items,
            total_price,
            paid_amount: 0,
            is_paid: false,
            discount,
        };

        log_event(b"Place Order", b"Order placed", ctx);
        order
    }

    // Function to get order details
    public fun get_order_details(order: &Order): (&ID, &vector<MenuItem>, u64, u64, bool, u64) {
        (&order.user, &order.items, order.total_price, order.paid_amount, order.is_paid, order.discount)
    }

    // Function to process payment for an order using balance
    public fun process_payment_with_balance(
        user: &mut User,
        order: &mut Order,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        assert!(!order.is_paid, ERR_ORDER_ALREADY_PAID);
        assert!(balance::value(&user.balance) >= order.total_price, ERR_INSUFFICIENT_BALANCE);

        let total_pay = coin::take(&mut user.balance, order.total_price, ctx);
        transfer::public_transfer(total_pay, recipient);
        order.is_paid = true;
        order.paid_amount = order.total_price;

        // Add loyalty points
        let points = convert_loyalty_points(order.total_price);
        add_loyalty_points(user, points, ctx);

        log_event(b"Payment", b"Order paid with balance", ctx);
    }

    // Function to process payment for an order using loyalty points
    public fun process_payment_with_loyalty_points(
        user: &mut User,
        order: &mut Order,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        assert!(!order.is_paid, ERR_ORDER_ALREADY_PAID);
        assert!(user.loyalty_points >= order.total_price, ERR_INSUFFICIENT_BALANCE);

        user.loyalty_points = user.loyalty_points - order.total_price;
        order.is_paid = true;
        order.paid_amount = order.total_price;

        let loyalty_points_pay = coin::take(&mut user.balance, user.loyalty_points, ctx);
        transfer::public_transfer(loyalty_points_pay, recipient);

        log_event(b"Payment", b"Order paid with loyalty points", ctx);
    }

    // Function to apply a discount to an order
    public fun apply_discount(order: &mut Order, discount: u64, ctx: &mut TxContext) {
        order.discount = discount;
        order.total_price = order.total_price - discount;

        log_event(b"Apply Discount", b"Discount applied to order", ctx);
    }

    // Function to handle partial payments
    public fun process_partial_payment(
        user: &mut User,
        order: &mut Order,
        recipient: address,
        ctx: &mut TxContext,
        amount: u64,
    ) {
        assert!(!order.is_paid, ERR_ORDER_ALREADY_PAID);
        assert!(balance::value(&user.balance) >= amount, ERR_INSUFFICIENT_BALANCE);

        let pay_amount = coin::take(&mut user.balance, amount, ctx);
        let paid: u64 = coin::value(&pay_amount);
        order.paid_amount = order.paid_amount + paid;

        if (order.paid_amount >= order.total_price) {
            order.is_paid = true;
            order.paid_amount = order.total_price;

            // Add loyalty points
            let points = convert_loyalty_points(order.total_price);
            add_loyalty_points(user, points, ctx);
        } else {
            order.total_price = order.total_price - paid;
        }

        transfer::public_transfer(pay_amount, recipient);

        log_event(b"Partial Payment", b"Partial payment processed", ctx);
    }

    // Role-based access control (RBAC) for function execution
    public fun ensure_admin(user: &User) {
        assert!(user.role == ROLE_ADMIN, ERR_UNAUTHORIZED);
    }

    // Validate user input
    public fun validate_user_input(name: vector<u8>, role: u8) {
        assert!(name.size() > 0, ERR_INVALID_INPUT);
        assert!(role == ROLE_USER || role == ROLE_ADMIN, ERR_INVALID_INPUT);
    }

    // Convert total price to loyalty points
    public fun convert_loyalty_points(total_price: u64): u64 {
        // Example conversion rate: 1 point per 10 units of price
        total_price / 10
    }

    // Event logging function
    public fun log_event(event_type: vector<u8>, details: vector<u8>, ctx: &mut TxContext) {
        let event_id = object::new(ctx);
        let event = Event {
            id: event_id,
            event_type,
            details,
            timestamp: ctx.timestamp(),
        };
    }
}
