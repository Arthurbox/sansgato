from rest_framework import serializers
from .models import (
    Product, VariantImage, ProductVariant, Category, Color, Brand,
    Kit, KitItem, Promotion
)

class AdminProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'nom_complet', 'slug', 'marque', 'modele', 'description', 'caracteristiques', 'etat', 'categorie']

class AdminVariantImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = VariantImage
        fields = ['id', 'variante', 'image', 'ordre']

class AdminProductVariantSerializer(serializers.ModelSerializer):
    sku = serializers.CharField(required=False)

    class Meta:
        model = ProductVariant
        fields = ['id', 'produit', 'couleur', 'ram', 'stockage', 'taille_ecran', 'resolution', 'technologie', 'taux_rafraichissement', 'prix', 'stock', 'sku']

class AdminCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'nom', 'code']

class AdminColorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Color
        fields = ['id', 'nom', 'code_hex']

class AdminBrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = ['id', 'nom', 'logo', 'categories']

class AdminKitItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = KitItem
        fields = ['id', 'kit', 'variante', 'quantite']

class AdminKitSerializer(serializers.ModelSerializer):
    items = AdminKitItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = Kit
        fields = ['id', 'nom', 'description', 'image', 'prix_total', 'statut', 'items', 'created_at']

class AdminPromotionSerializer(serializers.ModelSerializer):
    content_type_model = serializers.CharField(required=False)
    cible_name = serializers.SerializerMethodField()

    class Meta:
        model = Promotion
        fields = ['id', 'content_type', 'content_type_model', 'object_id', 'cible_name', 'type_reduction', 'valeur', 'date_debut', 'date_fin', 'statut']
        extra_kwargs = {
            'content_type': {'required': False}
        }

    def validate(self, data):
        content_type_model = data.pop('content_type_model', None)
        if content_type_model:
            from django.contrib.contenttypes.models import ContentType
            try:
                ct = ContentType.objects.get(model=content_type_model)
                data['content_type'] = ct
            except ContentType.DoesNotExist:
                raise serializers.ValidationError({"content_type_model": "Modèle invalide."})
        elif not data.get('content_type'):
            raise serializers.ValidationError({"content_type": "Ce champ est requis."})
        return data

    def get_cible_name(self, obj):
        return str(obj.cible)

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        if instance.content_type:
            ret['content_type_model'] = instance.content_type.model
        return ret

