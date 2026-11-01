import '../models/diet_type.dart';
import '../models/shop_model.dart';
import '../models/item_model.dart';
import '../models/address_model.dart';
import '../models/offer_model.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';

class MockData {
  MockData._();

  static const UserModel currentUser = UserModel(
    id: 'usr_101',
    fullName: 'Aarav Sharma',
    mobileNumber: '+91 98765 43210',
    email: 'aarav.sharma@example.com',
    gender: 'Male',
    termsAccepted: true,
    isEmailVerified: true,
  );

  static const List<AddressModel> savedAddresses = [
    AddressModel(
      id: 'addr_1',
      title: 'Home',
      fullAddress: 'Flat 402, Lotus Orchid, 8th Main, Indiranagar',
      landmark: 'Near BDA Complex',
      pinCode: '560038',
      city: 'Bengaluru',
      state: 'Karnataka',
      type: AddressType.home,
      isDefault: true,
      isServiceable: true,
      isColdChainEligible: true,
      distanceKm: 2.1,
      contactName: 'Aarav Sharma',
      contactPhone: '+91 98765 43210',
    ),
    AddressModel(
      id: 'addr_2',
      title: 'Work',
      fullAddress: 'Tower B, 6th Floor, Cyber Tech Park, Whitefield',
      landmark: 'Opposite Metro Gate 3',
      pinCode: '560066',
      city: 'Bengaluru',
      state: 'Karnataka',
      type: AddressType.work,
      isDefault: false,
      isServiceable: true,
      isColdChainEligible: false, // Too far for delicate cold chain
      distanceKm: 9.8,
      contactName: 'Aarav Sharma',
      contactPhone: '+91 98765 43210',
    ),
    AddressModel(
      id: 'addr_3',
      title: 'Parents’ House',
      fullAddress: 'Villa 14, Green Meadows, Jayanagar 4th Block',
      landmark: 'Near Cosmopolitan Club',
      pinCode: '560011',
      city: 'Bengaluru',
      state: 'Karnataka',
      type: AddressType.other,
      isDefault: false,
      isServiceable: false, // Non-serviceable area for current pilot
      isColdChainEligible: false,
      distanceKm: 14.2,
      contactName: 'Ramesh Sharma',
      contactPhone: '+91 94480 12345',
    ),
  ];

  static const List<ShopModel> shops = [
    ShopModel(
      id: 'shop_anand',
      name: 'Anand Sweets & Purveyors',
      imageUrl: 'https://images.unsplash.com/photo-1599785209707-a456fc1337bb?w=800&q=80',
      rating: 4.8,
      ratingCount: 1420,
      distanceKm: 2.4,
      prepTimeMinutes: '20-25 min',
      status: ShopStatus.open,
      isVerified: true,
      fssaiLicense: '11221334000542',
      gstin: '29AAAAA0000A1Z5',
      address: 'Commercial Street, Tasker Town, Bengaluru',
      tags: ['Artisanal Mithai', 'Pure Ghee', 'Dry Fruit Treats'],
      supportsPreOrder: true,
      isSponsored: true,
    ),
    ShopModel(
      id: 'shop_milano',
      name: 'Milano Ice Cream & Gelateria',
      imageUrl: 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=800&q=80',
      rating: 4.7,
      ratingCount: 890,
      distanceKm: 3.1,
      prepTimeMinutes: '15-20 min',
      status: ShopStatus.open,
      isVerified: true,
      fssaiLicense: '11222334000981',
      gstin: '29BBBBB1111B2Z8',
      address: '12th Main Road, Indiranagar, Bengaluru',
      tags: ['Artisan Gelato', 'Kulfi Sundaes', 'Cold-Packed'],
      supportsPreOrder: true,
      isSponsored: false,
    ),
    ShopModel(
      id: 'shop_lavonne',
      name: 'Lavonne Patisserie & Bakery',
      imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80',
      rating: 4.9,
      ratingCount: 2100,
      distanceKm: 3.8,
      prepTimeMinutes: '35-45 min',
      status: ShopStatus.busy,
      isVerified: true,
      fssaiLicense: '11219334000311',
      gstin: '29CCCCC2222C3Z1',
      address: 'HAL 2nd Stage, Indiranagar, Bengaluru',
      tags: ['French Pastries', 'Custom Cakes', 'Fresh Breads'],
      supportsPreOrder: true,
      isSponsored: false,
    ),
    ShopModel(
      id: 'shop_kc_das',
      name: 'K.C. Das Grand Heritage',
      imageUrl: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800&q=80',
      rating: 4.6,
      ratingCount: 3400,
      distanceKm: 4.5,
      prepTimeMinutes: '20-30 min',
      status: ShopStatus.open,
      isVerified: true,
      fssaiLicense: '11218334000109',
      gstin: '29DDDDD3333D4Z4',
      address: 'St. Marks Road, Bengaluru',
      tags: ['Authentic Rasgulla', 'Sandesh', 'Mishti Doi'],
      supportsPreOrder: false,
      isSponsored: false,
    ),
    ShopModel(
      id: 'shop_polar_bear',
      name: 'Polar Bear Sundae Zone',
      imageUrl: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=800&q=80',
      rating: 4.4,
      ratingCount: 650,
      distanceKm: 1.8,
      prepTimeMinutes: '15-20 min',
      status: ShopStatus.closed,
      isVerified: true,
      fssaiLicense: '11220334000450',
      gstin: '29EEEEE4444E5Z7',
      address: '100ft Road, Indiranagar, Bengaluru',
      tags: ['Family Tubs', 'Ice Cream Cakes', 'Thick Shakes'],
      supportsPreOrder: true,
      isSponsored: false,
    ),
  ];

