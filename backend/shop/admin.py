from django.contrib import admin
from django.utils.safestring import mark_safe
from .models import (
    Category, Color, Brand, Product, VariantImage, ProductVariant, Kit, KitItem,
    Cart, CartItem, Order, OrderItem, AdresseLivraison, AdresseExpedition, LivraisonOrder,
    Promotion, AvisClient, Notification, Favori
)


class VariantImageInline(admin.TabularInline):
    """Images associées directement à une variante (couleur/RAM/stockage)."""
    model = VariantImage
    extra = 1
    fields = ('image', 'ordre', 'apercu_image')
    readonly_fields = ('apercu_image',)

    def apercu_image(self, obj):
        if obj.image:
            return mark_safe(f'<img src="{obj.image}" style="height:60px; border-radius:4px;" />')
        return "—"
    apercu_image.short_description = "Aperçu"


class ProductVariantInline(admin.StackedInline):
    model = ProductVariant
    extra = 1
    fields = (('couleur', 'ram', 'stockage'), ('prix', 'stock', 'sku'))


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('nom', 'created_at', 'updated_at')
    search_fields = ('nom', 'description')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Color)
class ColorAdmin(admin.ModelAdmin):
    list_display = ('nom', 'code_hex')
    search_fields = ('nom', 'code_hex')


@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin):
    list_display = ('nom',)
    search_fields = ('nom',)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('nom_complet', 'categorie', 'marque', 'modele', 'etat', 'note_etat_occasion', 'created_at')
    list_filter = ('categorie', 'etat', 'marque', 'created_at')
    search_fields = ('nom_complet', 'marque', 'modele', 'description')
    inlines = [ProductVariantInline]
    readonly_fields = ('created_at', 'updated_at')


@admin.register(ProductVariant)
class ProductVariantAdmin(admin.ModelAdmin):
    """
    Depuis cette page, on peut ajouter les images de chaque variante directement.
    """
    list_display = ('produit', 'couleur', 'ram', 'stockage', 'prix', 'stock', 'sku', 'est_disponible', 'nb_images')
    list_filter = ('couleur', 'ram', 'stockage', 'produit__categorie')
    search_fields = ('sku', 'produit__nom_complet')
    raw_id_fields = ('produit',)
    inlines = [VariantImageInline]

    def nb_images(self, obj):
        return obj.images.count()
    nb_images.short_description = "Nb images"


class KitItemInline(admin.TabularInline):
    model = KitItem
    extra = 1
    raw_id_fields = ('variante',)

@admin.register(Kit)
class KitAdmin(admin.ModelAdmin):
    list_display = ('nom', 'prix_total', 'statut', 'created_at')
    list_filter = ('statut', 'created_at')
    search_fields = ('nom', 'description')
    inlines = [KitItemInline]
    readonly_fields = ('created_at', 'updated_at')


class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ('user', 'total_items', 'total_price', 'created_at')
    search_fields = ('user__username', 'user__phone_number')
    inlines = [CartItemInline]


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0


class AdresseLivraisonInline(admin.StackedInline):
    model = AdresseLivraison
    extra = 0


class AdresseExpeditionInline(admin.StackedInline):
    model = AdresseExpedition
    extra = 0


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'mode_reception', 'statut', 'total_price', 'created_at')
    list_filter = ('mode_reception', 'statut', 'created_at')
    search_fields = ('id', 'user__username', 'user__phone_number')
    inlines = [OrderItemInline, AdresseLivraisonInline, AdresseExpeditionInline]
    readonly_fields = ('created_at', 'updated_at')


@admin.register(LivraisonOrder)
class LivraisonOrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'client_nom', 'client_telephone', 'statut', 'adresse_complete', 'coordonnees_gps', 'produits_commandes', 'created_at')
    list_filter = ('statut', 'created_at')
    search_fields = ('id', 'user__username', 'user__phone_number', 'adresse_livraison__adresse_complete')
    actions = ['accepter_commandes', 'preparer_commandes', 'marquer_livrees']
    inlines = [OrderItemInline, AdresseLivraisonInline]
    readonly_fields = ('created_at', 'updated_at', 'carte_google_maps')

    def get_queryset(self, request):
        return super().get_queryset(request).filter(mode_reception='livraison')

    def client_nom(self, obj):
        return obj.user.username
    client_nom.short_description = "Nom du client"

    def client_telephone(self, obj):
        return obj.user.phone_number
    client_telephone.short_description = "Téléphone du client"

    def adresse_complete(self, obj):
        if hasattr(obj, 'adresse_livraison') and obj.adresse_livraison:
            return obj.adresse_livraison.adresse_complete
        return "N/A"
    adresse_complete.short_description = "Adresse complète"

    def coordonnees_gps(self, obj):
        if hasattr(obj, 'adresse_livraison') and obj.adresse_livraison:
            return f"{obj.adresse_livraison.latitude}, {obj.adresse_livraison.longitude}"
        return "N/A"
    coordonnees_gps.short_description = "Coordonnées GPS"

    def produits_commandes(self, obj):
        items = obj.items.all()
        return ", ".join(f"{item.quantite}x {item.item}" for item in items)
    produits_commandes.short_description = "Produits commandés"

    def carte_google_maps(self, obj):
        if hasattr(obj, 'adresse_livraison') and obj.adresse_livraison:
            lat = obj.adresse_livraison.latitude
            lng = obj.adresse_livraison.longitude
            # Google Maps Embed Query
            maps_url = f"https://maps.google.com/maps?q={lat},{lng}&z=15&output=embed"
            return mark_safe(f'<iframe src="{maps_url}" width="100%" height="450" style="border:0;" allowfullscreen="" loading="lazy"></iframe>')
        return "Pas de localisation de livraison disponible"
    carte_google_maps.short_description = "Position de livraison (Google Maps)"

    @admin.action(description="Accepter les livraisons sélectionnées")
    def accepter_commandes(self, request, queryset):
        queryset.update(statut='accepte')

    @admin.action(description="Préparer les livraisons sélectionnées")
    def preparer_commandes(self, request, queryset):
        queryset.update(statut='en_preparation')

    @admin.action(description="Marquer les livraisons sélectionnées comme livrées")
    def marquer_livrees(self, request, queryset):
        queryset.update(statut='livre')


@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = ('id', 'cible', 'type_reduction', 'valeur', 'date_debut', 'date_fin', 'statut')
    list_filter = ('type_reduction', 'statut', 'date_debut', 'date_fin')
    search_fields = ('valeur',)
    readonly_fields = ('created_at', 'updated_at')


@admin.register(AvisClient)
class AvisClientAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'product', 'note', 'created_at')
    list_filter = ('note', 'created_at')
    search_fields = ('user__username', 'product__nom', 'commentaire')
    readonly_fields = ('created_at',)

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'titre', 'type', 'est_lu', 'created_at')
    list_filter = ('type', 'est_lu', 'created_at')
    search_fields = ('titre', 'message', 'user__username')
    readonly_fields = ('created_at',)

@admin.register(Favori)
class FavoriAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'product', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__username', 'product__nom')
    readonly_fields = ('created_at',)
