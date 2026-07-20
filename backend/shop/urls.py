from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CartView, CartItemView, CheckoutView, OrderListView, OrderDetailView,
    CategoryListView, ProductListView, ProductDetailView,
    KitListView, KitDetailView, ActivePromotionsView,
    NotificationListView, NotificationMarkReadView,
    FavoriteListView, FavoriteToggleView,
    AvisListCreateView
)
from .admin_views import (
    AdminProductViewSet, AdminProductVariantViewSet, AdminCategoryViewSet,
    AdminColorViewSet, AdminBrandViewSet, AdminKitViewSet, AdminPromotionViewSet
)

router = DefaultRouter()
router.register(r'admin/products', AdminProductViewSet, basename='admin-product')
router.register(r'admin/variants', AdminProductVariantViewSet, basename='admin-variant')
router.register(r'admin/categories', AdminCategoryViewSet, basename='admin-category')
router.register(r'admin/colors', AdminColorViewSet, basename='admin-color')
router.register(r'admin/brands', AdminBrandViewSet, basename='admin-brand')
router.register(r'admin/kits', AdminKitViewSet, basename='admin-kit')
router.register(r'admin/promotions', AdminPromotionViewSet, basename='admin-promotion')


urlpatterns = [
    path('', include(router.urls)),
    path("categories/", CategoryListView.as_view(), name="category-list"),
    path("products/", ProductListView.as_view(), name="product-list"),
    path("products/<int:pk>/", ProductDetailView.as_view(), name="product-detail"),
    path("kits/", KitListView.as_view(), name="kit-list"),
    path("kits/<int:pk>/", KitDetailView.as_view(), name="kit-detail"),
    path("promotions/active/", ActivePromotionsView.as_view(), name="active-promotions"),
    path("cart/", CartView.as_view(), name="cart"),
    path("cart/<int:pk>/", CartItemView.as_view(), name="cart-item"),
    path("checkout/", CheckoutView.as_view(), name="checkout"),
    path("orders/", OrderListView.as_view(), name="order-list"),
    path("orders/<int:pk>/", OrderDetailView.as_view(), name="order-detail"),
    path("notifications/", NotificationListView.as_view(), name="notification-list"),
    path("notifications/<int:pk>/read/", NotificationMarkReadView.as_view(), name="notification-read"),
    path("favorites/", FavoriteListView.as_view(), name="favorite-list"),
    path("favorites/<int:pk>/toggle/", FavoriteToggleView.as_view(), name="favorite-toggle"),
    path("products/<int:pk>/avis/", AvisListCreateView.as_view(), name="product-avis"),
]