  static const List<ItemModel> allItems = [
    // 1. Royal Kaju Katli (Anand Sweets)
    ItemModel(
      id: 'item_kaju_katli',
      shopId: 'shop_anand',
      shopName: 'Anand Sweets & Purveyors',
      name: 'Royal Silver Kaju Katli',
      description: 'Handcrafted diamond cut cashew fudge made with premium Goan cashews and edible 24k silver vark.',
      imageUrl: 'https://images.unsplash.com/photo-1599785209707-a456fc1337bb?w=800&q=80',
      category: 'Sweets',
      dietType: DietType.veg,
      isPerishable: false,
      shelfLife: '15 days at room temperature',
      storageNote: 'Store in a cool dry place. Keep away from direct sunlight.',
      ingredients: ['Goan Cashew Nuts (68%)', 'Organic Cane Sugar', 'Cow Ghee', 'Cardamom', 'Silver Vark (E174)'],
      allergens: ['Contains Tree Nuts (Cashew)'],
      variants: [
        ItemVariant(id: 'v_250g', label: '250 g', price: 290, mrp: 320, isDefault: true),
        ItemVariant(id: 'v_500g', label: '500 g', price: 560, mrp: 620),
        ItemVariant(id: 'v_1kg', label: '1 kg', price: 1080, mrp: 1200),
      ],
      customizationGroups: [
        ItemCustomizationGroup(
          id: 'cg_packaging',
          title: 'Packaging Style',
          isRequired: true,
          options: [
            ItemCustomizationOption(id: 'opt_std', name: 'Artisanal Golden Box', price: 0),
            ItemCustomizationOption(id: 'opt_tin', name: 'Air-tight Heritage Tin (+₹40)', price: 40),
          ],
        ),
      ],
    ),

    // 2. Artisanal Motichoor Ladoo
    ItemModel(
      id: 'item_motichoor',
      shopId: 'shop_anand',
      shopName: 'Anand Sweets & Purveyors',
      name: 'Pure Desi Ghee Motichoor Ladoo',
      description: 'Melt-in-mouth tiny gram flour droplets fried in pure cow desi ghee, infused with saffron and green cardamom.',
      imageUrl: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800&q=80',
      category: 'Sweets',
      dietType: DietType.veg,
      isPerishable: false,
      shelfLife: '7 days',
      storageNote: 'Do not refrigerate. Ghee hardens in cold temperatures.',
      ingredients: ['Gram Flour (Besan)', 'Pure Cow Ghee', 'Kashmiri Saffron', 'Cardamom Seeds', 'Melon Seeds'],
      allergens: ['May contain traces of nuts'],
      variants: [
        ItemVariant(id: 'v_moti_250g', label: '250 g (6 pcs)', price: 210, mrp: 230, isDefault: true),
        ItemVariant(id: 'v_moti_500g', label: '500 g (12 pcs)', price: 400, mrp: 440),
        ItemVariant(id: 'v_moti_1kg', label: '1 kg (24 pcs)', price: 780, mrp: 850),
      ],
    ),

    // 3. Kesari Shahi Rasmalai (Perishable)
    ItemModel(
      id: 'item_rasmalai',
      shopId: 'shop_anand',
      shopName: 'Anand Sweets & Purveyors',
      name: 'Kesari Shahi Rasmalai (2 Pcs)',
      description: 'Spongy cottage cheese patties immersed in chilled clotted saffron cream milk garnished with pistachio flakes.',
      imageUrl: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=800&q=80',
      category: 'Desserts',
      dietType: DietType.veg,
      isPerishable: true,
      shelfLife: '24 hours in refrigerator (2°C - 4°C)',
      storageNote: 'Highly Perishable. Packed in insulated pouch. Consume chilled immediately.',
      ingredients: ['Fresh Cow Milk Chhena', 'Condensed Milk', 'Kashmiri Saffron', 'Iranian Pistachios'],
      allergens: ['Contains Milk & Dairy, Pistachios'],
      variants: [
        ItemVariant(id: 'v_ras_2pc', label: '2 Pieces (200 ml)', price: 140, mrp: 150, isDefault: true),
        ItemVariant(id: 'v_ras_4pc', label: '4 Pieces (400 ml)', price: 260, mrp: 280),
      ],
    ),

    // 4. Belgian Dark Chocolate Gelato Tub (Milano)
    ItemModel(
      id: 'item_gelato_dark',
      shopId: 'shop_milano',
      shopName: 'Milano Ice Cream & Gelateria',
      name: 'Belgian 70% Dark Chocolate Gelato',
      description: 'Intense slow-churned Italian gelato crafted with 70% Single Origin Belgian cocoa. Packed with ice gel packs.',
      imageUrl: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=800&q=80',
      category: 'Ice Cream',
      dietType: DietType.veg,
      isPerishable: true,
      shelfLife: '30 days in deep freeze (-18°C)',
      storageNote: 'Packed for cold delivery. Please refrigerate or freeze immediately on arrival.',
      ingredients: ['Whole Milk', 'Cream', '70% Belgian Dark Cocoa Mass', 'Organic Raw Sugar'],
      allergens: ['Contains Dairy & Soy Lecithin'],
      variants: [
        ItemVariant(id: 'v_g_cup', label: 'Single Cup (150 ml)', price: 160, mrp: 180),
        ItemVariant(id: 'v_g_tub', label: 'Half-Litre Tub (500 ml)', price: 420, mrp: 450, isDefault: true),
      ],
      customizationGroups: [
        ItemCustomizationGroup(
          id: 'cg_toppings',
          title: 'Artisan Toppings',
          allowMultiple: true,
          options: [
            ItemCustomizationOption(id: 'top_roasted_almonds', name: 'Roasted Almond Slivers', price: 35),
            ItemCustomizationOption(id: 'top_fudge_sauce', name: 'Warm Fudge Drizzle Cup', price: 40),
            ItemCustomizationOption(id: 'top_waffle_cone', name: 'Handmade Waffle Cone (Crisp)', price: 25),
          ],
        ),
      ],
    ),

    // 5. Alphonso Mango Gelato (Milano)
    ItemModel(
      id: 'item_gelato_mango',
      shopId: 'shop_milano',
      shopName: 'Milano Ice Cream & Gelateria',
      name: 'Ratnagiri Alphonso Mango Gelato',
      description: 'Fresh seasonal Alphonso mango pulp churned with rich dairy cream for an authentic tropical delight.',
      imageUrl: 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=800&q=80',
      category: 'Ice Cream',
      dietType: DietType.veg,
      isPerishable: true,
      shelfLife: '30 days in freezer',
      storageNote: 'Cold-chain delivery. Must be frozen immediately on receipt.',
      ingredients: ['Ratnagiri Alphonso Pulp (45%)', 'Fresh Cream', 'Whole Milk', 'Cane Sugar'],
      allergens: ['Contains Milk'],
      variants: [
        ItemVariant(id: 'v_m_cup', label: 'Cup (150 ml)', price: 150, mrp: 170),
        ItemVariant(id: 'v_m_tub', label: 'Tub (500 ml)', price: 390, mrp: 430, isDefault: true),
      ],
    ),

    // 6. Belgian Truffle Silk Cake (Lavonne)
    ItemModel(
      id: 'item_cake_truffle',
      shopId: 'shop_lavonne',
      shopName: 'Lavonne Patisserie & Bakery',
      name: 'Belgian Truffle Silk Ganache Cake',
      description: 'Layers of moist dark chocolate sponge filled with velvety smooth Belgian chocolate ganache.',
      imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80',
      category: 'Cakes',
      dietType: DietType.egg, // Contains egg by default, has eggless toggle
      isPerishable: true,
      shelfLife: '3 days refrigerated (2-5°C)',
      storageNote: 'Keep chilled. Consume within 48 hours for best silkiness.',
      allowsCakeMessage: true,
      allowsEgglessToggle: true,
      ingredients: ['Flour', 'Cocoa Butter', 'Belgian Chocolate (55%)', 'Dairy Cream', 'Sugar', 'Eggs/Curd'],
      allergens: ['Gluten', 'Dairy', 'Egg (if selected)'],
      variants: [
        ItemVariant(id: 'v_cake_500g', label: '500 g (Serves 4-6)', price: 750, mrp: 850, isDefault: true),
        ItemVariant(id: 'v_cake_1kg', label: '1.0 kg (Serves 8-10)', price: 1390, mrp: 1500),
      ],
      customizationGroups: [
        ItemCustomizationGroup(
          id: 'cg_candles',
          title: 'Party Essentials',
          allowMultiple: true,
          options: [
            ItemCustomizationOption(id: 'opt_candles', name: 'Metallic Candle Set', price: 40),
            ItemCustomizationOption(id: 'opt_knife', name: 'Premium Wooden Knife', price: 20),
          ],
        ),
      ],
    ),

    // 7. Rose Pistachio Baklava Gift Box (Anand)
    ItemModel(
      id: 'item_baklava_box',
      shopId: 'shop_anand',
      shopName: 'Anand Sweets & Purveyors',
      name: 'Grand Ottoman Rose Pistachio Baklava',
      description: 'Filo pastry sheets layered with Turkish pistachios and fragrant Damascus rosewater syrup.',
      imageUrl: 'https://images.unsplash.com/photo-1519869325930-281384150729?w=800&q=80',
      category: 'Gift Boxes',
      dietType: DietType.veg,
      isPerishable: false,
      shelfLife: '20 days',
      storageNote: 'Store at room temperature in a dry container.',
      ingredients: ['Wheat Filo Sheets', 'Antep Pistachio (40%)', 'Clarified Butter', 'Rosewater Honey Glaze'],
      allergens: ['Wheat (Gluten)', 'Nuts (Pistachio)'],
      variants: [
        ItemVariant(id: 'v_bak_12', label: 'Box of 12 pcs (350 g)', price: 480, mrp: 550, isDefault: true),
        ItemVariant(id: 'v_bak_24', label: 'Royal Box of 24 pcs (700 g)', price: 920, mrp: 1050),
      ],
    ),
  ];

