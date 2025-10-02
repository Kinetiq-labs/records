import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'responsive_app_bar.dart';

class ResponsiveDemo extends StatelessWidget {
  const ResponsiveDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ResponsiveAppBar(
        title: 'Responsive Demo',
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveBuilder(
        builder: (context, screenType) {
          return ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Current Screen Type: ${screenType.name}',
                  baseFontSize: 18,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 20)),

                ResponsiveText(
                  'Screen Width: ${MediaQuery.of(context).size.width.toInt()}px',
                  baseFontSize: 16,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 10)),

                ResponsiveText(
                  'Columns: ${ResponsiveUtils.getResponsiveColumns(context)}',
                  baseFontSize: 16,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 20)),

                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveUtils.getResponsiveColumns(context),
                      crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 10),
                      mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 10),
                    ),
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Center(
                          child: ResponsiveText(
                            'Card ${index + 1}',
                            baseFontSize: 14,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}