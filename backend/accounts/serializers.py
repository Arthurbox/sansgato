import re
from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User, OTPVerification

class RegisterSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=150)
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    email = serializers.EmailField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, data):
        phone_number = data.get('phone_number')
        email = data.get('email')

        if not phone_number and not email:
            raise serializers.ValidationError("Le numéro de téléphone ou l'email est requis.")

        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({"password": "Les mots de passe ne correspondent pas."})

        if phone_number:
            clean_phone = re.sub(r'[\s\-]', '', phone_number)
            if not re.match(r'^\+?[0-9]+$', clean_phone):
                raise serializers.ValidationError({"phone_number": "Le format du numéro de téléphone est invalide."})
            if User.objects.filter(phone_number=clean_phone).exists():
                raise serializers.ValidationError({"phone_number": "Ce numéro de téléphone est déjà enregistré."})
            data['phone_number'] = clean_phone

        if email:
            if User.objects.filter(email=email).exists():
                raise serializers.ValidationError({"email": "Cet e-mail est déjà enregistré."})

        return data

    def create(self, validated_data):
        full_name = validated_data.pop('full_name')
        
        base_username = full_name.replace(" ", "").lower()
        if not base_username:
            base_username = "user"
        username = base_username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1
            
        validated_data['username'] = username
        validated_data['first_name'] = full_name
        
        validated_data.pop('confirm_password')
        password = validated_data.pop('password')
        
        user = User.objects.create_user(
            phone_number=validated_data.get('phone_number'),
            email=validated_data.get('email'),
            username=validated_data['username'],
            password=password,
            first_name=validated_data.get('first_name', ''),
            is_active=True 
        )
        return user


class LoginSerializer(serializers.Serializer):
    identifier = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        identifier = data.get('identifier', '').strip()
        password = data.get('password')

        if not identifier or not password:
            raise serializers.ValidationError("L'identifiant et le mot de passe sont requis.")
            
        user = None
        if '@' in identifier:
            try:
                user_obj = User.objects.get(email=identifier)
                user = authenticate(username=user_obj.username, password=password)
            except User.DoesNotExist:
                pass
        else:
            clean_phone = re.sub(r'[\s\-]', '', identifier)
            try:
                user_obj = User.objects.get(phone_number=clean_phone)
                user = authenticate(username=user_obj.username, password=password)
            except User.DoesNotExist:
                pass

        if not user:
            raise serializers.ValidationError("Identifiants incorrects.")

        data['user'] = user
        data['identifier'] = identifier
        return data


from .twilio_service import check_verification_otp

class VerifyOTPSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    code = serializers.CharField(max_length=6)
    purpose = serializers.ChoiceField(choices=[('register', 'register'), ('login', 'login')])

    def validate(self, data):
        phone_number = re.sub(r'[\s\-]', '', data.get('phone_number', ''))
        code = data.get('code')
        purpose = data.get('purpose')

        try:
            is_valid = check_verification_otp(phone_number, code)
            if not is_valid:
                raise serializers.ValidationError({"code": "Code de vérification incorrect ou expiré."})
        except Exception as e:
            raise serializers.ValidationError({"code": f"Erreur de validation OTP : {str(e)}"})

        data['phone_number'] = phone_number
        return data

class SocialLoginSerializer(serializers.Serializer):
    provider = serializers.ChoiceField(choices=['google', 'facebook'])
    token = serializers.CharField()

class SocialRegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    name = serializers.CharField(max_length=150)
    phone_number = serializers.CharField(max_length=20)
    provider = serializers.ChoiceField(choices=['google', 'facebook'], required=False)
    
    def validate_phone_number(self, value):
        clean_value = re.sub(r'[\s\-]', '', value)
        if not re.match(r'^\+?[0-9]+$', clean_value):
            raise serializers.ValidationError("Le format du numéro de téléphone est invalide.")
        if User.objects.filter(phone_number=clean_value).exists():
            raise serializers.ValidationError("Ce numéro de téléphone est déjà enregistré.")
        return clean_value