  static const List<OfferModel> availableOffers = [
    OfferModel(
      code: 'SWEETFEAST',
      title: 'Flat ₹75 Off on Mithai & Sweets',
      description: 'Valid on artisanal sweets orders above ₹399 from verified sweet makers.',
      discountAmount: 75,
      minimumOrderAmount: 399,
      isApplicable: true,
    ),
    OfferModel(
      code: 'CHILLOUT',
      title: '₹50 Off on Artisanal Gelato & Ice Cream',
      description: 'Special cold-chain discount on all ice cream tubs and cones.',
      discountAmount: 50,
      minimumOrderAmount: 299,
      isApplicable: true,
    ),
    OfferModel(
      code: 'CELEBRATE150',
      title: 'Flat ₹150 Off on Designer Cakes',
      description: 'Celebrate sweet moments with premium cakes over ₹700.',
      discountAmount: 150,
      minimumOrderAmount: 700,
      isApplicable: true,
    ),
    OfferModel(
      code: 'FESTIVE500',
      title: 'Flat ₹200 Off on Grand Gift Boxes',
      description: 'Requires minimum order value of ₹1,200.',
      discountAmount: 200,
      minimumOrderAmount: 1200,
      isApplicable: false,
      ineligibilityReason: 'Add ₹720 more items to unlock this coupon.',
    ),
  ];

