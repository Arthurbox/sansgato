from rest_framework import serializers
from .models import (
    Product, VariantImage, ProductVariant, Category, Color, Brand,
    Kit, KitItem, Promotion, StockMovement, ExpenseCategory, Expense, Employee
)

class AdminProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'nom_complet', 'slug', 'marque', 'modele', 'description', 'caracteristiques', 'etat', 'categorie', 'statut_publication']

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        ret['categorie'] = AdminCategorySerializer(instance.categorie).data if instance.categorie else None
        ret['marque'] = AdminBrandSerializer(instance.marque).data if instance.marque else None
        ret['variantes'] = AdminProductVariantSerializer(instance.variantes.all(), many=True).data
        return ret

class AdminVariantImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = VariantImage
        fields = ['id', 'variante', 'image', 'ordre']

class AdminProductVariantSerializer(serializers.ModelSerializer):
    sku = serializers.CharField(required=False)

    class Meta:
        model = ProductVariant
        fields = ['id', 'produit', 'couleur', 'ram', 'stockage', 'taille_ecran', 'resolution', 'technologie', 'taux_rafraichissement', 'prix_achat', 'prix', 'stock', 'sku']

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        ret['couleur'] = AdminColorSerializer(instance.couleur).data if instance.couleur else None
        return ret

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

class AdminStockMovementSerializer(serializers.ModelSerializer):
    variante_nom = serializers.CharField(source='variante.__str__', read_only=True)

    class Meta:
        model = StockMovement
        fields = ['id', 'variante', 'variante_nom', 'quantite', 'type_mouvement', 'motif', 'date']

class AdminExpenseCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ExpenseCategory
        fields = '__all__'

class AdminExpenseSerializer(serializers.ModelSerializer):
    categorie_nom = serializers.CharField(source='categorie.nom', read_only=True)

    class Meta:
        model = Expense
        fields = ['id', 'categorie', 'categorie_nom', 'montant', 'date', 'description', 'created_at']


class AdminEmployeeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Employee
        fields = ['id', 'nom', 'poste', 'salaire_mensuel', 'date_embauche', 'est_actif', 'created_at', 'updated_at']
