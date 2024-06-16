module cafeteria::cafeteria {

    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{TxContext, sender};
    use sui::table::{Self, Table};

    use std::string::{Self, String};

    // Error section
    const ERR_INSUFFICIENT_BALANCE: u64 = 1;
    const ERR_ORDER_ALREADY_PAID: u64 = 0;


    // User struct to hold user details
    struct User has key, store {
        id: UID,
        name: String,
        balance: Balance<SUI>,
        loyalty_points: u64,
    }

    // Menu item struct
    struct MenuItem has key, store {
        id: UID,
        name: String,
        price: u64,
    }

      // Order struct
    struct Orders has key, store {
        id: UID,
        items: Table<address, MenuItem>,
        balance: Balance<SUI>
    }

    struct AdminCap has key {id: UID}

    fun init(ctx:&mut TxContext) {
        transfer::transfer(AdminCap{id: object::new(ctx)}, sender(ctx));
        // share the order object        
        transfer::share_object(Orders{
            id: object::new(ctx),
            items: table::new(ctx),
            balance:balance::zero()
        });
    }

     // Function to register a new user
    public fun register_user(
        name: String,
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
    public fun get_user_details(user: &User): (String, &Balance<SUI>, u64) {
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
        name: String,
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
        self: &mut Orders,
        user: &mut User,
        menu: MenuItem,
        ctx: &mut TxContext,
    ) {
        let balance_ = balance::split(&mut user.balance, menu.price);
        let amount = balance::join(&mut self.balance, balance_);
        // add menu to table
        table::add(&mut self.items, sender(ctx), menu);
    }

    
    // // Function to get order details
    // public fun get_order_details(order: &Order): (&ID, &vector<MenuItem>, u64, bool, u64) {
    //     (&order.user, &order.items, order.total_price, order.is_paid, order.discount)
    // }

    // // Function to process payment for an order using balance
    // public fun process_payment_with_balance(
    //     user: &mut User,
    //     order: &mut Order,
    //     reciepient: address,
    //     ctx : &mut TxContext,
    // ) {
    //     assert!(!order.is_paid, ERR_ORDER_ALREADY_PAID);
    //     assert!(balance::value(&user.balance) >= order.total_price, ERR_INSUFFICIENT_BALANCE);

    //     let total_pay = coin::take(&mut user.balance, order.total_price,ctx);
    //     transfer::public_transfer(total_pay, reciepient);
    //     order.is_paid = true;

    //     // Add loyalty points
    //     let points = order.total_price / 10;
    //     add_loyalty_points(user, points);
    // }


    // // Function to process payment for an order using loyalty points
    // public fun process_payment_with_loyalty_points(
    //     user: &mut User,
    //     order: &mut Order,
    //     reciepient: address,
    //     ctx : &mut TxContext,
    // ) {
    //     assert!(!order.is_paid, ERR_ORDER_ALREADY_PAID);
    //     assert!(user.loyalty_points >= order.total_price, ERR_INSUFFICIENT_BALANCE);

    //     user.loyalty_points = user.loyalty_points - order.total_price;
    //     order.is_paid = true;
        
    //     let loyalty_points_pay = coin::take(&mut user.balance, user.loyalty_points,ctx);
    //     transfer::public_transfer(loyalty_points_pay, reciepient);
    // }

    //  // Function to apply a discount to an order
    // public fun apply_discount(order: &mut Order, discount: u64) {
    //     order.discount = discount;
    //     order.total_price = order.total_price - discount;
    // }

    //  // Function to handle partial payments
    // public fun process_partial_payment(
    //     user: &mut User,
    //     order: &mut Order,
    //     reciepient: address,
    //     ctx : &mut TxContext,
    //     amount: u64,
    // ) {
    //     assert!(!order.is_paid, ERR_ORDER_ALREADY_PAID);
    //     assert!(balance::value(&user.balance) >= amount, ERR_INSUFFICIENT_BALANCE);

    //     let pay_amount = coin::take(&mut user.balance, amount, ctx);

    //     let paid: u64 = coin::value(&pay_amount);
    //     order.total_price = order.total_price - paid;

    //     if (order.total_price == 0) {
    //         order.is_paid = true;

    //         // Add loyalty points
    //         let points = amount / 10;
    //         add_loyalty_points(user, points);
    //     };
    //     transfer::public_transfer(pay_amount,reciepient);
    // } 
}
