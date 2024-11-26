import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:window_manager/window_manager.dart';


extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this; // Return the string as is if it's empty
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Set initial window size and other properties
  windowManager.setSize(Size(1440, 900)); // Set your desired width and height
  windowManager.setMinimumSize(Size(1440, 900)); // Optionally set a minimum size
  windowManager.setMaximumSize(Size(1440, 900)); // Optionally set a maximum size
  windowManager.setResizable(false); // Disable resizing if needed
  windowManager.setTitle("InvoiceIT");
runApp(const InvoiceApp());
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoice Generator',
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: const InvoicePage(),
    );
  }
}

class InvoicePage extends StatefulWidget {
  const InvoicePage({Key? key}) : super(key: key);

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final List<Map<String, dynamic>> products = [];
  double tva = 0.0;
  String numCommande = '';
  String numFacture = '';
String clientName = '';
String clientAddress = '';
String clientPhone = '';
String clientEmail = '';
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
  final TextEditingController prixController = TextEditingController();

  void addProduct() {
    final reference = referenceController.text.trim();
    final designation = designationController.text.trim();
    final quantite = int.tryParse(quantiteController.text) ?? 0;
    final prix = double.tryParse(prixController.text) ?? 0.0;

    if (reference.isNotEmpty && designation.isNotEmpty && quantite > 0 && prix > 0) {
      setState(() {
        products.add({
          'reference': reference,
          'designation': designation,
          'quantite': quantite,
          'prix': prix,
        });
      });

      // Clear inputs
      referenceController.clear();
      designationController.clear();
      quantiteController.clear();
      prixController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs correctement.')),
      );
    }
  }
// Function to handle number to words conversion
// Function to convert numbers to words in French
String numberToWords(int number) {
  const List<String> units = [
    "",
    "un",
    "deux",
    "trois",
    "quatre",
    "cinq",
    "six",
    "sept",
    "huit",
    "neuf"
  ];
  const List<String> teens = [
    "dix",
    "onze",
    "douze",
    "treize",
    "quatorze",
    "quinze",
    "seize",
    "dix-sept",
    "dix-huit",
    "dix-neuf"
  ];
  const List<String> tens = [
    "",
    "",
    "vingt",
    "trente",
    "quarante",
    "cinquante",
    "soixante",
    "soixante-dix",
    "quatre-vingt",
    "quatre-vingt-dix"
  ];

  if (number == 0) return "zéro";

  if (number < 10) return units[number];
  if (number < 20) return teens[number - 10];
  if (number < 100) {
    final int ten = number ~/ 10;
    final int unit = number % 10;
    return unit == 0
        ? tens[ten]
        : (ten == 7 || ten == 9)
            ? tens[ten - 1] + "-" + teens[unit]
            : tens[ten] + (unit > 0 ? "-" + units[unit] : "");
  }
  if (number < 1000) {
    final int hundred = number ~/ 100;
    final int remainder = number % 100;
    return (hundred == 1 ? "cent" : units[hundred] + " cent") +
        (remainder > 0 ? " " + numberToWords(remainder) : "");
  }
  if (number < 1000000) {
    final int thousand = number ~/ 1000;
    final int remainder = number % 1000;
    return (thousand == 1 ? "mille" : numberToWords(thousand) + " mille") +
        (remainder > 0 ? " " + numberToWords(remainder) : "");
  }
  if (number < 1000000000) {
    final int million = number ~/ 1000000;
    final int remainder = number % 1000000;
    return (million == 1 ? "un million" : numberToWords(million) + " millions") +
        (remainder > 0 ? " " + numberToWords(remainder) : "");
  }
  return number.toString(); // Handle larger numbers as needed.
}

