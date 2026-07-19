from django.db import models
from django.conf import settings
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.utils import timezone
from django.utils.text import slugify



class Category(models.Model):
    nom = models.CharField(max_length=100, unique=True, verbose_name="Nom")
    code = models.CharField(max_length=50, unique=True, blank=True, null=True, verbose_name="Code Technique (ex: SMARTPHONE)")
    description = models.TextField(blank=True, verbose_name="Description")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Catégorie"
        verbose_name_plural = "Catégories"
        ordering = ['nom']

    def __str__(self):
        return self.nom


class Color(models.Model):
    nom = models.CharField(max_length=50, unique=True, verbose_name="Couleur")
    code_hex = models.CharField(max_length=7, verbose_name="Code Hex (ex: #FF0000)")

    class Meta:
        verbose_name = "Couleur"
        verbose_name_plural = "Couleurs"
        ordering = ['nom']

    def __str__(self):
        return f"{self.nom} ({self.code_hex})"

class Brand(models.Model):
    nom = models.CharField(max_length=100, unique=True, verbose_name="Marque")
    logo = models.URLField(max_length=500, null=True, blank=True, verbose_name="Logo de la marque")
    categories = models.ManyToManyField(Category, related_name='marques', blank=True, verbose_name="Catégories")
    
    class Meta:
        verbose_name = "Marque"
        verbose_name_plural = "Marques"
        ordering = ['nom']

    def __str__(self):
        return self.nom


