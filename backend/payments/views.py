import hmac
import hashlib
import json
from django.conf import settings
from django.db import transaction
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from .models import Payment

class PaymentWebhookView(APIView):
    """POST – Webhook pour recevoir les notifications de paiement."""
    permission_classes = [AllowAny]

    def post(self, request):
        # 1. Vérification de la signature HMAC (Sécurité)
        signature_fournie = request.headers.get("X-Webhook-Signature")
        if not signature_fournie:
            return Response({"detail": "Signature manquante."}, status=status.HTTP_403_FORBIDDEN)
        
        # Calcul de la signature attendue
        payload_bytes = request.body
        secret_bytes = settings.WEBHOOK_SECRET.encode('utf-8')
        signature_attendue = hmac.new(secret_bytes, payload_bytes, hashlib.sha256).hexdigest()
        
        if not hmac.compare_digest(signature_fournie, signature_attendue):
            return Response({"detail": "Signature invalide."}, status=status.HTTP_403_FORBIDDEN)

        # 2. Traitement du webhook
        try:
            data = json.loads(payload_bytes)
        except json.JSONDecodeError:
            return Response({"detail": "JSON invalide."}, status=status.HTTP_400_BAD_REQUEST)

        transaction_id = data.get("transaction_id")
        status_paiement = data.get("status")

        if not transaction_id or not status_paiement:
            return Response({"detail": "Données invalides."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # 3. Transaction atomique pour garantir l'intégrité de la DB
            with transaction.atomic():
                # select_for_update verrouille la ligne pour éviter les race conditions
                payment = Payment.objects.select_for_update().get(transaction_id=transaction_id)
                
                if status_paiement == "success":
                    payment.payment_status = "paye"
                    payment.commande.statut = "accepte"
                    payment.commande.save()
                elif status_paiement == "failed":
                    payment.payment_status = "echoue"
                
                payment.save()
                
            return Response({"detail": "Statut mis à jour avec succès."}, status=status.HTTP_200_OK)
        except Payment.DoesNotExist:
            return Response({"detail": "Paiement introuvable."}, status=status.HTTP_404_NOT_FOUND)
