from rest_framework import viewsets, parsers, status
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.decorators import action

from .models import (
    Product, VariantImage, ProductVariant, Category, Color, Brand,
    Kit, KitItem, Promotion
)
from .admin_serializers import (
    AdminProductSerializer, AdminVariantImageSerializer, AdminProductVariantSerializer,
    AdminCategorySerializer, AdminColorSerializer, AdminBrandSerializer,
    AdminKitSerializer, AdminKitItemSerializer, AdminPromotionSerializer
)

class AdminProductViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = Product.objects.all().order_by('-created_at')
    serializer_class = AdminProductSerializer

    def destroy(self, request, *args, **kwargs):
        from django.db.models import ProtectedError
        try:
            return super().destroy(request, *args, **kwargs)
        except ProtectedError:
            return Response(
                {"detail": "Ce produit ne peut pas être supprimé car il est utilisé (ex: dans un kit, une commande ou une promotion)."},
                status=status.HTTP_400_BAD_REQUEST
            )



class AdminProductVariantViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = ProductVariant.objects.all().order_by('-created_at')
    serializer_class = AdminProductVariantSerializer

    def destroy(self, request, *args, **kwargs):
        from django.db.models import ProtectedError
        try:
            return super().destroy(request, *args, **kwargs)
        except ProtectedError:
            return Response(
                {"detail": "Cette variante ne peut pas être supprimée car elle est utilisée (ex: dans un kit ou une commande)."},
                status=status.HTTP_400_BAD_REQUEST
            )

    def perform_create(self, serializer):
        import uuid
        if not serializer.validated_data.get('sku'):
            serializer.validated_data['sku'] = f"SKU-{str(uuid.uuid4())[:8].upper()}"
        serializer.save()

    @action(detail=True, methods=['post'])
    def upload_image(self, request, pk=None):
        variante = self.get_object()
        image_url = request.data.get('image_url')
        if not image_url:
            return Response({'detail': 'No image_url provided.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Obtenir l'ordre maximum existant
        last_image = variante.images.order_by('-ordre').first()
        ordre = (last_image.ordre + 1) if last_image else 0

        image = VariantImage.objects.create(variante=variante, image=image_url, ordre=ordre)
        serializer = AdminVariantImageSerializer(image)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class AdminCategoryViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = Category.objects.all()
    serializer_class = AdminCategorySerializer

class AdminColorViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = Color.objects.all()
    serializer_class = AdminColorSerializer

class AdminBrandViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminBrandSerializer

    def get_queryset(self):
        queryset = Brand.objects.all()
        category_id = self.request.query_params.get('category')
        if category_id:
            queryset = queryset.filter(categories__id=category_id)
        return queryset

class AdminKitViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = Kit.objects.all().order_by('-created_at')
    serializer_class = AdminKitSerializer

    @action(detail=True, methods=['post'])
    def upload_image(self, request, pk=None):
        kit = self.get_object()
        image_url = request.data.get('image_url')
        if not image_url:
            return Response({'detail': 'No image_url provided.'}, status=status.HTTP_400_BAD_REQUEST)
        
        kit.image = image_url
        kit.save()
        serializer = self.get_serializer(kit)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        kit = self.get_object()
        variante_id = request.data.get('variante')
        quantite = request.data.get('quantite', 1)

        try:
            variante = ProductVariant.objects.get(id=variante_id)
            kit_item, created = KitItem.objects.update_or_create(
                kit=kit,
                variante=variante,
                defaults={'quantite': quantite}
            )
            return Response(AdminKitItemSerializer(kit_item).data, status=status.HTTP_201_CREATED)
        except ProductVariant.DoesNotExist:
            return Response({'detail': 'Variante introuvable'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=True, methods=['post'])
    def remove_item(self, request, pk=None):
        kit = self.get_object()
        variante_id = request.data.get('variante')
        KitItem.objects.filter(kit=kit, variante_id=variante_id).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

class AdminPromotionViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = Promotion.objects.all().order_by('-created_at')
    serializer_class = AdminPromotionSerializer