class Product(models.Model):
    ETAT_CHOICES = [
        ('neuf', 'Neuf'),
        ('occasion', 'Occasion'),
    ]

    categorie = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,
        related_name='produits',
        verbose_name="Catégorie"
    )
    marque = models.ForeignKey(
        Brand,
        on_delete=models.PROTECT,
        related_name='produits',
        verbose_name="Marque",
        null=True,
        blank=True
    )
    modele = models.CharField(max_length=100, verbose_name="Modèle")
    nom_complet = models.CharField(max_length=255, verbose_name="Nom complet")
    slug = models.SlugField(max_length=255, unique=True, blank=True, null=True, verbose_name="Slug (URL)")
    description = models.TextField(blank=True, verbose_name="Description")
    caracteristiques = models.JSONField(
        default=dict,
        blank=True,
        verbose_name="Caractéristiques techniques",
        help_text="Ex: {\"ecran\": \"6.1 pouces\", \"processeur\": \"Snapdragon 8 Gen 2\", \"batterie\": \"3900 mAh\"}"
    )
    etat = models.CharField(
        max_length=10,
        choices=ETAT_CHOICES,
        default='neuf',
        verbose_name="État"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Produit"
        verbose_name_plural = "Produits"
        ordering = ['-created_at']

    def __str__(self):
        return self.nom_complet

    def save(self, *args, **kwargs):
        if not self.slug and self.marque and self.modele:
            base_slug = slugify(f"{self.marque.nom} {self.modele}")
            self.slug = base_slug
            counter = 1
            while Product.objects.filter(slug=self.slug).exclude(id=self.id).exists():
                self.slug = f"{base_slug}-{counter}"
                counter += 1
        super().save(*args, **kwargs)


class VariantImage(models.Model):
    variante = models.ForeignKey(
        'ProductVariant',
        on_delete=models.CASCADE,
        related_name='images',
        verbose_name="Variante"
    )
    image = models.URLField(max_length=500, verbose_name="URL de l'image")
    ordre = models.PositiveIntegerField(default=0, verbose_name="Ordre d'affichage")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Image de variante"
        verbose_name_plural = "Images de variante"
        ordering = ['ordre']

    def __str__(self):
        return f"Image {self.ordre} – {self.variante}"


class ProductVariant(models.Model):
    produit = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='variantes',
        verbose_name="Produit"
    )
    couleur = models.ForeignKey(
        Color,
        on_delete=models.PROTECT,
        related_name='variantes',
        verbose_name="Couleur",
        blank=True,
        null=True
    )
    RAM_CHOICES = [
        ('4 GB', '4 GB'), ('6 GB', '6 GB'), ('8 GB', '8 GB'),
        ('12 GB', '12 GB'), ('16 GB', '16 GB'), ('24 GB', '24 GB'), ('32 GB', '32 GB')
    ]

    STOCKAGE_CHOICES = [
        ('32 GB', '32 GB'), ('64 GB', '64 GB'), ('128 GB', '128 GB'),
        ('256 GB', '256 GB'), ('512 GB', '512 GB'), ('1 TB', '1 TB'), ('2 TB', '2 TB')
    ]

    ram = models.CharField(
        max_length=20,
        choices=RAM_CHOICES,
        blank=True,
        null=True,
        verbose_name="RAM"
    )
    stockage = models.CharField(
        max_length=20,
        choices=STOCKAGE_CHOICES,
        blank=True,
        null=True,
        verbose_name="Stockage"
    )
    taille_ecran = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name="Taille de l'écran"
    )
    RESOLUTION_CHOICES = [
        ('hd', 'HD (1366x768)'),
        ('full_hd', 'Full HD (1920x1080)'),
        ('4k', '4K Ultra HD (3840x2160)'),
        ('8k', '8K (7680x4320)'),
    ]

    TECHNOLOGIE_CHOICES = [
        ('lcd', 'LCD'),
        ('led', 'LED'),
        ('qled', 'QLED'),
        ('oled', 'OLED'),
        ('mini_led', 'Mini-LED'),
        ('micro_led', 'Micro-LED'),
        ('qd_mini_led', 'QD-Mini LED'),
        ('sqd_mini_led', 'SQD-Mini LED'),
    ]

    resolution = models.CharField(
        max_length=50,
        choices=RESOLUTION_CHOICES,
        blank=True,
        null=True,
        verbose_name="Résolution"
    )

    technologie = models.CharField(
        max_length=50,
        choices=TECHNOLOGIE_CHOICES,
        blank=True,
        null=True,
        verbose_name="Technologie"
    )

    TAUX_RAFRAICHISSEMENT_CHOICES = [
        ('50hz', '50 Hz'),
        ('60hz', '60 Hz'),
        ('100hz', '100 Hz'),
        ('120hz', '120 Hz'),
        ('144hz', '144 Hz'),
        ('240hz', '240 Hz'),
    ]

    taux_rafraichissement = models.CharField(
        max_length=20,
        choices=TAUX_RAFRAICHISSEMENT_CHOICES,
        blank=True,
        null=True,
        verbose_name="Taux de rafraîchissement"
    )

    prix = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Prix (FCFA)")
    stock = models.PositiveIntegerField(default=0, verbose_name="Stock disponible")
    sku = models.CharField(max_length=100, unique=True, verbose_name="SKU (référence interne)")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Variante produit"
        verbose_name_plural = "Variantes produit"
        ordering = ['produit', 'couleur', 'ram', 'stockage']
        # Contrainte d'unicité : une seule variante par combinaison
        unique_together = [['produit', 'couleur', 'ram', 'stockage']]

    def __str__(self):
        return f"{self.produit.nom_complet} – {self.couleur.nom} / {self.ram} / {self.stockage}"

    @property
    def est_disponible(self):
        return self.stock > 0

    def get_active_promotion(self):
        content_type = ContentType.objects.get_for_model(self)
        now = timezone.now()
        return Promotion.objects.filter(
            content_type=content_type,
            object_id=self.id,
            statut=True,
            date_debut__lte=now,
            date_fin__gte=now
        ).first()

    @property
    def prix_promo(self):
        promo = self.get_active_promotion()
        if promo:
            return promo.get_prix_reduit(self.prix)
        return None

    @property
    def get_prix_final(self):
        prix_p = self.prix_promo
        return prix_p if prix_p is not None else self.prix


