from rest_framework import viewsets, parsers, status
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.decorators import action

from .models import (
    Product, VariantImage, ProductVariant, Category, Color, Brand,
    Kit, KitItem, Promotion, StockMovement, ExpenseCategory, Expense, Employee
)
from .admin_serializers import (
    AdminProductSerializer, AdminVariantImageSerializer, AdminProductVariantSerializer,
    AdminCategorySerializer, AdminColorSerializer, AdminBrandSerializer,
    AdminKitSerializer, AdminKitItemSerializer, AdminPromotionSerializer,
    AdminStockMovementSerializer, AdminExpenseCategorySerializer, AdminExpenseSerializer,
    AdminEmployeeSerializer
)

class AdminProductViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminProductSerializer

    def get_queryset(self):
        queryset = Product.objects.all().order_by('-created_at')
        statut = self.request.query_params.get('statut_publication')
        if statut:
            queryset = queryset.filter(statut_publication=statut)
        return queryset

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

    @action(detail=True, methods=['delete'])
    def delete_image(self, request, pk=None):
        variante = self.get_object()
        image_id = request.data.get('image_id')
        if not image_id:
            return Response({'detail': 'No image_id provided.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            image = variante.images.get(id=image_id)
            image.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except VariantImage.DoesNotExist:
            return Response({'detail': 'Image introuvable.'}, status=status.HTTP_404_NOT_FOUND)

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


class AdminInventoryViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminUser]

    @action(detail=False, methods=['get'], url_path='low-stock')
    def low_stock(self, request):
        variants = ProductVariant.objects.filter(stock__lt=5).order_by('stock')
        serializer = AdminProductVariantSerializer(variants, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def movements(self, request):
        movements = StockMovement.objects.all().order_by('-date')[:100]
        serializer = AdminStockMovementSerializer(movements, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def adjust(self, request):
        variant_id = request.data.get('variante')
        quantite = request.data.get('quantite')
        motif = request.data.get('motif', 'Ajustement manuel')

        if not variant_id or quantite is None:
            return Response({'detail': 'variante et quantite sont requis.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            quantite = int(quantite)
            variante = ProductVariant.objects.get(id=variant_id)
            
            if quantite == 0:
                return Response({'detail': 'La quantité doit être différente de zéro.'}, status=status.HTTP_400_BAD_REQUEST)

            type_mouv = 'entree' if quantite > 0 else 'sortie'
            
            StockMovement.objects.create(
                variante=variante,
                quantite=quantite,
                type_mouvement=type_mouv,
                motif=motif
            )
            
            variante.stock += quantite
            variante.save()
            
            return Response({'detail': 'Stock mis à jour avec succès.', 'nouveau_stock': variante.stock})
        except ProductVariant.DoesNotExist:
            return Response({'detail': 'Variante introuvable.'}, status=status.HTTP_404_NOT_FOUND)
        except ValueError:
            return Response({'detail': 'Quantite invalide.'}, status=status.HTTP_400_BAD_REQUEST)


class AdminDashboardViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminUser]

    @action(detail=False, methods=['get'])
    def overview(self, request):
        from .models import Order
        from django.utils import timezone
        from django.contrib.auth import get_user_model
        
        User = get_user_model()
        now = timezone.now()
        
        orders_today = Order.objects.filter(
            created_at__year=now.year,
            created_at__month=now.month,
            created_at__day=now.day,
        )
        ventes_jour = sum(o.total_price for o in orders_today if o.statut not in ['en_attente_paiement', 'annule'])
        commandes_jour = orders_today.count()

        orders_month = Order.objects.filter(
            created_at__year=now.year,
            created_at__month=now.month,
        )
        ventes_mois = sum(o.total_price for o in orders_month if o.statut not in ['en_attente_paiement', 'annule'])
        commandes_mois = orders_month.count()

        commandes_attente = Order.objects.filter(statut='en_attente_paiement').count()
        rupture_stock = ProductVariant.objects.filter(stock=0).count()
        total_clients = User.objects.filter(is_superuser=False, is_staff=False).count()

        all_completed_orders = Order.objects.exclude(statut__in=['en_attente_paiement', 'annule'])
        monthly_sales = {}
        for o in all_completed_orders:
            month_key = f"{o.created_at.year}-{o.created_at.month:02d}"
            monthly_sales[month_key] = monthly_sales.get(month_key, 0) + o.total_price
        
        top_mois = ""
        top_mois_montant = 0
        if monthly_sales:
            best_month_key = max(monthly_sales, key=monthly_sales.get)
            top_mois = best_month_key
            top_mois_montant = monthly_sales[best_month_key]

        return Response({
            'ventes_jour': ventes_jour,
            'commandes_jour': commandes_jour,
            'ventes_mois': ventes_mois,
            'commandes_mois': commandes_mois,
            'commandes_attente': commandes_attente,
            'rupture_stock': rupture_stock,
            'total_clients': total_clients,
            'top_mois': top_mois,
            'top_mois_montant': top_mois_montant
        })

    @action(detail=False, methods=['get'])
    def history_filter(self, request):
        from .models import Order
        year = request.query_params.get('year')
        month = request.query_params.get('month')
        day = request.query_params.get('day')
        
        queryset = Order.objects.all().order_by('-created_at')
        
        if year:
            queryset = queryset.filter(created_at__year=year)
        if month:
            queryset = queryset.filter(created_at__month=month)
        if day:
            queryset = queryset.filter(created_at__day=day)
            
        ventes_total = sum(o.total_price for o in queryset if o.statut not in ['en_attente_paiement', 'annule'])
        
        data = []
        for o in queryset:
            data.append({
                'id': o.id,
                'user': o.user.username if o.user else 'Anonyme',
                'total': o.total_price,
                'statut': o.statut,
                'created_at': o.created_at
            })
            
        return Response({
            'total_ventes': ventes_total,
            'nombre_commandes': queryset.count(),
            'commandes': data
        })

class AdminExpenseCategoryViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = ExpenseCategory.objects.all()
    serializer_class = AdminExpenseCategorySerializer

class AdminExpenseViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = Expense.objects.all().order_by('-date')
    serializer_class = AdminExpenseSerializer

class AdminEmployeeViewSet(viewsets.ModelViewSet):
    """CRUD complet pour les employés et leurs salaires."""
    permission_classes = [IsAdminUser]
    queryset = Employee.objects.all().order_by('nom')
    serializer_class = AdminEmployeeSerializer

class AdminFinanceViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminUser]

    @action(detail=False, methods=['get'])
    def report(self, request):
        from .models import Order
        from django.db.models import Sum
        
        year = request.query_params.get('year')
        month = request.query_params.get('month')
        
        orders = Order.objects.exclude(statut__in=['en_attente_paiement', 'annule'])
        expenses = Expense.objects.all()
        
        if year:
            orders = orders.filter(created_at__year=year)
            expenses = expenses.filter(date__year=year)
        if month:
            orders = orders.filter(created_at__month=month)
            expenses = expenses.filter(date__month=month)
            
        ca = sum(o.total_price for o in orders)
        
        cout_marchandises = 0
        for o in orders:
            for item in o.items.all():
                if hasattr(item.item, 'prix_achat'):
                    cout_marchandises += (item.item.prix_achat * item.quantite)
                    
        marge_brute = ca - cout_marchandises
        
        # Total des charges fixes (loyer, électricité, autres)
        total_charges_fixes = expenses.aggregate(Sum('montant'))['montant__sum'] or 0
        
        # Total des salaires des employés actifs
        # Si un mois précis est demandé → on compte le salaire mensuel de ce mois
        # Sinon (année entière) → on multiplie par 12 (estimation annuelle)
        employes_actifs = Employee.objects.filter(est_actif=True)
        total_salaires_mois = employes_actifs.aggregate(Sum('salaire_mensuel'))['salaire_mensuel__sum'] or 0
        
        if month:
            # Mois précis : salaire mensuel
            total_salaires = float(total_salaires_mois)
        elif year:
            # Année entière : 12 mois de salaires
            total_salaires = float(total_salaires_mois) * 12
        else:
            # Pas de filtre : on retourne le salaire mensuel courant (pas extrapolé)
            total_salaires = float(total_salaires_mois)
        
        total_charges = float(total_charges_fixes) + total_salaires
        
        benefice_net = float(marge_brute) - total_charges
        
        return Response({
            'chiffre_affaires': ca,
            'cout_marchandises': cout_marchandises,
            'marge_brute': marge_brute,
            'total_charges_fixes': float(total_charges_fixes),
            'total_salaires': total_salaires,
            'total_charges': total_charges,
            'benefice_net': benefice_net,
            'nb_employes': employes_actifs.count(),
        })
