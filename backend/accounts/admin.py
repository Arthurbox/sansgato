from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, OTPVerification

# Configuration personnalisée de l'administration pour notre modèle User personnalisé
class CustomUserAdmin(UserAdmin):
    model = User
    list_display = ['username', 'phone_number', 'is_phone_verified', 'is_staff', 'is_active']
    fieldsets = UserAdmin.fieldsets + (
        (None, {'fields': ('is_phone_verified',)}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        (None, {'fields': ('phone_number', 'is_phone_verified')}),
    )

admin.site.register(User, CustomUserAdmin)
admin.site.register(OTPVerification)