class Kit(models.Model):
    STATUT_CHOICES = [
        ('actif', 'Actif'),
        ('inactif', 'Inactif'),
    ]

    nom = models.CharField(max_length=150, verbose_name="Nom du kit")
    description = models.TextField(blank=True, verbose_name="Description du kit")
    image = models.URLField(max_length=500, null=True, blank=True, verbose_name="Image")
    prix_total = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, verbose_name="Prix total (FCFA)")
    statut = models.CharField(max_length=10, choices=STATUT_CHOICES, default='actif', verbose_name="Statut")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'kits'
        verbose_name = "Kit de produits"
        verbose_name_plural = "Kits de produits"
        ordering = ['-created_at']

    def __str__(self):
        return self.nom

    def get_active_promotion(self):
        content_type = ContentType.objects.get_for_model(self)
        now = timezone.now()
        return Promotion.objects.filter(
            content_type=content_type,
            object_id=self.id,
            statut=True,
            date_debut__lte=now,
            date_fin__gte=now
        ).first()

    @property
    def prix_promo(self):
        promo = self.get_active_promotion()
        if promo and self.prix_total:
            return promo.get_prix_reduit(self.prix_total)
        return None

    @property
    def get_prix_final(self):
        prix_p = self.prix_promo
        return prix_p if prix_p is not None else self.prix_total


class KitItem(models.Model):
    kit = models.ForeignKey(Kit, on_delete=models.CASCADE, related_name='items', verbose_name="Kit")
    variante = models.ForeignKey(ProductVariant, on_delete=models.PROTECT, related_name='kit_items', verbose_name="Variante")
    quantite = models.PositiveIntegerField(default=1, verbose_name="Quantité")

    class Meta:
        verbose_name = "Article du kit"
        verbose_name_plural = "Articles du kit"
        unique_together = [['kit', 'variante']]

    def __str__(self):
        return f"{self.quantite}x {self.variante} (dans {self.kit.nom})"


class Cart(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='cart', verbose_name="Utilisateur")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Panier"
        verbose_name_plural = "Paniers"

    def __str__(self):
        return f"Panier de {self.user.username}"

    @property
    def total_items(self):
        return sum(item.quantite for item in self.items.all())

    @property
    def total_price(self):
        return sum(item.total_price for item in self.items.all())


class CartItem(models.Model):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items', verbose_name="Panier")
    content_type = models.ForeignKey(
        ContentType, 
        on_delete=models.CASCADE, 
        limit_choices_to={'model__in': ('productvariant', 'kit')}, 
        verbose_name="Type d'article"
    )
    object_id = models.PositiveIntegerField(verbose_name="ID de l'article")
    item = GenericForeignKey('content_type', 'object_id')
    
    quantite = models.PositiveIntegerField(default=1, verbose_name="Quantité")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name="Article de panier"
        verbose_name_plural = "Articles de panier"
        unique_together = [['cart', 'content_type', 'object_id']]

    def __str__(self):
        return f"{self.quantite}x {self.item} dans le panier de {self.cart.user.username}"

    @property
    def total_price(self):
        prix = self.item.get_prix_final if hasattr(self.item, 'get_prix_final') else 0
        return prix * self.quantite


class Order(models.Model):
    MODE_CHOICES = [
        ('livraison', 'Livraison'),
        ('expedition', 'Expédition'),
    ]

    STATUS_CHOICES = [
        ('en_attente_paiement', 'En attente de paiement'),
        ('paye', 'Payé'),
        ('accepte', 'Accepté'),
        ('en_preparation', 'En préparation'),
        ('livre', 'Livré'),
        ('annule', 'Annulé'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='orders', verbose_name="Utilisateur")
    mode_reception = models.CharField(max_length=20, choices=MODE_CHOICES, verbose_name="Mode de réception")
    statut = models.CharField(max_length=30, choices=STATUS_CHOICES, default='en_attente_paiement', verbose_name="Statut")

    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Date création")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Date mise à jour")

    class Meta:
        verbose_name = "Commande"
        verbose_name_plural = "Commandes"
        ordering = ['-created_at']

    def __str__(self):
        return f"Commande #{self.id} – {self.user.username} ({self.get_statut_display()})"

    @property
    def total_price(self):
        return sum(item.total_price for item in self.items.all())


