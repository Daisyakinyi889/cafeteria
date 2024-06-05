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

    // User struct to hold user details
    struct User has key, store {
        id: UID,
        name: vector<u8>,
        balance: Balance<SUI>,
        loyalty_points: u64,
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
        is_paid: bool,
        discount: u64,
    }

    // Function to register a new user
    public fun register_user(
        name: vector<u8>,
        ctx: &mut TxContext,
    ): User {
        let user_id = object::new(ctx);
        let user = User {
            id: user_id,
            name,
            balance: balance::zero(),
            loyalty_points: 0,
        };
        user
    }

    // Function to get user details
    public fun get_user_details(user: &User): (vector<u8>, &Balance<SUI>, u64) {
        (user.name, &user.balance, user.loyalty_points)
    }

    // Function to add balance to the user's account
    public fun add_balance(user: &mut User, amount: Coin<SUI>) {
        let balance_to_add = coin::into_balance(amount);
        balance::join(&mut user.balance, balance_to_add);
    }

    // Function to add loyalty points to the user's account
    public fun add_loyalty_points(user: &mut User, points: u64) {
        user.loyalty_points = user.loyalty_points + points;
    }

    // Function to create a menu item
    public fun create_menu_item(
        name: vector<u8>,
        price: u64,
        ctx: &mut TxContext,
    ): MenuItem {
        let menu_item_id = object::new(ctx);
        let item = MenuItem {
            id: menu_item_id,
            name,
            price,
        };
        item
    }

    // Function to place an order
    public fun place_order(
        user: &mut User,
        items: vector<MenuItem>,
        discount: u64,
        total_price: u64,
        ctx: &mut TxContext,
    ): Order {
        let order_id = object::new(ctx);        
        let order = Order {
            id: order_id,
            user: object::uid_to_inner(&user.id),
            items,
            total_price,
            is_paid: false,
            discount,
        };
        order
    }

    // Function to get order details
    public fun get_order_details(order: &Order): (&ID, &vector<MenuItem>, u64, bool, u64) {
        (&order.user, &order.items, order.total_price, order.is_paid, order.discount)
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

        // Add loyalty points
        let points = order.total_price / 10;
        add_loyalty_points(user, points);
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
        
        let loyalty_points_pay = coin::take(&mut user.balance, user.loyalty_points, ctx);
        transfer::public_transfer(loyalty_points_pay, recipient);
    }

    // Function to apply a discount to an order
    public fun apply_discount(order: &mut Order, discount: u64) {
        order.discount = discount;
        order.total_price = order.total_price - discount;
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
        order.total_price = order.total_price - paid;

        if (order.total_price == 0) {
            order.is_paid = true;

            // Add loyalty points
            let points = amount / 10;
            add_loyalty_points(user, points);
        };
        transfer::public_transfer(pay_amount, recipient);
    }

    // Additional functionality

    // Function to list all users
    public fun list_all_users(ctx: &TxContext): vector<User> {
        let objects = object::list_all();
        let mut users = vector<User>::empty();
        for obj in objects {
            if (object::type(obj) == type_of<User>()) {
                let user: User = object::read(obj);
                users.push_back(user);
            }
        }
        users
    }

    // Function to list all menu items
    public fun list_all_menu_items(ctx: &TxContext): vector<MenuItem> {
        let objects = object::list_all();
        let mut items = vector<MenuItem>::empty();
        for obj in objects {
            if (object::type(obj) == type_of<MenuItem>()) {
                let item: MenuItem = object::read(obj);
                items.push_back(item);
            }
        }
        items
    }

    // Function to list all orders
    public fun list_all_orders(ctx: &TxContext): vector<Order> {
        let objects = object::list_all();
        let mut orders = vector<Order>::empty();
        for obj in objects {
            if (object::type(obj) == type_of<Order>()) {
                let order: Order = object::read(obj);
                orders.push_back(order);
            }
        }
        orders
    }

    // Function to fetch all orders for a user
    public fun get_user_orders(user: &User, ctx: &TxContext): vector<Order> {
        let objects = object::list_all();
        let mut orders = vector<Order>::empty();
        for obj in objects {
            if (object::type(obj) == type_of<Order>()) {
                let order: Order = object::read(obj);
                if (order.user == object::uid_to_inner(&user.id)) {
                    orders.push_back(order);
                }
            }
        }
        orders
    }
}
