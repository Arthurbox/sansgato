from rest_framework import serializers
from .models import (
    Category, Color, Brand, Product, VariantImage, ProductVariant, Kit, KitItem,
    Cart, CartItem, Order, OrderItem, AdresseLivraison, AdresseExpedition,
    Notification, AvisClient
)

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "nom", "code", "layout_type", "description"]


class ColorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Color
        fields = ["id", "nom", "code_hex"]


class BrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = ["id", "nom", "logo"]



class VariantImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = VariantImage
        fields = ["id", "image", "ordre"]


class ProductVariantSerializer(serializers.ModelSerializer):
    """Serializer complet pour une variante, sans le produit parent (pour éviter la référence circulaire)."""
    couleur = ColorSerializer(read_only=True)
    ram = serializers.CharField(read_only=True)
    stockage = serializers.CharField(read_only=True)
    images = VariantImageSerializer(many=True, read_only=True)

    prix_initial = serializers.DecimalField(source='prix', max_digits=10, decimal_places=2, read_only=True)
    prix_promo = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    prix_final = serializers.DecimalField(source='get_prix_final', max_digits=10, decimal_places=2, read_only=True)
    en_promotion = serializers.SerializerMethodField()
    promo_valeur = serializers.SerializerMethodField()
    promo_type = serializers.SerializerMethodField()

    class Meta:
        model = ProductVariant
        fields = [
            "id", "couleur", "ram", "stockage", "taille_ecran", "resolution", "technologie",
            "prix", "prix_initial", "prix_promo", "prix_final",
            "en_promotion", "promo_valeur", "promo_type",
            "stock", "sku", "est_disponible",
            "images"  # ← images liées à cette variante
        ]

    def get_en_promotion(self, obj):
        return obj.get_active_promotion() is not None

    def get_promo_valeur(self, obj):
        promo = obj.get_active_promotion()
        return promo.valeur if promo else None

    def get_promo_type(self, obj):
        promo = obj.get_active_promotion()
        return promo.type_reduction if promo else None


class ProductMinimalSerializer(serializers.ModelSerializer):
    """Serializer léger pour le catalogue (liste de produits).
    Les images sont désormais portées par chaque variante.
    """
    categorie = CategorySerializer(read_only=True)
    marque = BrandSerializer(read_only=True)
    variantes = ProductVariantSerializer(many=True, read_only=True)
    note_moyenne = serializers.FloatField(read_only=True)
    avis_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Product
        fields = ["id", "categorie", "marque", "modele", "nom_complet", "etat", "variantes", "note_moyenne", "avis_count"]


class KitItemSerializer(serializers.ModelSerializer):
    variante = ProductVariantSerializer(read_only=True)
    
    class Meta:
        model = KitItem
        fields = ["id", "variante", "quantite"]

class KitSerializer(serializers.ModelSerializer):
    items = KitItemSerializer(many=True, read_only=True)
    prix_initial = serializers.DecimalField(source='prix_total', max_digits=10, decimal_places=2, read_only=True)
    prix_promo = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    prix_final = serializers.DecimalField(source='get_prix_final', max_digits=10, decimal_places=2, read_only=True)
    en_promotion = serializers.SerializerMethodField()
    promo_valeur = serializers.SerializerMethodField()
    promo_type = serializers.SerializerMethodField()

    class Meta:
        model = Kit
        fields = ["id", "nom", "description", "image", "prix_total", "prix_initial", "prix_promo", "prix_final", "en_promotion", "promo_valeur", "promo_type", "statut", "items"]

    def get_en_promotion(self, obj):
        return obj.prix_promo is not None

    def get_promo_valeur(self, obj):
        promo = obj.get_active_promotion()
        return promo.valeur if promo else None

    def get_promo_type(self, obj):
        promo = obj.get_active_promotion()
        return promo.type_reduction if promo else None


class ProductDetailSerializer(serializers.ModelSerializer):
    """Serializer complet pour la page détail d'un produit.
    Les images sont désormais portées par chaque variante (voir images dans ProductVariantSerializer).
    """
    categorie = CategorySerializer(read_only=True)
    marque = BrandSerializer(read_only=True)
    variantes = ProductVariantSerializer(many=True, read_only=True)
    note_moyenne = serializers.FloatField(read_only=True)
    avis_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Product
        fields = [
            "id", "categorie", "marque", "modele", "nom_complet", "slug",
            "description", "caracteristiques", "etat", "variantes",
            "note_moyenne", "avis_count", "created_at", "updated_at"
        ]



