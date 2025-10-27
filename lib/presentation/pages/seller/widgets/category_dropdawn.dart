// import 'package:flutter/material.dart';

// class CategoryDropdown extends StatelessWidget {
//   final String value;
//   final List<String> categories;
//   final Function(String?) onChanged;

//   const CategoryDropdown({
//     super.key,
//     required this.value,
//     required this.categories,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       decoration: InputDecoration(
//         labelText: 'Категория',
//         prefixIcon: const Icon(Icons.category),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),
//       ),
//       items: categories.map((category) {
//         return DropdownMenuItem<String>(
//           value: category,
//           child: Text(category),
//         );
//       }).toList(),
//       onChanged: onChanged,
//     );
//   }
// }
