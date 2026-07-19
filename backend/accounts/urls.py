from django.urls import path
from .views import RegisterView, LoginView, VerifyOTPView, SocialLoginView, SocialRegisterView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('social-login/', SocialLoginView.as_view(), name='social-login'),
    path('social-register/', SocialRegisterView.as_view(), name='social-register'),
]
