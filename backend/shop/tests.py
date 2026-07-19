from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from shop.models import Category, Product, ProductVariant, Color, RAM, Storage
from accounts.models import OTPVerification
from accounts.twilio_service import send_verification_otp, check_verification_otp
from django.conf import settings

class ShopCatalogTests(APITestCase):

    def setUp(self):
        # Création des données de test
        self.category = Category.objects.create(nom="Smartphones", description="Téléphones portables")
        self.color = Color.objects.create(nom="Noir", code_hex="#000000")
        self.ram = RAM.objects.create(capacite="8 Go")
        self.storage = Storage.objects.create(capacite="256 Go")
        
        self.product = Product.objects.create(
            categorie=self.category,
            marque="Apple",
            modele="iPhone 15",
            nom_complet="Apple iPhone 15 Noir 256 Go",
            description="Le dernier iPhone",
            etat="neuf"
        )
        
        self.variant = ProductVariant.objects.create(
            produit=self.product,
            couleur=self.color,
            ram=self.ram,
            stockage=self.storage,
            prix=800000.00,
            stock=10,
            sku="IPHONE-15-NOIR-8-256"
        )
        
        self.category_list_url = reverse('category-list')
        self.product_list_url = reverse('product-list')
        self.product_detail_url = reverse('product-detail', kwargs={'pk': self.product.pk})

    def test_category_list(self):
        response = self.client.get(self.category_list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['nom'], "Smartphones")

    def test_product_list(self):
        response = self.client.get(self.product_list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['nom_complet'], "Apple iPhone 15 Noir 256 Go")

    def test_product_list_filtering(self):
        # Filtre par catégorie existante
        response = self.client.get(f"{self.product_list_url}?category={self.category.id}")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # Filtre par catégorie inexistante
        response = self.client.get(f"{self.product_list_url}?category=999")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)

        # Filtre par marque
        response = self.client.get(f"{self.product_list_url}?marque=Apple")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # Filtre par recherche textuelle
        response = self.client.get(f"{self.product_list_url}?search=iPhone")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_product_detail(self):
        response = self.client.get(self.product_detail_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['nom_complet'], "Apple iPhone 15 Noir 256 Go")
        self.assertEqual(len(response.data['variantes']), 1)
        self.assertEqual(response.data['variantes'][0]['sku'], "IPHONE-15-NOIR-8-256")


class TwilioSandboxTests(APITestCase):

    def test_twilio_sandbox_flow(self):
        # On force DEBUG = True et on vide temporairement les clés Twilio dans settings
        original_debug = settings.DEBUG
        original_sid = settings.TWILIO_ACCOUNT_SID
        
        settings.DEBUG = True
        settings.TWILIO_ACCOUNT_SID = None # Simuler l'absence de config Twilio
        
        phone_number = "+22611223344"
        
        try:
            # 1. Envoi de l'OTP (doit générer un code local et le stocker sans exception)
            send_verification_otp(phone_number)
            
            # Vérifier qu'un OTP a été créé dans la base de données locale
            otp_record = OTPVerification.objects.filter(phone_number=phone_number, is_verified=False).first()
            self.assertIsNotNone(otp_record)
            self.assertEqual(len(otp_record.code), 6)
            
            # 2. Vérification de l'OTP avec un mauvais code (doit renvoyer False)
            is_valid_wrong = check_verification_otp(phone_number, "000000")
            self.assertFalse(is_valid_wrong)
            
            # 3. Vérification de l'OTP avec le bon code (doit renvoyer True et marquer comme vérifié)
            is_valid_correct = check_verification_otp(phone_number, otp_record.code)
            self.assertTrue(is_valid_correct)
            
            # Vérifier que le code est marqué comme vérifié en base
            otp_record.refresh_from_db()
            self.assertTrue(otp_record.is_verified)
            
        finally:
            # Restaurer les settings originaux
            settings.DEBUG = original_debug
            settings.TWILIO_ACCOUNT_SID = original_sid
