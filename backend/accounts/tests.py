from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from unittest.mock import patch

from .models import User

class AuthenticationTests(APITestCase):

    def setUp(self):
        self.register_url = reverse('register')
        self.login_url = reverse('login')
        self.verify_url = reverse('verify-otp')
        self.user_data = {
            'username': 'testuser',
            'phone_number': '+33612345678',
            'password': 'testpassword123',
            'confirm_password': 'testpassword123'
        }

    @patch('accounts.views.send_verification_otp')
    @patch('accounts.serializers.check_verification_otp')
    def test_registration_flow(self, mock_check, mock_send):
        mock_check.return_value = True
        mock_send.return_value = None

        # 1. Tester l'inscription
        response = self.client.post(self.register_url, self.user_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('phone_number', response.data)
        
        # Vérifier que le service d'envoi OTP a bien été appelé
        mock_send.assert_called_once_with('+33612345678')

        # Vérifier que l'utilisateur a été créé et n'est pas encore vérifié
        user = User.objects.get(phone_number='+33612345678')
        self.assertEqual(user.username, 'testuser')
        self.assertFalse(user.is_phone_verified)

        # 2. Tester la vérification de l'OTP
        verify_data = {
            'phone_number': '+33612345678',
            'code': '123456',
            'purpose': 'register'
        }
        verify_response = self.client.post(self.verify_url, verify_data, format='json')
        self.assertEqual(verify_response.status_code, status.HTTP_200_OK)
        self.assertIn('tokens', verify_response.data)
        self.assertIn('access', verify_response.data['tokens'])

        # Vérifier que le service de validation OTP a été appelé avec les bons paramètres
        mock_check.assert_called_once_with('+33612345678', '123456')

        # Vérifier que l'utilisateur est maintenant marqué comme vérifié
        user.refresh_from_db()
        self.assertTrue(user.is_phone_verified)

    @patch('accounts.views.send_verification_otp')
    @patch('accounts.serializers.check_verification_otp')
    def test_login_flow(self, mock_check, mock_send):
        mock_check.return_value = True
        mock_send.return_value = None

        # Créer d'abord un utilisateur vérifié
        user = User.objects.create_user(
            username='existinguser',
            phone_number='+33698765432',
            password='securepassword'
        )
        user.is_phone_verified = True
        user.save()

        # 1. Initier la connexion
        login_data = {
            'phone_number': '+33698765432',
            'password': 'securepassword'
        }
        response = self.client.post(self.login_url, login_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Vérifier que le service d'envoi OTP a bien été appelé
        mock_send.assert_called_once_with('+33698765432')
        
        # 2. Vérifier l'OTP
        verify_data = {
            'phone_number': '+33698765432',
            'code': '123456',
            'purpose': 'login'
        }
        verify_response = self.client.post(self.verify_url, verify_data, format='json')
        self.assertEqual(verify_response.status_code, status.HTTP_200_OK)
        self.assertIn('tokens', verify_response.data)
        mock_check.assert_called_once_with('+33698765432', '123456')

    @patch('accounts.views.send_verification_otp')
    @patch('accounts.serializers.check_verification_otp')
    def test_invalid_otp(self, mock_check, mock_send):
        mock_check.return_value = False
        mock_send.return_value = None

        # Inscrire un utilisateur
        self.client.post(self.register_url, self.user_data, format='json')
        
        # Tenter de vérifier avec un code erroné
        verify_data = {
            'phone_number': '+33612345678',
            'code': '000000', # Code incorrect
            'purpose': 'register'
        }
        response = self.client.post(self.verify_url, verify_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        mock_check.assert_called_once_with('+33612345678', '000000')
