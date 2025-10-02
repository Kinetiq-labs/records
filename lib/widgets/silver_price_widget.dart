import 'dart:async';
import 'package:flutter/material.dart';
import '../services/silver_price_service.dart';

class SilverPriceWidget extends StatefulWidget {
  const SilverPriceWidget({super.key});

  @override
  State<SilverPriceWidget> createState() => _SilverPriceWidgetState();
}

class _SilverPriceWidgetState extends State<SilverPriceWidget> with TickerProviderStateMixin {
  // Brand palette (silver/grays for silver theme)
  static const Color background = Color(0xFFF8F9FA); // Light gray
  static const Color deepSilver = Color(0xFF434343);  // Dark gray for text
  static const Color lightSilverFill = Color(0xFFE8EAED); // Very light gray fill
  static const Color borderSilver = Color(0xFF9E9E9E); // For borders/focus

  final SilverPriceService _silverService = SilverPriceService();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  SilverPriceData? _currentData;
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription<SilverPriceData>? _priceSubscription;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _initializeSilverService();
  }

  Future<void> _initializeSilverService() async {
    debugPrint('SilverPriceWidget: Initializing silver service...');
    try {
      // First set up the stream listener
      _priceSubscription = _silverService.priceStream.listen(
        (data) {
          debugPrint('SilverPriceWidget: Received price data: ${data.price} ${data.currency}');
          if (mounted) {
            setState(() {
              _currentData = data;
              _isLoading = false;
              _hasError = false;
            });
            _fadeController.forward();
            _startPulseAnimation();
          }
        },
        onError: (error) {
          debugPrint('SilverPriceWidget: Stream error: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        },
        onDone: () {
          debugPrint('SilverPriceWidget: Stream closed');
        },
      );
      
      // Then initialize the service (this will trigger data to be sent to stream)
      await _silverService.initialize();
      debugPrint('SilverPriceWidget: Silver service initialized successfully');
      
      // Add a small delay to ensure stream is ready, then try to get current data
      await Future.delayed(const Duration(milliseconds: 100));
      
      // If we still don't have data after initialization, try manual refresh
      if (_currentData == null && mounted) {
        debugPrint('SilverPriceWidget: No data received, attempting manual refresh...');
        await _silverService.refresh();
        
        // Wait a bit more for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        // If still no data, show error state to prevent infinite loading
        if (_currentData == null && mounted) {
          debugPrint('SilverPriceWidget: Still no data after refresh, showing error state');
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
      
    } catch (e) {
      debugPrint('SilverPriceWidget: Initialization error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _startPulseAnimation() {
    _pulseController.reset();
    _pulseController.forward();
  }

  @override
  void dispose() {
    _priceSubscription?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    // Don't dispose the singleton service here - it's shared across the app
    super.dispose();
  }

  Color _getChangeColor(double change) {
    if (change > 0) {
      return const Color(0xFF4CAF50); // Green for positive
    } else if (change < 0) {
      return const Color(0xFFF44336); // Red for negative
    } else {
      return Colors.grey; // Neutral for no change
    }
  }

  IconData _getChangeIcon(double change) {
    if (change > 0) {
      return Icons.trending_up;
    } else if (change < 0) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  String _formatPrice(double price, String currency, {bool compact = false}) {
    final symbol = _silverService.getCurrencySymbol(currency);
    
    if (compact) {
      if (price >= 1000000) {
        return '$symbol${(price / 1000000).toStringAsFixed(1)}M';
      } else if (price >= 1000) {
        return '$symbol${(price / 1000).toStringAsFixed(0)}K';
      } else {
        return '$symbol${price.toStringAsFixed(2)}';
      }
    } else {
      // Full price with commas for readability - show decimal places if significant
      final formattedNumber = price % 1 == 0 
          ? price.toStringAsFixed(0)
          : price.toStringAsFixed(2);
      return '$symbol${formattedNumber.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
    }
  }

  String _formatChange(double change, String currency) {
    final symbol = _silverService.getCurrencySymbol(currency);
    final sign = change >= 0 ? '+' : '';
    
    if (change.abs() >= 1000) {
      return '$sign$symbol${(change / 1000).toStringAsFixed(1)}K';
    } else {
      return '$sign$symbol${change.toStringAsFixed(2)}';
    }
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: lightSilverFill.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSilver.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: deepSilver.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(deepSilver),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading Silver Price...',
            style: TextStyle(
              color: deepSilver,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
        _initializeSilverService();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE57373), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              color: Color(0xFFD32F2F),
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Tap to retry',
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay() {
    if (_currentData == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: () async {
            setState(() => _isLoading = true);
            await _silverService.refresh();
            setState(() => _isLoading = false);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 100,
              maxWidth: 300,
              minHeight: 50,
              maxHeight: 200,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    lightSilverFill,
                    background,
                    lightSilverFill.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSilver.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: deepSilver.withOpacity(0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: _currentData!.pakistaniRates != null 
                  ? _buildCompactPakistaniDisplay()
                  : _buildRegularPriceDisplay(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompactPakistaniDisplay() {
    final rates = _currentData!.pakistaniRates!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row with live indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFC0C0C0), // Silver color
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC0C0C0).withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.payments,
                color: Color(0xFF757575),
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            // Replace Column with simple text to avoid nested layout issues
            Text(
              '999 Silver • Pakistan',
              style: TextStyle(
                color: deepSilver,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
          
          const SizedBox(height: 12),
          
          // Main price display
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatPrice(rates.silver999PerGram, 'PKR'),
                style: TextStyle(
                  color: deepSilver,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/gram',
                style: TextStyle(
                  color: deepSilver.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Change indicator and See Details button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentData!.change != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getChangeColor(_currentData!.change).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getChangeColor(_currentData!.change).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getChangeIcon(_currentData!.change),
                        color: _getChangeColor(_currentData!.change),
                        size: 10,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${_currentData!.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: _getChangeColor(_currentData!.change),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_currentData!.change != 0) const SizedBox(width: 8),
              
              // See Details button
              GestureDetector(
                onTap: _showDetailedRatesDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: deepSilver,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: deepSilver.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Last updated
          Text(
            'Updated ${_formatLastUpdated(_currentData!.lastUpdated)}',
            style: TextStyle(
              color: deepSilver.withOpacity(0.5),
              fontSize: 8,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      
    );
  }

  Widget _buildRegularPriceDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFC0C0C0), // Silver color
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC0C0C0).withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.payments,
                color: Color(0xFF757575), // Dark silver
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Silver Price',
                    style: TextStyle(
                      color: deepSilver,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _currentData!.country,
                    style: TextStyle(
                      color: deepSilver.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Refresh indicator
            if (_isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(deepSilver),
                ),
              )
            else
              Icon(
                Icons.refresh,
                color: deepSilver.withOpacity(0.6),
                size: 14,
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Price and change row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current price
            Text(
              _formatPrice(_currentData!.price, _currentData!.currency),
              style: TextStyle(
                color: deepSilver,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            
            Text(
              '/oz',
              style: TextStyle(
                color: deepSilver.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Change indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getChangeColor(_currentData!.change).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getChangeColor(_currentData!.change).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getChangeIcon(_currentData!.change),
                    color: _getChangeColor(_currentData!.change),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatChange(_currentData!.change, _currentData!.currency),
                    style: TextStyle(
                      color: _getChangeColor(_currentData!.change),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${_currentData!.changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: _getChangeColor(_currentData!.change),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Last updated
        Text(
          'Updated ${_formatLastUpdated(_currentData!.lastUpdated)}',
          style: TextStyle(
            color: deepSilver.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _showDetailedRatesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildDetailedRatesDialog(),
    );
  }
  
  Widget _buildDetailedRatesDialog() {
    if (_currentData?.pakistaniRates == null) return const SizedBox.shrink();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              lightSilverFill,
              background,
              lightSilverFill.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderSilver.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: deepSilver.withOpacity(0.2),
              offset: const Offset(0, 10),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [deepSilver, deepSilver.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC0C0C0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments,
                          color: Color(0xFF757575),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Silver Rates',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Pakistan • PKR',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content with StreamBuilder for live updates
            Flexible(
              child: StreamBuilder<SilverPriceData>(
                stream: _silverService.priceStream,
                builder: (context, snapshot) {
                  final rates = snapshot.hasData && snapshot.data!.pakistaniRates != null
                      ? snapshot.data!.pakistaniRates!
                      : _currentData!.pakistaniRates!;
                      
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDetailedSilverCard('999 Silver', rates.silver999PerGram, rates.silver999Per10Gram, rates.silver999PerTola, const Color(0xFFF5F5F5), const Color(0xFFC0C0C0)),
                        const SizedBox(height: 16),
                        _buildDetailedSilverCard('958 Silver', rates.silver958PerGram, rates.silver958Per10Gram, rates.silver958PerTola, const Color(0xFFEEEEEE), const Color(0xFFBDBDBD)),
                        const SizedBox(height: 16),
                        _buildDetailedSilverCard('925 Silver', rates.silver925PerGram, rates.silver925Per10Gram, rates.silver925PerTola, const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)),
                        
                        const SizedBox(height: 20),
                        
                        // Last updated
                        Text(
                          'Last Updated: ${_formatLastUpdated(rates.lastUpdated)}',
                          style: TextStyle(
                            color: deepSilver.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailedSilverCard(String title, double perGram, double per10Gram, double perTola, Color bgColor, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: deepSilver,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: _buildDetailedRateItem('Per Gram', _formatPrice(perGram, 'PKR'), Icons.grain),
              ),
              const SizedBox(width: 12),
              Flexible(
                fit: FlexFit.loose,
                child: _buildDetailedRateItem('Per 10g', _formatPrice(per10Gram, 'PKR'), Icons.scale),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailedRateItem('Per Tola', _formatPrice(perTola, 'PKR'), Icons.balance),
        ],
      ),
    );
  }
  
  Widget _buildDetailedRateItem(String label, String price, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderSilver.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: deepSilver.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: deepSilver.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              color: deepSilver,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentData == null) {
      return _buildLoadingState();
    } else if (_hasError && _currentData == null) {
      return _buildErrorState();
    } else {
      return _buildPriceDisplay();
    }
  }
}