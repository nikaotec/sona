import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/banner_ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  late BannerAdService _bannerAdService;

  @override
  void initState() {
    super.initState();
    _bannerAdService = BannerAdService();
    _bannerAdService.loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaywallProvider>(
      builder: (context, paywallProvider, child) {
        // Se o usuário é premium, não mostra o banner
        if (paywallProvider.isPremium) {
          return const SizedBox.shrink();
        }

        // Se o banner não está pronto, mostra um placeholder ou nada
        if (!_bannerAdService.isBannerAdReady || _bannerAdService.bannerAd == null) {
          return Container(
            height: 50,
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                'Carregando anúncio...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // Mostra o banner
        return Container(
          alignment: Alignment.center,
          width: _bannerAdService.bannerAd!.size.width.toDouble(),
          height: _bannerAdService.bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAdService.bannerAd!),
        );
      },
    );
  }
}