class OrderItem(models.Model):
    commande = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items', verbose_name="Commande")
    content_type = models.ForeignKey(
        ContentType, 
        on_delete=models.PROTECT, 
        limit_choices_to={'model__in': ('productvariant', 'kit')}, 
        verbose_name="Type d'article"
    )
    object_id = models.PositiveIntegerField(verbose_name="ID de l'article")
    item = GenericForeignKey('content_type', 'object_id')

    quantite = models.PositiveIntegerField(verbose_name="Quantité")
    prix_unitaire = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Prix unitaire (FCFA)")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Article de commande"
        verbose_name_plural = "Articles de commande"

    def __str__(self):
        return f"{self.quantite} x {self.item} à {self.prix_unitaire} FCFA"

    @property
    def total_price(self):
        return self.prix_unitaire * self.quantite


class AdresseLivraison(models.Model):
    commande = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='adresse_livraison', verbose_name="Commande")
    latitude = models.DecimalField(max_digits=9, decimal_places=6, verbose_name="Latitude")
    longitude = models.DecimalField(max_digits=9, decimal_places=6, verbose_name="Longitude")
    adresse_complete = models.TextField(verbose_name="Adresse complète")
    commentaire = models.TextField(blank=True, null=True, verbose_name="Commentaire / Description")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'adresses_livraison'
        verbose_name = "Adresse de livraison"
        verbose_name_plural = "Adresses de livraison"

    def __str__(self):
        return f"Livraison pour Commande #{self.commande.id} ({self.latitude}, {self.longitude})"


class AdresseExpedition(models.Model):
    commande = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='adresse_expedition', verbose_name="Commande")
    nom = models.CharField(max_length=100, verbose_name="Nom")
    prenom = models.CharField(max_length=100, verbose_name="Prénom")
    telephone = models.CharField(max_length=20, verbose_name="Téléphone")
    ville = models.CharField(max_length=100, verbose_name="Ville")
    adresse = models.TextField(blank=True, null=True, verbose_name="Adresse")
    commentaire = models.TextField(blank=True, null=True, verbose_name="Commentaire")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'adresses_expedition'
        verbose_name = "Adresse d'expédition"
        verbose_name_plural = "Adresses d'expédition"

    def __str__(self):
        return f"Expédition pour Commande #{self.commande.id} ({self.nom} {self.prenom} - {self.ville})"


class LivraisonOrder(Order):
    class Meta:
        proxy = True
        verbose_name = "Livraison"
        verbose_name_plural = "Livraisons"


class Promotion(models.Model):
    TYPE_CHOICES = [
        ('pourcentage', 'Pourcentage (%)'),
        ('montant', 'Montant fixe (FCFA)'),
    ]

    content_type = models.ForeignKey(
        ContentType, 
        on_delete=models.CASCADE, 
        limit_choices_to={'model__in': ('productvariant', 'kit')}, 
        verbose_name="Type de cible"
    )
    object_id = models.PositiveIntegerField(verbose_name="ID de la cible")
    cible = GenericForeignKey('content_type', 'object_id')

    type_reduction = models.CharField(max_length=20, choices=TYPE_CHOICES, verbose_name="Type de réduction")
    valeur = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Valeur de la réduction")
    date_debut = models.DateTimeField(verbose_name="Date de début")
    date_fin = models.DateTimeField(verbose_name="Date de fin")
    statut = models.BooleanField(default=True, verbose_name="Active")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'promotions'
        verbose_name = "Promotion"
        verbose_name_plural = "Promotions"
        ordering = ['-created_at']

    def __str__(self):
        return f"Promo {self.valeur} {self.type_reduction} sur {self.cible}"

    def is_active(self):
        now = timezone.now()
        return self.statut and self.date_debut <= now <= self.date_fin

    def get_prix_reduit(self, prix_initial):
        if not prix_initial:
            return 0
        if self.type_reduction == 'pourcentage':
            reduction = (prix_initial * self.valeur) / 100
            return max(0, prix_initial - reduction)
        elif self.type_reduction == 'montant':
            return max(0, prix_initial - self.valeur)
        return prix_initial