// Function to handle decimals
String convertNumberToFrenchWords(double number) {
  final int integerPart = number.floor();
  final int decimalPart = ((number - integerPart) * 1000).round();

  final String integerWords = numberToWords(integerPart);
  final String decimalWords = decimalPart > 0 ? numberToWords(decimalPart) : "";

  return decimalPart > 0
      ? "$integerWords dinars et $decimalWords millième"
      : "$integerWords dinars";
}
Future<void> generatePdf() async {
  final PdfDocument document = PdfDocument();
  final PdfPage page = document.pages.add();

  // Fonts
  final PdfStandardFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
  final PdfStandardFont subtitleFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
  final PdfStandardFont regularFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
// Load the logo from assets
final ByteData logoData = await rootBundle.load('assets/images/logo.png'); // Replace with your actual logo path
final List<int> logoBytes = logoData.buffer.asUint8List();
final PdfBitmap logoImage = PdfBitmap(logoBytes);

// Draw the logo in the header (smaller size)
page.graphics.drawImage(
  logoImage,
  const Rect.fromLTWH(0, 0, 50, 30), // Adjusted size (50 width, 30 height)
);

// Add company details below the logo
page.graphics.drawString(
  'Nom de la société: MMH ARMERIE\nAdresse:Rue El Bassra Ouerdanine 5010\nTéléphone : 73 533 449',
  regularFont,
  bounds: const Rect.fromLTWH(0, 35, 300, 60), // Positioned below the logo
);

  page.graphics.drawString(
    'FACTURE',
    titleFont,
    bounds: const Rect.fromLTWH(200, 20, 200, 30),
    format: PdfStringFormat(alignment: PdfTextAlignment.center),
  );

  // Invoice and Client Details (Header)
  final String invoiceDetails = 
      'Facture n° $numFacture\n'
      'Commande n° $numCommande\n'
      'Date : ${DateTime.now().toLocal().toString().split(' ')[0]}';
  page.graphics.drawString(
    invoiceDetails,
    regularFont,
    bounds: const Rect.fromLTWH(0, 100, 300, 60),
  );

  final String clientDetails = 
      'Client:\n'
      'Nom: $clientName\n'
      'Adresse: $clientAddress\n'
      'Téléphone: $clientPhone\n'
      'Email: $clientEmail';
  page.graphics.drawString(
    clientDetails,
    regularFont,
    bounds: const Rect.fromLTWH(300, 100, 300, 60),
  );

  // Product Table
  final PdfGrid grid = PdfGrid();
  grid.columns.add(count: 6);
  grid.headers.add(1);

  // Table Header Style
  final PdfGridRow header = grid.headers[0];
  header.style = PdfGridRowStyle(
    backgroundBrush: PdfBrushes.gray,
    textBrush: PdfBrushes.white,
    font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
  );

  header.cells[0].value = 'Référence';
  header.cells[1].value = 'Désignation';
  header.cells[2].value = 'Quantité';
  header.cells[3].value = 'Prix Unitaire HT (TND)';
  header.cells[4].value = 'TVA (%)';
  header.cells[5].value = 'Total HT (TND)';

  // Body Row Style (with adjusted padding and gray borders)
  final PdfGridCellStyle bodyStyle = PdfGridCellStyle(
   
    font: PdfStandardFont(PdfFontFamily.helvetica, 10),
    textBrush: PdfBrushes.black,
    cellPadding: PdfPaddings(left: 5, right: 5, top: 2, bottom: 2),
  );

  // Add Products to Table
  double montantTotalHT = 0.0;
  double montantTotalTVA = 0.0;

  for (var product in products) {
    final double prixUnitaireHT = product['prix'];
    final int quantite = product['quantite'];
    final double totalHT = prixUnitaireHT * quantite;
    final double productTVA = totalHT * (tva / 100);

    final row = grid.rows.add();
    row.cells[0].value = product['reference'];
    row.cells[1].value = product['designation'];
    row.cells[2].value = quantite.toString();
    row.cells[3].value = '${prixUnitaireHT}';
    row.cells[4].value = '${tva}%';
    row.cells[5].value = '${totalHT}';

    // Apply Body Row Style
    for (int i = 0; i < row.cells.count; i++) {
      row.cells[i].style = bodyStyle;
    }

    montantTotalHT += totalHT;
    montantTotalTVA += productTVA;
  }

  // Calculate the width percentages for the first two columns
  final double totalWidth = page.getClientSize().width - 20; // Subtract margins
  final double remainingWidth = totalWidth - 250; // Subtract width of the last 4 columns (fixed)

  // Set the first two columns' width based on the remaining space
  grid.columns[0].width = (remainingWidth * 0.40);  // 40% of remaining width
  grid.columns[1].width = (remainingWidth * 0.60);  // 60% of remaining width

  // Set fixed widths for the last 4 columns
  grid.columns[2].width = 50;   // Quantité
  grid.columns[3].width = 80;   // Prix Unitaire HT
  grid.columns[4].width = 50;   // TVA
  grid.columns[5].width = 80;   // Total HT

  // Draw the Table
  final PdfLayoutResult result = grid.draw(
    page: page,
    bounds: const Rect.fromLTWH(0, 240, 500, 500),
  )!;

  // Summary Calculations
  final double totalNetHT = montantTotalHT ;
  final double montantTotalTTC = totalNetHT + montantTotalTVA;

  final PdfTextAlignment alignment = PdfTextAlignment.right;

  final List<Map<String, String>> summaryData = [
    {'label': 'Montant Total HT', 'value': '${montantTotalHT} '},
    {'label': 'Total Net HT', 'value': '${totalNetHT} '},
    {'label': 'Total TVA', 'value': '${montantTotalTVA} '},
    {'label': 'Montant Total TTC', 'value': '${montantTotalTTC} '},
  ];

  final PdfStandardFont boldFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
  final double summaryStartY = result.bounds.bottom + 10; // Start just below the table

  // Draw Summary below the Table
  double currentY = summaryStartY;
  const double labelWidth = 100; // Set fixed width for labels
  const double valueWidth = 50; // Set width for values
  const double padding = 10.0; // Padding between label and value

  for (var item in summaryData) {
    // Label on the left
    page.graphics.drawString(
      item['label']!,
      boldFont,
      bounds: Rect.fromLTWH(totalWidth - labelWidth - valueWidth - padding, currentY, labelWidth, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );

    // Value on the right
    page.graphics.drawString(
      item['value']!,
      regularFont,
      bounds: Rect.fromLTWH(totalWidth - valueWidth - padding, currentY, valueWidth, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    currentY += 25; // Move to next row
  }
// Convert montantTotalTTC to words
final String montantTTCEnLettres = convertNumberToFrenchWords(montantTotalTTC).capitalize();

// Add Montant TTC in Words to the bottom-left, aligned below the summary
final double marginLeft = 20; // Margin from the left
final double montantEnLettresStartY = currentY + 30; // Position it below the summary

page.graphics.drawString(
  "Montant Total TTC en lettres :",
  boldFont,
  bounds: Rect.fromLTWH(marginLeft, montantEnLettresStartY, totalWidth / 2, 20), // Left side
);

page.graphics.drawString(
  montantTTCEnLettres,
  regularFont,
  bounds: Rect.fromLTWH(marginLeft, montantEnLettresStartY + 20, totalWidth - marginLeft, 40), // Spaced below the label
);
  // Save the PDF
  final Directory directory = await getApplicationDocumentsDirectory();
  final String path = '${directory.path}/Facture_$numFacture.pdf';
  final File file = File(path);
  await file.writeAsBytes(await document.save());
  document.dispose();
   // Open the PDF using open_file
    OpenFile.open(file.path);
  // Show confirmation
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Facture enregistrée à : $path')));
}

  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Number and Command Number (First Card)
            Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Num Facture'),
                        onChanged: (value) => numFacture = value,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Num Commande'),
                        onChanged: (value) => numCommande = value,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TVA Input Field (inside the first card)
            Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(labelText: 'TVA %'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => tva = double.tryParse(value) ?? 0.0,
                  inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                ),
              ),
            ),

            // Client Info Card
            Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Client Name'),
                      onChanged: (value) => clientName = value,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Client Address'),
                      onChanged: (value) => clientAddress = value,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Client Telephone'),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => clientPhone = value,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Client Email'),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => clientEmail = value,
                    ),
                  ],
                ),
              ),
            ),

            // Product Input Fields (Row for reference, designation, quantity, price)
            Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: referenceController,
                        decoration: const InputDecoration(labelText: 'Reference'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: designationController,
                        decoration: const InputDecoration(labelText: 'Designation'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: quantiteController,
                        decoration: const InputDecoration(labelText: 'Quantité'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: prixController,
                        decoration: const InputDecoration(labelText: 'Prix'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: addProduct,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),

            // Display Products in a ListView
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text('${product['reference']} - ${product['designation']}'),
                    subtitle: Text(
                        'Quantité: ${product['quantite']}, Prix: ${product['prix']} TND'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => setState(() {
                        products.removeAt(index);
                      }),
                    ),
                  );
                },
              ),
            ),

            // Generate PDF Button
            ElevatedButton(
              onPressed: products.isEmpty ? null : generatePdf,
              child: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }
}