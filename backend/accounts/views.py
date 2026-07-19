from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import RegisterSerializer, LoginSerializer, VerifyOTPSerializer
from .twilio_service import send_verification_otp

class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            if user.phone_number:
                try:
                    send_verification_otp(user.phone_number)
                except Exception as e:
                    user.delete()
                    return Response({
                        "detail": f"Erreur Twilio : impossible d'envoyer le SMS de vérification ({str(e)})"
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                return Response({
                    "message": "Inscription réussie. Veuillez valider votre numéro avec le code OTP envoyé par SMS.",
                    "phone_number": user.phone_number,
                    "requires_otp": True
                }, status=status.HTTP_201_CREATED)
            else:
                refresh = RefreshToken.for_user(user)
                return Response({
                    "message": "Inscription réussie.",
                    "requires_otp": False,
                    "tokens": {
                        "refresh": str(refresh),
                        "access": str(refresh.access_token),
                    },
                    "user": {
                        "username": user.username,
                        "email": user.email,
                        "is_staff": user.is_staff
                    }
                }, status=status.HTTP_201_CREATED)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            identifier = serializer.validated_data['identifier']
            
            if user.phone_number and identifier == user.phone_number:
                try:
                    send_verification_otp(user.phone_number)
                except Exception as e:
                    return Response({
                        "detail": f"Erreur Twilio : impossible d'envoyer le SMS de vérification ({str(e)})"
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                return Response({
                    "message": "Identifiants corrects. Veuillez entrer le code OTP envoyé par SMS.",
                    "phone_number": user.phone_number,
                    "requires_otp": True
                }, status=status.HTTP_200_OK)
            else:
                refresh = RefreshToken.for_user(user)
                return Response({
                    "message": "Connexion réussie.",
                    "requires_otp": False,
                    "tokens": {
                        "refresh": str(refresh),
                        "access": str(refresh.access_token),
                    },
                    "user": {
                        "username": user.username,
                        "email": user.email,
                        "is_staff": user.is_staff
                    }
                }, status=status.HTTP_200_OK)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        if serializer.is_valid():
            phone_number = serializer.validated_data['phone_number']
            purpose = serializer.validated_data['purpose']
            
            # Trouver l'utilisateur
            try:
                user = User.objects.get(phone_number=phone_number)
            except User.DoesNotExist:
                return Response({"detail": "Utilisateur non trouvé."}, status=status.HTTP_404_NOT_FOUND)
            
            if purpose == 'register':
                user.is_phone_verified = True
                user.save()
            
            # Générer le token JWT
            refresh = RefreshToken.for_user(user)
            
            return Response({
                "message": "Vérification réussie.",
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
                "user": {
                    "username": user.username,
                    "phone_number": user.phone_number,
                    "is_phone_verified": user.is_phone_verified,
                    "is_staff": user.is_staff
                }
            }, status=status.HTTP_200_OK)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

import requests
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from django.conf import settings
from .serializers import SocialLoginSerializer, SocialRegisterSerializer

class SocialLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SocialLoginSerializer(data=request.data)
        if serializer.is_valid():
            provider = serializer.validated_data['provider']
            token = serializer.validated_data['token']
            
            email = None
            name = None
            
            if provider == 'google':
                try:
                    # Utilise l'endpoint tokeninfo de Google (plus fiable que verify_oauth2_token)
                    token_info_url = f"https://oauth2.googleapis.com/tokeninfo?id_token={token}"
                    token_resp = requests.get(token_info_url)
                    token_data = token_resp.json()
                    
                    # Log pour debug
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.warning(f"[Google] tokeninfo response: {token_data}")
                    
                    if 'error_description' in token_data or 'error' in token_data:
                        error_msg = token_data.get('error_description', token_data.get('error', 'Token invalide'))
                        return Response({"detail": f"Token Google invalide: {error_msg}"}, status=status.HTTP_400_BAD_REQUEST)
                    
                    email = token_data.get('email')
                    name = token_data.get('name')
                    
                except Exception as e:
                    return Response({"detail": f"Erreur vérification Google: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)
            
            elif provider == 'facebook':
                try:
                    graph_url = f"https://graph.facebook.com/me?fields=id,name,email&access_token={token}"
                    resp = requests.get(graph_url)
                    data = resp.json()
                    if 'error' in data:
                        return Response({"detail": "Token Facebook invalide."}, status=status.HTTP_400_BAD_REQUEST)
                    email = data.get('email')
                    name = data.get('name')
                except Exception:
                    return Response({"detail": "Erreur lors de la vérification Facebook."}, status=status.HTTP_400_BAD_REQUEST)
            
            if not email:
                return Response({"detail": "L'email n'a pas pu être récupéré depuis le fournisseur."}, status=status.HTTP_400_BAD_REQUEST)
            
            # Vérifier si l'utilisateur existe déjà
            try:
                user = User.objects.get(email=email)
                # L'utilisateur existe, on le connecte
                refresh = RefreshToken.for_user(user)
                return Response({
                    "message": "Connexion sociale réussie.",
                    "tokens": {
                        "refresh": str(refresh),
                        "access": str(refresh.access_token),
                    },
                    "user": {
                        "username": user.username,
                        "phone_number": user.phone_number,
                        "is_phone_verified": user.is_phone_verified,
                        "is_staff": user.is_staff
                    }
                }, status=status.HTTP_200_OK)
            except User.DoesNotExist:
                # Nouvel utilisateur, on redirige vers l'étape 2 (téléphone)
                return Response({
                    "requires_phone": True,
                    "email": email,
                    "name": name,
                    "provider": provider
                }, status=status.HTTP_200_OK)
                
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SocialRegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SocialRegisterSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            name = serializer.validated_data['name']
            phone_number = serializer.validated_data['phone_number']
            
            # Générer un username unique à partir du nom
            base_username = name.replace(" ", "")
            username = base_username
            counter = 1
            while User.objects.filter(username=username).exists():
                username = f"{base_username}{counter}"
                counter += 1

            # Créer l'utilisateur (is_phone_verified=False par défaut)
            # On génère un mot de passe aléatoire car c'est un compte social
            user = User.objects.create_user(
                phone_number=phone_number,
                username=username,
                email=email,
                is_active=True
            )
            user.set_unusable_password()
            user.save()
            
            # Envoyer le code OTP
            try:
                send_verification_otp(user.phone_number)
            except Exception as e:
                user.delete()
                return Response({
                    "detail": f"Erreur Twilio : impossible d'envoyer le SMS ({str(e)})"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            return Response({
                "message": "Inscription sociale initiée. Veuillez valider votre numéro de téléphone.",
                "phone_number": user.phone_number
            }, status=status.HTTP_201_CREATED)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
