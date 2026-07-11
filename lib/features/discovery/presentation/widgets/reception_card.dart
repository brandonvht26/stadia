import 'package:flutter/material.dart';
import '../../domain/entities/reception_entity.dart';

// Widget que renderiza una recepción a pantalla completa,
// soportando un carrusel de imágenes horizontal.

class ReceptionCard extends StatefulWidget {
  final ReceptionEntity reception;
  final VoidCallback? onLikeToggle;

  const ReceptionCard({
    super.key,
    required this.reception,
    this.onLikeToggle,
  });

  @override
  State<ReceptionCard> createState() => _ReceptionCardState();
}

class _ReceptionCardState extends State<ReceptionCard> {
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.reception.imageUrls;
    final hasImages = imageUrls.isNotEmpty;
    final hasMultipleImages = imageUrls.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fondo (Carrusel de imágenes o imagen estática/placeholder)
        if (!hasImages)
          _buildPlaceholder()
        else if (!hasMultipleImages)
          _buildImage(imageUrls.first)
        else
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildImage(imageUrls[index]);
            },
          ),

        // 2. Gradiente oscuro para contraste y legibilidad
        // Se envuelve en IgnorePointer para que no bloquee los gestos de swipe hacia el PageView
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 3. Indicador tipo "dots" (solo si hay más de 1 imagen)
        if (hasMultipleImages)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 80.0), // Espacio para la SearchBar (aprox 70-90px)
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imageUrls.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: _currentImageIndex == index ? 12.0 : 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 4. Contenido (Información de la Recepción)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título y Badge Verificado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.reception.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.reception.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.verified,
                          color: Colors.blueAccent,
                          size: 28,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Precio y Likes
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '\$${widget.reception.basePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _AnimatedHeartButton(
                      isLiked: widget.reception.isLikedByUser,
                      likesCount: widget.reception.likesCount,
                      onTap: widget.onLikeToggle,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Ubicación (Solo coordenadas por ahora)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatLocation(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Sin imágenes',
              style: TextStyle(color: Colors.white54),
            )
          ],
        ),
      ),
    );
  }

  String _formatLocation() {
    if (widget.reception.distanceKm != null) {
      return 'A ${widget.reception.distanceKm!.toStringAsFixed(1)} km de ti';
    } else if (widget.reception.latitude != null && widget.reception.longitude != null) {
      return 'Ubicación en mapa';
    }
    return 'Ubicación no especificada';
  }
}

class _AnimatedHeartButton extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final VoidCallback? onTap;

  const _AnimatedHeartButton({
    required this.isLiked,
    required this.likesCount,
    this.onTap,
  });

  @override
  State<_AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<_AnimatedHeartButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      // Usamos HitTestBehavior.opaque para que el área táctil incluya los SizedBox y el texto
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border,
                color: widget.isLiked ? Colors.redAccent : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.likesCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

