from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.utils import timezone

class UserManager(BaseUserManager):
    def create_user(self, phone_number, username, password=None, **extra_fields):
        if not phone_number and not extra_fields.get('email'):
            raise ValueError("Le numéro de téléphone ou l'email est requis")
        if not username:
            raise ValueError("Le nom d'utilisateur est requis")
        
        email = self.normalize_email(extra_fields.pop('email', ''))
        user = self.model(
            phone_number=phone_number,
            username=username,
            email=email,
            **extra_fields
        )
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, username, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('is_phone_verified', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(phone_number, username, password, **extra_fields)


class User(AbstractUser):
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    is_phone_verified = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = []

    def __str__(self):
        return f"{self.username} ({self.phone_number})"


class OTPVerification(models.Model):
    PURPOSE_CHOICES = [
        ('register', 'Inscription'),
        ('login', 'Connexion'),
    ]
    phone_number = models.CharField(max_length=20)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_verified = models.BooleanField(default=False)
    purpose = models.CharField(max_length=10, choices=PURPOSE_CHOICES)

    def is_expired(self):
        return timezone.now() > self.expires_at

    def __str__(self):
        return f"OTP {self.code} pour {self.phone_number} ({self.purpose})"
