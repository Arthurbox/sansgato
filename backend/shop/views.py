from django.db import transaction
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny

from .models import (
    Category, Product, Cart, CartItem, ProductVariant,
    Order, OrderItem, AdresseLivraison, AdresseExpedition, Kit
)
from .serializers import (
    CategorySerializer, ProductMinimalSerializer, ProductDetailSerializer,
    CartSerializer, CartItemSerializer,
    CheckoutSerializer, OrderSerializer, KitSerializer
)


class CartView(APIView):
    """GET, POST – Afficher et ajouter au panier."""
    permission_classes = [IsAuthenticated]

    def _get_or_create_cart(self, user):
        cart, _ = Cart.objects.get_or_create(user=user)
        return cart

    def get(self, request):
        cart = self._get_or_create_cart(request.user)
        serializer = CartSerializer(cart)
        return Response(serializer.data)

    def post(self, request):
        """Ajouter un article (variante ou kit) au panier."""
        cart = self._get_or_create_cart(request.user)
        serializer = CartItemSerializer(data=request.data)
        if serializer.is_valid():
            content_type = serializer.validated_data["content_type"]
            object_id = serializer.validated_data["object_id"]
            quantite = serializer.validated_data.get("quantite", 1)
            
            cart_item, created = CartItem.objects.get_or_create(
                cart=cart, content_type=content_type, object_id=object_id,
                defaults={"quantite": quantite}
            )
            
            # Use model_class() to get the item and check stock
            model_class = content_type.model_class()
            item = model_class.objects.get(id=object_id)
            
            if not created:
                new_qty = cart_item.quantite + quantite
                if hasattr(item, 'stock') and item.stock < new_qty:
                    return Response(
                        {"detail": f"Stock insuffisant. Seulement {item.stock} unites disponibles."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                cart_item.quantite = new_qty
                cart_item.save()
            return Response(CartSerializer(cart).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CartItemView(APIView):
    """PATCH, DELETE – Modifier ou supprimer un article du panier."""
    permission_classes = [IsAuthenticated]

    def _get_cart_item(self, user, pk):
        try:
            return CartItem.objects.get(pk=pk, cart__user=user)
        except CartItem.DoesNotExist:
            return None

    def patch(self, request, pk):
        item = self._get_cart_item(request.user, pk)
        if not item:
            return Response({"detail": "Article introuvable."}, status=status.HTTP_404_NOT_FOUND)
        quantite = request.data.get("quantite")
        if not quantite or not str(quantite).isdigit() or int(quantite) <= 0:
            return Response({"detail": "Quantite invalide."}, status=status.HTTP_400_BAD_REQUEST)
        quantite = int(quantite)
        if hasattr(item.item, 'stock') and item.item.stock < quantite:
            return Response(
                {"detail": f"Stock insuffisant. Seulement {item.item.stock} unites disponibles."},
                status=status.HTTP_400_BAD_REQUEST
            )
        item.quantite = quantite
        item.save()
        return Response(CartSerializer(item.cart).data)

    def delete(self, request, pk):
        item = self._get_cart_item(request.user, pk)
        if not item:
            return Response({"detail": "Article introuvable."}, status=status.HTTP_404_NOT_FOUND)
        cart = item.cart
        item.delete()
        return Response(CartSerializer(cart).data)


class CheckoutView(APIView):
    """POST – Passer commande depuis le panier."""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        serializer = CheckoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        cart, _ = Cart.objects.get_or_create(user=request.user)
        if not cart.items.exists():
            return Response({"detail": "Votre panier est vide."}, status=status.HTTP_400_BAD_REQUEST)

        # Verifier les stocks
        for item in cart.items.all():
            if hasattr(item.item, 'stock') and item.item.stock < item.quantite:
                return Response(
                    {"detail": f"Stock insuffisant pour {item.item}."},
                    status=status.HTTP_400_BAD_REQUEST
                )

        mode_reception = serializer.validated_data["mode_reception"]
        payment_method = serializer.validated_data.get("payment_method", "mobile_money")

        # Creer la commande
        order = Order.objects.create(
            user=request.user,
            mode_reception=mode_reception,
            statut="en_attente_paiement"
        )

        # Creer les articles de la commande et decrementer les stocks
        for item in cart.items.all():
            OrderItem.objects.create(
                commande=order,
                content_type=item.content_type,
                object_id=item.object_id,
                quantite=item.quantite,
                prix_unitaire=item.item.get_prix_final if hasattr(item.item, 'get_prix_final') else 0
            )
            if hasattr(item.item, 'stock'):
                item.item.stock -= item.quantite
                item.item.save()

        # Enregistrer l adresse selon le mode de reception
        if mode_reception == "livraison":
            addr_data = serializer.validated_data["adresse_livraison"]
            AdresseLivraison.objects.create(commande=order, **addr_data)
        elif mode_reception == "expedition":
            addr_data = serializer.validated_data["adresse_expedition"]
            AdresseExpedition.objects.create(commande=order, **addr_data)

        # Vider le panier
        cart.items.all().delete()

        # Initier le paiement
        payment_url = None
        
        # Créer le paiement dans l'application payments
        from payments.models import Payment
        payment = Payment.objects.create(
            commande=order,
            montant=order.total_price,
            payment_method=payment_method,
            payment_status='en_attente'
        )

        if payment_method == 'mobile_money':
            from payments.services import MockPaymentService
            payment_response = MockPaymentService.initiate_payment(payment)
            if payment_response.get("success"):
                payment.transaction_id = payment_response.get("transaction_id")
                payment.save()
                payment_url = payment_response.get("payment_url")

        response_data = OrderSerializer(order).data
        if payment_url:
            response_data["payment_url"] = payment_url

        return Response(response_data, status=status.HTTP_201_CREATED)


class OrderListView(APIView):
    """GET – Historique des commandes de l utilisateur connecte."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        orders = Order.objects.filter(user=request.user).order_by("-created_at")
        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data)


class OrderDetailView(APIView):
    """GET – Detail d une commande specifique."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            order = Order.objects.get(pk=pk, user=request.user)
        except Order.DoesNotExist:
            return Response({"detail": "Commande introuvable."}, status=status.HTTP_404_NOT_FOUND)
        serializer = OrderSerializer(order)
        return Response(serializer.data)


class CategoryListView(APIView):
    """GET – Liste de toutes les catégories de produits."""
    permission_classes = [AllowAny]

    def get(self, request):
        categories = Category.objects.all()
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data)


class ProductListView(APIView):
    """GET – Liste des produits avec filtres optionnels."""
    permission_classes = [AllowAny]

    def get(self, request):
        queryset = Product.objects.all()

        # Filtrage par catégorie
        category_id = request.query_params.get("category")
        if category_id:
            queryset = queryset.filter(categorie_id=category_id)

        # Filtrage par marque
        marque = request.query_params.get("marque")
        if marque:
            queryset = queryset.filter(marque__iexact=marque)

        # Recherche simple
        search = request.query_params.get("search")
        if search:
            queryset = queryset.filter(nom_complet__icontains=search)

        serializer = ProductMinimalSerializer(queryset, many=True)
        return Response(serializer.data)


class ProductDetailView(APIView):
    """GET – Détails complets d'un produit avec images et variantes."""
    permission_classes = [AllowAny]

    def get(self, request, pk):
        try:
            product = Product.objects.prefetch_related('variantes__images').get(pk=pk)
        except Product.DoesNotExist:
            return Response({"detail": "Produit introuvable."}, status=status.HTTP_404_NOT_FOUND)

        serializer = ProductDetailSerializer(product)
        return Response(serializer.data)


class KitListView(APIView):
    """GET – Liste de tous les kits actifs."""
    permission_classes = [AllowAny]

    def get(self, request):
        kits = Kit.objects.filter(statut='actif')
        serializer = KitSerializer(kits, many=True)
        return Response(serializer.data)


class KitDetailView(APIView):
    """GET – Détails complets d'un kit avec ses articles."""
    permission_classes = [AllowAny]

    def get(self, request, pk):
        try:
            kit = Kit.objects.prefetch_related('items__variante__produit').get(pk=pk, statut='actif')
        except Kit.DoesNotExist:
            return Response({"detail": "Kit introuvable."}, status=status.HTTP_404_NOT_FOUND)

        serializer = KitSerializer(kit)
        return Response(serializer.data)


class ActivePromotionsView(APIView):
    """GET – Retourne les produits et les kits actuellement en promotion."""
    permission_classes = [AllowAny]

    def get(self, request):
        from django.utils import timezone
        now = timezone.now()
        
        # Trouver les promotions actives
        from .models import Promotion
        active_promos = Promotion.objects.filter(statut=True, date_debut__lte=now, date_fin__gte=now)
        
        # Récupérer les identifiants
        variant_ids = active_promos.filter(content_type__model='productvariant').values_list('object_id', flat=True)
        kit_ids = active_promos.filter(content_type__model='kit').values_list('object_id', flat=True)
        
        # Récupérer les produits qui ont au moins une variante en promo
        promoted_products = Product.objects.filter(variantes__id__in=variant_ids).distinct()
        
        # Récupérer les kits en promo
        promoted_kits = Kit.objects.filter(id__in=kit_ids, statut='actif')
        
        return Response({
            "products": ProductMinimalSerializer(promoted_products, many=True).data,
            "kits": KitSerializer(promoted_kits, many=True).data
        })



