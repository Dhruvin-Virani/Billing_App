import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class BillingProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  List<Item> _items = List.generate(
    6,
        (index) {
      // Updated item names and prices
      switch (index) {
        case 0: return Item(name: 'Premium Kesar Kajukarti (500g)', price: 430);
        case 1: return Item(name: 'Royal Dryfruit Khajurpak (500g)', price: 400);
        case 2: return Item(name: 'Spl. Mohanthal (500g)', price: 230);
        case 3: return Item(name: 'Kela no Chevdo (500g)', price: 170);
        case 4: return Item(name: 'Chatpata Phudina Sev (500g)', price: 170);
        case 5: return Item(name: 'Dryfruit Cookies Box (1 Box)', price: 170);
        default: return Item(name: 'Item ${String.fromCharCode(65 + index)}', price: 100);
      }
    },
  );

  List<Item> get items => _items;

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.total);

  void resetItems() {
    for (var item in _items) {
      item.quantity = 0; // Reset quantity to 0 internally
    }
    notifyListeners(); // Trigger UI update
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BillingProvider(),
      child: Consumer<BillingProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            theme: provider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
            home: BillingApp(),
          );
        },
      ),
    );
  }
}

class BillingApp extends StatefulWidget {
  @override
  _BillingAppState createState() => _BillingAppState();
}

class _BillingAppState extends State<BillingApp> {
  TextEditingController amountGivenController = TextEditingController();
  double amountGiven = 0.0;
  double returnAmount = 0.0;

  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers and focus nodes for each item
    final billingProvider = Provider.of<BillingProvider>(context, listen: false);
    controllers = List.generate(billingProvider.items.length, (_) => TextEditingController());
    focusNodes = List.generate(billingProvider.items.length, (_) => FocusNode());
  }

  void _updateReturnAmount() {
    double totalAmount = Provider.of<BillingProvider>(context, listen: false).totalAmount;
    setState(() {
      if (amountGiven >= totalAmount) {
        returnAmount = amountGiven - totalAmount;
      } else {
        returnAmount = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var billingProvider = Provider.of<BillingProvider>(context);
    double totalAmount = billingProvider.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Billing App'),
        actions: [
          IconButton(
            icon: Icon(billingProvider.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
            onPressed: () => billingProvider.toggleTheme(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Items List (Single Column with 6 Items one below another)
            Expanded(
              child: ListView.builder(
                itemCount: billingProvider.items.length,
                itemBuilder: (context, index) {
                  var item = billingProvider.items[index];
                  var controller = controllers[index];
                  controller.text = item.quantity == 0 ? "" : item.quantity.toString(); // Sync input field

                  return GestureDetector(
                    onTap: () {
                      // Focus on the TextField inside the item box
                      FocusScope.of(context).requestFocus(focusNodes[index]);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name and quantity in one line
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              // Rectangular input field for quantity
                              Container(
                                width: 60,  // Set width for the input field
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      item.quantity = int.tryParse(value) ?? 0;
                                    });
                                    _updateReturnAmount(); // Recalculate return amount
                                  },
                                  onEditingComplete: () {
                                    // Move to the next field after hitting done
                                    if (index < focusNodes.length - 1) {
                                      FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                                    } else {
                                      FocusScope.of(context).unfocus(); // Close keyboard if last field
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          // Price and total in another line
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Price: \₹${item.price}',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Total: \₹${item.total.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Amount
                    Text(
                      'Total Amount: \₹${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    // Amount Given Input
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: amountGivenController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount Given',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            amountGiven = double.tryParse(value) ?? 0.0;
                            _updateReturnAmount(); // Recalculate return amount
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    // Return Amount
                    Text(
                      'Return Amount: \₹${returnAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Reset Icon Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),  // Border color
                    borderRadius: BorderRadius.circular(8),  // Rounded corners
                  ),
                  height: 50,  // Set height
                  width: 50,   // Set width to make it square or adjust to your need
                  child: IconButton(
                    icon: Icon(Icons.refresh, size: 30),
                    onPressed: () {
                      setState(() {
                        billingProvider.resetItems();
                        amountGivenController.clear();
                        amountGiven = 0.0;
                        returnAmount = 0.0;

                        // Reset controllers to empty after resetting quantities
                        for (var controller in controllers) {
                          controller.text = "";  // Set text to empty instead of 0
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Item model
class Item {
  final String name;
  final double price;
  int quantity;

  Item({required this.name, required this.price, this.quantity = 0});

  double get total => price * quantity;
}