class GenericItemRelatedField(serializers.RelatedField):
    def to_representation(self, value):
        from shop.models import ProductVariant, Kit
        if isinstance(value, ProductVariant):
            return ProductVariantSerializer(value).data
        elif isinstance(value, Kit):
            return KitSerializer(value).data
        return None

class CartItemSerializer(serializers.ModelSerializer):
    content_type = serializers.CharField(write_only=True)
    object_id = serializers.IntegerField(write_only=True)
    item = GenericItemRelatedField(read_only=True)
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = CartItem
        fields = ["id", "content_type", "object_id", "item", "quantite", "total_price"]

    def validate_quantite(self, value):
        if value <= 0:
            raise serializers.ValidationError("La quantite doit etre superieure a 0.")
        return value

    def validate(self, data):
        from django.contrib.contenttypes.models import ContentType
        content_type_str = data.get("content_type")
        object_id = data.get("object_id")
        quantite = data.get("quantite", 1)

        try:
            content_type = ContentType.objects.get(model=content_type_str)
        except ContentType.DoesNotExist:
            raise serializers.ValidationError({"content_type": "Type d'article invalide."})

        model_class = content_type.model_class()
        try:
            item = model_class.objects.get(id=object_id)
        except model_class.DoesNotExist:
            raise serializers.ValidationError({"object_id": "L'article n'existe pas."})

        if hasattr(item, 'stock') and item.stock < quantite:
            raise serializers.ValidationError(
                {"quantite": f"Stock insuffisant. Seulement {item.stock} unites disponibles."}
            )
        
        # Replace string content_type with ContentType object in validated_data
        data['content_type'] = content_type
        return data


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total_items = serializers.IntegerField(read_only=True)
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = Cart
        fields = ["id", "items", "total_items", "total_price", "created_at", "updated_at"]


class AdresseLivraisonSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdresseLivraison
        fields = ["latitude", "longitude", "adresse_complete", "commentaire"]


class AdresseExpeditionSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdresseExpedition
        fields = ["nom", "prenom", "telephone", "ville", "adresse", "commentaire"]


class CheckoutSerializer(serializers.Serializer):
    MODE_CHOICES = [("livraison", "Livraison"), ("expedition", "Expedition")]
    PAYMENT_CHOICES = [("mobile_money", "Mobile Money"), ("especes", "Espèces")]
    mode_reception = serializers.ChoiceField(choices=MODE_CHOICES)
    payment_method = serializers.ChoiceField(choices=PAYMENT_CHOICES, default="mobile_money")
    adresse_livraison = AdresseLivraisonSerializer(required=False)
    adresse_expedition = AdresseExpeditionSerializer(required=False)

    def validate(self, data):
        mode_reception = data.get("mode_reception")
        if mode_reception == "livraison":
            if not data.get("adresse_livraison"):
                raise serializers.ValidationError(
                    {"adresse_livraison": "Les informations de localisation pour la livraison sont requises."}
                )
        elif mode_reception == "expedition":
            if not data.get("adresse_expedition"):
                raise serializers.ValidationError(
                    {"adresse_expedition": "Les informations du destinataire pour l expedition sont requises."}
                )
        return data


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "titre", "message", "type", "est_lu", "created_at"]


class OrderItemSerializer(serializers.ModelSerializer):
    item = GenericItemRelatedField(read_only=True)
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = OrderItem
        fields = ["id", "item", "quantite", "prix_unitaire", "total_price"]


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    adresse_livraison = AdresseLivraisonSerializer(read_only=True)
    adresse_expedition = AdresseExpeditionSerializer(read_only=True)
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    statut_label = serializers.CharField(source="get_statut_display", read_only=True)
    mode_reception_label = serializers.CharField(source="get_mode_reception_display", read_only=True)
    from payments.serializers import PaymentSerializer
    payments = PaymentSerializer(many=True, read_only=True)
    payment_url = serializers.CharField(read_only=True, required=False)

    class Meta:
        model = Order
        fields = [
            "id", "mode_reception", "mode_reception_label", "statut", "statut_label",
            "payments", "payment_url",
            "items", "adresse_livraison", "adresse_expedition", "total_price",
            "created_at", "updated_at"
        ]

class AvisClientSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True, default='Anonyme')

    class Meta:
        model = AvisClient
        fields = ['id', 'user_name', 'note', 'commentaire', 'created_at']