  static List<OrderModel> getInitialPastOrders() {
    return [
      OrderModel(
        orderId: 'FD10245',
        shopId: 'shop_anand',
        shopName: 'Anand Sweets & Purveyors',
        shopAddress: 'Commercial Street, Tasker Town, Bengaluru',
        fssaiLicense: '11221334000542',
        gstin: '29AAAAA0000A1Z5',
        items: [
          CartItemModel(
            id: 'ci_1',
            item: allItems[0], // Kaju Katli
            selectedVariant: allItems[0].variants[0],
            quantity: 2,
          ),
          CartItemModel(
            id: 'ci_2',
            item: allItems[1], // Motichoor Ladoo
            selectedVariant: allItems[1].variants[0],
            quantity: 1,
          ),
        ],
        orderStatus: OrderStatus.preparing,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethodType.upi,
        subtotal: 790.0,
        discountAmount: 75.0,
        deliveryFee: 35.0,
        packagingFee: 15.0,
        platformFee: 5.0,
        taxes: 39.5,
        tipAmount: 20.0,
        totalAmount: 824.5,
        deliveryAddress: 'Flat 402, Lotus Orchid, 8th Main, Indiranagar',
        deliveryInstructions: 'Ring the doorbell twice and leave on doorstep shoe rack.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 23)),
        driverName: 'Vikram Singh',
        driverPhone: '+91 98888 12345',
        driverVehicle: 'Electric Scooter (KA-03-EX-4491)',
        driverPhotoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      ),
      OrderModel(
        orderId: 'FD10198',
        shopId: 'shop_milano',
        shopName: 'Milano Ice Cream & Gelateria',
        shopAddress: '12th Main Road, Indiranagar, Bengaluru',
        fssaiLicense: '11222334000981',
        gstin: '29BBBBB1111B2Z8',
        items: [
          CartItemModel(
            id: 'ci_3',
            item: allItems[3], // Gelato
            selectedVariant: allItems[3].variants[1],
            quantity: 1,
          ),
        ],
        orderStatus: OrderStatus.delivered,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethodType.card,
        subtotal: 420.0,
        discountAmount: 50.0,
        deliveryFee: 35.0,
        packagingFee: 20.0,
        platformFee: 5.0,
        taxes: 21.0,
        tipAmount: 0.0,
        totalAmount: 451.0,
        deliveryAddress: 'Flat 402, Lotus Orchid, 8th Main, Indiranagar',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        estimatedDeliveryTime: DateTime.now().subtract(const Duration(days: 2, hours: 2, minutes: 25)),
        driverName: 'Rahul Nayak',
        driverPhone: '+91 97777 54321',
        driverVehicle: 'Hero Splendor (KA-01-MJ-9921)',
      ),
    ];
  }

  static List<NotificationItemModel> getInitialNotifications() => [
    NotificationItemModel(
      id: 'notif_1',
      title: 'Order #FD10245 is being prepared',
      message: 'Anand Sweets has confirmed your order and the confectioners are preparing your fresh treats.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      category: NotificationCategory.orders,
      icon: Icons.outdoor_grill,
      isRead: false,
      deepLinkRoute: '/order-tracking/FD10245',
    ),
    NotificationItemModel(
      id: 'notif_2',
      title: 'Payment Confirmed: ₹824.50',
      message: 'Your payment via UPI was successfully debited. Order confirmation sent to shop.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
      category: NotificationCategory.payments,
      icon: Icons.verified_user,
      isRead: false,
      deepLinkRoute: '/order-details/FD10245',
    ),
    NotificationItemModel(
      id: 'notif_3',
      title: 'Special Diwali Gifting Collection',
      message: 'Explore handcrafted royal gift hampers and silver-leaf sweets from Anand & Lavonne.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      category: NotificationCategory.offers,
      icon: Icons.card_giftcard,
      isRead: true,
      deepLinkRoute: '/category/Gift Boxes',
    ),
  ];
}
