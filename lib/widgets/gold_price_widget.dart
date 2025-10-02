import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gold_price_service.dart';

class GoldPriceWidget extends StatefulWidget {
  const GoldPriceWidget({super.key});

  @override
  State<GoldPriceWidget> createState() => _GoldPriceWidgetState();
}

class _GoldPriceWidgetState extends State<GoldPriceWidget> with TickerProviderStateMixin {
  // Brand palette (gold theme)
  static const Color background = Color(0xFFFFFDF5); // Cream white
  static const Color deepGold = Color(0xFFB8860B);   // Dark goldenrod
  static const Color lightGoldFill = Color(0xFFFFF8DC); // Light cream/beige
  static const Color borderGold = Color(0xFFDAA520); // Goldenrod for borders

  final GoldPriceService _goldService = GoldPriceService();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  GoldPriceData? _currentData;
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription<GoldPriceData>? _priceSubscription;

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

    _initializeGoldService();
  }

  Future<void> _initializeGoldService() async {
    debugPrint('GoldPriceWidget: Initializing gold service...');
    try {
      // First set up the stream listener
      _priceSubscription = _goldService.priceStream.listen(
        (data) {
          debugPrint('GoldPriceWidget: Received price data: ${data.price} ${data.currency}');
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
          debugPrint('GoldPriceWidget: Stream error: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        },
        onDone: () {
          debugPrint('GoldPriceWidget: Stream closed');
        },
      );
      
      // Then initialize the service (this will trigger data to be sent to stream)
      await _goldService.initialize();
      debugPrint('GoldPriceWidget: Gold service initialized successfully');
      
      // Add a small delay to ensure stream is ready, then try to get current data
      await Future.delayed(const Duration(milliseconds: 100));
      
      // If we still don't have data after initialization, try manual refresh
      if (_currentData == null && mounted) {
        debugPrint('GoldPriceWidget: No data received, attempting manual refresh...');
        await _goldService.refresh();
        
        // Wait a bit more for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        // If still no data, show error state to prevent infinite loading
        if (_currentData == null && mounted) {
          debugPrint('GoldPriceWidget: Still no data after refresh, showing error state');
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
      
    } catch (e) {
      debugPrint('GoldPriceWidget: Initialization error: $e');
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
    _goldService.dispose();
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
    final symbol = _goldService.getCurrencySymbol(currency);
    
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
    final symbol = _goldService.getCurrencySymbol(currency);
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
        color: lightGoldFill.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGold.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: deepGold.withOpacity(0.1),
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
              valueColor: AlwaysStoppedAnimation<Color>(deepGold),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading Gold Price...',
            style: TextStyle(
              color: deepGold,
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
        _initializeGoldService();
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
            await _goldService.refresh();
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
                    lightGoldFill,
                    background,
                    lightGoldFill.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderGold.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: deepGold.withOpacity(0.15),
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
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Color(0xFFB8860B),
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            // Replace Column with simple text to avoid nested layout issues
            Text(
              '24K Gold • Pakistan',
              style: TextStyle(
                color: deepGold,
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
                _formatPrice(rates.gold24kPerGram, 'PKR'),
                style: TextStyle(
                  color: deepGold,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/gram',
                style: TextStyle(
                  color: deepGold.withOpacity(0.8),
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
                    color: deepGold,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: deepGold.withOpacity(0.3),
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
              color: deepGold.withOpacity(0.5),
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
                color: const Color(0xFFFFD700), // Gold color
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Color(0xFFB8860B), // Dark gold
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
                    'Gold Price',
                    style: TextStyle(
                      color: deepGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _currentData!.country,
                    style: TextStyle(
                      color: deepGold.withOpacity(0.7),
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
                  valueColor: AlwaysStoppedAnimation<Color>(deepGold),
                ),
              )
            else
              Icon(
                Icons.refresh,
                color: deepGold.withOpacity(0.6),
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
                color: deepGold,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            
            Text(
              '/oz',
              style: TextStyle(
                color: deepGold.withOpacity(0.6),
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
            color: deepGold.withOpacity(0.5),
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
              lightGoldFill,
              background,
              lightGoldFill.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderGold.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: deepGold.withOpacity(0.2),
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
                  colors: [deepGold, deepGold.withOpacity(0.8)],
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
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          color: Color(0xFFB8860B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Gold Rates',
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
              child: StreamBuilder<GoldPriceData>(
                stream: _goldService.priceStream,
                builder: (context, snapshot) {
                  final rates = snapshot.hasData && snapshot.data!.pakistaniRates != null
                      ? snapshot.data!.pakistaniRates!
                      : _currentData!.pakistaniRates!;
                      
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDetailedGoldCard('24K Gold', rates.gold24kPerGram, rates.gold24kPer10Gram, rates.gold24kPerTola, const Color(0xFFFFF8DC), const Color(0xFFFFD700)),
                        const SizedBox(height: 16),
                        _buildDetailedGoldCard('22K Gold', rates.gold22kPerGram, rates.gold22kPer10Gram, rates.gold22kPerTola, const Color(0xFFFFF3CD), const Color(0xFFFFC107)),
                        const SizedBox(height: 16),
                        _buildDetailedGoldCard('21K Gold', rates.gold21kPerGram, rates.gold21kPer10Gram, rates.gold21kPerTola, const Color(0xFFFFE5B4), const Color(0xFFFF8C00)),
                        
                        const SizedBox(height: 20),
                        
                        // Last updated
                        Text(
                          'Last Updated: ${_formatLastUpdated(rates.lastUpdated)}',
                          style: TextStyle(
                            color: deepGold.withOpacity(0.7),
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
  
  Widget _buildDetailedGoldCard(String title, double perGram, double per10Gram, double perTola, Color bgColor, Color accentColor) {
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
              color: deepGold,
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
          color: borderGold.withOpacity(0.3),
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
                color: deepGold.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: deepGold.withOpacity(0.8),
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
              color: deepGold,
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